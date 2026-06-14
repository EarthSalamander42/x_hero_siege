const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');

function resolveRepoPath(value) {
  if (path.isAbsolute(value)) {
    return value;
  }

  return path.join(repoRoot, value);
}

function parseArgs(argv) {
  const args = {
    dotaItemsPath: 'scripts/dota_item_removal/official_dota_items.txt',
    whitelistPath: 'scripts/dota_item_removal/item_whitelist.txt',
    outputPath: 'game/scripts/npc/generated/removed_dota_items.txt',
  };

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    const next = argv[i + 1];

    if ((arg === '--dota-items' || arg === '--dotaItemsPath') && next) {
      args.dotaItemsPath = next;
      i++;
    } else if ((arg === '--whitelist' || arg === '--whitelistPath') && next) {
      args.whitelistPath = next;
      i++;
    } else if ((arg === '--output' || arg === '--outputPath') && next) {
      args.outputPath = next;
      i++;
    } else if (arg === '--help' || arg === '-h') {
      args.help = true;
    } else {
      throw new Error(`Unknown or incomplete argument: ${arg}`);
    }
  }

  return args;
}

function printHelp() {
  console.log(`Usage:
  node scripts/update_removed_dota_items.js [options]

Options:
  --dota-items <path>   Path to Valve's extracted scripts/npc/items.txt
                        Default: scripts/dota_item_removal/official_dota_items.txt
  --whitelist <path>    Manual allow-list
                        Default: scripts/dota_item_removal/item_whitelist.txt
  --output <path>       Generated REMOVE entries
                        Default: game/scripts/npc/generated/removed_dota_items.txt
`);
}

function stripComment(line) {
  const hashIndex = line.indexOf('#');
  const slashIndex = line.indexOf('//');
  const candidates = [hashIndex, slashIndex].filter((index) => index >= 0);

  if (candidates.length === 0) {
    return line;
  }

  return line.slice(0, Math.min(...candidates));
}

function addItem(set, itemName) {
  if (/^item_[A-Za-z0-9_]+$/.test(itemName)) {
    set.add(itemName);
  }
}

function readLines(filePath) {
  return fs.readFileSync(filePath, 'utf8').split(/\r?\n/);
}

function readManualWhitelist(filePath) {
  if (!fs.existsSync(filePath)) {
    throw new Error(`Whitelist not found: ${filePath}`);
  }

  const items = new Set();
  for (const line of readLines(filePath)) {
    const clean = stripComment(line).trim();
    if (!clean) {
      continue;
    }

    const quotedMatch = clean.match(/"(?<item>item_[^"]+)"/);
    if (quotedMatch) {
      addItem(items, quotedMatch.groups.item);
      continue;
    }

    const plainMatch = clean.match(/^(?<item>item_[A-Za-z0-9_]+)$/);
    if (plainMatch) {
      addItem(items, plainMatch.groups.item);
    }
  }

  return items;
}

function readTopLevelItemKeys(filePath) {
  const items = new Set();
  for (const line of readLines(filePath)) {
    const clean = stripComment(line);
    const match = clean.match(/^\s*"(?<item>item_[^"]+)"\s*(?:\{|$|"REMOVE")/);
    if (match) {
      addItem(items, match.groups.item);
    }
  }

  return items;
}

function readShopItems(shopDir) {
  const items = new Set();
  if (!fs.existsSync(shopDir)) {
    return items;
  }

  for (const fileName of fs.readdirSync(shopDir)) {
    if (!fileName.endsWith('.txt')) {
      continue;
    }

    const filePath = path.join(shopDir, fileName);
    if (!fs.statSync(filePath).isFile()) {
      continue;
    }

    for (const line of readLines(filePath)) {
      const clean = stripComment(line);
      const match = clean.match(/"item"\s+"(?<item>item_[^"]+)"/);
      if (match) {
        addItem(items, match.groups.item);
      }
    }
  }

  return items;
}

function readManualOverrideItemBlocks(filePath) {
  const items = new Set();
  if (!fs.existsSync(filePath)) {
    return items;
  }

  for (const line of readLines(filePath)) {
    const clean = stripComment(line);
    const match = clean.match(/^\s*"(?<item>item_[^"]+)"\s*\{/);
    if (match) {
      addItem(items, match.groups.item);
    }
  }

  return items;
}

function mergeSet(target, source) {
  for (const value of source) {
    target.add(value);
  }
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    return;
  }

  const dotaItemsPath = resolveRepoPath(args.dotaItemsPath);
  const whitelistPath = resolveRepoPath(args.whitelistPath);
  const outputPath = resolveRepoPath(args.outputPath);
  const customItemsPath = resolveRepoPath('game/scripts/npc/npc_items_custom.txt');
  const overridePath = resolveRepoPath('game/scripts/npc/npc_abilities_override.txt');
  const shopDir = resolveRepoPath('game/scripts/shops');

  if (!fs.existsSync(dotaItemsPath)) {
    throw new Error(`Official Dota items file not found: ${dotaItemsPath}

Extract Valve's latest scripts/npc/items.txt from Dota's pak01_dir.vpk and save it as:
  scripts/dota_item_removal/official_dota_items.txt

Or pass it directly:
  node scripts/update_removed_dota_items.js --dota-items C:\\path\\to\\items.txt`);
  }

  const officialItems = readTopLevelItemKeys(dotaItemsPath);
  const allowedItems = new Set();

  mergeSet(allowedItems, readManualWhitelist(whitelistPath));
  mergeSet(allowedItems, readShopItems(shopDir));
  mergeSet(allowedItems, readTopLevelItemKeys(customItemsPath));
  mergeSet(allowedItems, readManualOverrideItemBlocks(overridePath));

  const removedItems = [...officialItems]
    .filter((item) => !allowedItems.has(item))
    .sort();

  fs.mkdirSync(path.dirname(outputPath), { recursive: true });

  const lines = [
    '// AUTO-GENERATED FILE - DO NOT EDIT BY HAND',
    '// Regenerate with: node scripts/update_removed_dota_items.js',
    `// Generated at: ${new Date().toISOString()}`,
    `// Source: ${dotaItemsPath}`,
    '//',
    `// Official items: ${officialItems.size}`,
    `// Allowed items: ${allowedItems.size}`,
    `// Removed items: ${removedItems.length}`,
    '',
    '"DOTAAbilities"',
    '{',
    ...removedItems.map((item) => `\t"${item}"\t"REMOVE"`),
    '}',
    '',
  ];

  fs.writeFileSync(outputPath, lines.join('\n'), 'ascii');

  console.log(`Generated: ${outputPath}`);
  console.log(`Official items: ${officialItems.size}`);
  console.log(`Allowed items: ${allowedItems.size}`);
  console.log(`Removed items: ${removedItems.length}`);
}

try {
  main();
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
