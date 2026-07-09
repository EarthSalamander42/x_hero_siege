const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const repoRoot = path.resolve(__dirname, '..');
const defaultOutputDir = 'patch_notes';

const categoryOrder = [
  'Lua gameplay',
  'Panorama/UI',
  'Localization',
  'KV data',
  'Assets',
  'Scripts/Tooling',
  'Docs',
  'Other',
];

function parseArgs(argv) {
  const args = {
    baseRef: 'master',
    releaseRef: 'HEAD',
    outputDir: defaultOutputDir,
    force: false,
  };

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    const next = argv[i + 1];

    if (arg === '--version' && next) {
      args.version = next;
      i++;
    } else if (arg === '--base' && next) {
      args.baseRef = next;
      i++;
    } else if (arg === '--release' && next) {
      args.releaseRef = next;
      i++;
    } else if (arg === '--title' && next) {
      args.title = next;
      i++;
    } else if (arg === '--summary' && next) {
      args.summary = next;
      i++;
    } else if (arg === '--output-dir' && next) {
      args.outputDir = next;
      i++;
    } else if (arg === '--force') {
      args.force = true;
    } else if (arg === '--help' || arg === '-h') {
      args.help = true;
    } else {
      throw new Error(`Unknown or incomplete argument: ${arg}`);
    }
  }

  if (args.version && !args.title) {
    args.title = `X Hero Siege ${args.version}`;
  }

  if (!args.summary) {
    args.summary = 'Generated draft from Git diff. Needs human review.';
  }

  return args;
}

function printHelp() {
  console.log(`Usage:
  node scripts/generate_patch_note_draft.js --version <version> [options]

Options:
  --version <version>      Release version, for example 4.0
  --base <ref>             Base Git ref
                           Default: master
  --release <ref>          Release Git ref
                           Default: HEAD
  --title <text>           Patch title
                           Default: X Hero Siege <version>
  --summary <text>         One-line patch summary
                           Default: Generated draft from Git diff. Needs human review.
  --output-dir <path>      Output directory
                           Default: ${defaultOutputDir}
  --force                  Overwrite existing output files
  --help, -h               Show this help
`);
}

function resolveRepoPath(value) {
  if (path.isAbsolute(value)) {
    return value;
  }

  return path.join(repoRoot, value);
}

function runGit(args, options = {}) {
  return execFileSync('git', args, {
    cwd: repoRoot,
    encoding: 'utf8',
    stdio: options.stdio || ['ignore', 'pipe', 'pipe'],
  }).trim();
}

function readGitLines(args) {
  const output = runGit(args);
  if (!output) {
    return [];
  }

  return output.split(/\r?\n/);
}

function sanitizeFileName(value) {
  const safe = String(value || '').replace(/[^A-Za-z0-9._-]/g, '_');
  if (!safe || safe === '.' || safe === '..') {
    throw new Error(`Invalid version for output file name: ${value}`);
  }

  return safe;
}

function normalizePath(value) {
  return String(value || '').replace(/\\/g, '/');
}

function formatNumber(value) {
  return Number(value || 0).toLocaleString('en-US');
}

function makeDiffFooter(stats) {
  return `Diff analyzed: ${formatNumber(stats.changedFiles)} files, ${formatNumber(stats.commitCount)} commits, +${formatNumber(stats.insertions)} / -${formatNumber(stats.deletions)} lines.`;
}

function parseShortStat(text) {
  const stats = {
    changedFiles: 0,
    insertions: 0,
    deletions: 0,
  };

  const fileMatch = text.match(/(\d+)\s+files?\s+changed/);
  const insertionMatch = text.match(/(\d+)\s+insertions?\(\+\)/);
  const deletionMatch = text.match(/(\d+)\s+deletions?\(-\)/);

  if (fileMatch) {
    stats.changedFiles = Number(fileMatch[1]);
  }
  if (insertionMatch) {
    stats.insertions = Number(insertionMatch[1]);
  }
  if (deletionMatch) {
    stats.deletions = Number(deletionMatch[1]);
  }

  return stats;
}

function parseCommits(lines) {
  return lines.map((line) => {
    const match = line.match(/^([0-9a-f]+)\s+(.*)$/i);
    return {
      hash: match ? match[1] : '',
      subject: match ? match[2] : line,
      line,
    };
  });
}

function parseNameStatus(lines) {
  return lines.map((line) => {
    const parts = line.split('\t');
    const status = parts[0] || '';
    const code = status.charAt(0) || '?';

    if ((code === 'R' || code === 'C') && parts.length >= 3) {
      return {
        status,
        statusCode: code,
        oldPath: normalizePath(parts[1]),
        path: normalizePath(parts[2]),
      };
    }

    return {
      status,
      statusCode: code,
      oldPath: null,
      path: normalizePath(parts.slice(1).join('\t') || parts[0]),
    };
  });
}

