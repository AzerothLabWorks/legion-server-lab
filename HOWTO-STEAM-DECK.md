# Legion 7.3.5 on Steam Deck

This guide covers a user-supplied **World of Warcraft: Legion 7.3.5 build
26365** client on Steam Deck. It is modeled after the practical flow in Dad's
MMO Lab WoTLK guide while preserving this project's different server and data
requirements.

This is a single-device guide: the Steam Deck runs both the Linux Docker server
and the Windows x64 client through Proton. No second computer is part of this
workflow. The client connects to the local server at `127.0.0.1`.

Compilation is slow, Docker installation modifies SteamOS's normally read-only
system image, and the client plus server data uses substantial storage. Those
tradeoffs are called out at the relevant steps rather than changing the guide
into a remote-server workflow.

This repository does not provide or download a World of Warcraft client,
modified client executable, repack, or client-derived `dbc`, `maps`, `vmaps`,
or `mmaps` data. You must already have lawful access to compatible build-26365
materials. Review [docs/DISTRIBUTION_BOUNDARY.md](docs/DISTRIBUTION_BOUNDARY.md)
before sharing files or a fork.

Read [docs/CLIENT_SETUP.md](docs/CLIENT_SETUP.md) before copying anything to the
Deck. It explains how to verify build 26365, why a normal CASC client `Data`
directory is not the extracted server-data input, and why this project does not
publish a legacy-client download link.

## Requirements

- Steam Deck with current SteamOS;
- approximately **160 GB total free** for the client, Proton prefix, server
  source/build, runtime, and extracted data;
- a sufficiently large microSD card or external SSD is acceptable;
- the Deck plugged into power during compilation;
- a configured `sudo` password; and
- locally supplied build-26365 `dbc/maps/vmaps/mmaps` data.

The 64 GB LCD model is not a realistic internal-storage target. Use a
sufficiently large microSD card or external SSD, preferably with a Linux
filesystem for the server runtime, and keep backups of that runtime.

## Part A - Prepare the Client on Steam Deck

### 1. Enter Desktop Mode

Press **Steam > Power > Switch to Desktop**. Open Dolphin for file management
and Konsole for terminal commands. In Desktop Mode, `Steam+X` opens the
on-screen keyboard and `Ctrl+Shift+V` pastes into Konsole.

### 2. Copy the user-supplied client

Copy the complete build-26365 client directory from your own storage or PC to a
stable location such as:

```text
/home/deck/Games/WoW-7.3.5-Legion/
```

An SD-card location normally begins with `/run/media/deck/`. Do not put the
original client inside a Proton `compatdata` directory; removing or recreating
the Steam shortcut can make those generated directories difficult to track.

Confirm the client login screen identifies **7.3.5 (26365) Release x64**. A
current Battle.net retail client is not protocol-compatible.

### 3. Configure the portal

With the client closed, open `WTF/Config.wtf` in Kate. Add or replace the portal
line with the Deck's local loopback address:

```text
SET portal "127.0.0.1"
```

Do not use the Deck's Wi-Fi address. Both services are on the same device, so
`127.0.0.1` is the correct and private endpoint.

### 4. Add the client to Steam

In Steam Desktop:

1. select **Games > Add a Non-Steam Game to My Library**;
2. browse to the compatible client's x64 executable;
3. rename the shortcut to **World of Warcraft: Legion 7.3.5**;
4. open **Properties > Compatibility**; and
5. force **Proton Experimental** initially.

Try the client before installing another compatibility layer. If it fails to
start, has a black screen, or has broken cinematics, install **ProtonUp-Qt**
from Discover, use it to install a current GE-Proton release for Steam, restart
Steam, and choose that release in the shortcut's Compatibility page. Avoid
pinning this guide to a particular GE-Proton number because compatibility
releases change frequently.

Launch the shortcut once in Desktop Mode. Confirm that it reaches the login
screen, then exit. Steam will create its Proton prefix automatically.

### 5. Set controls and display options

In Gaming Mode, open the shortcut's controller settings. A keyboard-and-mouse
community layout is a reasonable starting point. Useful bindings include:

