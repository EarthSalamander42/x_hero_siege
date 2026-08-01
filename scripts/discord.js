const fs = require("fs");

const webhookUrl = process.env.DISCORD_WEBHOOK;
const eventName = process.env.GITHUB_EVENT_NAME;
const eventPath = process.env.GITHUB_EVENT_PATH;
const githubToken = process.env.GITHUB_TOKEN;
const discordMessageId = process.env.DISCORD_MESSAGE_ID;

if (!webhookUrl) {
	console.error("Missing DISCORD_WEBHOOK secret.");
	process.exit(1);
}

const event = JSON.parse(fs.readFileSync(eventPath, "utf8"));
const repo = event.repository || {};
const sender = event.sender || {};
const repoName = repo.full_name || "Unknown repository";
const repoUrl = repo.html_url || "";
const avatarUrl = sender.avatar_url || repo.owner?.avatar_url || undefined;

const COLORS = {
	success: 0x2ecc71,
	info: 0x3498db,
	warning: 0xf1c40f,
	danger: 0xe74c3c,
	purple: 0x9b59b6,
	gray: 0x95a5a6,
	discord: 0x5865f2
};

function truncate(text, max = 1000) {
	if (!text) return "";
	const value = String(text);
	return value.length > max ? `${value.slice(0, max - 3)}...` : value;
}

function titleCase(value) {
	return String(value || "")
		.replace(/_/g, " ")
		.replace(/\b\w/g, char => char.toUpperCase());
}

function shortSha(value) {
	return value ? value.slice(0, 7) : "unknown";
}

function field(name, value, inline = true) {
	return {
		name,
		value: truncate(value || "N/A", 1024),
		inline
	};
}

function baseEmbed({ title, description, url, color = COLORS.discord, fields = [] }) {
	return {
		title,
		description: truncate(description, 3900),
		url: url || repoUrl,
		color,
		author: {
			name: sender.login || "GitHub",
			icon_url: avatarUrl,
			url: sender.html_url || undefined
		},
		fields: [
			field("Repository", repoUrl ? `[${repoName}](${repoUrl})` : repoName),
			...fields
		],
		timestamp: new Date().toISOString(),
		footer: {
			text: "GitHub Notifications"
		}
	};
}

async function getCommitStats(commit) {
	if (!commit?.id || !repo.full_name) return null;

	const headers = {
		Accept: "application/vnd.github+json",
		"X-GitHub-Api-Version": "2022-11-28"
	};

	if (githubToken) headers.Authorization = `Bearer ${githubToken}`;

	try {
		const response = await fetch(`https://api.github.com/repos/${repo.full_name}/commits/${commit.id}`, {
			headers
		});

		if (!response.ok) {
			console.warn(`Could not load stats for ${shortSha(commit.id)}: GitHub API returned ${response.status}.`);
			return null;
		}

		const details = await response.json();
		if (!details.stats) return null;

		return {
			additions: Number(details.stats.additions) || 0,
			deletions: Number(details.stats.deletions) || 0
		};
	} catch (error) {
		console.warn(`Could not load stats for ${shortSha(commit.id)}: ${error.message}`);
		return null;
	}
}

async function addStatsToExistingDescription(description) {
	const withoutStats = String(description || "").replace(
		/\n```diff\n\+\d+ additions\n-\d+ deletions\n```/g,
		""
	);
	const commitUrlPattern = /https:\/\/github\.com\/[^/\s)]+\/[^/\s)]+\/commit\/([0-9a-f]{7,40})/i;
	const lines = withoutStats.split("\n");
	const updatedLines = [];

	for (const line of lines) {
		updatedLines.push(line);
		const match = line.match(commitUrlPattern);
		if (!match) continue;

		const stats = await getCommitStats({ id: match[1] });
		if (stats) {
			updatedLines.push(`\`\`\`diff\n+${stats.additions} additions\n-${stats.deletions} deletions\n\`\`\``);
		}
	}

	return truncate(updatedLines.join("\n"), 4096);
}

