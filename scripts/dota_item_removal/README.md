# Dota Item Removal Generator

This keeps new Valve items out of X Hero Siege after Dota patches.

Editable files:

- `scripts/dota_item_removal/item_whitelist.txt`: manual allow-list.
- `scripts/dota_item_removal/official_dota_items.txt`: local copy of Valve's official `scripts/npc/items.txt`. This file is ignored by Git.

Generated file:

- `game/scripts/npc/generated/removed_dota_items.txt`: auto-generated `REMOVE` entries. Do not edit by hand.

Workflow after a Dota patch:

1. Extract Valve's latest `scripts/npc/items.txt` from Dota's `pak01_dir.vpk`.
2. Save it as `scripts/dota_item_removal/official_dota_items.txt`, or pass it directly:

   ```powershell
   node scripts/update_removed_dota_items.js --dota-items C:\path\to\items.txt
   ```

3. Run:

   ```powershell
   node scripts/update_removed_dota_items.js
   ```

The script keeps these items out of the generated removal list:

- items in `scripts/dota_item_removal/item_whitelist.txt`
- items referenced by `game/scripts/shops/*.txt`
- custom items declared in `game/scripts/npc/npc_items_custom.txt`
- item blocks already manually overridden in `game/scripts/npc/npc_abilities_override.txt`

The generated file is included by `game/scripts/npc/npc_abilities_override.txt` using `#base generated/removed_dota_items.txt`.