function parseNumStat(lines) {
  return lines.map((line) => {
    const parts = line.split('\t');
    const rawInsertions = parts[0];
    const rawDeletions = parts[1];
    const filePath = normalizePath(parts.slice(2).join('\t'));
    const binary = rawInsertions === '-' || rawDeletions === '-';

    return {
      path: filePath,
      insertions: binary ? 0 : Number(rawInsertions || 0),
      deletions: binary ? 0 : Number(rawDeletions || 0),
      binary,
    };
  });
}

function classifyPath(filePath) {
  const p = normalizePath(filePath).toLowerCase();

  if (p.endsWith('.md') || p.startsWith('docs/') || p.includes('/docs/')) {
    return 'Docs';
  }

  if (p.startsWith('game/resource/') || p.startsWith('content/resource/') || p.includes('/localization/')) {
    return 'Localization';
  }

  if (p.startsWith('content/panorama/') || p.startsWith('game/panorama/')) {
    return 'Panorama/UI';
  }

  if (p.startsWith('game/scripts/vscripts/') || p.endsWith('.lua')) {
    return 'Lua gameplay';
  }

  if (
    p.startsWith('game/scripts/npc/') ||
    p.startsWith('game/scripts/shops/') ||
    p.startsWith('game/scripts/custom_net_tables') ||
    p.startsWith('game/scripts/items/')
  ) {
    return 'KV data';
  }

  if (
    p.startsWith('content/models/') ||
    p.startsWith('content/materials/') ||
    p.startsWith('content/particles/') ||
    p.startsWith('content/sound') ||
    p.startsWith('content/panorama/images/') ||
    p.startsWith('game/models/') ||
    p.startsWith('game/materials/') ||
    p.startsWith('game/particles/') ||
    p.startsWith('game/sound') ||
    p.startsWith('game/resource/flash3/') ||
    /\.(png|jpe?g|tga|psd|gif|webp|vtex|vtex_c|vmat|vmat_c|vmdl|vmdl_c|fbx|obj|mp3|wav|vsnd|vsnd_c|vpcf|vpcf_c)$/i.test(p)
  ) {
    return 'Assets';
  }

  if (
    p.startsWith('scripts/') ||
    p === 'sync_loading_screen.js' ||
    p.endsWith('.js') ||
    p.endsWith('.ps1') ||
    p.endsWith('.bat') ||
    p.endsWith('.cmd')
  ) {
    return 'Scripts/Tooling';
  }

  return 'Other';
}

function mergeFileStats(files, numStats) {
  const numStatByPath = new Map();
  for (const item of numStats) {
    numStatByPath.set(item.path, item);
  }

  return files.map((file, index) => {
    const stats = numStatByPath.get(file.path) || numStatByPath.get(file.oldPath) || numStats[index] || {
      insertions: 0,
      deletions: 0,
      binary: false,
    };

    return {
      ...file,
      category: classifyPath(file.path),
      insertions: stats.insertions,
      deletions: stats.deletions,
      binary: stats.binary,
    };
  });
}

function buildCategories(files) {
  const categories = new Map();
  for (const name of categoryOrder) {
    categories.set(name, {
      name,
      fileCount: 0,
      insertions: 0,
      deletions: 0,
      files: [],
    });
  }

  for (const file of files) {
    const category = categories.get(file.category) || categories.get('Other');
    category.fileCount++;
    category.insertions += file.insertions || 0;
    category.deletions += file.deletions || 0;
    category.files.push(file);
  }

  return categoryOrder
    .map((name) => categories.get(name))
    .filter((category) => category.fileCount > 0);
}

function parseGithubCompareUrl(baseRef, releaseRef) {
  let remoteUrl = '';
  try {
    remoteUrl = runGit(['remote', 'get-url', 'origin']);
  } catch (error) {
    return null;
  }

  let repoUrl = remoteUrl.trim();
  const sshMatch = repoUrl.match(/^git@github\.com:(.+?)(?:\.git)?$/);
  if (sshMatch) {
    repoUrl = `https://github.com/${sshMatch[1]}`;
  }

  if (repoUrl.startsWith('https://github.com/')) {
    repoUrl = repoUrl.replace(/\.git$/, '');
    return `${repoUrl}/compare/${encodeURIComponent(baseRef)}...${encodeURIComponent(releaseRef)}`;
  }

  return null;
}

function getWorkingTreeStatus() {
  try {
    return readGitLines(['status', '--short']);
  } catch (error) {
    return [];
  }
}

