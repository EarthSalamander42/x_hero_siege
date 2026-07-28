BEGIN;

CREATE TABLE IF NOT EXISTS xhs_player_item_builds (
	steamid character varying(20) NOT NULL,
	game_type character varying(16) NOT NULL DEFAULT 'XHS',
	map_scope character varying(64) NOT NULL,
	hero_name character varying(96) NOT NULL,
	schema_version integer NOT NULL DEFAULT 1,
	revision integer NOT NULL DEFAULT 1,
	payload jsonb NOT NULL,
	last_idempotency_key character varying(128),
	created_at timestamp without time zone NOT NULL DEFAULT now(),
	updated_at timestamp without time zone NOT NULL DEFAULT now(),
	PRIMARY KEY (steamid, game_type, map_scope, hero_name)
);

CREATE INDEX IF NOT EXISTS idx_xhs_player_item_builds_updated
	ON xhs_player_item_builds(updated_at DESC);

COMMIT;
