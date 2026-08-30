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

The generated world configuration sets `Quests.LowLevelHideDiff = -1`. The
archived default hides the normal `!` marker when a quest is more than four
levels below the player even though the quest can still be accepted and can
still award XP. The lab default keeps those otherwise-eligible starter markers
visible. It does not bypass quest prerequisites, faction or class restrictions,
conditions, phases, events, profession requirements, or minimum levels.

The generated configuration also applies the selected progression preset.
`balanced` is the default and uses 2x reputation, two profession skill points
per successful gain, and 1.25x XP. Operators can switch presets or set validated
custom values without editing this generated file; see
[PROGRESSION_RATES.md](PROGRESSION_RATES.md).

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

The required updates also repair two high-confidence ambient movement gaps.
Spawns already marked for waypoint movement are reconnected only when an
authored path using that spawn GUID has at least two nodes and starts within 25
yards. Ordinary non-elite outdoor combat creatures without scripts, services,
quest-giver roles, active movement or pose addons, paths, formations, events,
or other spawn-specific references receive a three-yard random wander.
Harmless addon bytes such as weapon sheath state are retained. Original
creature rows and restored path metadata are kept in `azerothlab_*` audit
tables so both changes remain recoverable.

All four build-26365 allied races can be unlocked for one installed account
without enabling the core's broad test-server mode:

```bash
bash scripts/unlock-allied-races.sh player@example.com 1
```

The account must already have one character. Fully reconnect the client after
running the helper so its account-achievement cache is refreshed.

The required updates also restore missing entry-level SmartAI for the eight
Vilebranch combat templates. The migration installs melee, ranged, caster,
support, low-health, and flee behavior only when an entry has no existing
SmartAI rows, so it does not replace a future source implementation. A server
restart is required after first applying the migration so the world process
loads the new scripts.

Rocket Rescue's Steamwheedle Rescue Balloon is also repaired conservatively.
The archived world contains the correct spell-click, summon, boarding, and
waypoint SmartAI chain, but leaves the clickable template's `AIName` empty.
The required migration backs up that template and enables its existing SmartAI
only when every expected part of the build-26365 chain is still present. It
also backs up the moving vehicle's invisible display before assigning the
matching visible balloon model. A narrowly scoped spell script preserves the
original impact spells while redirecting each payload to a selected, or nearest,
valid quest target within its original 10–70 yard range.

Rocket Rescue is intentionally classified as semi-functional. The balloon
travels its authored route and both quest objectives can be completed, but the
7.3.5 client may display the passenger below the moving balloon and may animate
the payload straight ahead instead of toward the server-resolved target. These
remaining presentation defects do not prevent quest credit or completion.

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
