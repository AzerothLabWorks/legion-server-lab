# Community Installation Guide

This guide builds a private World of Warcraft: Legion 7.3.5 server for local
research, preservation, and testing. The tested protocol target is **7.3.5
build 26365**.

For a new Windows machine, follow the complete
[Windows/WSL2 guide](../HOWTO-WINDOWS-WSL2.md). This page is the shorter
reference workflow for users who already have WSL2 and Docker.

Steam Deck users should follow [HOWTO-STEAM-DECK.md](../HOWTO-STEAM-DECK.md),
which covers both a Deck client connecting over the LAN and an experimental
all-in-one SteamOS installation.

## Downloads and Distribution Boundary

### Server

- Lab installer and operations repository:
  <https://github.com/AzerothLabWorks/legion-server-lab>
- Open-source LegionCore used by the installer:
  <https://github.com/Legion-Pandaria-Preservation-Project/LegionCore-7.3.5V2>
- Pinned core commit:
  `6c41d0faa23474bf9e76a4811b144d43e9545bab`

The installer clones that exact commit, applies the lab patches, builds Linux
binaries, prepares the database supplied by the upstream source repository,
and creates the Docker runtime.

### Client

- Official World of Warcraft page: <https://worldofwarcraft.blizzard.com/start>
- Official Battle.net desktop installer: <https://download.battle.net/desktop>

Those official downloads normally install Blizzard's currently supported game,
not the legacy build required by this lab. This project does **not** provide,
mirror, recommend, or automate downloads of repacks, modified executables,
archived clients, or client-derived data.

To connect, a user must already have lawful access to a matching **Windows x64
7.3.5.26365** client and compatible extracted `dbc`, `maps`, `vmaps`, and
`mmaps` data. A current retail client is not protocol-compatible.

This project is an independent community preservation lab and is not affiliated
with or endorsed by Blizzard Entertainment.

## Supported Host

The tested community path is:

- Windows 10 or 11;
- WSL2 with Ubuntu;
- Docker Desktop configured for WSL2; and
- at least 60 GB free for source, build output, databases, and extracted data.

Install WSL from Microsoft's documentation:
<https://learn.microsoft.com/windows/wsl/install>

Install Docker Desktop from:
<https://docs.docker.com/desktop/setup/install/windows-install/>

In Ubuntu, confirm:

```bash
docker info
docker compose version
git --version
```

Or run the repository preflight after cloning:

```bash
bash install/install.sh --check
```

## Automated Server Installation

### Bootstrap option

Review [`install/bootstrap.sh`](../install/bootstrap.sh), then run it from WSL:

```bash
curl -fsSL https://raw.githubusercontent.com/AzerothLabWorks/legion-server-lab/main/install/bootstrap.sh | bash
```

To supply extracted data in the same command:

```bash
curl -fsSL https://raw.githubusercontent.com/AzerothLabWorks/legion-server-lab/main/install/bootstrap.sh \
  | bash -s -- --data-source /absolute/path/to/Data
```

The bootstrap only clones or fast-forwards this repository and invokes the
checked-in installer. Users who prefer not to pipe a script into Bash should
use the manual clone workflow below.

### Manual clone option

Clone the lab inside WSL or through the Windows-mounted filesystem:

```bash
git clone https://github.com/AzerothLabWorks/legion-server-lab.git
cd legion-server-lab
```

If compatible extracted data is already available:

```bash
bash install/install.sh --data-source /absolute/path/to/Data
```

The supplied directory must contain:

```text
Data/
├── dbc/
├── maps/
├── vmaps/
└── mmaps/
```

The pinned open-source core contains `mapextractor`, `vmap4extractor`,
`vmap4assembler`, and `mmaps_generator` source code, but it is not currently a
reliable end-to-end build-26365 extraction toolchain: DB2 extraction is disabled
and part of the map path retains an older hard-coded build. Extracting data from
an authorized client remains an advanced, version-sensitive prerequisite, not
a supported automated installer feature. Do not upload or redistribute the
resulting data. Community contributions that make lawful local extraction
reproducible for build 26365 are welcome.