async function updateDiscordMessage() {
	if (!/^\d+$/.test(discordMessageId || "")) {
		throw new Error("DISCORD_MESSAGE_ID must be a numeric Discord message ID.");
	}

	const messageUrl = `${webhookUrl}/messages/${discordMessageId}`;
	const currentResponse = await fetch(messageUrl);
	if (!currentResponse.ok) {
		throw new Error(`Could not load Discord message ${discordMessageId}: ${currentResponse.status} ${await currentResponse.text()}`);
	}

	const message = await currentResponse.json();
	if (!Array.isArray(message.embeds) || message.embeds.length === 0) {
		throw new Error(`Discord message ${discordMessageId} has no embed to update.`);
	}

	const embeds = await Promise.all(message.embeds.map(async embed => ({
		...embed,
		description: await addStatsToExistingDescription(embed.description)
	})));
	const updateResponse = await fetch(messageUrl, {
		method: "PATCH",
		headers: { "Content-Type": "application/json" },
		body: JSON.stringify({ embeds })
	});

	if (!updateResponse.ok) {
		throw new Error(`Discord message update failed: ${updateResponse.status} ${await updateResponse.text()}`);
	}

	console.log(`Updated Discord message ${discordMessageId} in place.`);
}

async function pushEmbed() {
	const branch = (event.ref || "").replace("refs/heads/", "");
	const commits = event.commits || [];
	const displayedCommits = commits.slice(0, 10);
	const commitStats = await Promise.all(displayedCommits.map(getCommitStats));

	const commitLines = displayedCommits
		.map((commit, index) => {
			const summary = `• [${shortSha(commit.id)}](${commit.url}) ${truncate(commit.message.split("\n")[0], 130)}`;
			const stats = commitStats[index];

			if (!stats) return summary;

			return `${summary}\n\`\`\`diff\n+${stats.additions} additions\n-${stats.deletions} deletions\n\`\`\``;
		})
		.join("\n");

	const extra = commits.length > 10 ? `\n…and ${commits.length - 10} more commit(s).` : "";

	return baseEmbed({
		title: "🚀 New Push",
		description: `${commitLines || "No commits listed."}${extra}`,
		url: event.compare || repoUrl,
		color: COLORS.success,
		fields: [
			field("Branch", `\`${branch}\``),
			field("Pusher", event.pusher?.name || sender.login),
			field("Commit count", String(commits.length))
		]
	});
}

function pullRequestEmbed() {
	const pr = event.pull_request;
	const merged = event.action === "closed" && pr.merged;

	let icon = "🔀";
	let color = COLORS.info;
	let action = titleCase(event.action);

	if (merged) {
		icon = "✅";
		color = COLORS.success;
		action = "Merged";
	} else if (event.action === "closed") {
		icon = "❌";
		color = COLORS.danger;
	} else if (event.action === "ready_for_review") {
		icon = "👀";
		color = COLORS.purple;
		action = "Ready For Review";
	} else if (event.action === "converted_to_draft") {
		icon = "📝";
		color = COLORS.gray;
		action = "Converted To Draft";
	} else if (event.action === "synchronize") {
		icon = "🔄";
		color = COLORS.info;
		action = "Updated";
	}

	return baseEmbed({
		title: `${icon} Pull Request ${action}`,
		description: `**#${pr.number}: ${pr.title}**\n${truncate(pr.body || "No description.", 1200)}`,
		url: pr.html_url,
		color,
		fields: [
			field("Author", pr.user.login),
			field("Branch", `\`${pr.head.ref}\` → \`${pr.base.ref}\``),
			field("Changed files", String(pr.changed_files ?? "N/A")),
			field("Additions", `+${pr.additions ?? 0}`),
			field("Deletions", `-${pr.deletions ?? 0}`)
		]
	});
}

function issueEmbed() {
	const issue = event.issue;
	const labels = (issue.labels || []).map(label => `\`${label.name}\``).join(", ") || "None";

	let color = COLORS.warning;
	if (event.action === "closed") color = COLORS.success;
	if (event.action === "reopened") color = COLORS.info;

	return baseEmbed({
		title: `🐛 Issue ${titleCase(event.action)}`,
		description: `**#${issue.number}: ${issue.title}**\n${truncate(issue.body || "No description.", 1200)}`,
		url: issue.html_url,
		color,
		fields: [
			field("Author", issue.user.login),
			field("State", issue.state),
			field("Labels", labels, false)
		]
	});
}

function commentEmbed(type, item, comment) {
	return baseEmbed({
		title: `💬 ${type} Comment ${titleCase(event.action)}`,
		description: truncate(comment.body || "No content.", 1600),
		url: comment.html_url,
		color: COLORS.warning,
		fields: [
			field("Author", comment.user.login),
			field("Target", item.title ? `#${item.number || ""} ${item.title}` : repoName, false)
		]
	});
}

