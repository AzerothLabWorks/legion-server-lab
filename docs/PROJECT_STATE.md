# Project State

## Repository

- GitHub: `https://github.com/AzerothLabWorks/legion-server-lab`
- Windows checkout: `C:\Users\User\OneDrive\Documents\legion-server-lab`
- Default branch: `main`

## Isolation policy

- Do not modify or reuse WoTLK containers, databases, volumes, ports, or source
  trees.
- Do not commit client files, extracted maps, database dumps, repack archives,
  compiled binaries, credentials, or persistent runtime data.
- Build server executables from a pinned source revision.
- Treat third-party repack executables as untrusted and do not run them during
  analysis.

## Candidate input

- Advertised version: Legion 7.3.5 build 26365
- Archive type: 7-Zip
- Archive SHA-256:
  `7B5F777833D7817BD811F00868D878D251409AB21B62C4B14633548C327F3214`
- Observed contents include multiple SPP, DekkCore, and LegionCore Windows
  repack trees. Compatibility and provenance have not yet been established.
- Extraction location:
  `C:\Games\WoW-7.3.5-Legion\[7.3.5] SPP V2 Legion Core`
- Primary candidate: `SPP V2 Year 5 Update 3 Repack`, labeled PraeviusCore V2
  and configured for client build 26365.
- Detailed findings: `docs/REPACK_INVENTORY.md`

## Historical Development Validation Environment

- Initial development host: x86-64 Linux
- Docker Engine: 29.6.0
- Docker Compose: 5.1.4
- The core builds in a pinned Ubuntu 18.04 container to retain Boost 1.65 and
  other legacy ABI dependencies.

This records the environment used during initial core bring-up. The supported
community targets are Steam Deck/SteamOS and Windows with Ubuntu/WSL2.

## Verified milestones

- The pinned public V2 source builds Linux `worldserver` and `bnetserver`
  binaries successfully.
- MySQL 5.7 initializes all four source-matched databases successfully.
- `bnetserver` connects to MySQL, registers realm ID 1, and listens on TCP
  1119.
- `worldserver` connects to all four databases.
- The extracted SPP/Praevius build-26365 data initializes all 297 required DB2
  stores, 2,288 hotfix records, and 31 game tables with the pinned Linux core.
- The persistent `worldserver` completes startup and listens on TCP 8085.
- Realm 1 advertises client build 26365 and is registered by `bnetserver` at
  the configured `LEGION_REALM_ADDRESS` (`127.0.0.1` by default).
- Profession shop products execute their validation and delivery scripts,
  teach the base skill and recipes without a level-90 gate, and grant the
  standard Blacksmithing, Mining, Skinning, and Fishing tools.
- The optional `scripts/unlock-allied-races.sh` helper grants only the four
  Legion allied-race account achievements. It leaves expansion and race/class
  validation enabled and does not require the broad test-server switch.
- The starter QoL login package teaches the zone-flight licenses used by the
  build-26365 core for the old continents, Northrend, Pandaria, Draenor, and the
  Broken Isles while retaining explicit no-fly, instance, battlefield, and
  Argus restrictions.
- Dormant creature waypoint paths with locally matching authored geometry are
  reconnected, and high-confidence unscripted outdoor combat spawns receive a
  small ambient wander without moving services, scripted actors, or encounters.
- All eight Vilebranch combat templates use restored, entry-specific SmartAI
  rotations instead of falling back to melee-only behavior when the archived
  database omits their script rows.
- Eligible low-level quest starters retain their normal available-quest marker
  instead of being hidden once the player exceeds the archived four-level
  threshold. Normal prerequisites, conditions, phases, and level requirements
  still decide whether each quest is available.
- Rocket Rescue's existing click, summon, boarding, and flight SmartAI chain is
  reactivated without changing the core vehicle subsystem. Its moving vehicle
  uses the visible rescue-balloon model, while its two trajectory payloads apply
  to a selected or nearby valid quest target within their original range. The
  quest is classified as semi-functional: both objectives and completion work,
  but the client may render the character below the balloon and may show the
  projectile traveling forward instead of visually striking its resolved target.

## Compatibility finding

The extracted SPP/Praevius build-26365 `Data/dbc` tree is compatible with the
public core at the DB2 loader boundary. The earlier termination during DB2
loading was caused by missing `version` tables in the imported `legion_auth`
and `legion_characters` schemas. Database updater threads terminated the
process while DB2 workers were active, which initially resembled a DB2 crash.

`scripts/apply-required-updates.sh` now installs those required version tables
and the source-required world script columns idempotently. The archived
auction-house bot is disabled for the initial Linux test baseline because it
crashes during startup; it is not required for login or gameplay testing.
