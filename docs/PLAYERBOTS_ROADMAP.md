# Legion Playerbots Roadmap

## Objective

Populate the private Legion 7.3.5 build 26365 lab with persistent,
server-controlled player characters that can travel, fight, group, and
eventually participate in ordinary world content. The first target is a stable
test harness, not immediate parity with mature WoTLK Playerbots.

## Repository Boundary

- `legion-server-lab` owns Compose, configuration, migrations, operations, and
  compatibility documentation.
- A dedicated `AzerothLabWorks/LegionCore-7.3.5-playerbots` fork will own core
  and bot source changes. The lab will pin a tested commit from that fork.
- Client files, extracted game data, runtime databases, binaries, and secrets
  remain outside Git.
- Playerbot schema changes must be idempotent SQL migrations; no manual-only
  database edits are accepted as project state.

The pinned LegionCore has no existing Playerbot implementation and registers
scripts statically through `ScriptLoader.cpp`. Playerbots therefore require a
maintained core fork; AzerothCore WoTLK modules are design references, not
source-compatible drop-ins.

## Guiding Principles

1. Keep bots distinguishable from normal accounts and easy to remove.
2. Prefer deterministic tests before autonomous behavior.
3. Put hard limits on population, CPU time, database writes, and login rate.
4. Never let a bot command modify non-bot characters unless explicitly asked.
5. Gate incomplete Legion systems such as phasing, scenarios, and artifacts.
6. Preserve clean server startup, shutdown, and database recovery at every milestone.

## Milestones

### M0 — Baseline and Design Contract

- Pin the exact LegionCore source commit, compiler, database baseline, and client build.
- Record relevant `Player`, `WorldSession`, map, movement, spell, group, and persistence APIs.
- Define bot account flags, naming rules, ownership, configuration, and log category.
- Add an empty Playerbots component that compiles and registers commands.

Acceptance: unmodified gameplay still passes login and world-entry smoke tests;
`.playerbot status` reports that the subsystem is disabled.

### M1 — Bot Lifecycle

- Add `.playerbot add`, `remove`, `list`, `login`, and `logout` commands.
- Create server-controlled sessions without a client socket.
- Load and save existing bot characters through normal character persistence.
- Enforce account ownership and a configurable maximum bot count.
- Cleanly remove bots on world shutdown and map unload.

Acceptance: ten bots can repeatedly log in and out, survive a server restart,
and leave no stuck online records or orphaned sessions.

### M2 — Movement and Recovery

- Follow, stay, teleport-to-owner, idle, and waypoint movement strategies.
- Detect invalid maps, falling, path failures, transport changes, and death.
- Add bounded unstuck and resurrection behavior.
- Instrument movement decisions and failure counters.

Acceptance: a party of five follows a player across two outdoor zones for 30
minutes, including combat and death, without crashes or permanent stuck states.

### M3 — Combat Foundation

- Build shared target selection, threat, range, facing, interrupt, dispel,
  consumable, and retreat logic.
- Implement one simple damage specialization first, then tank and healer roles.
- Read abilities from the character spellbook rather than assuming fixed IDs.
- Add deterministic combat scenarios and performance budgets.

Acceptance: a five-bot party defeats a curated set of ordinary and elite
creatures, resurrects, and resumes following without GM intervention.

### M4 — Groups and Player Interaction

- Invitations, role assignment, leader/follower behavior, ready checks, loot,
  trade restrictions, and basic chat commands.
- Human-led and bot-led group policies.
- Safe commands to inspect current strategy and force a reset.

Acceptance: one human and four bots form a party, travel together, complete
combat encounters, distribute loot, and disband cleanly.

### M5 — World Population

- Configurable population targets by faction, level range, zone, class, and time.
- Rate-limited login/logout scheduler and activity selection.
- Equipment validation, repair, vendors, trainers, mail, and auction policies.
- Metrics for online bots, update time, failures, deaths, and database latency.

Acceptance: 25 bots run for two hours within defined CPU/memory budgets, with
no server crash, login storm, or uncontrolled database growth.

### M6 — Questing and Progression

- Quest discovery, prerequisite evaluation, objective planning, turn-in, and rewards.
- Experience, specialization, talents, equipment upgrades, and travel routing.
- Explicit support matrix for phasing, scenarios, class halls, artifact weapons,
  world quests, and other Legion-specific systems.

Acceptance: selected race/class combinations complete curated leveling routes;
unsupported content is skipped and logged instead of trapping the bot.

### M7 — Instances and Matchmaking

- Dungeon navigation, encounter strategies, wipe recovery, and instance resets.
- Optional dungeon finder and battleground participation after party behavior is stable.
- Per-instance support declarations so incomplete content is never selected blindly.

Acceptance: a supported five-player dungeon completes repeatedly with bounded
recovery and no persistent instance or queue corruption.

## Test Matrix

Every milestone must cover:

- clean database and upgraded database;
- bot login/logout during human play;
- server restart with bots online;
- both factions and representative race/class combinations;
- map change, teleport, death, logout, and forced removal;
- maximum population enforcement and rapid-command abuse;
- AddressSanitizer or equivalent debug runs where the toolchain permits;
- a soak test whose duration grows from 30 minutes to overnight.

## Operational Deliverables

- Playerbot configuration template with conservative defaults.
- Idempotent database migrations and rollback notes.
- GM command reference and troubleshooting guide.
- Structured logs and a compact status report for `server-management`.
- Backup/restore procedure before schema migrations.
- Release notes identifying supported classes, zones, and known limitations.

## Initial Backlog

1. Create the dedicated LegionCore playerbots fork and record its upstream commit.
2. Document lifecycle call graphs for a normal client-controlled player.
3. Add the disabled subsystem, configuration keys, logs, and command root.
4. Implement a synthetic session prototype for one existing test character.
5. Prove clean save/logout/restart behavior before adding AI.
6. Add CI compilation and lifecycle smoke tests.

## Explicit Non-Goals for the First Release

- Full support for every class specialization.
- Unattended completion of all Legion campaigns and scenarios.
- Human-like chat generation or attempts to disguise bots as real people.
- Public-server scale, anti-cheat evasion, or operation outside this private lab.
