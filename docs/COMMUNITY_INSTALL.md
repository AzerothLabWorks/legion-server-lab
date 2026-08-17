# Steam Deck Community Installation

This is the short command reference for running the complete Legion lab on one
Steam Deck. SteamOS/Arch Linux runs the Docker server and Proton runs the
operator-supplied **Legion 7.3.5 build 26365 Release x64** client.

For explanations, storage planning, controller setup, Gaming Mode shortcuts,
and troubleshooting, use the canonical
[Steam Deck guide](../HOWTO-STEAM-DECK.md).

## Distribution Boundary

The installer downloads pinned open-source server source and builds Linux
binaries locally. It does not provide or download:

- a World of Warcraft client or launcher;
- modified game executables or repacks;
- `dbc`, `maps`, `vmaps`, or `mmaps` data;
- server binaries or database dumps; or
- credentials or runtime volumes.

The operator must already have access to a matching client and compatible
extracted server data. Read [CLIENT_SETUP.md](CLIENT_SETUP.md) and
[DISTRIBUTION_BOUNDARY.md](DISTRIBUTION_BOUNDARY.md) before installing or
sharing the project.

## Requirements

- Steam Deck running current SteamOS;
- approximately 160 GB total free for the client, Proton prefix, source/build,
  runtime, and extracted data;
- power connected throughout compilation;
- a configured Deck-local `sudo` password;
- an operator-supplied client at a stable location such as
  `/home/deck/Games/WoW-7.3.5-Legion`; and
- extracted data whose immediate children are `dbc`, `maps`, `vmaps`, and
  `mmaps`.

An external SSD or sufficiently large microSD card is suitable. Keep the MySQL
runtime on a Linux filesystem when possible.

## 1. Enter Desktop Mode

Press **Steam > Power > Switch to Desktop**, then open Konsole. Set a local
password if the Deck account does not have one:

```bash
passwd
```

## 2. Install Docker and Git

SteamOS normally uses a read-only system image. Install the native Arch packages
and immediately restore read-only mode:

```bash
sudo steamos-readonly disable
sudo pacman -Syu --needed docker docker-compose docker-buildx git openssl
sudo steamos-readonly enable

sudo systemctl enable --now docker
sudo usermod -aG docker deck
```

Restart the Deck so group membership applies. Return to Desktop Mode and verify:

```bash
docker info
docker compose version
docker buildx version
git --version
```

SteamOS updates may remove packages installed into the system image. If that
happens, repeat only this dependency step; do not remove the lab or runtime.

## 3. Prepare the Client and Data Paths

Confirm the client login screen says:

```text
Version 7.3.5 (26365) Release x64
```

A typical single-device layout is:

```text
/home/deck/Games/WoW-7.3.5-Legion/
/home/deck/Games/LegionData/Data/
    dbc/
    maps/
    vmaps/
    mmaps/
```

The ordinary CASC `Data` directory inside the playable client is not the same
as the four extracted server-data trees.

## 4. Clone and Check Prerequisites

```bash
cd ~
git clone https://github.com/AzerothLabWorks/legion-server-lab.git
cd legion-server-lab

LEGION_MIN_FREE_GB=100 bash install/install.sh --check \
  --client-dir "/home/deck/Games/WoW-7.3.5-Legion" \
  --client-build 26365
```

The check must report SteamOS/Arch Linux, x86-64, Docker, Compose, Git, OpenSSL,
and adequate free space. The client directory is inspected read-only and is not
copied or modified.

## 5. Build and Start

Limit compilation to two jobs on the Deck:

```bash
LEGION_BUILD_JOBS=2 bash install/install.sh \
  --client-dir "/home/deck/Games/WoW-7.3.5-Legion" \
  --client-build 26365 \
  --data-source "/home/deck/Games/LegionData/Data"
```

If the extracted data is on removable storage, replace only the data path, for
example:

```text
/run/media/deck/YOUR_DRIVE_LABEL/LegionData/Data
```

The first build and database import can take considerable time. Keep the Deck
awake, connected to power, and on a ventilated surface.

## 6. Create the First Account

After all services are healthy:

```bash
cd ~/legion-server-lab
docker compose attach worldserver
```

At the server console:

```text
bnetaccount create player@example.com USE-A-UNIQUE-LOCAL-PASSWORD true
account set gmlevel 1#1 3 -1
```

Replace `1#1` with the game-account name printed by the first command. Detach
without stopping the server with `Ctrl+P`, then `Ctrl+Q`.

## 7. Configure and Launch the Client

Close the client and put this in its `WTF/Config.wtf`:

```text
SET portal "127.0.0.1"
```

Add the client's x64 executable to Steam as a Non-Steam Game and force Proton
Experimental initially. Start the local server before launching the client:

```bash
cd ~/legion-server-lab
bash scripts/compose.sh up -d mysql bnetserver worldserver
docker compose ps
```

## Routine Commands

```bash
cd ~/legion-server-lab
bash scripts/compose.sh ps
bash scripts/compose.sh logs -f bnetserver worldserver
bash scripts/compose.sh restart worldserver
bash scripts/compose.sh down
```

Stop the services before suspending or shutting down the Deck. Suspending the
Deck suspends the local server and disconnects the client.

## Updating

```bash
cd ~/legion-server-lab
git pull --ff-only
bash tests/install-smoke.sh
bash tests/verify-patches.sh
LEGION_BUILD_JOBS=2 bash install/install.sh \
  --data-source ~/legion-server-runtime/data
```

Back up `~/legion-server-runtime/mysql` before core or database changes.

## Quick Troubleshooting

- **Preflight identifies another distribution:** the supported community host
  is Steam Deck with SteamOS/Arch Linux.
- **Client immediately exits:** verify build 26365 x64, try Proton Experimental,
  then a current GE-Proton release.
- **No realms:** confirm `SET portal "127.0.0.1"`, run `docker compose ps`, and
  inspect `docker compose logs --tail=200 bnetserver worldserver`.
- **World server exits:** confirm all four extracted data directories are
  populated under `~/legion-server-runtime/data`.
- **Build is killed:** rerun with `LEGION_BUILD_JOBS=1` and check `df -h`.

This remains an experimental preservation server. Community reports should
include client build, character, zone, quest or creature ID, exact reproduction
steps, and relevant server logs.
