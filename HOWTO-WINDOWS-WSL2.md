# Legion 7.3.5 WSL2 Clean-Machine Installation

This is the supported clean-machine path for building the AzerothLabWorks
Legion server on Windows. It follows the same operating model as the WoTLK
hybrid lab: Windows hosts the game client, while Ubuntu/WSL2 owns the source,
build output, database, and Docker services.

The target is **Legion 7.3.5 build 26365**. This repository automates the
open-source server build and the AzerothLabWorks improvements. It does not
download or distribute a World of Warcraft client, a repack, server binaries,
or client-derived `dbc`, `maps`, `vmaps`, and `mmaps` files.

Before installing, read [docs/CLIENT_SETUP.md](docs/CLIENT_SETUP.md). It explains
the exact client build, the difference between a playable client and extracted
server data, supported paths, portal configuration, and why this project cannot
provide a legacy-client download link.

## 1. Requirements

- Windows 10 version 2004 or newer, or Windows 11;
- an x86-64 computer with virtualization enabled;
- 8 GB RAM minimum (16 GB recommended);
- at least 60 GB free on the WSL filesystem;
- WSL2 with Ubuntu;
- Docker Desktop using its WSL2 backend, or Docker Engine installed directly
  in Ubuntu; and
- lawful access to a matching 7.3.5.26365 client and compatible data extracted
  locally from it.

Keep the lab checkout and runtime under the Linux home directory. Building or
running the database from `/mnt/c`, OneDrive, or another Windows-mounted folder
is slower and can cause Linux permission or file-watching problems.

## 2. Install WSL2 and Ubuntu

Open **PowerShell as Administrator**:

```powershell
wsl --install -d Ubuntu
```

Restart Windows if prompted. Open Ubuntu once and create the requested Linux
username and password. Back in PowerShell, verify that Ubuntu uses WSL2:

```powershell
wsl --list --verbose
```

The `VERSION` column for Ubuntu must be `2`. If it is not:

```powershell
wsl --set-version Ubuntu 2
```

Microsoft's current instructions are at
<https://learn.microsoft.com/windows/wsl/install>.

## 3. Provide Docker to Ubuntu

### Option A: Docker Desktop (recommended for most Windows users)

Install Docker Desktop from
<https://docs.docker.com/desktop/setup/install/windows-install/>. In Docker
Desktop:

1. enable **Use the WSL 2 based engine**;
2. open **Resources > WSL Integration**; and
3. enable integration for the Ubuntu distribution.

Restart Docker Desktop after changing those settings. Do not also install a
second Docker Engine inside the same Ubuntu distribution.

### Option B: Docker Engine inside Ubuntu

Advanced users can install Docker Engine and the Compose v2 plugin directly in
Ubuntu using Docker's official Ubuntu instructions:
<https://docs.docker.com/engine/install/ubuntu/>.

Use exactly one Docker provider. The lab requires the `docker compose` command,
not the retired standalone `docker-compose` program.

## 4. Prepare Ubuntu

Run in the **Ubuntu terminal**, not PowerShell:

```bash
sudo apt update
sudo apt install -y ca-certificates curl git openssl
```

Confirm Docker is available to the current Linux user:

```bash
docker info
docker compose version
docker buildx version
```

If `docker info` cannot connect, start Docker Desktop and confirm WSL
integration. If using native Docker Engine, follow Docker's post-install steps
to permit non-root use, then close and reopen Ubuntu.

## 5. Clone and Run Preflight

```bash
cd ~
git clone https://github.com/AzerothLabWorks/legion-server-lab.git
cd legion-server-lab
bash install/install.sh --check \
  --client-dir "/mnt/c/Games/WoW-7.3.5-Legion-Client" \
  --client-build 26365
```

The check is read-only. It validates Linux/WSL, x86-64, Git, OpenSSL, Docker,
Compose v2, the Docker daemon, available disk space, the supplied client
directory, and the operator-confirmed login-screen build. Change the client path
to your actual location. A headless server operator can omit both client
options.

The installer creates this isolated layout:

```text
~/legion-server-lab/                         automation and documentation
~/legion-server-sources/LegionCore-7.3.5V2/ pinned upstream source + patches
~/legion-server-runtime/                     build, server, DB, config, logs, data
```

