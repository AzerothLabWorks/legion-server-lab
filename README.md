# Legion Server Lab

An isolated local lab for building and running a World of Warcraft: Legion
server under WSL2. This repository is independent of the AzerothCore WoTLK,
addon, and module repositories.

## Current target

- Expansion: Legion 7.3.5
- Candidate client build: 26365
- Runtime: Ubuntu on WSL2 using Docker Compose
- Status: build 26365 login, world entry, gameplay, addons, and companion
  auto-loot validated in the local lab

The downloaded SPP archive contains a mixture of Windows repacks. Its bundled
executables and services are not treated as trusted build inputs. The intended
server will use Linux binaries built from identified source, with separately
managed database and extracted game-data volumes.

## Repository boundary

This repository contains scripts, container definitions, configuration
templates, patches, and documentation. It does not contain game clients,
client-derived data, repack archives, server binaries, database dumps, secrets,
or runtime volumes.

The planned WSL layout is:

```text
~/legion-server-lab/          repository checkout
~/legion-server-runtime/      generated configuration and persistent data
~/legion-server-sources/      upstream core source and build trees
```

## Reproducible state

- The repack was inventoried without using its Windows binaries as build input.
- The public V2 core and exact source commit are pinned.
- Linux compilation is reproducible in the checked-in build container.
- Docker Compose owns the isolated MySQL, Battle.net, and world runtime.
- Authentication, realm selection, world entry, gameplay, and the documented
  lab improvements have been validated against client build 26365.

Build details are in [docs/SOURCE_BASELINE.md](docs/SOURCE_BASELINE.md), and
the isolated Compose runtime workflow is in [docs/RUNTIME.md](docs/RUNTIME.md).
The staged Playerbots plan is in
[docs/PLAYERBOTS_ROADMAP.md](docs/PLAYERBOTS_ROADMAP.md).
The companion-triggered loot prototype and its test checklist are in
[docs/COMPANION_AUTO_LOOT.md](docs/COMPANION_AUTO_LOOT.md).
The level-1 starter rewards and compatibility notes are in
[docs/STARTUP_QOL.md](docs/STARTUP_QOL.md).
The custom played-time Shop currency is documented in
[docs/NORDRASSIL_COINS.md](docs/NORDRASSIL_COINS.md).

## WSL2 community installation

Start with the clean-machine Windows guide:
[HOWTO-WINDOWS-WSL2.md](HOWTO-WINDOWS-WSL2.md). The shorter reference workflow
is in [docs/COMMUNITY_INSTALL.md](docs/COMMUNITY_INSTALL.md), and the release
boundary is in [docs/DISTRIBUTION_BOUNDARY.md](docs/DISTRIBUTION_BOUNDARY.md).

After cloning this repository under WSL2/Linux, run:

```bash
bash install/install.sh --check
bash install/install.sh --data-source /absolute/path/to/build-26365/Data
```

An optional reviewed bootstrap is also available:

```bash
curl -fsSL https://raw.githubusercontent.com/AzerothLabWorks/legion-server-lab/main/install/bootstrap.sh | bash
```

The installer automates the open-source server. It does not download or
distribute World of Warcraft clients or client-derived game data.

This repository is licensed under GPL-2.0-only; third-party and trademark
notices are summarized in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