function ensureOutputsCanBeWritten(paths, force) {
  if (force) {
    return;
  }

  const existing = paths.filter((filePath) => fs.existsSync(filePath));
  if (existing.length > 0) {
    throw new Error(`Output file already exists. Re-run with --force to overwrite:
${existing.map((filePath) => `  ${path.relative(repoRoot, filePath)}`).join('\n')}`);
  }
}

function fileDisplayLine(file) {
  const pathLabel = file.oldPath ? `${file.oldPath} -> ${file.path}` : file.path;
  const statLabel = file.binary ? 'binary' : `+${formatNumber(file.insertions)} / -${formatNumber(file.deletions)}`;
  return `- ${file.status} \`${pathLabel}\` (${statLabel})`;
}

function buildMarkdown(data) {
  const lines = [];

  lines.push(`# ${data.title}`);
  lines.push('');
  lines.push(`> ${data.summary}`);
  lines.push('> Draft generated from Git diff. Needs human review before publishing.');
  lines.push('');
  lines.push('## Authoring Rules');
  lines.push('');
  lines.push('- Sort entries alphabetically inside each patch-note category.');
  lines.push('- For hero or unit ability changes, use a second hierarchy: entity, then ability section, then ability entries.');
  lines.push('- Do not publish internal Lua rewrites unless they change visible behavior, repair ability behavior, or add readable combat mechanics.');
  lines.push('- Label bug fixes only when the diff provides visible gameplay evidence or after manual review.');
  lines.push('');
  lines.push('## Highlights');
  lines.push('');
  lines.push('- TODO: Add 3-5 player-facing highlights after reviewing the generated evidence below.');
  lines.push('');
  lines.push('## New Features');
  lines.push('');
  lines.push('- TODO: Move new player-visible systems from the diff evidence into this section.');
  lines.push('');
  lines.push('## Gameplay Changes');
  lines.push('');
  lines.push('- TODO: Summarize gameplay changes by player impact, not by commit.');
  lines.push('');
  lines.push('## Heroes');
  lines.push('');
  lines.push('- TODO: Add hero-specific changes if present in the diff.');
  lines.push('');
  lines.push('## Items');
  lines.push('');
  lines.push('- TODO: Add item-specific changes if present in the diff.');
  lines.push('');
  lines.push('## Bosses And Waves');
  lines.push('');
  lines.push('- TODO: Add boss, wave, quest, and event changes if present in the diff.');
  lines.push('');
  lines.push('## UI And Quality Of Life');
  lines.push('');
  lines.push('- TODO: Add Panorama, localization, tooltip, loading screen, and end screen changes.');
  lines.push('');
  lines.push('## Fixes');
  lines.push('');
  lines.push('- TODO: Add bug fixes confirmed by commit messages or file changes.');
  lines.push('');
  lines.push('## Balance');
  lines.push('');
  lines.push('- TODO: Add tuning changes and numbers only after verifying gameplay files.');
  lines.push('');
  lines.push('## Technical Changes');
  lines.push('');
  lines.push('- TODO: Keep internal-only changes here unless they clearly affect players.');
  lines.push('');
  lines.push('## Known Issues');
  lines.push('');
  lines.push('- TODO: Add release-blocking or player-visible known issues.');
  lines.push('');
  lines.push('## Diff Summary');
  lines.push('');
  lines.push(`- Compare: \`${data.baseRef}...${data.releaseRef}\``);
  if (data.compareUrl) {
    lines.push(`- GitHub: ${data.compareUrl}`);
  }
  lines.push(`- Commits: ${formatNumber(data.commitCount)}`);
  lines.push(`- Changed files: ${formatNumber(data.changedFiles)}`);
  lines.push(`- Lines: +${formatNumber(data.insertions)} / -${formatNumber(data.deletions)}`);
  if (data.workingTreeStatus.length > 0) {
    lines.push('- Note: working tree had unrelated local changes when this draft was generated.');
  }
  lines.push('');

  for (const category of data.categories) {
    lines.push(`### ${category.name}`);
    lines.push('');
    lines.push(`- Files: ${formatNumber(category.fileCount)}`);
    lines.push(`- Lines: +${formatNumber(category.insertions)} / -${formatNumber(category.deletions)}`);
    lines.push('');
    for (const file of category.files) {
      lines.push(fileDisplayLine(file));
    }
    lines.push('');
  }

  lines.push('## Commit Evidence');
  lines.push('');
  if (data.commits.length === 0) {
    lines.push('- No commits found for this compare range.');
  } else {
    for (const commit of data.commits) {
      lines.push(`- \`${commit.hash}\` ${commit.subject}`);
    }
  }
  lines.push('');
  lines.push('---');
  lines.push('');
  lines.push(data.diffFooter);
  lines.push('');

  return lines.join('\n');
}

