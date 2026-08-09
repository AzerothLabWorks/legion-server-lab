# Source Baseline

## Selected build candidate

- Repository: `https://github.com/Legion-Pandaria-Preservation-Project/LegionCore-7.3.5V2`
- Branch: `V2`
- Commit: `6c41d0faa23474bf9e76a4811b144d43e9545bab`
- Commit date: 2025-03-11
- License declared by repository: GPL-2.0

The source configuration lists client builds 26124, 26365, 26654, 26822,
26899, and 26972 as available. Its named full world/hotfix database snapshots
are labeled for build 26124, so configuration-level protocol support does not
prove that all DB2/hotfix content is correct for build 26365.

## Relationship to SPP V2

The downloaded SPP V2 Year 5 Update 3 server identifies itself as PraeviusCore
V2. No matching public source revision was found. Community discussions describe
the SPP V2 source as unpublished. Therefore, the public V2 core is a build
candidate, not a source-equivalent reproduction of the repack.

The SPP database and extracted data will not be imported until the public core
successfully compiles and its expected schema is compared with the repack.

## WSL checkout

```text
~/legion-server-sources/LegionCore-7.3.5V2
```

The source checkout is intentionally outside the lab repository. The lab pins
the revision and owns only the reproducible build/runtime orchestration.

The build container uses Ubuntu 18.04 because this code relies on the legacy
Boost.Asio strand API. Ubuntu 20.04's Boost 1.71 fails at `boost::asio::strand`
before the core itself can compile; Ubuntu 18.04 provides Boost 1.65, close to
the upstream project's stated Boost 1.64 toolchain.

Repository-owned compatibility patches are kept under `patches/` and applied
idempotently by the build script. The first patch corrects the upstream cotire
module path for CMake versions older than 3.16.

## Verified build

The pinned revision successfully built on 2026-08-09 using the repository's
Ubuntu 18.04 build container with precompiled headers enabled. The install tree
is kept outside Git at `~/legion-server-runtime/server` and contains:

- `bin/worldserver` (Linux x86-64 ELF, approximately 74 MiB)
- `bin/bnetserver` (Linux x86-64 ELF, approximately 5.8 MiB)
- distribution configuration files under `etc/`

The binaries intentionally link against Ubuntu 18.04-era libraries, including
Boost 1.65, OpenSSL 1.1, and MySQL client 20. They therefore need an Ubuntu
18.04-compatible runtime container and should not be launched directly on the
Ubuntu 26.04 WSL host.

Build command:

```bash
LEGION_BUILD_JOBS=4 bash /mnt/c/Users/User/OneDrive/Documents/legion-server-lab/scripts/build-core.sh
```
