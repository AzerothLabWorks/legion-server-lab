# Local Runtime

The runtime uses three Compose services:

- MySQL 5.7, matching the version recorded in the source database dumps
- `bnetserver` on TCP 1119, with its REST-login endpoint on local TCP 8081
- `worldserver` on TCP 8085

All persistent state remains under `~/legion-server-runtime` in WSL. The Git
repository contains only orchestration and templates.

## Prepare

Copy `.env.example` to `.env`, replace both example passwords, and confirm the
WSL paths. Then run from WSL:

```bash
set -a
source /mnt/c/Users/User/OneDrive/Documents/legion-server-lab/.env
set +a
bash /mnt/c/Users/User/OneDrive/Documents/legion-server-lab/scripts/prepare-runtime.sh
```

The preparation script extracts the source-matched database baseline into
ignored runtime storage, prefixes each dump with its target database, and
generates server configuration using the same database password.

## Start

```bash
cd /mnt/c/Users/User/OneDrive/Documents/legion-server-lab
docker compose up -d mysql
docker compose logs -f mysql
```

The first database initialization imports roughly 775 MiB of SQL and can take
several minutes. Start the two server processes only after MySQL reports
healthy:

```bash
docker compose up -d bnetserver worldserver
docker compose logs -f bnetserver worldserver
```

The initial boot is intentionally based on the database bundled with the
pinned public source. Do not replace it with the SPP/Praevius databases until
their schemas have been compared.

Run the required idempotent schema updates before the first worldserver boot:

```bash
bash scripts/apply-required-updates.sh
```

The current SPP/Praevius 26365 data mount passes the public core's DB2 loading
boundary: 297 DB2 stores, 2,288 hotfix records, and 31 game tables initialize.
This does not yet prove client login or gameplay compatibility. MySQL and
`bnetserver` can run independently while `worldserver` remains stopped for
WoTLK port isolation.

The initial test configuration disables the optional archived auction-house
seller and buyer. With those disabled, `worldserver` completes initialization
and listens on TCP 8085. Realm 1 is pinned to client build 26365 by
`scripts/apply-required-updates.sh`.

## Game data

`worldserver` expects client-derived data at the path configured by
`LEGION_DATA_ROOT`, mounted as `/opt/legion/data`. At minimum, this core expects
the matching `dbc`, `maps`, `vmaps`, and `mmaps` trees. These files are not
stored in Git.
