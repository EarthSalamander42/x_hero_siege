"use strict";

const SCHEMA_VERSION = 1;
const MAX_BUILDS = 3;
const MAX_ITEMS_PER_SECTION = 12;
const MAX_TOTAL_ITEMS = 60;
const SECTIONS = ["starting", "early", "core", "situational", "late"];
const MAPS = new Set(["x_hero_siege_4", "x_hero_siege_8", "x_hero_siege_demo"]);
const ALLOWED_ITEMS = new Set([
	"item_amulet_of_the_wild",
	"item_ankh_of_reincarnation",
	"item_astral_core",
	"item_boots_of_speed",
	"item_bracer_of_the_void",
	"item_celestial_claws",
	"item_healing_wards",
	"item_healing_wards2",
	"item_health_potion",
	"item_lifesteal_mask",
	"item_mana_potion",
	"item_mystic_gem",
	"item_orb_of_arcane",
	"item_orb_of_darkness",
	"item_orb_of_darkness2",
	"item_orb_of_earth",
	"item_orb_of_earth2",
	"item_orb_of_earth3",
	"item_orb_of_fire",
	"item_orb_of_fire2",
	"item_orb_of_lightning",
	"item_orb_of_lightning2",
	"item_orb_of_wind",
	"item_plagueheart",
	"item_potion_full",
	"item_potion_of_antimagic",
	"item_potion_of_invulnerability",
	"item_searing_blade",
	"item_staff_of_mastery",
	"item_tempest_aegis",
	"item_tome_big",
	"item_tome_of_power",
	"item_tome_small",
	"item_viridian_gem",
	"item_xhs_cloak_of_flames",
	"item_xhs_orb_of_venom",
	"item_zephyr_gem"
]);

let tableReady = false;

function toArray(value) {
	if (Array.isArray(value)) return value.slice();
	if (!value || typeof value !== "object") return [];
	return Object.keys(value)
		.filter(key => /^\d+$/.test(key))
		.sort((left, right) => Number(left) - Number(right))
		.map(key => value[key]);
}

function cleanText(value, maxLength) {
	return String(value || "")
		.replace(/[\u0000-\u001f\u007f]/g, "")
		.trim()
		.substring(0, maxLength);
}

function normalizeSteamID(value) {
	const steamid = String(value || "");
	if (!/^\d{5,20}$/.test(steamid)) throw new Error("invalid steamid");
	return steamid;
}

function normalizeHero(value) {
	const hero = String(value || "");
	if (!/^npc_dota_hero_[a-z0-9_]{1,76}$/.test(hero)) throw new Error("invalid hero_name");
	return hero;
}

function normalizeMap(value) {
	const mapScope = String(value || "");
	if (!MAPS.has(mapScope)) throw new Error("invalid map_scope");
	return mapScope;
}

function normalizeGameTypeValue(value) {
	const gameType = String(value || "").toUpperCase();
	if (!/^[A-Z0-9_]{1,16}$/.test(gameType)) throw new Error("invalid game type");
	return gameType;
}

function normalizeIdempotencyKey(value) {
	const key = String(value || "").trim();
	if (key.length < 1 || key.length > 128 || !/^[A-Za-z0-9_.:-]+$/.test(key)) {
		throw new Error("invalid idempotency_key");
	}
	return key;
}

function normalizeExpectedRevision(value) {
	const revision = Number(value);
	if (!Number.isSafeInteger(revision) || revision < 0) {
		throw new Error("invalid expected_revision");
	}
	return revision;
}

function normalizeBuildName(value) {
	const name = String(value || "")
		.replace(/[\u0000-\u001f\u007f]/g, "")
		.trim();
	if (!name || Array.from(name).length > 32) throw new Error("invalid build name");
	return name;
}

