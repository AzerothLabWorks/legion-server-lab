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

## Next steps

1. Inventory the extracted SPP archive without executing its programs. (Done)
2. Determine the exact core, protocol build, database lineage, and data format. (Candidate documented)
3. Compile the pinned public V2 source candidate under Linux. (Done)
4. Add reproducible Docker Compose runtime definitions.
5. Import databases and game data into ignored runtime storage.
6. Verify authentication, realm selection, character creation, and world login.

Build details are in [docs/SOURCE_BASELINE.md](docs/SOURCE_BASELINE.md), and
the isolated Compose runtime workflow is in [docs/RUNTIME.md](docs/RUNTIME.md).
The staged Playerbots plan is in
[docs/PLAYERBOTS_ROADMAP.md](docs/PLAYERBOTS_ROADMAP.md).
The companion-triggered loot prototype and its test checklist are in
[docs/COMPANION_AUTO_LOOT.md](docs/COMPANION_AUTO_LOOT.md).

## Community installation

The supported community workflow and lawful download boundaries are documented
in [docs/COMMUNITY_INSTALL.md](docs/COMMUNITY_INSTALL.md).

After cloning this repository under WSL2/Linux, run:

```bash
bash install/install.sh --data-source /absolute/path/to/build-26365/Data
```

An optional reviewed bootstrap is also available:

```bash
curl -fsSL https://raw.githubusercontent.com/AzerothLabWorks/legion-server-lab/main/install/bootstrap.sh | bash
```

The installer automates the open-source server. It does not download or
distribute World of Warcraft clients or client-derived game data.
