const fs = require("fs");

const webhookUrl = process.env.DISCORD_WEBHOOK;
const eventName = process.env.GITHUB_EVENT_NAME;
const eventPath = process.env.GITHUB_EVENT_PATH;

if (!webhookUrl) {
	console.error("Missing DISCORD_WEBHOOK secret.");
	process.exit(1);
}

const event = JSON.parse(fs.readFileSync(eventPath, "utf8"));
const repo = event.repository || {};
const sender = event.sender || {};
const repoName = repo.full_name || "Unknown repository";
const repoUrl = repo.html_url || "";
const avatarUrl = sender.avatar_url || repo.owner?.avatar_url || null;

const colors = {
	push: 0x2ecc71,
	pull_request: 0x3498db,
	pull_request_review: 0x9b59b6,
	pull_request_review_comment: 0x9b59b6,
	issues: 0xe74c3c,
	issue_comment: 0xf1c40f,
	release: 0x1abc9c,
	fork: 0x95a5a6,
	watch: 0xf1c40f,
	discussion: 0x5865f2,
	discussion_comment: 0x5865f2,
	create: 0x2ecc71,
	delete: 0xe74c3c,
	label: 0x95a5a6,
	milestone: 0xe67e22,
	gollum: 0x34495e,
	workflow_run: 0xe67e22
};

function truncate(text, max = 1000) {
	if (!text) return "";
	return text.length > max ? `${text.slice(0, max - 3)}...` : text;
}

function titleCase(value) {
	return String(value || "")
		.replace(/_/g, " ")
		.replace(/\b\w/g, char => char.toUpperCase());
}

function makeEmbed(title, description, url = repoUrl) {
	return {
		title,
		description: truncate(description, 3900),
		url,
		color: colors[eventName] || 0x5865f2,
		author: {
			name: sender.login || "GitHub",
			icon_url: avatarUrl || undefined,
			url: sender.html_url || undefined
		},
		fields: [
			{
				name: "Repository",
				value: repoUrl ? `[${repoName}](${repoUrl})` : repoName,
				inline: true
			}
		],
		timestamp: new Date().toISOString(),
		footer: {
			text: "GitHub"
		}
	};
}

function getPushEmbed() {
	const branch = (event.ref || "").replace("refs/heads/", "");
	const commits = event.commits || [];
	const commitList = commits
		.slice(0, 8)
		.map(commit => `• [${commit.id.slice(0, 7)}](${commit.url}) ${truncate(commit.message.split("\n")[0], 120)}`)
		.join("\n");

	const extra = commits.length > 8 ? `\n…and ${commits.length - 8} more commit(s).` : "";

	return makeEmbed(
		"🚀 New Push",
		`**Branch:** \`${branch}\`\n**Pusher:** ${event.pusher?.name || sender.login}\n\n${commitList || "No commits listed."}${extra}`,
		event.compare || repoUrl
	);
}

function getPullRequestEmbed() {
	const pr = event.pull_request;
	const merged = event.action === "closed" && pr.merged;
	const icon = merged ? "✅" : event.action === "closed" ? "❌" : "🔀";

	return makeEmbed(
		`${icon} Pull Request ${titleCase(merged ? "merged" : event.action)}`,
		`**#${pr.number}:** ${pr.title}\n**Author:** ${pr.user.login}\n**Branch:** \`${pr.head.ref}\` → \`${pr.base.ref}\``,
		pr.html_url
	);
}

function getIssueEmbed() {
	const issue = event.issue;

	return makeEmbed(
		`🐛 Issue ${titleCase(event.action)}`,
		`**#${issue.number}:** ${issue.title}\n**Author:** ${issue.user.login}`,
		issue.html_url
	);
}

function getCommentEmbed(type, item, comment) {
	return makeEmbed(
		`💬 ${type} Comment ${titleCase(event.action)}`,
		`**Target:** ${item.title || item.html_url || repoName}\n**Author:** ${comment.user.login}\n\n${truncate(comment.body, 1200)}`,
		comment.html_url
	);
}

function getReleaseEmbed() {
	const release = event.release;

	return makeEmbed(
		`📦 Release ${titleCase(event.action)}`,
		`**${release.name || release.tag_name}**\n**Tag:** \`${release.tag_name}\`\n\n${truncate(release.body || "No release notes.", 1500)}`,
		release.html_url
	);
}

function getSimpleEmbed(icon, title, description, url = repoUrl) {
	return makeEmbed(`${icon} ${title}`, description, url);
}

function buildEmbed() {
	switch (eventName) {
		case "push":
			return getPushEmbed();

		case "pull_request":
			return getPullRequestEmbed();

		case "pull_request_review":
			return getSimpleEmbed(
				"📝",
				`Pull Request Review ${titleCase(event.action)}`,
				`**PR:** #${event.pull_request.number} ${event.pull_request.title}\n**Reviewer:** ${event.review.user.login}\n**State:** ${event.review.state}`,
				event.review.html_url
			);

		case "pull_request_review_comment":
			return getCommentEmbed("Pull Request Review", event.pull_request, event.comment);

		case "issues":
			return getIssueEmbed();

		case "issue_comment":
			return getCommentEmbed("Issue", event.issue, event.comment);

		case "release":
			return getReleaseEmbed();

		case "fork":
			return getSimpleEmbed("🍴", "Repository Forked", `**Forked by:** ${event.forkee.owner.login}`, event.forkee.html_url);

		case "watch":
			return getSimpleEmbed("⭐", "Repository Starred", `**Starred by:** ${sender.login}\n**Total stars:** ${repo.stargazers_count}`);

		case "discussion":
			return getSimpleEmbed("💬", `Discussion ${titleCase(event.action)}`, `**${event.discussion.title}**\n**Author:** ${event.discussion.user.login}`, event.discussion.html_url);

		case "discussion_comment":
			return getSimpleEmbed("💬", `Discussion Comment ${titleCase(event.action)}`, `**Author:** ${event.comment.user.login}\n\n${truncate(event.comment.body, 1200)}`, event.comment.html_url);

		case "create":
			return getSimpleEmbed("🌱", `${titleCase(event.ref_type)} Created`, `**Name:** \`${event.ref}\``);

		case "delete":
			return getSimpleEmbed("🗑️", `${titleCase(event.ref_type)} Deleted`, `**Name:** \`${event.ref}\``);

		case "label":
			return getSimpleEmbed("🏷️", `Label ${titleCase(event.action)}`, `**Label:** ${event.label.name}`);

		case "milestone":
			return getSimpleEmbed("🎯", `Milestone ${titleCase(event.action)}`, `**Milestone:** ${event.milestone.title}`, event.milestone.html_url);

		case "gollum":
			return getSimpleEmbed("📚", "Wiki Updated", event.pages.map(page => `• [${page.title}](${page.html_url}) — ${page.action}`).join("\n"));

		case "workflow_run":
			return getSimpleEmbed(
				event.workflow_run.conclusion === "success" ? "✅" : event.workflow_run.conclusion === "failure" ? "❌" : "⚙️",
				`Workflow ${titleCase(event.action)}`,
				`**Workflow:** ${event.workflow_run.name}\n**Branch:** \`${event.workflow_run.head_branch}\`\n**Status:** ${event.workflow_run.status}\n**Conclusion:** ${event.workflow_run.conclusion || "pending"}`,
				event.workflow_run.html_url
			);

		default:
			return getSimpleEmbed("ℹ️", `GitHub Event: ${eventName}`, `Action: ${event.action || "unknown"}`);
	}
}

async function sendToDiscord() {
	const embed = buildEmbed();

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

sendToDiscord();
