# Legion 7.3.5 on Steam Deck

This guide covers a user-supplied **World of Warcraft: Legion 7.3.5 build
26365** client on Steam Deck. It is modeled after the practical flow in Dad's
MMO Lab WoTLK guide while preserving this project's different server and data
requirements.

There are two supported layouts:

1. **Deck as client, WSL2/Linux PC as server (recommended).** This gives the
   Deck the best battery, thermal, storage, and suspend behavior.
2. **Deck as both client and server (experimental).** This can work because the
   Deck is x86-64 Linux, but compilation is slow, Docker installation modifies
   SteamOS's normally read-only system, and the Legion client plus extracted
   server data uses substantial storage.

This repository does not provide or download a World of Warcraft client,
modified client executable, repack, or client-derived `dbc`, `maps`, `vmaps`,
or `mmaps` data. You must already have lawful access to compatible build-26365
materials. Review [docs/DISTRIBUTION_BOUNDARY.md](docs/DISTRIBUTION_BOUNDARY.md)
before sharing files or a fork.

## Requirements

### Client-only Deck

- Steam Deck with current SteamOS;
- approximately 60 GB free for the user-supplied client and Proton prefix;
- a microSD card or external SSD is acceptable;
- the Deck and server connected to the same trusted home network; and
- an already running Legion server from
  [HOWTO-WINDOWS-WSL2.md](HOWTO-WINDOWS-WSL2.md) or another x86-64 Linux host.

### All-in-one Deck

- all of the above;
- at least **100 GB free**, in addition to any separate client copy;
- the Deck plugged into power during compilation;
- a configured `sudo` password; and
- locally supplied build-26365 `dbc/maps/vmaps/mmaps` data.

The 64 GB LCD model is not a realistic internal-storage target for an all-in-one
installation. Use a sufficiently large microSD card or external SSD, and keep
backups of the server runtime.

## Part A - Prepare the Client on Steam Deck

These steps apply to both layouts.

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
line.

For an all-in-one Deck server:

```text
SET portal "127.0.0.1"
```

For a server on another computer, use that computer's LAN IPv4 address:

```text
SET portal "192.168.1.50"
```

Replace the example with the actual server address configured in Part B. Do not
use the Deck's address unless the server is running on the Deck.

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

## Part B - Connect the Deck to a WSL2 or Linux Server (Recommended)

### 1. Find the server computer's LAN address

On a Windows/WSL2 host, open PowerShell and run:

```powershell
ipconfig
```

Use the IPv4 address of the active Ethernet or Wi-Fi adapter, for example
`192.168.1.50`. Do not use the WSL virtual-adapter address, `127.0.0.1`, a public
Internet address, or the router's address.

On a native Linux server, use the host's LAN IPv4 address from:

```bash
ip -4 address
```

Consider reserving this address for the server computer in the router's DHCP
settings so it does not change later.

### 2. Advertise the LAN address from Legion

On the server, from the Legion lab checkout:

```bash
cd ~/legion-server-lab
bash scripts/configure-realm-address.sh 192.168.1.50 --enable-lan-rest
```

Replace the example address. The command:

- stores the realm address in the ignored `.env` file;
- updates the authentication database;
- explicitly exposes REST port 8081 to the trusted LAN; and
- recreates the Battle.net and world containers with the new port binding.

To return the server to local-only operation:

```bash
bash scripts/configure-realm-address.sh 127.0.0.1 --local-rest
```

### 3. Allow only trusted-LAN traffic

The Deck needs TCP access to ports `1119`, `8081`, `8085`, and `8086` on the
server computer. If Windows Defender Firewall prompts for Docker, allow it on
**Private networks only**. If no prompt appears, create narrowly scoped inbound
rules for those TCP ports on the Private profile.

Do not configure router port forwarding and do not expose this experimental
realm to the public Internet. MySQL port 3310 remains bound to the server's
loopback interface and is not needed by the Deck.

Docker Desktop normally publishes Compose ports through the Windows host. If a
third-party firewall or VPN is installed, it may need an equivalent trusted-LAN
exception.

### 4. Test the network from the Deck

In Deck Desktop Mode, replace the example address and run:

```bash
timeout 3 bash -c '</dev/tcp/192.168.1.50/1119' \
  && echo 'Battle.net port reachable' \
  || echo 'Cannot reach Battle.net port'

timeout 3 bash -c '</dev/tcp/192.168.1.50/8085' \
  && echo 'World port reachable' \
  || echo 'Cannot reach world port'
```

If either test fails, confirm the server containers are running, recheck the
Windows/Linux firewall, and verify both machines are on the same LAN without
wireless client isolation.

### 5. Log in

Confirm `Config.wtf` uses the same server address, return to Gaming Mode, launch
Legion, and sign in with the local Battle.net account created on your server.
If authentication works but the realm is unavailable, re-run the realm-address
command and inspect:

```bash
docker compose logs --tail=200 bnetserver worldserver
```

## Part C - Run the Server on the Steam Deck (Experimental)

Running both client and server avoids LAN configuration, but it consumes more
storage and battery and does not behave like a continuously available server
while the Deck is asleep.

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
sudo pacman -Sy --needed docker docker-compose git openssl
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

LEGION_MIN_FREE_GB=100 bash install/install.sh --check
```

The WSL check will identify SteamOS as native Linux rather than WSL2; that
warning is expected. All required command and Docker checks must pass.

### 5. Build and install

The Deck has limited memory for a large C++ build, so restrict compilation to
two jobs. Replace the example data path with the location of your compatible
client-derived data:

```bash
LEGION_BUILD_JOBS=2 bash install/install.sh \
  --data-source "/run/media/deck/YOUR_DRIVE_LABEL/LegionData/Data"
```

If the data and runtime are both under `/home/deck`, a typical command is:

```bash
LEGION_BUILD_JOBS=2 bash install/install.sh \
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
shortcut. The all-in-one client portal remains `127.0.0.1`.

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

- Confirm `SET portal` uses the correct server LAN address.
- Confirm ports 1119, 8081, 8085, and 8086 are allowed on the trusted LAN.
- Re-run `configure-realm-address.sh` with the Windows/Linux host address.
- Confirm Docker containers are healthy with `docker compose ps`.

### Docker disappears after SteamOS updates

This is a consequence of installing packages into SteamOS's managed system
image. Repeat Part C, Step 2. Do not delete the server source or runtime.

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
