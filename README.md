# Legion Server Lab

An isolated local lab for building and running a World of Warcraft: Legion
server from pinned source. Two community installation layouts are supported:

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

The server uses Linux binaries built from pinned source, with separately managed
database and extracted game-data volumes. Prebuilt server executables and
services are not trusted build inputs.

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
  --client-build 26365

bash install/install.sh \
  --client-dir /platform/path/to/WoW-7.3.5-Legion \
  --client-build 26365 \
  --data-source /platform/path/to/LegionData/Data
```

Use the exact paths shown in the selected platform guide. The installer builds
the open-source server but does not download or distribute World of Warcraft
clients or client-derived game data.

An optional reviewed bootstrap is also available after platform dependencies
are installed:

```bash
curl -fsSL https://raw.githubusercontent.com/AzerothLabWorks/legion-server-lab/main/install/bootstrap.sh | bash
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
