const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');

function escapeHtml(value) {
  return String(value == null ? '' : value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function formatNumber(value) {
  const number = Number(value || 0);
  return Number.isFinite(number) ? number.toLocaleString('en-US') : '0';
}

function parseArgs(argv) {
  const args = {
    input: 'patch_notes/4.0.web.json',
    output: 'patch_notes/4.0.preview.html',
  };

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    const next = argv[i + 1];

    if (arg === '--input' && next) {
      args.input = next;
      i++;
    } else if (arg === '--output' && next) {
      args.output = next;
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
  node scripts/generate_patch_note_preview.js [options]

Options:
  --input <path>    Patch web JSON
                    Default: patch_notes/4.0.web.json
  --output <path>   HTML preview output
                    Default: patch_notes/4.0.preview.html
  --help, -h        Show this help
`);
}

function resolveRepoPath(value) {
  if (path.isAbsolute(value)) {
    return value;
  }

  return path.join(repoRoot, value);
}

function itemHtml(item) {
  const lines = String(item == null ? '' : item)
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
  const main = lines.shift() || '';

  if (lines.length === 0) {
    return `<li>${escapeHtml(main)}</li>`;
  }

  const subitems = lines
    .map((line) => line.replace(/^-\s*/, ''))
    .map((line) => `    <li>${escapeHtml(line)}</li>`)
    .join('\n');

  return `<li><span class="item-main">${escapeHtml(main)}</span>
  <ul class="subitems">
${subitems}
  </ul>
</li>`;
}

function sectionHtml(section) {
  const auditClass = section.title === 'Release audit' ? ' audit' : '';
  const items = (section.items || [])
    .map(itemHtml)
    .join('\n');

  return `<article class="patch-section${auditClass}">
  <div class="patch-section-head">
    <span>${escapeHtml(section.title)}</span>
    <strong>${formatNumber((section.items || []).length)}</strong>
  </div>
  <ul>
${items}
  </ul>
</article>`;
}

function assetSrc(value) {
  if (!value) {
    return '';
  }

  const normalized = String(value).replace(/\\/g, '/');
  if (/^(?:https?:|data:|file:)/.test(normalized)) {
    return normalized;
  }

  return `../${normalized.replace(/^\/+/, '')}`;
}

function titleOf(entry) {
  return String(entry && entry.title ? entry.title : '');
}

function sortEntries(entries) {
  return (entries || []).slice().sort((a, b) => titleOf(a).localeCompare(titleOf(b), 'en', { sensitivity: 'base' }));
}

function breakdownSubsectionHtml(subsection) {
  const entries = sortEntries(subsection.entries || [])
    .map((entry) => {
      const image = entry.image
        ? `<img class="ability-icon" src="${escapeHtml(assetSrc(entry.image))}" alt="" loading="lazy">`
        : '';
      const noIconClass = entry.image ? '' : ' no-icon';
      const items = (entry.items || [])
        .map((item) => `<li>${escapeHtml(item)}</li>`)
        .join('\n');

      return `<div class="ability-entry${noIconClass}">
  ${image}
  <div class="ability-copy">
    <h4>${escapeHtml(entry.title)}</h4>
    <ul>
${items}
    </ul>
  </div>
</div>`;
    })
    .join('\n');

  return `<div class="entry-subsection">
  <div class="entry-subtitle">${escapeHtml(subsection.title)}</div>
  <div class="ability-list">
${entries}
  </div>
</div>`;
}

function breakdownEntryHtml(entry) {
  const image = entry.image
    ? `<img class="entry-icon" src="${escapeHtml(assetSrc(entry.image))}" alt="" loading="lazy">`
    : '';
  const noIconClass = entry.image ? '' : ' no-icon';
  const items = (entry.items || [])
    .map((item) => `<li>${escapeHtml(item)}</li>`)
    .join('\n');
  const subsections = (entry.subsections || [])
    .map(breakdownSubsectionHtml)
    .join('\n');
  const itemList = items
    ? `<ul class="entry-bullets">
${items}
    </ul>`
    : '';

  return `<div class="breakdown-entry${noIconClass}">
  ${image}
  <div class="entry-copy">
    <h3>${escapeHtml(entry.title)}</h3>
    ${itemList}
    ${subsections}
  </div>
</div>`;
}

function breakdownGroupHtml(group) {
  const entries = sortEntries(group.entries || [])
    .map(breakdownEntryHtml)
    .join('\n');
  const title = group.title
    ? `<div class="breakdown-subtitle">${escapeHtml(group.title)}</div>`
    : '';

  return `${title}
<div class="breakdown-content">
${entries}
</div>`;
}

function breakdownSectionHtml(section) {
  const groups = section.groups && section.groups.length
    ? section.groups.map(breakdownGroupHtml).join('\n')
    : breakdownGroupHtml({ entries: section.entries || [] });

  return `<section class="breakdown-section">
  <header class="breakdown-title">${escapeHtml(section.title)}</header>
${groups}
</section>`;
}

function breakdownGroups(section) {
  if (section.groups && section.groups.length) {
    return section.groups;
  }

  return [{ title: '', entries: section.entries || [] }];
}

function countBreakdownSection(patch, title) {
  const section = (patch.breakdown || []).find((item) => item.title === title);
  if (!section) {
    return 0;
  }

  return breakdownGroups(section).reduce((sum, group) => sum + ((group.entries || []).length), 0);
}

function buildTopStats(patch) {
  if (patch.stats && patch.stats.length) {
    return patch.stats;
  }

  if (patch.breakdown && patch.breakdown.length) {
    return [
      { label: 'Bosses', value: countBreakdownSection(patch, 'Boss Encounters'), text: 'Encounter entries', theme: 'violet' },
      { label: 'Items', value: countBreakdownSection(patch, 'Item Changes'), text: 'Item entries', theme: 'gold' },
      { label: 'General', value: countBreakdownSection(patch, 'General Changes'), text: 'System changes', theme: '' },
      { label: 'Audit', value: countBreakdownSection(patch, 'Needs Review Before Publishing'), text: 'Review notes', theme: 'red' },
    ];
  }

  return [
    { label: 'Selected', value: patch.version, text: `${patch.statusLabel} XHS build`, theme: 'gold' },
    { label: 'Sections', value: (patch.details || []).length, text: 'Patch sections', theme: '' },
    { label: 'Notes', value: (patch.details || []).reduce((sum, section) => sum + ((section.items || []).length), 0), text: 'Listed changes', theme: '' },
    { label: 'Status', value: patch.statusLabel, text: 'Patch state', theme: 'red' },
  ];
}

function buildAuditStats(diff) {
  return [
    { label: 'Files', value: formatNumber(diff.changedFiles), text: 'Changed in Git diff', theme: '' },
    { label: 'Commits', value: formatNumber(diff.commitCount), text: 'Compared commits', theme: '' },
    { label: 'Added', value: `+${formatNumber(diff.insertions)}`, text: 'Inserted lines', theme: 'gold' },
    { label: 'Removed', value: `-${formatNumber(diff.deletions)}`, text: 'Deleted lines', theme: 'red' },
  ];
}

function statCardHtml(stat) {
  const theme = stat.theme ? ` ${escapeHtml(stat.theme)}` : '';
  return `<div class="stat${theme}"><span>${escapeHtml(stat.label)}</span><strong>${escapeHtml(stat.value)}</strong><small>${escapeHtml(stat.text || '')}</small></div>`;
}

function buildHtml(patch) {
  const diff = patch.meta && patch.meta.diffStats ? patch.meta.diffStats : {};
  const footer = diff.footer || 'Diff analyzed: not available.';
  const details = patch.details || [];
  const sections = details.map(sectionHtml).join('\n');
  const releaseBody = patch.breakdown && patch.breakdown.length
    ? `<div class="breakdown-stack">\n${patch.breakdown.map(breakdownSectionHtml).join('\n')}\n</div>`
    : `<div class="patch-section-list">\n${sections}\n        </div>`;
  const compareUrl = patch.meta && patch.meta.compareUrl ? patch.meta.compareUrl : '';
  const topStats = buildTopStats(patch).map(statCardHtml).join('\n');
  const auditStats = buildAuditStats(diff).map(statCardHtml).join('\n');

  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapeHtml(patch.title)} - Preview</title>
  <style>
    :root {
      --accent: #5ad0ff;
      --accent-rgb: 90, 208, 255;
      --gold: #ffcf66;
      --bg: #02050b;
      --panel: rgba(7, 24, 39, 0.76);
      --panel-dark: rgba(2, 6, 12, 0.92);
      --text: #edf8ff;
      --muted: #9bb9ca;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      background:
        radial-gradient(circle at 50% 0%, rgba(var(--accent-rgb), 0.16), transparent 28%),
        linear-gradient(180deg, #07101d 0%, #030711 54%, #010309 100%);
      color: var(--text);
      font-family: Inter, "Segoe UI", Arial, sans-serif;
    }
    body::before {
      content: "";
      position: fixed;
      inset: 0;
      background:
        linear-gradient(90deg, rgba(255, 255, 255, 0.028) 1px, transparent 1px) 0 0 / 64px 64px,
        linear-gradient(0deg, rgba(255, 255, 255, 0.02) 1px, transparent 1px) 0 0 / 64px 64px;
      pointer-events: none;
    }
    main {
      position: relative;
      z-index: 1;
      width: min(1440px, calc(100vw - 48px));
      margin: 0 auto;
      padding: 42px 0 48px;
    }
    .hero {
      position: relative;
      display: grid;
      grid-template-columns: minmax(0, 1fr) 420px;
      gap: 18px;
      min-height: 390px;
      overflow: hidden;
      border: 1px solid rgba(var(--accent-rgb), 0.22);
      background:
        linear-gradient(90deg, rgba(2, 6, 12, 0.94), rgba(2, 6, 12, 0.58) 52%, rgba(2, 6, 12, 0.9)),
        radial-gradient(circle at 72% 22%, rgba(255, 207, 102, 0.18), transparent 34%),
        linear-gradient(135deg, rgba(17, 78, 108, 0.48), rgba(2, 6, 12, 0.96));
    }
    .hero-copy {
      align-self: end;
      padding: 34px;
    }
    .eyebrow {
      display: inline-flex;
      align-items: center;
      gap: 9px;
      margin-bottom: 16px;
      color: var(--gold);
      font-size: 11px;
      font-weight: 900;
      text-transform: uppercase;
    }
    .eyebrow::before {
      content: "";
      width: 32px;
      height: 2px;
      background: var(--gold);
      box-shadow: 0 0 12px rgba(255, 207, 102, 0.65);
    }
    h1, h2, h3 {
      margin: 0;
      color: #fff;
      font-weight: 950;
      line-height: 0.96;
      text-transform: uppercase;
    }
    h1 {
      max-width: 840px;
      font-size: clamp(54px, 8vw, 118px);
      text-shadow: 0 4px 24px rgba(0, 0, 0, 0.72);
    }
    h2 { font-size: clamp(28px, 4vw, 52px); }
    .lead {
      max-width: 720px;
      margin: 18px 0 0;
      color: #c0d9e5;
      font-size: 16px;
      line-height: 1.56;
    }
    .hero-panel {
      display: grid;
      align-content: center;
      gap: 14px;
      padding: 20px;
      border-left: 1px solid rgba(var(--accent-rgb), 0.2);
      background: rgba(3, 9, 17, 0.48);
    }
    .panel-title {
      color: var(--muted);
      font-size: 11px;
      font-weight: 900;
      text-transform: uppercase;
    }
    .hero-panel strong {
      display: block;
      color: #fff;
      font-size: 22px;
      font-weight: 950;
      line-height: 1.08;
      text-transform: uppercase;
    }
    .actions {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin-top: 26px;
    }
    .action {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-height: 42px;
      padding: 0 15px;
      border: 1px solid rgba(var(--accent-rgb), 0.72);
      background: linear-gradient(90deg, rgba(var(--accent-rgb), 0.62), rgba(3, 9, 17, 0.88));
      color: #fff;
      font-size: 12px;
      font-weight: 950;
      text-decoration: none;
      text-transform: uppercase;
    }
    .action.gold {
      border-color: rgba(255, 207, 102, 0.58);
      background: linear-gradient(90deg, rgba(117, 79, 18, 0.9), rgba(7, 24, 39, 0.88));
      color: #ffe7a7;
    }
    .stat-grid {
      display: grid;
      gap: 14px;
    }
    .stat-grid {
      grid-template-columns: repeat(4, minmax(0, 1fr));
      margin: 18px 0;
    }
    .stat {
      min-height: 104px;
      padding: 16px;
      border: 1px solid rgba(var(--accent-rgb), 0.2);
      background: linear-gradient(135deg, var(--panel), var(--panel-dark));
    }
    .stat span {
      display: block;
      color: var(--muted);
      font-size: 11px;
      font-weight: 900;
      text-transform: uppercase;
    }
    .stat strong {
      display: block;
      margin-top: 8px;
      color: #fff;
      font-size: 30px;
      font-weight: 950;
      line-height: 1;
    }
    .stat small {
      display: block;
      margin-top: 8px;
      color: #b9d7e7;
      font-size: 12px;
    }
    .stat.gold::after { background: linear-gradient(90deg, var(--gold), transparent); }
    .stat.violet::after { background: linear-gradient(90deg, #a56cff, transparent); }
    .stat.red::after { background: linear-gradient(90deg, #ff5a43, transparent); }
    .stat {
      position: relative;
      overflow: hidden;
    }
    .stat::after {
      content: "";
      position: absolute;
      inset: auto 0 0;
      height: 3px;
      background: linear-gradient(90deg, var(--accent), transparent);
    }
    .layout {
      display: block;
    }
    .main-panel,
    .patch-section {
      border: 1px solid rgba(var(--accent-rgb), 0.2);
      background: linear-gradient(135deg, var(--panel), var(--panel-dark));
      box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.06);
    }
    .main-panel {
      padding: 18px;
    }
    .section-heading {
      display: flex;
      justify-content: space-between;
      gap: 18px;
      align-items: flex-start;
    }
    .patch-section-list {
      display: grid;
      gap: 12px;
      margin-top: 18px;
    }
    .breakdown-stack {
      display: grid;
      gap: 30px;
      margin-top: 18px;
    }
    .breakdown-section {
      overflow: hidden;
      border: 1px solid rgba(var(--accent-rgb), 0.16);
      background:
        linear-gradient(125deg, rgba(6, 28, 45, 0.8), rgba(2, 6, 12, 0.92)),
        radial-gradient(circle at 88% 30%, rgba(var(--accent-rgb), 0.12), transparent 34%);
      box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.05);
    }
    .breakdown-title {
      padding: 15px 22px 16px;
      background:
        linear-gradient(90deg, rgba(132, 55, 20, 0.96), rgba(71, 31, 20, 0.8) 45%, rgba(5, 8, 13, 0.58)),
        linear-gradient(180deg, rgba(255, 222, 156, 0.08), rgba(0, 0, 0, 0));
      color: #fff;
      font-family: Georgia, "Times New Roman", serif;
      font-size: clamp(27px, 3.2vw, 42px);
      font-weight: 900;
      letter-spacing: 1.5px;
      line-height: 1;
      text-transform: uppercase;
      text-shadow: 0 2px 0 #000, 0 0 14px rgba(0, 0, 0, 0.75);
    }
    .breakdown-subtitle {
      padding: 10px 22px;
      background: linear-gradient(90deg, rgba(9, 41, 62, 0.96), rgba(6, 19, 31, 0.78));
      color: #effaff;
      font-size: 14px;
      font-weight: 950;
      letter-spacing: 3px;
      text-transform: uppercase;
    }
    .breakdown-content {
      display: grid;
      padding: 18px 32px 4px;
    }
    .breakdown-entry {
      display: grid;
      grid-template-columns: 72px minmax(0, 1fr);
      gap: 16px;
      padding: 18px 0 19px;
      border-bottom: 1px solid rgba(199, 226, 241, 0.13);
    }
    .breakdown-entry:last-child {
      border-bottom: 0;
    }
    .breakdown-entry.no-icon {
      grid-template-columns: minmax(0, 1fr);
      padding-left: 28px;
    }
    .entry-icon {
      width: 64px;
      height: 64px;
      border: 1px solid rgba(255, 207, 102, 0.28);
      background: rgba(0, 0, 0, 0.42);
      box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.65), 0 8px 18px rgba(0, 0, 0, 0.38);
      object-fit: cover;
    }
    .entry-copy h3 {
      margin: 0 0 10px;
      color: #fff;
      font-family: Georgia, "Times New Roman", serif;
      font-size: clamp(20px, 2.2vw, 30px);
      font-weight: 900;
      letter-spacing: 1.7px;
      line-height: 1.05;
      text-transform: uppercase;
      text-shadow: 0 2px 0 #000, 0 0 8px rgba(0, 0, 0, 0.72);
    }
    .entry-bullets {
      gap: 6px;
      padding-left: 0;
    }
    .entry-bullets li {
      position: relative;
      padding-left: 18px;
      color: #bcd7e4;
      font-size: 14px;
      line-height: 1.46;
    }
    .entry-bullets li::before {
      content: "";
      position: absolute;
      left: 0;
      top: 0.66em;
      width: 5px;
      height: 5px;
      border-radius: 50%;
      background: #d9e9f3;
      opacity: 0.76;
      transform: translateY(-50%);
    }
    .entry-subsection {
      margin-top: 18px;
      padding-top: 14px;
      border-top: 1px solid rgba(199, 226, 241, 0.12);
    }
    .entry-subtitle {
      margin-bottom: 12px;
      color: #fff;
      font-size: 13px;
      font-weight: 950;
      letter-spacing: 3px;
      text-transform: uppercase;
    }
    .ability-list {
      display: grid;
      gap: 14px;
    }
    .ability-entry {
      display: grid;
      grid-template-columns: 52px minmax(0, 1fr);
      gap: 14px;
      align-items: start;
    }
    .ability-entry.no-icon {
      grid-template-columns: minmax(0, 1fr);
      padding-left: 12px;
    }
    .ability-icon {
      width: 48px;
      height: 48px;
      border: 1px solid rgba(90, 208, 255, 0.26);
      background: rgba(0, 0, 0, 0.48);
      object-fit: cover;
    }
    .ability-copy h4 {
      margin: 0 0 7px;
      color: #fff;
      font-family: Georgia, "Times New Roman", serif;
      font-size: 20px;
      font-weight: 900;
      letter-spacing: 1.4px;
      line-height: 1.05;
      text-transform: uppercase;
      text-shadow: 0 2px 0 #000;
    }
    .ability-copy ul {
      display: grid;
      gap: 5px;
      margin: 0;
      padding: 0;
      list-style: none;
    }
    .ability-copy li {
      position: relative;
      padding-left: 16px;
      color: #bcd7e4;
      font-size: 13px;
      line-height: 1.45;
    }
    .ability-copy li::before {
      content: "";
      position: absolute;
      left: 0;
      top: 0.66em;
      width: 4px;
      height: 4px;
      border-radius: 50%;
      background: #ffcf66;
      transform: translateY(-50%);
    }
    .patch-section {
      padding: 16px;
    }
    .patch-section.audit {
      border-color: rgba(255, 207, 102, 0.42);
      background: linear-gradient(135deg, rgba(117, 79, 18, 0.36), rgba(2, 6, 12, 0.9));
    }
    .patch-section-head {
      display: flex;
      justify-content: space-between;
      gap: 12px;
      margin-bottom: 12px;
    }
    .patch-section-head span {
      color: #fff;
      font-size: 18px;
      font-weight: 950;
      text-transform: uppercase;
    }
    .patch-section-head strong {
      display: grid;
      place-items: center;
      min-width: 34px;
      height: 28px;
      border: 1px solid rgba(255, 207, 102, 0.32);
      color: var(--gold);
      font-size: 12px;
    }
    ul {
      display: grid;
      gap: 9px;
      margin: 0;
      padding: 0;
      list-style: none;
    }
    .patch-section > ul > li {
      position: relative;
      padding-left: 18px;
      color: #cfeeff;
      font-size: 14px;
      line-height: 1.5;
    }
    .patch-section > ul > li::before {
      content: "";
      position: absolute;
      left: 0;
      top: 0.78em;
      width: 7px;
      height: 7px;
      border-radius: 50%;
      background: var(--gold);
      box-shadow: 0 0 0 0 rgba(255, 207, 102, 0.58);
      transform: translateY(-50%);
      animation: bulletPulse 2.4s ease-in-out infinite;
    }
    .patch-section > ul > li::after {
      content: "";
      position: absolute;
      left: 0;
      top: 0.78em;
      width: 7px;
      height: 7px;
      border: 1px solid rgba(255, 207, 102, 0.72);
      border-radius: 50%;
      transform: translateY(-50%) scale(1);
      animation: bulletRing 2.4s ease-out infinite;
    }
    @keyframes bulletPulse {
      0%, 100% {
        box-shadow: 0 0 0 0 rgba(255, 207, 102, 0.5);
        opacity: 0.78;
      }
      50% {
        box-shadow: 0 0 11px 2px rgba(255, 207, 102, 0.66);
        opacity: 1;
      }
    }
    @keyframes bulletRing {
      0% {
        opacity: 0.38;
        transform: translateY(-50%) scale(1);
      }
      68%, 100% {
        opacity: 0;
        transform: translateY(-50%) scale(2.6);
      }
    }
    .item-main {
      display: block;
      color: #dff6ff;
      font-weight: 800;
    }
    .subitems {
      gap: 6px;
      margin-top: 7px;
      padding-left: 14px;
    }
    .subitems li {
      position: relative;
      padding-left: 13px;
      color: #b7d5e6;
      font-size: 13px;
      line-height: 1.44;
    }
    .subitems li::before {
      content: "-";
      position: absolute;
      left: 0;
      top: 0;
      color: var(--gold);
      font-weight: 900;
    }
    .subitems li::after {
      content: none;
    }
    @media (max-width: 980px) {
      main { width: min(100% - 28px, 1440px); }
      .hero,
      .layout {
        grid-template-columns: 1fr;
      }
      .hero-panel {
        border-left: 0;
        border-top: 1px solid rgba(var(--accent-rgb), 0.2);
      }
      .stat-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }
    }
    @media (max-width: 720px) {
      .hero-copy { padding: 24px 18px; }
      .stat-grid {
        grid-template-columns: 1fr;
      }
      .section-heading {
        display: grid;
      }
      .breakdown-content {
        padding: 14px 18px 2px;
      }
      .breakdown-entry {
        grid-template-columns: 52px minmax(0, 1fr);
        gap: 12px;
      }
      .breakdown-entry.no-icon {
        padding-left: 0;
      }
      .entry-icon {
        width: 48px;
        height: 48px;
      }
      .ability-entry {
        grid-template-columns: 42px minmax(0, 1fr);
      }
      .ability-icon {
        width: 40px;
        height: 40px;
      }
    }
  </style>
</head>
<body>
  <main>
    <section class="hero" aria-label="X Hero Siege patch note">
      <div class="hero-copy">
        <div class="eyebrow">XHS patch notes</div>
        <h1>${escapeHtml(patch.version)}</h1>
        <p class="lead">${escapeHtml(patch.summary)}</p>
        <div class="actions">
          <a class="action gold" href="${escapeHtml(patch.route)}">Patch route</a>
          ${compareUrl ? `<a class="action" href="${escapeHtml(compareUrl)}">GitHub diff</a>` : ''}
        </div>
      </div>
      <aside class="hero-panel">
        <div class="panel-title">Selected build</div>
        <strong>${escapeHtml(patch.title)}</strong>
        <span>${escapeHtml(patch.statusLabel)} release draft</span>
        <div class="panel-title">Diff footer</div>
        <strong>${escapeHtml(footer)}</strong>
      </aside>
    </section>
    <section class="stat-grid" aria-label="Patch stats">
${topStats}
    </section>
    <section class="stat-grid" aria-label="Patch audit stats">
${auditStats}
    </section>
    <section class="layout">
      <div class="main-panel">
        <header class="section-heading">
          <div>
            <div class="eyebrow">Release draft</div>
            <h2>${escapeHtml(patch.title)}</h2>
          </div>
          ${compareUrl ? `<a class="action" href="${escapeHtml(compareUrl)}">GitHub diff</a>` : ''}
        </header>
        ${releaseBody}
      </div>
    </section>
  </main>
</body>
</html>
`;
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    return;
  }

  const inputPath = resolveRepoPath(args.input);
  const outputPath = resolveRepoPath(args.output);
  const patch = JSON.parse(fs.readFileSync(inputPath, 'utf8'));
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, buildHtml(patch), 'utf8');
  console.log(`Generated: ${path.relative(repoRoot, outputPath)}`);
}

try {
  main();
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