function reviewEmbed() {
	const review = event.review;
	const pr = event.pull_request;

	let icon = "📝";
	let color = COLORS.purple;

	if (review.state === "approved") {
		icon = "✅";
		color = COLORS.success;
	} else if (review.state === "changes_requested") {
		icon = "❌";
		color = COLORS.danger;
	}

	return baseEmbed({
		title: `${icon} Pull Request Review ${titleCase(review.state)}`,
		description: truncate(review.body || "No review message.", 1200),
		url: review.html_url,
		color,
		fields: [
			field("Reviewer", review.user.login),
			field("Pull Request", `#${pr.number} ${pr.title}`, false)
		]
	});
}

function releaseEmbed() {
	const release = event.release;

	return baseEmbed({
		title: `📦 Release ${titleCase(event.action)}`,
		description: `**${release.name || release.tag_name}**\n\n${truncate(release.body || "No release notes.", 1800)}`,
		url: release.html_url,
		color: COLORS.success,
		fields: [
			field("Tag", `\`${release.tag_name}\``),
			field("Draft", release.draft ? "Yes" : "No"),
			field("Prerelease", release.prerelease ? "Yes" : "No")
		]
	});
}

function watchEmbed() {
	return baseEmbed({
		title: "Repository Starred",
		description: `**${sender.login || "Someone"}** starred **${repoName}**.`,
		url: repoUrl,
		color: COLORS.warning,
		fields: [
			field("Stars", String(repo.stargazers_count ?? "N/A")),
			field("Action", titleCase(event.action || "started"))
		]
	});
}

function discussionEmbed() {
	const discussion = event.discussion;

	return baseEmbed({
		title: `💬 Discussion ${titleCase(event.action)}`,
		description: `**${discussion.title}**\n${truncate(discussion.body || "No content.", 1400)}`,
		url: discussion.html_url,
		color: COLORS.discord,
		fields: [
			field("Author", discussion.user.login),
			field("Category", discussion.category?.name || "N/A")
		]
	});
}

function simpleEmbed(icon, title, description, url = repoUrl, color = COLORS.gray) {
	return baseEmbed({
		title: `${icon} ${title}`,
		description,
		url,
		color
	});
}

async function buildEmbed() {
	switch (eventName) {
		case "push":
			return await pushEmbed();

		case "pull_request":
			return pullRequestEmbed();

		case "pull_request_review":
			return reviewEmbed();

		case "pull_request_review_comment":
			return commentEmbed("Pull Request Review", event.pull_request, event.comment);

		case "issues":
			return issueEmbed();

		case "issue_comment":
			return commentEmbed("Issue", event.issue, event.comment);

		case "release":
			return releaseEmbed();

		case "watch":
			return watchEmbed();

		case "discussion":
			return discussionEmbed();

		case "discussion_comment":
			return commentEmbed("Discussion", event.discussion, event.comment);

		case "create":
			return simpleEmbed("🌱", `${titleCase(event.ref_type)} Created`, `**Name:** \`${event.ref}\``, repoUrl, COLORS.success);

		case "delete":
			return simpleEmbed("🗑️", `${titleCase(event.ref_type)} Deleted`, `**Name:** \`${event.ref}\``, repoUrl, COLORS.danger);

		case "label":
			return simpleEmbed("🏷️", `Label ${titleCase(event.action)}`, `**Label:** \`${event.label.name}\``, repoUrl, COLORS.gray);

		case "milestone":
			return simpleEmbed("🎯", `Milestone ${titleCase(event.action)}`, `**Milestone:** ${event.milestone.title}`, event.milestone.html_url, COLORS.warning);

		case "gollum":
			return simpleEmbed(
				"📚",
				"Wiki Updated",
				event.pages.map(page => `• [${page.title}](${page.html_url}) — ${page.action}`).join("\n"),
				repoUrl,
				COLORS.info
			);

		default:
			return simpleEmbed("ℹ️", `GitHub Event: ${eventName}`, `Action: ${event.action || "unknown"}`, repoUrl, COLORS.discord);
	}
}

async function sendToDiscord() {
	const embed = await buildEmbed();

	const response = await fetch(webhookUrl, {
		method: "POST",
		headers: {
			"Content-Type": "application/json"
		},
		body: JSON.stringify({
			username: "GitHub",
			avatar_url: "https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png",
			embeds: [embed]
		})
	});

	if (!response.ok) {
		const body = await response.text();
		console.error(`Discord webhook failed: ${response.status}`);
		console.error(body);
		process.exit(1);
	}
}

(discordMessageId ? updateDiscordMessage() : sendToDiscord()).catch(error => {
	console.error(error);
	process.exit(1);
});