function normalizePayload(payload, options = {}) {
	if (!payload || typeof payload !== "object") throw new Error("payload must be an object");
	if (Number(payload.schema_version) !== SCHEMA_VERSION) throw new Error("unsupported item build schema");

	const sourceBuilds = toArray(payload.builds);
	if (sourceBuilds.length < 1 || sourceBuilds.length > MAX_BUILDS) throw new Error("invalid build count");

	const normalized = {
		schema_version: SCHEMA_VERSION,
		active_build_id: cleanText(payload.active_build_id, 64),
		builds: []
	};
	const ids = new Set();
	let totalItems = 0;
	let changed = false;

	for (const sourceBuild of sourceBuilds) {
		if (!sourceBuild || typeof sourceBuild !== "object") throw new Error("invalid build");
		const id = cleanText(sourceBuild.id, 64);
		const name = normalizeBuildName(sourceBuild.name);
		if (!/^[A-Za-z0-9_-]+$/.test(id) || ids.has(id)) throw new Error("invalid or duplicate build id");
		ids.add(id);

		const build = { id, name, sections: {} };
		const sourceSections = sourceBuild.sections && typeof sourceBuild.sections === "object" ? sourceBuild.sections : {};
		for (const sectionKey of SECTIONS) {
			const sourceItems = toArray(sourceSections[sectionKey]);
			if (sourceItems.length > MAX_ITEMS_PER_SECTION) throw new Error("too many items in section");
			build.sections[sectionKey] = [];
			for (const sourceItem of sourceItems) {
				const itemName = String(sourceItem || "");
				if (!ALLOWED_ITEMS.has(itemName)) {
					if (options.pruneInvalidItems) {
						changed = true;
						continue;
					}
					throw new Error(`item is not in the XHS shop: ${itemName}`);
				}
				totalItems++;
				if (totalItems > MAX_TOTAL_ITEMS) throw new Error("too many items in payload");
				build.sections[sectionKey].push(itemName);
			}
		}
		normalized.builds.push(build);
	}

	if (!ids.has(normalized.active_build_id)) {
		if (!options.pruneInvalidItems) throw new Error("active build does not exist");
		normalized.active_build_id = normalized.builds[0].id;
		changed = true;
	}
	if (JSON.stringify(normalized) !== JSON.stringify(payload)) changed = true;
	return { payload: normalized, changed };
}

function logEvent(logger, eventName, fields) {
	const sink = logger && typeof logger.info === "function" ? logger.info.bind(logger) : console.info.bind(console);
	sink(`[XHSItemBuilds] ${eventName}`, fields);
}

async function ensureTable(client) {
	if (tableReady) return;
	await client.query(
		"create table if not exists xhs_player_item_builds (" +
		"steamid character varying(20) not null, " +
		"game_type character varying(16) not null default 'XHS', " +
		"map_scope character varying(64) not null, " +
		"hero_name character varying(96) not null, " +
		"schema_version integer not null default 1, " +
		"revision integer not null default 1, " +
		"payload jsonb not null, " +
		"last_idempotency_key character varying(128), " +
		"created_at timestamp without time zone not null default now(), " +
		"updated_at timestamp without time zone not null default now(), " +
		"primary key (steamid, game_type, map_scope, hero_name)" +
		");"
	);
	await client.query("create index if not exists idx_xhs_player_item_builds_updated on xhs_player_item_builds(updated_at desc);");
	tableReady = true;
}

async function lockRecord(client, steamid, gameType, mapScope, heroName) {
	await client.query(
		"select pg_advisory_xact_lock(hashtext($1), hashtext($2));",
		[`${steamid}|${gameType}`, `${mapScope}|${heroName}`]
	);
}