## 6. Supply Compatible Client-Derived Data

The world server needs four directories produced from a compatible build-26365
client:

```text
Data/
|-- dbc/
|-- maps/
|-- vmaps/
`-- mmaps/
```

These files are not in this repository and must not be uploaded to issues,
release archives, forks, or mirrors. The extraction utilities in the pinned
upstream core are not currently a reliable end-to-end build-26365 extractor:
its DB2 extraction path is disabled and part of its map path targets an older
build. For that reason this guide does not claim that it can safely generate
the four trees from a clean client yet.

If the data is on Windows, its path is visible inside WSL under `/mnt`. For
example:

```text
C:\Games\Legion-Server-Data\Data
```

becomes:

```text
/mnt/c/Games/Legion-Server-Data/Data
```

The installer validates the four trees and copies them to native WSL storage.
The Windows source can remain read-only.

Do not point `--data-source` at a normal client CASC `Data` directory. It must be
the extracted four-tree layout described in
[docs/CLIENT_SETUP.md](docs/CLIENT_SETUP.md).

Before beginning the long build, validate the client and all four server-data
trees together:

```bash
bash install/install.sh --check \
  --client-dir "/mnt/c/Games/WoW-7.3.5-Legion-Client" \
  --client-build 26365 \
  --data-source "/mnt/c/Games/Legion-Server-Data/Data"
```

The command is read-only and should report a nonzero file count for every data
tree.

## 7. Build and Start the Server

From `~/legion-server-lab`:

```bash
bash install/install.sh \
  --client-dir "/mnt/c/Games/WoW-7.3.5-Legion-Client" \
  --client-build 26365 \
  --data-source "/mnt/c/Games/Legion-Server-Data/Data"
```

Change that example to the real location. The installer will:

1. clone the pinned public LegionCore commit;
2. apply and verify the AzerothLabWorks compatibility and QoL patches;
3. build Linux `bnetserver` and `worldserver` binaries in an Ubuntu 18.04
   build container;
4. generate random local database passwords in the ignored `.env` file;
5. prepare the upstream database and lab migrations;
6. copy the four data trees to the WSL runtime; and
7. start MySQL, Battle.net authentication, and the world server; and
8. wait for the actual worldserver-ready marker before reporting success.

The first compilation and database import can take a while. The terminal shows
named phases, saves build output under `~/legion-server-runtime/logs/`, and
prints `LEGION SERVER READY` when the client can connect. In another Ubuntu
terminal, database progress can be watched with:

```bash
cd ~/legion-server-lab
docker compose logs -f mysql
```

If data is not ready, it is safe to build first:

```bash
bash install/install.sh \
  --client-dir "/mnt/c/Games/WoW-7.3.5-Legion-Client" \
  --client-build 26365
```

The installer stops at the data boundary with exit code 2. Resume later without
recompiling:

```bash
bash install/install.sh --skip-build \
  --client-dir "/mnt/c/Games/WoW-7.3.5-Legion-Client" \
  --client-build 26365 \
  --data-source /mnt/c/Games/Legion-Server-Data/Data
```

To prepare everything without starting the realm, add `--no-start`.

## 8. Confirm the Realm

```bash
cd ~/legion-server-lab
docker compose ps
docker compose logs --tail=100 bnetserver worldserver
```

`mysql`, `bnetserver`, and `worldserver` should be running. The installation
terminal or `bash scripts/wait-for-worldserver.sh` must print
`LEGION SERVER READY` before connecting.

The local endpoints are:

| Port | Service |
| ---: | --- |
| 1119 | Battle.net authentication |
| 8081 | REST/login service (localhost unless LAN access is explicitly enabled) |
| 8085 | primary world connection |
| 8086 | Legion instance/world traffic |
| 3310 | MySQL (localhost only) |

Stop another local WoW stack before starting Legion if it uses overlapping
ports. The AzerothLabWorks server-management project can switch named WoTLK and
Legion stacks: <https://github.com/AzerothLabWorks/server-management>.

For a separate all-in-one Steam Deck installation, use
[HOWTO-STEAM-DECK.md](HOWTO-STEAM-DECK.md). That guide runs both server and
client on the Deck and does not extend this Windows/WSL2 server over the LAN.

## 9. Create a Local Account

Attach to the world console:

```bash
docker compose attach worldserver
```

At the server prompt:

```text
bnetaccount create player@example.com USE-A-UNIQUE-LOCAL-PASSWORD true
```

Record the generated game-account name, commonly `1#1`, then grant it GM level
3 on all realms:

```text
account set gmlevel 1#1 3 -1
```

Replace `1#1` with the exact account printed by the first command. Detach from
the container without stopping it by pressing `Ctrl+P`, then `Ctrl+Q`.

Do not reuse or publish a real-world password.

## 10. Connect a User-Supplied Client

The login screen must report `Version 7.3.5 (26365) Release x64`. With the
client closed, its `WTF/Config.wtf` must point at the local authentication
service:

```text
SET portal "127.0.0.1"
```

This repository does not provide or link to a legacy client or modified client
executable. A current retail World of Warcraft client is not compatible with
this server protocol. Follow the verification, backup, account-name, and error
guidance in [docs/CLIENT_SETUP.md](docs/CLIENT_SETUP.md).

## 11. Routine Operation

To select the recommended progression rates (2x reputation, two profession
skill points per successful gain, and 1.25x XP):

```bash
cd ~/legion-server-lab
bash scripts/configure-rates.sh balanced
```

See [Progression Rates](docs/PROGRESSION_RATES.md) for the Blizzlike,
accelerated, and custom options.

```bash
cd ~/legion-server-lab

# Status
docker compose ps

# Follow server logs
docker compose logs -f bnetserver worldserver

# Start an existing installation
~/legion-server-launcher.sh

# Stop the Legion stack without deleting data
~/legion-server-launcher.sh stop

# Restart only the world server
bash scripts/compose.sh restart worldserver

# Generate a support report for review before sharing
bash scripts/support-report.sh
```

Do not add `-v` to `docker compose down`; that option is unnecessary for this
bind-mounted runtime and can remove unrelated named volumes in other projects.

## 12. Update or Rebuild Lab Improvements

Back up `~/legion-server-runtime/mysql` before database changes. Then:

```bash
cd ~/legion-server-lab
git pull --ff-only
bash tests/install-smoke.sh
bash tests/verify-patches.sh
bash install/install.sh --data-source ~/legion-server-runtime/data
```

The installer pins the upstream core commit and records a content manifest of
the exact files it manages. Repeat runs verify that manifest before applying a
new lab patch set; an older managed tree can therefore advance safely while an
unknown local source edit is refused instead of overwritten. A checkout that
predates manifests is verified once against a clean reconstruction.

## 13. Troubleshooting

### `docker info` fails

Start Docker Desktop and enable Ubuntu in WSL Integration. Do not run the
installer with `sudo` to work around a Docker configuration problem.

### Build is slow under `/mnt/c`

Move the repository to `~/legion-server-lab`. Source, build, MySQL, and runtime
files should live in the WSL ext4 filesystem.

### Installer exits after the build

Exit code 2 means the server build succeeded but the four data trees were not
available. Rerun with `--skip-build --data-source ...` as shown above.

### No realms are available

Confirm the client is exactly build 26365, all three containers are running,
and ports 1119/8085/8086 are not occupied by another stack:

```bash
docker compose ps
docker compose logs --tail=200 bnetserver worldserver
```

### World server exits during startup

Confirm the four data trees are populated under
`~/legion-server-runtime/data`. An empty directory with the right name is not
sufficient.

### Resetting a failed first database import

Do not delete MySQL data casually. Save the output of `docker compose logs
mysql` and open an issue first. If a maintainer confirms that the initial import
can be discarded, stop the stack and move the specific
`~/legion-server-runtime/mysql` directory aside as a backup before retrying.

## Distribution and Project Status

Read [docs/DISTRIBUTION_BOUNDARY.md](docs/DISTRIBUTION_BOUNDARY.md) before
publishing forks or release artifacts. This is an experimental private-server
preservation and development lab, not a production service and not an official
Blizzard project. Quest, encounter, phasing, class, and instance behavior still
requires community testing.
