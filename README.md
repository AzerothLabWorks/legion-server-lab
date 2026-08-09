# Legion Server Lab

An isolated local lab for building and running a World of Warcraft: Legion
server under WSL2. This repository is independent of the AzerothCore WoTLK,
addon, and module repositories.

## Current target

- Expansion: Legion 7.3.5
- Candidate client build: 26365
- Runtime: Ubuntu on WSL2 using Docker Compose
- Status: core and repack provenance investigation

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

1. Inventory the extracted SPP archive without executing its programs.
2. Determine the exact core, protocol build, database lineage, and data format.
3. Select and pin an auditable source revision compatible with the client.
4. Add reproducible Linux build and Docker Compose definitions.
5. Import databases and game data into ignored runtime storage.
6. verify authentication, realm selection, character creation, and world login.