function buildWebJson(data) {
  const details = [
    {
      title: 'Highlights',
      items: [
        'TODO: Add 3-5 player-facing highlights after reviewing the generated draft.',
      ],
    },
    {
      title: 'Gameplay',
      items: [
        'TODO: Summarize gameplay, hero, item, boss, wave, and balance changes by player impact.',
      ],
    },
    {
      title: 'UI and quality of life',
      items: [
        'TODO: Summarize visible UI, localization, loading screen, end screen, and tooltip changes.',
      ],
    },
    {
      title: 'Technical changes',
      items: data.categories.map((category) => `${category.name}: ${formatNumber(category.fileCount)} files, +${formatNumber(category.insertions)} / -${formatNumber(category.deletions)} lines.`),
    },
    {
      title: 'Release audit',
      items: [
        data.diffFooter,
      ],
    },
  ];

  return {
    version: data.version,
    title: data.title,
    status: 'current',
    statusLabel: 'Current',
    route: `/patches/xhs/${data.version}`,
    summary: data.summary,
    details,
    sections: [],
    impact: [],
    meta: {
      baseRef: data.baseRef,
      releaseRef: data.releaseRef,
      compareUrl: data.compareUrl,
      diffStats: {
        changedFiles: data.changedFiles,
        commitCount: data.commitCount,
        insertions: data.insertions,
        deletions: data.deletions,
        footer: data.diffFooter,
      },
      generatedAt: data.generatedAt,
      changelogRules: [
        'Entries inside a category are displayed alphabetically by title.',
        'Hero and unit ability changes use a second hierarchy: entity, then ability section, then ability entries.',
        'Internal Lua rewrites are not player-facing notes unless they change visible behavior, repair ability behavior, or add readable combat mechanics.',
        'Potential bug fixes inferred from code need visible gameplay evidence or manual review before being labeled as fixes.',
      ],
    },
  };
}

function toAscii(text) {
  return String(text).replace(/[^\x00-\x7F]/g, '?');
}

function writeAsciiFile(filePath, content) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, toAscii(content), 'utf8');
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    return;
  }

  if (!args.version) {
    throw new Error('Missing required argument: --version <version>');
  }

  const outputDir = resolveRepoPath(args.outputDir);
  const fileBase = sanitizeFileName(args.version);
  const mdPath = path.join(outputDir, `${fileBase}.md`);
  const metaPath = path.join(outputDir, `${fileBase}.meta.json`);
  const webPath = path.join(outputDir, `${fileBase}.web.json`);
  ensureOutputsCanBeWritten([mdPath, metaPath, webPath], args.force);

  const compareRange = `${args.baseRef}...${args.releaseRef}`;
  const commits = parseCommits(readGitLines(['log', '--oneline', compareRange]));
  const shortStatText = runGit(['diff', '--shortstat', compareRange]);
  const shortStat = parseShortStat(shortStatText);
  const nameStatus = parseNameStatus(readGitLines(['diff', '--name-status', compareRange]));
  const numStats = parseNumStat(readGitLines(['diff', '--numstat', compareRange]));
  const files = mergeFileStats(nameStatus, numStats);
  const categories = buildCategories(files);
  const workingTreeStatus = getWorkingTreeStatus();

  const stats = {
    version: args.version,
    title: args.title,
    summary: args.summary,
    baseRef: args.baseRef,
    releaseRef: args.releaseRef,
    compareRange,
    compareUrl: parseGithubCompareUrl(args.baseRef, args.releaseRef),
    generatedAt: new Date().toISOString(),
    commitCount: commits.length,
    changedFiles: shortStat.changedFiles || files.length,
    insertions: shortStat.insertions,
    deletions: shortStat.deletions,
    commits,
    files,
    categories,
    workingTreeDirty: workingTreeStatus.length > 0,
    workingTreeStatus,
  };
  stats.diffFooter = makeDiffFooter(stats);
  stats.diffStats = {
    changedFiles: stats.changedFiles,
    commitCount: stats.commitCount,
    insertions: stats.insertions,
    deletions: stats.deletions,
    footer: stats.diffFooter,
  };

  const markdown = buildMarkdown(stats);
  const metaJson = JSON.stringify(stats, null, 2) + '\n';
  const webJson = JSON.stringify(buildWebJson(stats), null, 2) + '\n';

  writeAsciiFile(mdPath, markdown);
  writeAsciiFile(metaPath, metaJson);
  writeAsciiFile(webPath, webJson);

  console.log(`Generated: ${path.relative(repoRoot, mdPath)}`);
  console.log(`Generated: ${path.relative(repoRoot, metaPath)}`);
  console.log(`Generated: ${path.relative(repoRoot, webPath)}`);
  console.log(stats.diffFooter);
  if (stats.workingTreeDirty) {
    console.log('Note: working tree had local changes during generation.');
  }
}

try {
  main();
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
