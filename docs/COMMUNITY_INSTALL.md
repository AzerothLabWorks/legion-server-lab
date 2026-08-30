# Community Installation Reference

This is the shared command reference for the Legion 7.3.5 build-26365 lab. Pick
one supported host and complete its platform guide first:

| Host layout | Guide |
| --- | --- |
| Steam Deck running both server and Proton client | [HOWTO-STEAM-DECK.md](../HOWTO-STEAM-DECK.md) |
| Windows client with server under Ubuntu/WSL2 | [HOWTO-WINDOWS-WSL2.md](../HOWTO-WINDOWS-WSL2.md) |

The guides are intentionally separate. Do not paste SteamOS package commands
into Ubuntu or use `/mnt/c/...` paths on Steam Deck.

## Downloads and Distribution Boundary

The installer downloads pinned open-source server source and builds Linux
binaries locally. It does not provide or download:

- a World of Warcraft client or launcher;
- modified executables or repacks;
- `dbc`, `maps`, `vmaps`, or `mmaps` data;
- server binaries or database dumps; or
- credentials or runtime volumes.

The operator must already have access to a matching **Legion 7.3.5 build 26365
Release x64** client and compatible extracted server data. Read
[CLIENT_SETUP.md](CLIENT_SETUP.md) and
[DISTRIBUTION_BOUNDARY.md](DISTRIBUTION_BOUNDARY.md) before installing or
sharing the project.

This build does not currently include a viable Legion Playerbots module. The
companion auto-loot feature does not create autonomous players, populate the
world, or provide dungeon and raid groups.

## Platform Paths

| Input | Steam Deck | Windows/WSL2 |
| --- | --- | --- |
| Playable client | `/home/deck/Games/WoW-7.3.5-Legion` | `/mnt/c/Games/WoW-7.3.5-Legion-Client` |
| Extracted data | `/home/deck/Games/LegionData/Data` | `/mnt/c/Games/LegionData/Data` |
| Repository | `/home/deck/legion-server-lab` | `/home/USER/legion-server-lab` |
| Runtime | `/home/deck/legion-server-runtime` | `/home/USER/legion-server-runtime` |

On Windows, `C:\Games\...` becomes `/mnt/c/Games/...` inside Ubuntu. Replace
`USER` and every example path with the real value for the selected host.

The extracted-data directory must have this immediate layout:

```text
Data/
|-- dbc/
|-- maps/
|-- vmaps/
`-- mmaps/
```

The ordinary CASC `Data` directory inside the playable client is not a
substitute for these extracted server-data trees.

## Clone and Check

### Preserved core source

The installer pins LegionCore commit
`6c41d0faa23474bf9e76a4811b144d43e9545bab`. AzerothLabWorks maintains a
complete preservation mirror at
<https://github.com/AzerothLabWorks/LegionCore-7.3.5V2-preservation>. While the
mirror remains private for provenance review, authorized maintainers can use it
by prefixing any installer command with:

```bash
LEGION_CORE_URL=https://github.com/AzerothLabWorks/LegionCore-7.3.5V2-preservation.git
```

Community installs continue to use the public upstream by default until the
preservation mirror is made public.

```bash
cd ~
git clone https://github.com/AzerothLabWorks/legion-server-lab.git
cd legion-server-lab
```

Steam Deck example:

```bash
LEGION_MIN_FREE_GB=100 bash install/install.sh --check \
  --client-dir "/home/deck/Games/WoW-7.3.5-Legion" \
  --client-build 26365 \
  --data-source "/home/deck/Games/LegionData/Data"
```

Windows/WSL2 example, entered in Ubuntu:

```bash
bash install/install.sh --check \
  --client-dir "/mnt/c/Games/WoW-7.3.5-Legion-Client" \
  --client-build 26365 \
  --data-source "/mnt/c/Games/LegionData/Data"
