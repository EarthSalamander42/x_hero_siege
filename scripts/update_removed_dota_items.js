const fs = require('fs');
const https = require('https');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const defaultDotaItemsUrl = 'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/items.txt';

function resolveRepoPath(value) {
  if (path.isAbsolute(value)) {
    return value;
  }

  return path.join(repoRoot, value);
}

function parseArgs(argv) {
  const args = {
    dotaItemsPath: defaultDotaItemsUrl,
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
  --dota-items <path>   Path or URL to Valve's scripts/npc/items.txt
                        Default: ${defaultDotaItemsUrl}
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

function isHttpUrl(value) {
  return /^https?:\/\//i.test(value);
}

function normalizeDotaItemsSource(value) {
  if (value === defaultDotaItemsUrl) {
    return value;
  }

  if (isHttpUrl(value)) {
    return value
      .replace('https://github.com/', 'https://raw.githubusercontent.com/')
      .replace('/blob/', '/');
  }

  return resolveRepoPath(value);
}

function fetchUrlText(url) {
  return new Promise((resolve, reject) => {
    https.get(url, {
      headers: {
        'User-Agent': 'x-hero-siege-item-removal-generator',
      },
    }, (response) => {
      if (response.statusCode >= 300 && response.statusCode < 400 && response.headers.location) {
        response.resume();
        fetchUrlText(response.headers.location).then(resolve, reject);
        return;
      }

      if (response.statusCode !== 200) {
        response.resume();
        reject(new Error(`Failed to fetch ${url}: HTTP ${response.statusCode}`));
        return;
      }

      response.setEncoding('utf8');
      let data = '';
      response.on('data', (chunk) => {
        data += chunk;
      });
      response.on('end', () => resolve(data));
    }).on('error', reject);
  });
}

async function readTextFromSource(source) {
  if (isHttpUrl(source)) {
    return fetchUrlText(source);
  }

  if (!fs.existsSync(source)) {
    throw new Error(`Official Dota items file not found: ${source}

Use the default live source:
  node scripts/update_removed_dota_items.js

Or pass a local file / URL:
  node scripts/update_removed_dota_items.js --dota-items C:\\path\\to\\items.txt
  node scripts/update_removed_dota_items.js --dota-items ${defaultDotaItemsUrl}`);
  }

  return fs.readFileSync(source, 'utf8');
}

function readLines(filePath) {
  return fs.readFileSync(filePath, 'utf8').split(/\r?\n/);
}

function readLinesFromText(text) {
  return text.split(/\r?\n/);
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

function readTopLevelItemKeysFromLines(lines) {
  const items = new Set();
  for (const line of lines) {
    const clean = stripComment(line);
    const match = clean.match(/^\s*"(?<item>item_[^"]+)"\s*(?:\{|$|"REMOVE")/);
    if (match) {
      addItem(items, match.groups.item);
    }
  }

  return items;
}

function readTopLevelItemKeys(filePath) {
  return readTopLevelItemKeysFromLines(readLines(filePath));
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

function readManualOverrideItems(filePath) {
  const items = new Set();
  if (!fs.existsSync(filePath)) {
    return items;
  }

  for (const line of readLines(filePath)) {
    const clean = stripComment(line);
    const match = clean.match(/^\s*"(?<item>item_[^"]+)"\s*(?:\{|$|"REMOVE")/);
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

function sortedSetValues(set) {
  return [...set].sort();
}

function intersectSets(left, right) {
  const result = new Set();
  for (const value of left) {
    if (right.has(value)) {
      result.add(value);
    }
  }
  return result;
}

function subtractSets(left, right) {
  const result = new Set();
  for (const value of left) {
    if (!right.has(value)) {
      result.add(value);
    }
  }
  return result;
}

function addCommentedItemSection(lines, title, items) {
  lines.push('//');
  lines.push(`// ${title}: ${items.length}`);

  if (items.length === 0) {
    lines.push('// - none');
    return;
  }

  for (const item of items) {
    lines.push(`// - ${item}`);
  }
}

function takeCategory(source, alreadyListed) {
  const items = subtractSets(source, alreadyListed);
  mergeSet(alreadyListed, items);
  return sortedSetValues(items);
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    return;
  }

  const dotaItemsSource = normalizeDotaItemsSource(args.dotaItemsPath);
  const whitelistPath = resolveRepoPath(args.whitelistPath);
  const outputPath = resolveRepoPath(args.outputPath);
  const customItemsPath = resolveRepoPath('game/scripts/npc/npc_items_custom.txt');
  const overridePath = resolveRepoPath('game/scripts/npc/npc_abilities_override.txt');
  const shopDir = resolveRepoPath('game/scripts/shops');

  const officialItemsText = await readTextFromSource(dotaItemsSource);
  const officialItems = readTopLevelItemKeysFromLines(readLinesFromText(officialItemsText));
  const allowedItems = new Set();
  const manualWhitelistItems = readManualWhitelist(whitelistPath);
  const shopItems = readShopItems(shopDir);
  const customItems = readTopLevelItemKeys(customItemsPath);
  const manualOverrideItems = readManualOverrideItems(overridePath);

  mergeSet(allowedItems, manualWhitelistItems);
  mergeSet(allowedItems, shopItems);
  mergeSet(allowedItems, customItems);
  mergeSet(allowedItems, manualOverrideItems);

  const removedItems = [...officialItems]
    .filter((item) => !allowedItems.has(item))
    .sort();
  const listedAllowedItems = new Set();
  const officialAllowedItems = takeCategory(intersectSets(officialItems, allowedItems), listedAllowedItems);
  const shopOnlyItems = takeCategory(subtractSets(shopItems, officialItems), listedAllowedItems);
  const xhsCustomOnlyItems = takeCategory(subtractSets(customItems, officialItems), listedAllowedItems);
  const manualWhitelistExtraItems = takeCategory(manualWhitelistItems, listedAllowedItems);
  const manualOverrideExtraItems = takeCategory(manualOverrideItems, listedAllowedItems);

  fs.mkdirSync(path.dirname(outputPath), { recursive: true });

  const lines = [
    '// AUTO-GENERATED FILE - DO NOT EDIT BY HAND',
    '// Regenerate with: node scripts/update_removed_dota_items.js',
    `// Generated at: ${new Date().toISOString()}`,
    `// Source: ${dotaItemsSource}`,
    '//',
    `// Official items: ${officialItems.size}`,
    `// Allowed items: ${allowedItems.size}`,
    `// Removed items: ${removedItems.length}`,
  ];

  addCommentedItemSection(lines, 'Allowed official Dota items', officialAllowedItems);
  addCommentedItemSection(lines, 'XHS shop items', shopOnlyItems);
  addCommentedItemSection(lines, 'XHS custom items not in shops', xhsCustomOnlyItems);
  addCommentedItemSection(lines, 'Manual whitelist extras', manualWhitelistExtraItems);
  addCommentedItemSection(lines, 'Manual override extras', manualOverrideExtraItems);

  lines.push('');
  lines.push('"DOTAAbilities"');
  lines.push('{');
  for (const item of removedItems) {
    lines.push(`\t"${item}"\t"REMOVE"`);
  }
  lines.push('}');
  lines.push('');

  fs.writeFileSync(outputPath, lines.join('\n'), 'ascii');

  console.log(`Generated: ${outputPath}`);
  console.log(`Source: ${dotaItemsSource}`);
  console.log(`Official items: ${officialItems.size}`);
  console.log(`Allowed items: ${allowedItems.size}`);
  console.log(`Removed items: ${removedItems.length}`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
