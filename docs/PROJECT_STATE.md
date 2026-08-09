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
- Native WSL compiler and CMake packages are not currently installed; the
  preferred approach is a pinned build container.