function mount(router, dependencies) {
	const { db, generalHelper, normalizeGameType } = dependencies;
	const logger = dependencies.logger || console;

	router.post("/xhs/item-builds/get", async function(req, res) {
		generalHelper.validation.requireNonEmpty(req.body, ["steamid", "hero_name", "map_scope"]);
		const steamid = normalizeSteamID(req.body.steamid);
		const heroName = normalizeHero(req.body.hero_name);
		const mapScope = normalizeMap(req.body.map_scope);
		const gameType = normalizeGameTypeValue(normalizeGameType(req));
		let out = null;

		await db.tx(async function(client) {
			await ensureTable(client);
			await lockRecord(client, steamid, gameType, mapScope, heroName);
			const result = await client.query(
				"select schema_version, revision, payload, updated_at from xhs_player_item_builds where steamid = $1 and game_type = $2 and map_scope = $3 and hero_name = $4 for update;",
				[steamid, gameType, mapScope, heroName]
			);
			const row = result.rows[0];
			if (!row) {
				out = { schema_version: SCHEMA_VERSION, revision: 0, payload: null };
				return;
			}

			const migrated = normalizePayload(row.payload, { pruneInvalidItems: true });
			let revision = Number(row.revision || 0);
			if (migrated.changed || Number(row.schema_version) !== SCHEMA_VERSION) {
				revision++;
				await client.query(
					"update xhs_player_item_builds set schema_version = $1, revision = $2, payload = $3::jsonb, updated_at = now() where steamid = $4 and game_type = $5 and map_scope = $6 and hero_name = $7;",
					[SCHEMA_VERSION, revision, JSON.stringify(migrated.payload), steamid, gameType, mapScope, heroName]
				);
				logEvent(logger, "payload-migrated", {
					player: steamid.slice(-6),
					game_type: gameType,
					map_scope: mapScope,
					hero_name: heroName,
					revision
				});
			}
			out = {
				schema_version: SCHEMA_VERSION,
				revision,
				payload: migrated.payload,
				updated_at: row.updated_at
			};
		});
		res.wrappedJson(out);
	});

	router.post("/xhs/item-builds/save", async function(req, res) {
		generalHelper.validation.requireNonEmpty(req.body, ["steamid", "hero_name", "map_scope", "idempotency_key", "payload"]);
		const steamid = normalizeSteamID(req.body.steamid);
		const heroName = normalizeHero(req.body.hero_name);
		const mapScope = normalizeMap(req.body.map_scope);
		const gameType = normalizeGameTypeValue(normalizeGameType(req));
		const expectedRevision = normalizeExpectedRevision(req.body.expected_revision);
		const idempotencyKey = normalizeIdempotencyKey(req.body.idempotency_key);
		const normalized = normalizePayload(req.body.payload, { pruneInvalidItems: false }).payload;
		let out = null;

		await db.tx(async function(client) {
			await ensureTable(client);
			await lockRecord(client, steamid, gameType, mapScope, heroName);
			const currentResult = await client.query(
				"select revision, last_idempotency_key from xhs_player_item_builds where steamid = $1 and game_type = $2 and map_scope = $3 and hero_name = $4 for update;",
				[steamid, gameType, mapScope, heroName]
			);
			const current = currentResult.rows[0];
			const currentRevision = current ? Number(current.revision || 0) : 0;

			if (current && current.last_idempotency_key === idempotencyKey) {
				out = { ok: true, idempotent: true, revision: currentRevision };
				logEvent(logger, "idempotent-retry", {
					player: steamid.slice(-6),
					map_scope: mapScope,
					hero_name: heroName,
					revision: currentRevision
				});
				return;
			}
			if (expectedRevision !== currentRevision) {
				out = { ok: false, conflict: true, revision: currentRevision };
				logEvent(logger, "revision-conflict", {
					player: steamid.slice(-6),
					map_scope: mapScope,
					hero_name: heroName,
					expected_revision: expectedRevision,
					current_revision: currentRevision
				});
				return;
			}

			const nextRevision = currentRevision + 1;
			await client.query(
				"insert into xhs_player_item_builds (steamid, game_type, map_scope, hero_name, schema_version, revision, payload, last_idempotency_key, created_at, updated_at) " +
				"values ($1,$2,$3,$4,$5,$6,$7::jsonb,$8,now(),now()) " +
				"on conflict (steamid, game_type, map_scope, hero_name) do update set schema_version = excluded.schema_version, revision = excluded.revision, payload = excluded.payload, last_idempotency_key = excluded.last_idempotency_key, updated_at = now();",
				[steamid, gameType, mapScope, heroName, SCHEMA_VERSION, nextRevision, JSON.stringify(normalized), idempotencyKey]
			);
			out = { ok: true, revision: nextRevision };
			logEvent(logger, "saved", {
				player: steamid.slice(-6),
				map_scope: mapScope,
				hero_name: heroName,
				revision: nextRevision
			});
		});
		res.wrappedJson(out);
	});
}

module.exports = {
	mount,
	test: {
		normalizePayload,
		normalizeSteamID,
		normalizeHero,
		normalizeMap,
		normalizeGameTypeValue,
		normalizeIdempotencyKey,
		normalizeExpectedRevision,
		normalizeBuildName,
		allowedItems: ALLOWED_ITEMS,
		sections: SECTIONS,
		resetTableReady() {
			tableReady = false;
		}
	}
};
