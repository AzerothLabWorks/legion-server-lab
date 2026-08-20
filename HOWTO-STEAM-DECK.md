# Legion 7.3.5 on Steam Deck

This guide covers a user-supplied **World of Warcraft: Legion 7.3.5 build
26365** client and the AzerothLabWorks server running together on Steam Deck.

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

## What This Installs

Following this guide produces:

- a Linux Legion server compiled from the repository's pinned public source;
- MySQL, `bnetserver`, and `worldserver` services managed with Docker Compose;
- a local Steam Deck launcher that starts the services and waits until the
  world is ready;
- persistent configuration, databases, logs, and an operator reference file;
  and
- a separately configured Windows x64 Legion client launched through Proton.

This is an experimental preservation lab, not a complete or Blizzlike Legion
implementation. It does **not** currently include a viable Playerbots module.
The companion auto-loot feature is not a playerbot and does not populate the
world, form groups, or run dungeons. See
[docs/PLAYERBOTS_ROADMAP.md](docs/PLAYERBOTS_ROADMAP.md) for the longer-term
research plan.

## Requirements

| Requirement | Details |
| --- | --- |
| Device | x86-64 Steam Deck with current SteamOS |
| Storage | Approximately **160 GB total free** for the client, Proton prefix, source/build, runtime, and extracted data |
| Memory | The Deck's standard 16 GB is supported; compilation is intentionally limited to two jobs |
| Time | Allow several hours for the first source build, plus as much as 15 minutes for initial database setup |
| Power | Keep the Deck plugged in, awake, and on a stable ventilated surface |
| Access | A configured Deck-local `sudo` password |

### Before you start

Make sure you can check every item below:

- [ ] The playable client reaches a login screen showing **7.3.5 (26365)
  Release x64**.
- [ ] You possess a **separate** directory whose immediate children are
  populated `dbc`, `maps`, `vmaps`, and `mmaps` directories.
- [ ] You have decided whether the large server source/runtime will use
  internal storage or a Linux-formatted microSD card/external SSD.
- [ ] The Deck is plugged in and sleep is disabled for the installation.
- [ ] You understand that the repository does not download, endorse, or link
  to third-party client, patched-executable, repack, or extracted-data
  downloads.

The playable client's ordinary CASC `Data` directory is **not** the extracted
server-data directory. The installer checks both inputs but never copies or
modifies the playable client.

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

For the simplest first installation, use the default locations below and skip
to Step 4. Choose external storage only when the Deck does not have enough
internal space.

The default server layout uses:

```text
/home/deck/legion-server-lab/
/home/deck/legion-server-sources/
/home/deck/legion-server-runtime/
```

#### Advanced: external storage

To put source and runtime files on a mounted SD card or external SSD, set the
locations explicitly. First confirm the drive is mounted and writable:

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
  --client-build 26365 \
  --data-source "/home/deck/Games/LegionData/Data"
```

Replace the data path if yours is on external storage. The preflight must
identify SteamOS/Arch Linux and pass every command, Docker, free-space, client,
and server-data check before the build begins. It is read-only: no source,
client, data, or runtime files are changed by `--check`.

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

The installer reports six phases:

1. validate the host, client, and supplied data;
2. retrieve the pinned server source;
3. build the Linux binaries and prepare the runtime;
4. copy the validated server data;
5. create the launcher and installation reference; and
6. initialize the database and wait for the world server.

Build output is saved under `~/legion-server-runtime/logs/`. The first database
initialization can take several minutes. Do not launch the client until the
installer prints:

```text
LEGION SERVER READY
```

The same data boundary applies on Deck: the pinned core's extraction utilities
are not yet a reliable end-to-end build-26365 extractor. The installer validates
and copies supplied `dbc/maps/vmaps/mmaps`; it does not create or download them.

### 6. Create an account

After the installer prints `LEGION SERVER READY`, create the first local
account:

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

### 7. Add the server launcher to Gaming Mode

The installer creates `~/legion-server-launcher.sh`. It starts all services,
waits for the actual worldserver-ready marker, and prints `LEGION SERVER READY`
when it is safe to launch the client.

Add `/usr/bin/konsole` as a Non-Steam game, rename it **Legion Server**, disable
Proton for that shortcut, and use these launch options:

```text
--hold -e bash /home/deck/legion-server-launcher.sh
```

The server runs in Docker after the Konsole window is closed, although leaving
the window open makes the readiness result easy to see. The client portal
remains `127.0.0.1`.

## Daily Use in Gaming Mode

1. Launch **Legion Server** from the Steam library.
2. Wait for the Konsole window to display `LEGION SERVER READY`.
3. Return to the Steam library and launch **World of Warcraft: Legion 7.3.5**.
4. Log in with the local Battle.net-format account created in Step 6.
5. When finished, exit the client normally.
6. In Desktop Mode, stop the server cleanly with:

```bash
~/legion-server-launcher.sh stop
```

Before suspending or shutting down the Deck, stop the server cleanly:

```bash
~/legion-server-launcher.sh stop
```

Suspending the Deck suspends the local server too and will disconnect the game.

## Quick Reference

| Task or file | Command or default path |
| --- | --- |
| Start and wait | `~/legion-server-launcher.sh` |
| Stop cleanly | `~/legion-server-launcher.sh stop` |
| Check status | `~/legion-server-launcher.sh status` |
| Watch logs | `~/legion-server-launcher.sh logs` |
| Attach console | `cd ~/legion-server-lab && docker compose attach worldserver` |
| Detach console | Press `Ctrl+P`, then `Ctrl+Q`; never use `Ctrl+C` |
| Repository | `~/legion-server-lab/` |
| Pinned source/build | `~/legion-server-sources/` |
| Runtime, database, and data | `~/legion-server-runtime/` |
| Installation reference | `~/legion-server-runtime/INSTALL_SUMMARY.txt` |
| Build and service logs | `~/legion-server-runtime/logs/` |

External-storage users should use the paths recorded in
`INSTALL_SUMMARY.txt` rather than assuming the defaults above.

## If Installation Is Interrupted

| Where it stopped | Safe next action |
| --- | --- |
| Preflight reports an error | Correct the named prerequisite and rerun the same `--check` command |
| Compilation is interrupted | Rerun the same full installation command; completed build work is reused |
| Build completes but server data was omitted | Rerun with `--skip-build --data-source "/actual/path/to/Data"` |
| Database or worldserver readiness times out | Run the launcher with `status`, inspect `logs`, then create a support report |
| Docker disappears after a SteamOS update | Repeat only Part B, Step 2; do not remove the runtime or source directories |
| Client reports no realm or world server down | Confirm `SET portal "127.0.0.1"`, wait for the ready message, and inspect server logs |

Do not delete the source or runtime to solve an ordinary retryable failure.
Those directories contain reusable build work and the persistent character
database.

## Asking for Community Support

Generate a diagnostic report with:

```bash
cd ~/legion-server-lab
bash scripts/support-report.sh
```

The command prints the report's location under the runtime `logs` directory.
Review the file before sharing it because logs can contain character names,
account names, or local IP addresses. The report intentionally excludes the
project `.env` contents and passwords.

When asking for help, include:

- Steam Deck model and current SteamOS version;
- internal, microSD, or external-SSD storage and its filesystem;
- confirmation that the login screen reports build 26365 x64;
- the exact failed step and command;
- the generated support report; and
- a short description of what you expected and what happened instead.

Never attach a client, repack, modified executable, extracted data, database
directory, or account password to an issue or community message.

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

## Project Status

Legion remains an experimental preservation server with incomplete quests,
encounters, class behavior, phasing, and instances.