- left stick to WASD;
- right trackpad to mouse;
- right-trackpad click to left mouse button;
- left-trackpad click to right mouse button;
- triggers or rear buttons for modifiers such as Shift and Ctrl; and
- one button for Enter and one for Escape.

Set the client to the Deck's native 1280x800 resolution and adjust UI scale in
game. Addons with many small windows are easier to configure in Desktop Mode or
with a temporary keyboard and mouse.

## Part B - Install the Server on Steam Deck

The server runs natively in Docker on SteamOS. It consumes significant storage
and battery and is unavailable while the Deck is asleep, so keep the Deck on
power and awake during installation and gameplay.

### 1. Set a sudo password

In Konsole:

```bash
passwd
```

Choose a Deck-local password and keep it private. Characters do not appear
while a Linux password is entered; that is normal.

### 2. Install Docker and required tools

SteamOS normally keeps its system image read-only. The following uses SteamOS's
Arch package manager. A SteamOS update can remove these system-installed
packages, in which case this dependency step must be repeated.

```bash
sudo steamos-readonly disable
sudo pacman -Syu --needed docker docker-compose docker-buildx git openssl
sudo steamos-readonly enable

sudo systemctl enable --now docker
sudo usermod -aG docker deck
```

Always run `sudo steamos-readonly enable` again if the package command reports
an error. Do not reset or delete the pacman keyring automatically; if package
signature validation fails, stop and resolve the SteamOS package/keyring issue
before continuing.

Restart the Deck so the Docker group membership applies. Return to Desktop Mode
and verify:

```bash
docker info
docker compose version
docker buildx version
git --version
```

### 3. Choose storage

The default server layout uses:

```text
/home/deck/legion-server-lab/
/home/deck/legion-server-sources/
/home/deck/legion-server-runtime/
```

To put source and runtime files on a mounted SD card or external SSD, set all
three locations explicitly. First confirm the drive is mounted and writable:

```bash
df -h /run/media/deck/YOUR_DRIVE_LABEL
touch /run/media/deck/YOUR_DRIVE_LABEL/legion-write-test
rm /run/media/deck/YOUR_DRIVE_LABEL/legion-write-test
```

Use a Linux filesystem when practical. NTFS or exFAT can work for the client
and source data but may cause permissions problems for MySQL; keep the runtime
on a Linux filesystem.

For example, to keep the source and runtime on an already mounted Linux-formatted
drive for this terminal session:

```bash
export LEGION_SOURCE_ROOT="/run/media/deck/YOUR_DRIVE_LABEL/legion-server-sources"
export LEGION_RUNTIME_ROOT="/run/media/deck/YOUR_DRIVE_LABEL/legion-server-runtime"
```

Use the same exports whenever rerunning the installer. Its generated `.env`
records the runtime and data paths, but the external source-root override still
comes from your shell environment.

### 4. Clone and run preflight

```bash
cd ~
git clone https://github.com/AzerothLabWorks/legion-server-lab.git
cd legion-server-lab

LEGION_MIN_FREE_GB=100 bash install/install.sh --check \
  --client-dir "/home/deck/Games/WoW-7.3.5-Legion" \
  --client-build 26365
```

The preflight must identify native Linux and pass every command, Docker, and
free-space check before the build begins.

### 5. Build and install

The Deck has limited memory for a large C++ build, so restrict compilation to
two jobs. Replace the example data path with the location of your compatible
client-derived data:

```bash
LEGION_BUILD_JOBS=2 bash install/install.sh \
  --client-dir "/home/deck/Games/WoW-7.3.5-Legion" \
  --client-build 26365 \
  --data-source "/run/media/deck/YOUR_DRIVE_LABEL/LegionData/Data"
```

If the data and runtime are both under `/home/deck`, a typical command is:

```bash
LEGION_BUILD_JOBS=2 bash install/install.sh \
  --client-dir "/home/deck/Games/WoW-7.3.5-Legion" \
  --client-build 26365 \
  --data-source "/home/deck/Games/LegionData/Data"
```

