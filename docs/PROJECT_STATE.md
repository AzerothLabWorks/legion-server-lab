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

## Environment

- WSL distribution: Ubuntu 26.04 LTS
- WSL version: 2
- Docker Engine: 29.6.0
- Docker Compose: 5.1.4
- The core builds in a pinned Ubuntu 18.04 container to retain Boost 1.65 and
  other legacy ABI dependencies.

## Verified milestones

- The pinned public V2 source builds Linux `worldserver` and `bnetserver`
  binaries successfully.
- MySQL 5.7 initializes all four source-matched databases successfully.
- `bnetserver` connects to MySQL, registers realm ID 1, and listens on TCP
  1119.
- `worldserver` connects to all four databases and reaches DB2 loading.

## Current compatibility boundary

The public core exits during DB2 validation when using the SPP/Praevius
build-26365 `Data/dbc` tree. This is a data-layout mismatch, not a WSL,
container, or database connectivity failure. The public source's database/data
lineage is 26124-era, while the extracted SPP V2 runtime is a different,
closed Praevius build configured for 26365.

Worldserver is intentionally left stopped until a DB2 set matching the public
core is obtained or the public core is ported to the 26365 layouts.