The installer copies this data to native WSL storage under
`~/legion-server-runtime/data`. This is intentional: very large client-data
bind mounts from `/mnt/c` have not behaved consistently with Docker Desktop.

If data is not ready yet, run:

```bash
bash install/install.sh
```

The script builds and prepares the server, then stops at the lawful data
boundary with the exact resume command. After obtaining and extracting data
from a client you are authorized to use:

```bash
bash install/install.sh --skip-build --data-source /absolute/path/to/Data
```

The first database import can take several minutes. Follow progress with:

```bash
docker compose logs -f mysql
```

## Create the First Account

Attach to the running worldserver console:

```bash
docker compose attach worldserver
```

At the `TC>` prompt, create a Battle.net account and its first game account:

```text
bnetaccount create you@example.com A-UNIQUE-LOCAL-PASSWORD true
```

The console prints the generated game-account name, commonly something like
`1#1`. Grant that generated game account administrator access on all realms:

```text
account set gmlevel 1#1 3 -1
```

Substitute the exact game-account name printed by the create command. Detach
without stopping the server using Docker's default detach sequence:
`Ctrl+P`, then `Ctrl+Q`.

Do not publish real passwords in screenshots, issues, logs, or configuration.

## Configure the Client

Confirm the login screen reports:

```text
Version 7.3.5 (26365) Release x64
```

Close the client and edit its `WTF/Config.wtf`. Ensure the portal targets the
local Battle.net endpoint:

```text
SET portal "127.0.0.1"
```

Launch the compatible x64 client directly, enter the Battle.net email and
password created above, and choose its `WoW1` game account if prompted.

The server exposes these local ports:

| Port | Purpose |
| --- | --- |
| `1119` | Battle.net authentication |
| `8081` | REST login endpoint; localhost unless LAN access is explicitly enabled |
| `8085` | Primary world connection |
| `8086` | Legion instance/world traffic |
| `3310` | MySQL, bound to localhost only |

## Routine Management

From the lab repository:

```bash
bash scripts/compose.sh ps
bash scripts/compose.sh logs -f bnetserver worldserver
bash scripts/compose.sh restart worldserver
bash scripts/compose.sh down
```

For named switching between WoTLK and Legion, install the companion management
tool from <https://github.com/AzerothLabWorks/server-management> and configure a
`legion` target as described there.

## Updating

The installer pins the core source. Pulling newer upstream commits without a
new lab compatibility review is unsupported.

Update the lab orchestration with:

```bash
git pull --ff-only
bash tests/install-smoke.sh
bash tests/verify-patches.sh
```

Back up `~/legion-server-runtime/mysql` before applying database or core changes.

## Troubleshooting

### No realms are available

- Confirm the client is exactly build 26365.
- Confirm both servers are running with `docker compose ps`.
- Inspect `docker compose logs bnetserver worldserver`.
- Rerun `bash scripts/apply-required-updates.sh` after MySQL is healthy.

### World server is down or login times out

- Confirm all four data trees exist under `~/legion-server-runtime/data`.
- Wait until the logs say `worldserver-daemon) ready`.
- Confirm ports `8085` and `8086` are not occupied by another WoW stack.
- Stop WoTLK before starting Legion, or use `server switch legion`.

### Installer reports a modified source checkout

The installer refuses to overwrite unknown source changes. Move the checkout
aside or review and commit your work before retrying. It safely recognizes the
patches managed by this repository on repeat runs.

## Known Limitations

- This remains an experimental preservation server, not a complete production realm.
- Many quests, encounters, scenarios, class halls, and phasing paths need testing.
- Client and extracted game data cannot be redistributed by this project.
- Community bug reports should include client build, character, zone, quest or
  creature ID, exact reproduction steps, and relevant server logs.