Keep the Deck plugged in on a stable, ventilated surface and do not play a game
during compilation. The fan running heavily is expected. If compilation is
terminated or the Deck restarts, rerun the same command; the build system will
reuse completed work where possible.

The same data boundary applies on Deck: the pinned core's extraction utilities
are not yet a reliable end-to-end build-26365 extractor. The installer validates
and copies supplied `dbc/maps/vmaps/mmaps`; it does not create or download them.

### 6. Create an account

When all three services are running:

```bash
cd ~/legion-server-lab
docker compose attach worldserver
```

At the server console:

```text
bnetaccount create player@example.com USE-A-UNIQUE-LOCAL-PASSWORD true
account set gmlevel 1#1 3 -1
```

Replace `1#1` with the generated game-account name. Detach without stopping the
server by pressing `Ctrl+P`, then `Ctrl+Q`. Do not press `Ctrl+C`.

### 7. Start from Gaming Mode

The Docker services continue after Konsole closes. Start them in Desktop Mode:

```bash
cd ~/legion-server-lab
bash scripts/compose.sh up -d mysql bnetserver worldserver
docker compose ps
```

For a Gaming Mode shortcut, add `/usr/bin/konsole` as a Non-Steam game, rename
it **Legion Server**, disable Proton for that shortcut, and use these launch
options:

```text
--hold -e bash -lc 'cd "$HOME/legion-server-lab" && bash scripts/compose.sh up -d mysql bnetserver worldserver && docker compose ps'
```

Wait for `worldserver` to become ready, then launch the separate Legion client
shortcut. The client portal remains `127.0.0.1`.

Before suspending or shutting down the Deck, stop the server cleanly:

```bash
cd ~/legion-server-lab
bash scripts/compose.sh down
```

Suspending the Deck suspends the local server too and will disconnect the game.

## Updating

From Desktop Mode:

```bash
cd ~/legion-server-lab
git pull --ff-only
bash tests/install-smoke.sh
bash tests/verify-patches.sh
LEGION_BUILD_JOBS=2 bash install/install.sh \
  --data-source ~/legion-server-runtime/data
```

Back up `~/legion-server-runtime/mysql` before core or database changes. After a
SteamOS update, run `docker info`; if Docker is missing, repeat only the Docker
dependency installation before touching the lab or runtime directories.

## Troubleshooting

### Client starts and immediately exits

- Confirm the x64 executable and build 26365 client are complete.
- Try Proton Experimental first, then a current GE-Proton.
- Remove only the generated non-Steam shortcut and add it again; do not delete
  the original client directory.

### Login hangs or reports no realms

- Confirm `SET portal "127.0.0.1"` is present in `WTF/Config.wtf`.
- Confirm Docker containers are healthy with `docker compose ps`.
- Inspect `docker compose logs --tail=200 bnetserver worldserver`.

### Docker disappears after SteamOS updates

This is a consequence of installing packages into SteamOS's managed system
image. Repeat Part B, Step 2. Do not delete the server source or runtime.

### Build fails or is killed

Check free space with `df -h`. Re-run with `LEGION_BUILD_JOBS=1` if memory
pressure killed a compiler process. Preserve the existing build directory so
completed objects can be reused.

### Containers start but worldserver exits

Confirm all four data trees are populated:

```bash
for tree in dbc maps vmaps mmaps; do
  find "$HOME/legion-server-runtime/data/$tree" -type f -print -quit
done
```

Then inspect:

```bash
docker compose logs --tail=200 mysql bnetserver worldserver
```

## Reference and Project Status

The user-focused structure of this guide was informed by
[Dad's MMO Lab WoTLK Steam Deck guide](https://github.com/DadsMmoLab/dads-mmo-lab/blob/main/guides/wow-wotlk/WoW-WotLK-HOWTO.md).
Its AzerothCore installer and data sizes are not interchangeable with this
Legion build. Legion remains an experimental preservation server with incomplete
quests, encounters, class behavior, phasing, and instances.