```

The check validates the selected supported host, x86-64, Git, OpenSSL, Docker
Engine, Docker Compose, Docker Buildx, disk space, client prerequisite, and all
four supplied server-data trees. It does not execute, copy, or modify the
playable client or server data.

## Build and Start

Steam Deck uses two compilation jobs:

```bash
LEGION_BUILD_JOBS=2 bash install/install.sh \
  --client-dir "/home/deck/Games/WoW-7.3.5-Legion" \
  --client-build 26365 \
  --data-source "/home/deck/Games/LegionData/Data"
```

Windows/WSL2 may use the installer default or set an appropriate job count:

```bash
bash install/install.sh \
  --client-dir "/mnt/c/Games/WoW-7.3.5-Legion-Client" \
  --client-build 26365 \
  --data-source "/mnt/c/Games/LegionData/Data"
```

The installer copies extracted data into native Linux runtime storage. If data
is not ready, omit `--data-source`; the build stops safely at the data boundary.
Resume later with the same platform paths plus `--skip-build`.

## Create the First Account

After the installer prints `LEGION SERVER READY`:

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
without stopping the server using `Ctrl+P`, then `Ctrl+Q`.

### Optional: Unlock the Legion Allied Races

After that game account has at least one character, grant its four Legion
allied-race unlocks without completing the retail achievements:

```bash
cd ~/legion-server-lab
bash scripts/unlock-allied-races.sh player@example.com 1
```

Replace the email with the Battle.net-style login created above. The final
argument selects the linked game account and defaults to `1` (`WoW1`). Fully
disconnect and reconnect the client afterward so the account achievement cache
is reloaded. This unlocks Void Elf, Lightforged Draenei, Nightborne, and
Highmountain Tauren while preserving normal expansion and race/class checks.

## Configure the Client

Both supported layouts run client and server on the same physical device, so
the portal value is the same:

```text
SET portal "127.0.0.1"
```

- On Steam Deck, edit the client's `WTF/Config.wtf` and launch its x64
  executable through Proton.
- On Windows, edit `CLIENT_FOLDER\WTF\Config.wtf` and launch the compatible x64
  executable directly. Docker services remain under Ubuntu/WSL2.

## Routine Commands

Choose a progression preset without editing server configuration:

```bash
cd ~/legion-server-lab
bash scripts/configure-rates.sh balanced
```

The available presets and custom-value syntax are documented in
[PROGRESSION_RATES.md](PROGRESSION_RATES.md).

Run these from the Linux repository checkout on either host:

```bash
cd ~/legion-server-lab
bash scripts/compose.sh ps
bash scripts/compose.sh logs -f bnetserver worldserver
bash scripts/compose.sh restart worldserver
bash scripts/compose.sh down
```

The installer also creates `~/legion-server-launcher.sh`, which supports
`start`, `stop`, `status`, and `logs`. Running it without an argument starts the
services and waits for the worldserver-ready marker.

## Updating

```bash
cd ~/legion-server-lab
git pull --ff-only
bash tests/install-smoke.sh
bash tests/verify-patches.sh
bash install/install.sh --data-source ~/legion-server-runtime/data
```

Back up `~/legion-server-runtime/mysql` before core or database changes.

## Quick Troubleshooting

- **Unsupported host:** use current SteamOS/Arch on Steam Deck or Ubuntu under
  WSL2 as described in the selected guide.
- **Client immediately exits:** confirm `7.3.5 (26365) Release x64`; Steam Deck
  users should try Proton Experimental and then a current GE-Proton release.
- **No realms:** confirm `SET portal "127.0.0.1"`, run `docker compose ps`, and
  inspect `docker compose logs --tail=200 bnetserver worldserver`.
- **World server exits:** confirm all four extracted data directories are
  populated under `~/legion-server-runtime/data`.
- **Build is killed:** check free space and reduce `LEGION_BUILD_JOBS`.

This remains an experimental preservation server. Create a sanitized starting
point for a support request with:

```bash
bash scripts/support-report.sh
```

Review the generated report before sharing it. Reports should also include the
client build, character, zone, quest or creature ID, exact reproduction steps,
and expected behavior. Never attach clients, repacks, extracted data, database
directories, or passwords.
