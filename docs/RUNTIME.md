# Local Runtime

The runtime uses three Compose services:

- MySQL 5.7, matching the version recorded in the source database dumps
- `bnetserver` on TCP 1119
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

The current SPP/Praevius 26365 data mount reaches DB2 loading but does not pass
the public core's DB2 compatibility checks. Keep `worldserver` stopped until a
matching data set is available. MySQL and `bnetserver` can run independently.

## Game data

`worldserver` expects client-derived data at the path configured by
`LEGION_DATA_ROOT`, mounted as `/opt/legion/data`. At minimum, this core expects
the matching `dbc`, `maps`, `vmaps`, and `mmaps` trees. These files are not
stored in Git.
