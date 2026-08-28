# Legion Server Lab

An isolated local lab for building and running a World of Warcraft: Legion
server from pinned source. Two community installation layouts are supported:

This is an experimental preservation and interoperability project. Development
is AI-assisted with OpenAI Codex, with changes kept in version control and
validated through repeatable repository checks and hands-on gameplay testing.

| Platform | Server | Client | Complete guide |
| --- | --- | --- | --- |
| Steam Deck | Docker on SteamOS/Arch Linux | Windows x64 client through Proton on the same Deck | [Steam Deck](HOWTO-STEAM-DECK.md) |
| Windows PC | Docker under Ubuntu/WSL2 | Windows x64 client running directly on the same PC | [Windows/WSL2](HOWTO-WINDOWS-WSL2.md) |

Choose one platform guide and follow it end to end. Commands and paths are not
interchangeable: Steam Deck examples use `/home/deck/...`, while Windows files
are exposed to Ubuntu/WSL2 under `/mnt/c/...`.

## Current target

- Expansion: Legion 7.3.5
- Required client: build 26365, Release x64
- Server runtime: Docker Compose on SteamOS/Arch or Ubuntu/WSL2
- Status: authentication, realm selection, world entry, gameplay, addons, and
  companion auto-loot validated against build 26365
- Playerbots: no viable Legion Playerbots module is included at this time; the
  companion auto-loot feature is not a world-population or party-bot system

The server uses Linux binaries built from pinned source, with separately managed
database and extracted game-data volumes. Prebuilt server executables and
services are not trusted build inputs.

## Included lab improvements

This project carries reproducible source patches and database migrations for
issues found during hands-on Legion 7.3.5 gameplay. Current improvements include:

| Area | Improvements |
| --- | --- |
| Questing | Eligible low-level quest starters retain visible `!` markers so XP-bearing quests are easier to discover; quest markers refresh as objectives change; completed quests point to their configured turn-in NPCs; incomplete objective POIs stay with their matching verified client build; and multi-quest NPCs continue offering the next available quest without requiring the player to reopen the dialog. Rocket Rescue is semi-functional: its visible balloon follows the authored route and targeted payloads advance both objectives, although passenger attachment and projectile visuals remain imperfect. |
| Creature combat AI | Unscripted mage-class casters use ranged spell kits; ordinary melee enemies chase, swing, and retain configured special abilities despite missing SmartAI rows; imported zero-cooldown spells receive safe AI cooldowns; repeated positive buffs are suppressed while active; and all eight Vilebranch combat templates have restored melee, ranged, caster, support, low-health, and flee behavior. |
| Creature lifecycle and movement | Dead creatures stop updating combat AI, permanently sleeping Syndicate Thieves wake and aggro normally, dormant authored patrol paths are restored only when their geometry matches the spawn, and safe unscripted outdoor enemies receive a conservative three-yard ambient wander. Feral Lunge retains its jump animation while landing reliably in melee range. |
| World data and presentation | Exact, nearby singleton, and cross-generation duplicate creature spawns are cleaned through repeatable migrations. Realm time uses a configurable local timezone and defaults to Pacific Time. |
| Starter QoL | The optional idempotent login package grants riding through Master Riding; flight licenses for Eastern Kingdoms, Kalimdor, Northrend, Pandaria, Draenor, and the Broken Isles; Legion-compatible mounts; a 20,000-gold minimum; four Hexweave Bags; and the Magma Rageling companion. Existing characters receive only missing rewards. Explicit no-fly content remains protected. |
| Character creation | An optional account-scoped helper unlocks Void Elf, Lightforged Draenei, Nightborne, and Highmountain Tauren without enabling the core's broad test-server mode. Expansion and normal race/class validation remain active. |
| Loot and inventory | Silent companion auto-loot works during combat from melee range through 40 yards, revisits corpses for delayed eligible quest drops, and keeps normal inventory and group-loot safeguards. Native bag cleanup and the Bagnon 7.3.5 sort button work again. |
| Professions and shop | BattlePay profession purchases execute their delivery scripts, teach the base profession and recipes without the unrelated level-90 gate, respect primary-profession limits, and grant one appropriate Blacksmith Hammer, Mining Pick, Skinning Knife, or Fishing Pole. |
| Nordrassil Coins and Shop | Inherited Nordrassil Coin items are granted through played-time rewards, redeem into an account-wide Shop balance, and purchase configured in-game Shop products. The lab provides English item descriptions, redemption feedback, and balance messages; it does not add a real-money payment system. |
| Localization | Managed server broadcasts and other inherited custom messages use English text. |
| Installation and maintenance | Pinned upstream source, idempotent patch application, clean patch verification, managed-source integrity checks, and separate Steam Deck and Windows/WSL2 workflows. |

