const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const repoRoot = path.resolve(__dirname, '..');
const contentRoot = path.join(repoRoot, 'content');

const DEFAULT_FILES = [
  'content/panorama/layout/custom_game/custom_ui_manifest.xml',
  'content/panorama/layout/custom_game/xhs_top_hud.xml',
  'content/panorama/layout/custom_game/xhs_timers.xml',
  'content/panorama/styles/custom_game/xhs_top_hud.css',
  'content/panorama/scripts/custom_game/xhs_top_hud.js',
  'content/panorama/layout/custom_game/xhs_end_screen.xml',
  'content/panorama/styles/custom_game/xhs_end_screen.css',
  'content/panorama/scripts/custom_game/xhs_end_screen.js',
  'content/panorama/layout/custom_game/xhs_devtools.xml',
  'content/panorama/styles/custom_game/xhs_devtools.css',
  'content/panorama/scripts/custom_game/xhs_devtools.js',
];

function fail(message) {
  console.error(message);
  process.exit(1);
}

function realpathIfExists(filePath) {
  if (!fs.existsSync(filePath)) {
    fail(`Missing path: ${filePath}`);
  }

  return fs.realpathSync(filePath);
}

function findDotaRootFromContentPath(realContentRoot) {
  const marker = `${path.sep}content${path.sep}dota_addons${path.sep}`;
  const markerIndex = realContentRoot.toLowerCase().indexOf(marker.toLowerCase());

  if (markerIndex === -1) {
    fail(`Cannot infer Dota root from content junction target: ${realContentRoot}`);
  }

  return realContentRoot.slice(0, markerIndex);
}

function findResourceCompiler(dotaRoot) {
  const candidates = [
    path.join(dotaRoot, 'game', 'bin', 'win64', 'resourcecompiler.exe'),
    path.join(dotaRoot, 'game', 'bin', 'win32', 'resourcecompiler.exe'),
  ];

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  fail(`resourcecompiler.exe not found under: ${dotaRoot}`);
}

function normalizeInputFile(input) {
  const absolute = path.resolve(repoRoot, input);

  if (!absolute.startsWith(contentRoot + path.sep)) {
    fail(`Panorama compile inputs must be under content/: ${input}`);
  }

  return realpathIfExists(absolute);
}

function parseArgs() {
  const args = process.argv.slice(2);

  if (args.includes('--help') || args.includes('-h')) {
    console.log([
      'Usage:',
      '  node scripts/compile_panorama.js [content/panorama/...]',
      '',
      'If no files are passed, compiles the current XHS HUD files maintained by Codex.',
      'Always pass source files under content/, not game/ compiled files.',
    ].join('\n'));
    process.exit(0);
  }

  return args.length > 0 ? args : DEFAULT_FILES;
}

function main() {
  const realContentRoot = realpathIfExists(contentRoot);
  const dotaRoot = findDotaRootFromContentPath(realContentRoot);
  const resourceCompiler = findResourceCompiler(dotaRoot);
  const files = parseArgs().map(normalizeInputFile);

  console.log(`Compiler: ${resourceCompiler}`);
  console.log(`Content:  ${realContentRoot}`);
  console.log(`Files:`);
  files.forEach((file) => console.log(`- ${file}`));

  const result = spawnSync(
    resourceCompiler,
    ['-nop4', '-fshallow', '-i', ...files],
    {
      cwd: realContentRoot,
      stdio: 'inherit',
      windowsHide: true,
    },
  );

  if (result.error) {
    fail(result.error.message);
  }

  process.exit(result.status || 0);
}

main();
