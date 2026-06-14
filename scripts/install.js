const fs = require('fs');
const readline = require('readline');

const rl = readline.createInterface(process.stdin, process.stdout);
rl.setPrompt('Dota Path: ');
rl.prompt();

rl.on('line', (dotaPath) => {
  const gamePath = `${dotaPath}/game/dota_addons`;
  const contentPath = `${dotaPath}/content/dota_addons`;
  if (!fs.existsSync(gamePath)) {
    console.log(`${gamePath} not found`);
    rl.prompt();
    return;
  }
  if (!fs.existsSync(contentPath)) {
    console.log(`${contentPath} not found`);
    rl.prompt();
    return;
  }
  rl.close();

  (async () => {
    await fs.promises.rename('./game', gamePath + '/x_hero_siege');
    await fs.promises.rename('./content', contentPath + '/x_hero_siege');
    await fs.promises.symlink(gamePath + '/x_hero_siege', './game', 'junction');
    await fs.promises.symlink(contentPath + '/x_hero_siege', './content', 'junction');
  })().catch(err => {
    console.error(err);
    process.exit(1);
  });
});
