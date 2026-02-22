# X Hero Siege 4.0 Lite Roadmap

## Goal
Ship a visible and stable 4.0 update with limited volunteer time.

Target window: 4 to 6 weeks.

## Locked Scope
- Classic/Reborn vote at match start.
- Classic kept close to current gameplay, only critical fixes.
- Reborn includes one concrete gameplay slice:
  - one reworked area
  - one updated boss encounter (simple 2-phase flow)
  - one new mechanic/event
- Time Trial v1 in-game (timer + personal best only).
- Light UI polish (timers and end screen clarity).

## Out of Scope for 4.0 Lite
- Full website refactor.
- Global leaderboard web integration.
- Full battle pass release.
- Large multi-zone content expansion.

## Sprint Backlog

### Sprint 1 (Week 1)
- [x] Re-enable `gamemode` vote in loading screen for XHS.
- [x] Ensure vote works in normal games and tools mode.
- [ ] Add mode flag usage points (`XHS_GAMEMODE_ACTIVE`) in gameplay systems.
- [ ] Write short internal design note: what differs in Classic vs Reborn for 4.0 Lite.

### Sprint 2 (Week 2)
- [ ] Add Reborn feature gate in one subsystem (example: creep wave modifier or special event pacing).
- [ ] Keep Classic behavior unchanged under the same subsystem.
- [ ] Add one debug command/log to print current selected mode.

### Sprint 3 (Week 3)
- [ ] Implement one Reborn boss pass:
  - [ ] phase trigger at HP threshold
  - [ ] one new skill timing/pattern
  - [ ] anti-stall safeguard (soft enrage or timeout behavior)
- [ ] Balance pass for boss health/damage on all difficulties.

### Sprint 4 (Week 4)
- [ ] Time Trial v1:
  - [ ] start/stop timer flow
  - [ ] fail/reset conditions
  - [ ] personal best storage in-memory or local nettable path
- [ ] End-screen/timer UI cleanup for readability.

### Sprint 5 (Week 5)
- [ ] Bugfix pass (priority: blockers, softlocks, mode-specific desync).
- [ ] Balance pass using 3 quick playtest sessions.
- [ ] Prep patch notes with clear "Classic vs Reborn (current scope)" section.

### Sprint 6 (Optional buffer)
- [ ] Final polish and release branch stabilization.
- [ ] Hotfix-only lock after publish.

## Definition of Done (4.0 Lite)
- Mode vote appears and resolves correctly every game.
- Selected mode is available server-side for gameplay branching.
- Reborn has at least one clearly noticeable exclusive gameplay slice.
- No critical regressions in Classic baseline run.
- Time Trial v1 is playable end-to-end.
