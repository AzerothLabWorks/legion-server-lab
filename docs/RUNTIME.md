# Local Runtime

The runtime uses three Compose services:

- MySQL 5.7, matching the version recorded in the source database dumps
- `bnetserver` on TCP 1119, with its REST-login endpoint on TCP 8081
- `worldserver` on TCP 8085

All persistent state remains under `~/legion-server-runtime` on the supported
Linux server host: SteamOS on Deck or Ubuntu under WSL2. The Git repository
contains only orchestration and templates.

## Prepare

Copy `.env.example` to `.env`, replace both example passwords, and confirm the
selected platform's Linux paths. `LEGION_TIMEZONE` defaults to
`America/Los_Angeles`; replace it with another IANA timezone name if desired.
Then run from the repository:

```bash
set -a
source "$HOME/legion-server-lab/.env"
set +a
bash "$HOME/legion-server-lab/scripts/prepare-runtime.sh"
```

The preparation script extracts the source-matched database baseline into
ignored runtime storage, prefixes each dump with its target database, and
generates server configuration using the same database password.

## Start

```bash
cd ~/legion-server-lab
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
maintenance.

The initial test configuration disables the optional archived auction-house
seller and buyer. With those disabled, `worldserver` completes initialization
and listens on TCP 8085. Realm 1 is pinned to client build 26365 by
`scripts/apply-required-updates.sh`. It advertises `LEGION_REALM_ADDRESS`, which
defaults to `127.0.0.1`. REST port 8081 remains loopback-only unless
`LEGION_REST_BIND_ADDRESS` is explicitly changed. Both supported local-host
workflows keep it loopback-only.

All three containers receive `LEGION_TIMEZONE`, and the generated worldserver
configuration advertises that IANA timezone to the client. The patched login
clock packet uses the same local timezone, so realm time, logs, and
database-local timestamps agree after the services are rebuilt and recreated.

## Duplicate creature cleanup

The source-matched world database contains a limited number of duplicate
static creature records. `scripts/apply-required-updates.sh` first removes only
byte-equivalent spawn rows whose duplicate group has no GUID-specific addon,
event, pool, formation, transport, linked-respawn, conversation, or SmartAI
references. It also removes the confirmed extra Chef Grual spawn in Scarlet
Raven Tavern.

A second conservative world-wide pass handles nearby duplicates whose position
or facing differs. It is limited to structurally equivalent service, quest, or
uniquely titled NPC entries with exactly two global spawns. Both rows must be
in the same map/area/phase, within 15 yards, from separate GUID generations,
and free of spawn-specific references. Ordinary mob packs, guards, commoners,
and scripted pairs are therefore left intact.

A third pass handles ordinary creatures duplicated by later spawn imports. It
requires the same creature entry, map, area, phase, spawn mask, behavioral
fields, and a position within three yards, plus a GUID-generation gap greater
than 1,000. Spawn-specific addons, events, pools, formations, transports,
linked-respawns, conversations, and SmartAI remain protected. Different-entry
mixed packs are never candidates; for example, the Nightbane Vile Fang and
Nightbane Tainted One pairs at Roland's Doom are intentional quest packs rather
than duplicate rows.

Before deletion, every affected row is copied to
`legion_world.azerothlab_removed_creature_spawns`. The migration is idempotent,
and that archive makes an individual spawn recoverable if later testing finds
that it was intentional.

## Game data

`worldserver` expects client-derived data at the path configured by
`LEGION_DATA_ROOT`, mounted as `/opt/legion/data`. At minimum, this core expects
the matching `dbc`, `maps`, `vmaps`, and `mmaps` trees. These files are not
stored in Git.
