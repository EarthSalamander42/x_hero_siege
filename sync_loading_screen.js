const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const CURRENT_REPO_ROOT = path.resolve(__dirname);
const GITHUB_ROOT = path.resolve(CURRENT_REPO_ROOT, "..");

const REPOS = [
	{ name: "x_hero_siege", root: CURRENT_REPO_ROOT, primary: true },
	{ name: "PudgeWars", root: path.join(GITHUB_ROOT, "PudgeWars") },
	{ name: "herolinewars", root: path.join(GITHUB_ROOT, "Shopify", "net-lunettes.fr", "herolinewars") },
	{ name: "frostrose_battlefield", root: path.join(GITHUB_ROOT, "Shopify", "net-lunettes.fr", "frostrose_battlefield") },
	{ name: "dota_imba", root: path.join(GITHUB_ROOT, "Shopify", "net-lunettes.fr", "dota_imba") },
];

const SHARED_FILES = [
	path.join("content", "panorama", "layout", "custom_game", "custom_loading_screen.xml"),
	path.join("content", "panorama", "scripts", "custom_game", "custom_loading_screen.js"),
	path.join("content", "panorama", "styles", "custom_game", "custom_loading_screen.css"),
];

const WATCH_INTERVAL_MS = 400;
const WRITE_SUPPRESSION_MS = 1500;

const suppressedWritesUntil = new Map();
const lastKnownHashes = new Map();

function log(message, data) {
	if (data !== undefined) {
		console.log(`[loading-screen-sync] ${message}`, data);
		return;
	}

	console.log(`[loading-screen-sync] ${message}`);
}

function fileKey(filePath) {
	return path.resolve(filePath).toLowerCase();
}

function getActiveRepos() {
	return REPOS.filter((repo) => fs.existsSync(repo.root));
}

function getPrimaryRepo(activeRepos) {
	for (const repo of activeRepos) {
		if (repo.primary) {
			return repo;
		}
	}

	return activeRepos[0];
}

function getRepoFilePath(repo, relativePath) {
	return path.join(repo.root, relativePath);
}

function ensureParentDirectory(filePath) {
	fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function getFileHash(filePath) {
	if (!fs.existsSync(filePath)) {
		return null;
	}

	const content = fs.readFileSync(filePath);
	return crypto.createHash("sha1").update(content).digest("hex");
}

function readFileContent(filePath) {
	return fs.readFileSync(filePath);
}

function relativeRepoDisplay(repo, relativePath) {
	return `${repo.name}:${relativePath.replace(/\\/g, "/")}`;
}

function writeSharedFile(sourceRepo, targetRepo, relativePath, content, hash) {
	const targetFilePath = getRepoFilePath(targetRepo, relativePath);
	const targetKey = fileKey(targetFilePath);
	const currentTargetHash = getFileHash(targetFilePath);

	if (currentTargetHash === hash) {
		lastKnownHashes.set(targetKey, hash);
		return false;
	}

	ensureParentDirectory(targetFilePath);
	fs.writeFileSync(targetFilePath, content);
	suppressedWritesUntil.set(targetKey, Date.now() + WRITE_SUPPRESSION_MS);
	lastKnownHashes.set(targetKey, hash);

	log(`updated ${relativeRepoDisplay(targetRepo, relativePath)} from ${sourceRepo.name}`);
	return true;
}

function syncRelativePathFromSource(sourceRepo, relativePath) {
	const sourceFilePath = getRepoFilePath(sourceRepo, relativePath);
	if (!fs.existsSync(sourceFilePath)) {
		log(`source file missing, skip ${relativeRepoDisplay(sourceRepo, relativePath)}`);
		return;
	}

	const content = readFileContent(sourceFilePath);
	const hash = crypto.createHash("sha1").update(content).digest("hex");
	lastKnownHashes.set(fileKey(sourceFilePath), hash);

	for (const targetRepo of getActiveRepos()) {
		if (targetRepo.root === sourceRepo.root) {
			continue;
		}

		writeSharedFile(sourceRepo, targetRepo, relativePath, content, hash);
	}
}

function performInitialSync() {
	const activeRepos = getActiveRepos();
	if (activeRepos.length === 0) {
		log("no configured repositories found");
		return;
	}

	const primaryRepo = getPrimaryRepo(activeRepos);
	log(`initial sync using primary source ${primaryRepo.name}`);

	for (const relativePath of SHARED_FILES) {
		syncRelativePathFromSource(primaryRepo, relativePath);
	}
}

function propagateFileChange(sourceRepo, relativePath) {
	const sourceFilePath = getRepoFilePath(sourceRepo, relativePath);
	const sourceKey = fileKey(sourceFilePath);

	if (!fs.existsSync(sourceFilePath)) {
		log(`change ignored because file does not exist anymore: ${relativeRepoDisplay(sourceRepo, relativePath)}`);
		return;
	}

	const sourceHash = getFileHash(sourceFilePath);
	if (!sourceHash) {
		return;
	}

	if (lastKnownHashes.get(sourceKey) === sourceHash) {
		return;
	}

	lastKnownHashes.set(sourceKey, sourceHash);
	const content = readFileContent(sourceFilePath);
	log(`detected change in ${relativeRepoDisplay(sourceRepo, relativePath)}`);

	for (const targetRepo of getActiveRepos()) {
		if (targetRepo.root === sourceRepo.root) {
			continue;
		}

		writeSharedFile(sourceRepo, targetRepo, relativePath, content, sourceHash);
	}
}

function watchFile(repo, relativePath) {
	const filePath = getRepoFilePath(repo, relativePath);
	const key = fileKey(filePath);
	lastKnownHashes.set(key, getFileHash(filePath));

	fs.watchFile(filePath, { interval: WATCH_INTERVAL_MS }, () => {
		const suppressedUntil = suppressedWritesUntil.get(key) || 0;
		if (suppressedUntil > Date.now()) {
			lastKnownHashes.set(key, getFileHash(filePath));
			return;
		}

		propagateFileChange(repo, relativePath);
	});

	log(`watching ${relativeRepoDisplay(repo, relativePath)}`);
}

function startWatchMode() {
	performInitialSync();

	for (const repo of getActiveRepos()) {
		for (const relativePath of SHARED_FILES) {
			watchFile(repo, relativePath);
		}
	}

	log("watch mode active");
}

function stopWatchers() {
	for (const repo of getActiveRepos()) {
		for (const relativePath of SHARED_FILES) {
			fs.unwatchFile(getRepoFilePath(repo, relativePath));
		}
	}
}

function main() {
	const onceMode = process.argv.includes("--once") || process.argv.includes("--sync");

	if (onceMode) {
		performInitialSync();
		return;
	}

	startWatchMode();

	process.on("SIGINT", () => {
		stopWatchers();
		log("watch mode stopped");
		process.exit(0);
	});
}

main();
