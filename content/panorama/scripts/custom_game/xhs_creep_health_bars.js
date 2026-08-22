(function () {
	"use strict";

	var ROOT = null;
	var BAR_METRICS = {
		creep: { width: 82, height: 31, fallbackZ: 125 },
		creep_controlled: { width: 82, height: 31, fallbackZ: 125 },
		creep_hero: { width: 132, height: 42, fallbackZ: 185 }
	};
	var SCREEN_Y_OFFSET = 10;
	var POSITION_RATE = 0.0;
	var STATE_RATE = 0.05;
	var OFFSCREEN_POSITION_DIVISOR = 4;
	var LAG_DELAY_TICKS = Math.max(1, Math.ceil(0.16 / STATE_RATE));
	var bars = {};
	var trackedUnits = {};
	var trackedIndices = [];
	var positionFrame = 0;

	function ResolveRoot() {
		if (!ROOT || !ROOT.IsValid()) {
			ROOT = $("#XHSCreepHealthBarsRoot");
		}
		return ROOT;
	}

	function Clamp(value, minimum, maximum) {
		return Math.max(minimum, Math.min(maximum, Number(value) || 0));
	}

	function IsValidTrackedUnit(entityIndex, kind) {
		// The server already classified the unit. Panorama's IsHero does not
		// consistently include KV ConsideredHero NPCs on every runtime.
		return entityIndex >= 0 && Entities.IsValidEntity(entityIndex) && !!BAR_METRICS[kind];
	}

	function GetKindClass(kind) {
		if (kind === "creep_hero") { return "CreepHero"; }
		if (kind === "creep_controlled") { return "ControlledCreep"; }
		return "Creep";
	}

	function GetWorldZOffset(entityIndex, fallbackZ) {
		try {
			if (typeof Entities.GetHealthBarOffset === "function") {
				var entityOffset = Number(Entities.GetHealthBarOffset(entityIndex));
				if (isFinite(entityOffset) && entityOffset > 0) { return entityOffset; }
			}
		} catch (error) {}
		return fallbackZ;
	}

	function GetPresentationStack(entityIndex, bar) {
		try {
			var cachedBuff = bar && Number(bar.presentationBuff);
			if (cachedBuff >= 0
				&& Buffs.GetName(entityIndex, cachedBuff) === "modifier_xhs_custom_creep_health_bar") {
				return Number(Buffs.GetStackCount(entityIndex, cachedBuff));
			}
			var buffCount = Math.max(0, Number(Entities.GetNumBuffs(entityIndex)) || 0);
			for (var buffIndex = 0; buffIndex < buffCount; buffIndex++) {
				var buff = Entities.GetBuff(entityIndex, buffIndex);
				if (buff !== -1
					&& Buffs.GetName(entityIndex, buff) === "modifier_xhs_custom_creep_health_bar") {
					if (bar) { bar.presentationBuff = buff; }
					return Number(Buffs.GetStackCount(entityIndex, buff));
				}
			}
		} catch (error) {
			if (bar) { bar.presentationBuff = -1; }
		}
		return -1;
	}

	function HasEntityState(entityIndex, apiName) {
		try {
			return typeof Entities[apiName] === "function" && !!Entities[apiName](entityIndex);
		} catch (error) {
			return false;
		}
	}

	function IsVisibleToLocalPlayer(entityIndex, bar, localTeam) {
		var relayStack = GetPresentationStack(entityIndex, bar);
		// Server-side presentation blocks are authoritative. Visibility APIs only
		// answer FOW and would otherwise reveal frozen/locked quest targets.
		if (relayStack >= 0 && (relayStack & 1) !== 0) { return false; }
		try {
			if (typeof Entities.IsVisibleToTeam === "function") {
				return !!Entities.IsVisibleToTeam(entityIndex, localTeam);
			}
		} catch (error) {}
		try {
			if (typeof Entities.IsVisible === "function") { return !!Entities.IsVisible(entityIndex); }
		} catch (error) {}
		try {
			if (typeof Entities.IsEntityVisible === "function") { return !!Entities.IsEntityVisible(entityIndex); }
		} catch (error) {}
		return relayStack >= 0 && (localTeam !== 2 || (relayStack & 2) !== 0);
	}

	function CreateBar(entityIndex, kind, level) {
		if (!ResolveRoot()) { return null; }
		var panel = $.CreatePanel("Panel", ROOT, "XHSCreepHealthBar_" + entityIndex);
		panel.AddClass("XHSCreepHealthBar");
		panel.AddClass(GetKindClass(kind));
		panel.hittest = false;

		var levelLabel = null;
		if (kind === "creep_controlled" && level > 0) {
			levelLabel = $.CreatePanel("Label", panel, "");
			levelLabel.AddClass("XHSCreepLevelLabel");
			levelLabel.text = "Level " + level;
			levelLabel.hittest = false;
		}

		var unitName = null;
		var heroFrame = null;
		if (kind === "creep_hero") {
			unitName = $.CreatePanel("Label", panel, "");
			unitName.AddClass("XHSCreepHeroName");
			unitName.hittest = false;

			heroFrame = $.CreatePanel("Panel", panel, "");
			heroFrame.AddClass("XHSCreepHeroFrame");
			heroFrame.hittest = false;
		}
		var healthContainer = heroFrame || panel;

		var track = $.CreatePanel("Panel", healthContainer, "");
		track.AddClass("XHSCreepHealthTrack");
		track.hittest = false;

		var lag = $.CreatePanel("Panel", track, "");
		lag.AddClass("XHSCreepHealthLag");
		lag.hittest = false;

		var fill = $.CreatePanel("Panel", track, "");
		fill.AddClass("XHSCreepHealthFill");
		fill.hittest = false;

		var dividers = $.CreatePanel("Panel", track, "");
		dividers.AddClass("XHSCreepHealthDividers");
		dividers.hittest = false;

		var healthValue = null;
		if (kind === "creep_hero") {
			healthValue = $.CreatePanel("Label", heroFrame, "");
			healthValue.AddClass("XHSCreepHeroHealthValue");
			healthValue.hittest = false;
		}

		bars[entityIndex] = {
			panel: panel,
			kind: kind,
			metrics: BAR_METRICS[kind] || BAR_METRICS.creep,
			worldZ: GetWorldZOffset(entityIndex, (BAR_METRICS[kind] || BAR_METRICS.creep).fallbackZ),
			healthFill: fill,
			healthLag: lag,
			healthDividers: dividers,
			levelLabel: levelLabel,
			unitName: unitName,
			heroFrame: heroFrame,
			healthValue: healthValue,
			lastUnitName: "",
			lastLevel: level > 0 ? level : 0,
			lastMaxHealth: -1,
			lastHealth: 100,
			lastHealthText: "",
			lastX: null,
			lastY: null,
			lastTeam: null,
			lastCritical: null,
			lastFrozen: null,
			frozenIndicator: null,
			lastFillWidth: 100,
			lastLagWidth: 100,
			lagTarget: 100,
			lagTicks: 0,
			shouldRender: false,
			isVisible: false,
			presentationBuff: -1
		};
		return bars[entityIndex];
	}

	function EnsureFrozenIndicator(bar) {
		if (!bar || bar.frozenIndicator) { return; }
		var indicator = $.CreatePanel("Label", bar.heroFrame || bar.panel, "");
		indicator.AddClass("XHSCreepFrozenIndicator");
		indicator.text = "FROZEN";
		indicator.hittest = false;
		bar.frozenIndicator = indicator;
	}

	function SetBarVisible(bar, visible) {
		if (!bar || !bar.panel || bar.isVisible === visible) { return; }
		bar.isVisible = visible;
		bar.panel.SetHasClass("Visible", visible);
	}

	function SetPanelWidth(panel, bar, cacheKey, healthPercent) {
		if (bar[cacheKey] === healthPercent) { return; }
		bar[cacheKey] = healthPercent;
		panel.style.width = healthPercent.toFixed(2) + "%";
	}

	function UpdateHealthLag(bar, healthPercent) {
		if (healthPercent > bar.lastHealth) {
			bar.lagTicks = 0;
			bar.lagTarget = healthPercent;
			SetPanelWidth(bar.healthLag, bar, "lastLagWidth", healthPercent);
		} else if (healthPercent < bar.lastHealth) {
			bar.lagTarget = healthPercent;
			bar.lagTicks = LAG_DELAY_TICKS;
		} else if (bar.lagTicks > 0) {
			bar.lagTicks--;
			if (bar.lagTicks === 0) {
				SetPanelWidth(bar.healthLag, bar, "lastLagWidth", bar.lagTarget);
			}
		}
		bar.lastHealth = healthPercent;
	}

	function UpdateBarPosition(entityIndex, bar, rootWidth, rootHeight) {
		var origin = Entities.GetAbsOrigin(entityIndex);
		if (!origin) {
			SetBarVisible(bar, false);
			return;
		}
		var metrics = bar.metrics;
		var worldZ = bar.worldZ;
		var screenX = Game.WorldToScreenX(origin[0], origin[1], origin[2] + worldZ);
		var screenY = Game.WorldToScreenY(origin[0], origin[1], origin[2] + worldZ);
		if (screenX < 0 || screenY < 0 || rootWidth <= 0 || rootHeight <= 0) {
			SetBarVisible(bar, false);
			return;
		}

		// WorldToScreen returns physical screen pixels, while Panorama positions
		// panels in scaled layout pixels. Convert through the current viewport so
		// health frames stay attached on ultrawide and non-default UI scales.
		var screenWidth = typeof Game.GetScreenWidth === "function" ? Number(Game.GetScreenWidth()) : rootWidth;
		var screenHeight = typeof Game.GetScreenHeight === "function" ? Number(Game.GetScreenHeight()) : rootHeight;
		if (screenWidth > 0 && screenHeight > 0) {
			screenX *= rootWidth / screenWidth;
			screenY *= rootHeight / screenHeight;
		}
		var x = Math.floor(screenX - (metrics.width * 0.5));
		var y = Math.floor(screenY - metrics.height - SCREEN_Y_OFFSET);
		if (x < -metrics.width || x > rootWidth || y < -metrics.height || y > rootHeight) {
			SetBarVisible(bar, false);
			return;
		}
		var worldHealthOcclusion = null;
		try {
			worldHealthOcclusion = GameUI.CustomUIConfig().xhsWorldHealthFrameOcclusion;
		} catch (error) {}
		worldHealthOcclusion = worldHealthOcclusion || {};
		var overlapsFlyout = worldHealthOcclusion.flyoutLeft === true
			&& x < rootWidth * 0.40;
		var overlapsShop = worldHealthOcclusion.shopRight === true
			&& x + metrics.width > rootWidth * 0.75;
		if (overlapsFlyout || overlapsShop) {
			SetBarVisible(bar, false);
			return;
		}
		if (bar.lastX !== x || bar.lastY !== y) {
			bar.lastX = x;
			bar.lastY = y;
			bar.panel.style.position = x + "px " + y + "px 0px";
		}
		SetBarVisible(bar, true);
	}

	function FormatHealth(value) {
		value = Math.max(0, Number(value) || 0);
		if (value >= 1000000) { return (value / 1000000).toFixed(value >= 10000000 ? 0 : 1) + "M"; }
		if (value >= 1000) { return (value / 1000).toFixed(value >= 10000 ? 0 : 1) + "K"; }
		return String(Math.ceil(value));
	}

	function NiceHealthStep(maxHealth) {
		var target = Math.max(1, maxHealth / 10);
		var magnitude = Math.pow(10, Math.floor(Math.log(target) / Math.LN10));
		var normalized = target / magnitude;
		var nice = normalized <= 1 ? 1 : (normalized <= 2 ? 2 : (normalized <= 5 ? 5 : 10));
		return nice * magnitude;
	}

	function RefreshHealthDividers(bar, maxHealth) {
		if (!bar || bar.kind !== "creep_hero" || bar.lastMaxHealth === maxHealth) { return; }
		bar.lastMaxHealth = maxHealth;
		bar.healthDividers.RemoveAndDeleteChildren();
		var step = NiceHealthStep(maxHealth);
		for (var health = step; health < maxHealth; health += step) {
			var divider = $.CreatePanel("Panel", bar.healthDividers, "");
			divider.AddClass("XHSCreepHeroHealthDivider");
			divider.style.position = (health * 100 / maxHealth).toFixed(2) + "% 0px 0px";
			divider.hittest = false;
		}
	}

	function UpdateCreepState(entityIndex, entry, localTeam) {
		var kind = entry && entry.kind || "creep";
		var bar = bars[entityIndex];
		if (bar && bar.kind !== kind) {
			if (bar.panel && bar.panel.IsValid()) { bar.panel.DeleteAsync(0); }
			delete bars[entityIndex];
			bar = null;
		}
		if (!IsValidTrackedUnit(entityIndex, kind)
			|| !Entities.IsAlive(entityIndex)
			|| HasEntityState(entityIndex, "IsOutOfGame")
			|| HasEntityState(entityIndex, "IsNoDraw")
			|| HasEntityState(entityIndex, "IsInvisible")
			|| !IsVisibleToLocalPlayer(entityIndex, bar, localTeam)) {
			if (bar) {
				bar.shouldRender = false;
				SetBarVisible(bar, false);
			}
			return;
		}

		var displayedLevel = Math.max(0, Math.floor(Number(entry && entry.level) || 0));
		bar = bar || CreateBar(entityIndex, kind, displayedLevel);
		if (!bar) { return; }
		bar.shouldRender = true;
		if (bar.levelLabel && bar.lastLevel !== displayedLevel) {
			bar.lastLevel = displayedLevel;
			bar.levelLabel.text = "Level " + displayedLevel;
		}

		var healthPercent = Clamp(Entities.GetHealthPercent(entityIndex), 0, 100);
		var maxHealth = Math.max(1, Number(Entities.GetMaxHealth(entityIndex)) || 1);
		var unitTeam = Entities.GetTeamNumber(entityIndex);
		if (bar.lastTeam !== unitTeam) {
			bar.lastTeam = unitTeam;
			bar.panel.SetHasClass("Ally", unitTeam === localTeam);
			bar.panel.SetHasClass("Enemy", unitTeam !== localTeam);
		}
		var isCritical = healthPercent <= 25;
		if (bar.lastCritical !== isCritical) {
			bar.lastCritical = isCritical;
			bar.panel.SetHasClass("Critical", isCritical);
		}
		var isFrozen = HasEntityState(entityIndex, "IsFrozen");
		if (bar.lastFrozen !== isFrozen) {
			bar.lastFrozen = isFrozen;
			if (isFrozen) { EnsureFrozenIndicator(bar); }
			bar.panel.SetHasClass("Frozen", isFrozen);
		}
		SetPanelWidth(bar.healthFill, bar, "lastFillWidth", healthPercent);
		RefreshHealthDividers(bar, maxHealth);
		if (bar.unitName) {
			var unitName = String(Entities.GetUnitName(entityIndex) || "");
			if (bar.lastUnitName !== unitName) {
				var localizedName = unitName ? $.Localize("#" + unitName) : "";
				bar.unitName.text = localizedName && localizedName !== "#" + unitName
					? localizedName
					: unitName.replace(/^npc_dota_/, "").replace(/^npc_/, "").replace(/_/g, " ").toUpperCase();
				bar.lastUnitName = unitName;
			}
		}
		if (bar.healthValue) {
			var healthText = FormatHealth(Entities.GetHealth(entityIndex)) + " / " + FormatHealth(maxHealth);
			if (bar.lastHealthText !== healthText) {
				bar.lastHealthText = healthText;
				bar.healthValue.text = healthText;
			}
		}
		UpdateHealthLag(bar, healthPercent);
	}

	function ReadTrackedUnits() {
		var state = CustomNetTables.GetTableValue("xhs_creep_health_bars", "units") || {};
		var entries = state.entries || [];
		var nextTracked = {};
		var nextIndices = [];
		for (var entryKey in entries) {
			if (!entries.hasOwnProperty(entryKey)) { continue; }
			var entityIndex = Number((entries[entryKey] || {}).entindex);
			if (entityIndex >= 0) {
				nextTracked[entityIndex] = {
					kind: String((entries[entryKey] || {}).kind || "creep"),
					level: Math.max(0, Math.floor(Number((entries[entryKey] || {}).level) || 0))
				};
				nextIndices.push(entityIndex);
			}
		}

		for (var previousIndex in bars) {
			if (bars.hasOwnProperty(previousIndex) && !nextTracked.hasOwnProperty(previousIndex)) {
				var oldBar = bars[previousIndex];
				if (oldBar.panel && oldBar.panel.IsValid()) { oldBar.panel.DeleteAsync(0); }
				delete bars[previousIndex];
			}
		}
		trackedUnits = nextTracked;
		trackedIndices = nextIndices;
	}

	function OnTrackedUnitsChanged(tableName, key) {
		if (tableName === "xhs_creep_health_bars" && key === "units") {
			ReadTrackedUnits();
		}
	}

	function UpdatePositions() {
		if (!ResolveRoot()) {
			$.Schedule(0.1, UpdatePositions);
			return;
		}
		var rootWidth = Number(ROOT.actuallayoutwidth || ROOT.desiredlayoutwidth || 0);
		var rootHeight = Number(ROOT.actuallayoutheight || ROOT.desiredlayoutheight || 0);
		positionFrame++;
		for (var index = 0; index < trackedIndices.length; index++) {
			var entityIndex = trackedIndices[index];
			var bar = bars[entityIndex];
			var shouldProbePosition = bar && bar.shouldRender && (
				bar.isVisible || (positionFrame + index) % OFFSCREEN_POSITION_DIVISOR === 0
			);
			if (shouldProbePosition) {
				UpdateBarPosition(entityIndex, bar, rootWidth, rootHeight);
			}
		}
		$.Schedule(POSITION_RATE, UpdatePositions);
	}

	function UpdateStates() {
		var localPlayerId = Players.GetLocalPlayer();
		var localTeam = Players.GetTeam(localPlayerId);
		for (var index = 0; index < trackedIndices.length; index++) {
			var entityIndex = trackedIndices[index];
			UpdateCreepState(entityIndex, trackedUnits[entityIndex], localTeam);
		}
		$.Schedule(STATE_RATE, UpdateStates);
	}

	CustomNetTables.SubscribeNetTableListener("xhs_creep_health_bars", OnTrackedUnitsChanged);
	ReadTrackedUnits();
	$.Schedule(0.0, UpdateStates);
	$.Schedule(0.0, UpdatePositions);
})();