The detailed implementation notes and gameplay regression checks are maintained
in [docs/SOURCE_BASELINE.md](docs/SOURCE_BASELINE.md). These improvements make
the archived core more consistent for a local lab, but they do not make every
Legion quest, encounter, dungeon, or raid complete.

## Optional Legion GM addon

[GM Command Center - Legion](https://github.com/AzerothLabWorks/addons/tree/main/GMCommandCenter_Legion)
is a separate client addon for Legion 7.3.5 build 26365. It provides convenient
access to LegionCore GM commands and browsable build-matched catalogs for
mounts, heirlooms, armor, weapons, druid artifact forms, and reviewed cosmetic
spells. The addon requires a GM-enabled account and includes its own installation
instructions; it is not required to run or play on the server.

Client-only addons are maintained separately and are not counted as server
improvements in the catalog above.

## Repository boundary

This repository contains scripts, container definitions, configuration
templates, patches, and documentation. It does not contain game clients,
client-derived data, repack archives, server binaries, database dumps, secrets,
or runtime volumes.

Both supported platforms use the same Linux-side layout:

```text
~/legion-server-lab/          repository checkout
~/legion-server-runtime/      generated configuration and persistent data
~/legion-server-sources/      upstream core source and build trees
```

Read [docs/CLIENT_SETUP.md](docs/CLIENT_SETUP.md) before installing. It explains
the exact client version, separate Steam Deck and Windows/WSL2 paths, extracted
server-data requirements, portal configuration, and troubleshooting. The
project intentionally does not publish a legacy-client download link.

The complete distribution policy is in
[docs/DISTRIBUTION_BOUNDARY.md](docs/DISTRIBUTION_BOUNDARY.md).

## Installation

### Steam Deck

Use [HOWTO-STEAM-DECK.md](HOWTO-STEAM-DECK.md) for the native SteamOS server,
Proton client, storage planning, and Gaming Mode workflow.

### Windows with WSL2

Use [HOWTO-WINDOWS-WSL2.md](HOWTO-WINDOWS-WSL2.md) for Windows prerequisites,
Ubuntu/WSL2, Docker Desktop integration, Windows-to-Linux path conversion, and
the local Windows client.

The shorter cross-platform command reference is in
[docs/COMMUNITY_INSTALL.md](docs/COMMUNITY_INSTALL.md).

After completing the platform prerequisites, the shared installer interface is:

```bash
bash install/install.sh --check \
  --client-dir /platform/path/to/WoW-7.3.5-Legion \
  --client-build 26365 \
  --data-source /platform/path/to/LegionData/Data

bash install/install.sh \
  --client-dir /platform/path/to/WoW-7.3.5-Legion \
  --client-build 26365 \
  --data-source /platform/path/to/LegionData/Data
```

Use the exact paths shown in the selected platform guide. The installer builds
the open-source server but does not download or distribute World of Warcraft
clients or client-derived game data.

An optional bootstrap is also available after platform dependencies are
installed. Download it first so it can be reviewed before execution:

```bash
curl -fsSL -o ~/legion-bootstrap.sh \
  https://raw.githubusercontent.com/AzerothLabWorks/legion-server-lab/main/install/bootstrap.sh
less ~/legion-bootstrap.sh
bash ~/legion-bootstrap.sh
```

## Project documentation

- [Source baseline](docs/SOURCE_BASELINE.md)
- [Docker runtime](docs/RUNTIME.md)
- [Playerbots roadmap](docs/PLAYERBOTS_ROADMAP.md)
- [Companion auto-loot](docs/COMPANION_AUTO_LOOT.md)
- [Level-1 starter QoL](docs/STARTUP_QOL.md)
- [Nordrassil Coins](docs/NORDRASSIL_COINS.md)

This repository is licensed under GPL-2.0-only; third-party and trademark
notices are summarized in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
