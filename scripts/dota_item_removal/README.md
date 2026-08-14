# Dota Item Removal Generator

This keeps new Valve items out of X Hero Siege after Dota patches.

Editable files:

- `scripts/dota_item_removal/item_whitelist.txt`: manual allow-list.

Generated file:

- `game/scripts/npc/generated/removed_dota_items.txt`: auto-generated `REMOVE` entries. Do not edit by hand.

Workflow after a Dota patch:

1. Run:

   ```powershell
   node scripts/update_removed_dota_items.js
   ```

By default, the script fetches Valve's current `scripts/npc/items.txt` from:

```text
https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/scripts/npc/items.txt
```

You can still pass a local file or another URL:

```powershell
node scripts/update_removed_dota_items.js --dota-items C:\path\to\items.txt
node scripts/update_removed_dota_items.js --dota-items https://github.com/spirit-bear-productions/dota_vpk_updates/blob/main/scripts/npc/items.txt
```

The script keeps these items out of the generated removal list:

- items in `scripts/dota_item_removal/item_whitelist.txt`
- items referenced by `game/scripts/shops/*.txt`
- custom items declared in `game/scripts/npc/npc_items_custom.txt`
- item blocks already manually overridden in `game/scripts/npc/npc_abilities_override.txt`

The generated file is included by `game/scripts/npc/npc_abilities_override.txt` using `#base generated/removed_dota_items.txt`.
