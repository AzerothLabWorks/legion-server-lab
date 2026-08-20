# Legion 7.3.5 Client and Data Prerequisites

This page answers the client question separately from the server installer:

> The AzerothLabWorks installer builds the server. The operator supplies a
> compatible client and the four extracted server-data trees.

Choose one supported layout before collecting paths:

| Layout | Server host | Client launch | Guide |
| --- | --- | --- | --- |
| Steam Deck | SteamOS/Arch Linux on the Deck | Proton on the same Deck | [Steam Deck guide](../HOWTO-STEAM-DECK.md) |
| Windows PC | Ubuntu/WSL2 on the PC | Windows x64 executable on the same PC | [Windows/WSL2 guide](../HOWTO-WINDOWS-WSL2.md) |

The client requirements are identical, but filesystem paths and host setup are
different. Follow only the guide for the selected layout.

Server automation and client materials remain separate. This project does not
name, mirror, or link a third-party legacy client or repack, and the current
pinned core cannot reliably extract every required build-26365 data tree by
itself.

## Required version

The tested client is:

```text
World of Warcraft: Legion
Version 7.3.5 (26365)
Release x64
```

The login screen should show that version in its lower-left corner. All three
parts matter:

| Check | Required |
| --- | --- |
| Expansion/patch | Legion 7.3.5 |
| Build | 26365 |
| Architecture | x64 |

A current World of Warcraft retail, Classic Era, Wrath Classic, or other
Battle.net installation is not compatible. The official Battle.net application
normally installs Blizzard's currently supported builds; it is not a legacy
7.3.5.26365 downloader.

## What this project does not provide

This repository and its releases do not provide:

- a World of Warcraft client or launcher;
- a modified executable or binary patch;
- a repack, torrent, mirror, Google Drive, or archive link;
- Blizzard art, audio, CASC archives, or other game assets;
- extracted `dbc`, `maps`, `vmaps`, or `mmaps`; or
- instructions for bypassing Blizzard authentication or modifying a client
  executable.

An operator must already possess a matching copy they are authorized to use,
for example from their own retained backup or archival storage. Do not ask
maintainers to identify unofficial download sites, and do not attach a client
or extracted data to an issue.

Client and repack files found independently on the internet are unverified
third-party binaries. This project cannot evaluate their safety, completeness,
or licensing. Avoid bundled download managers and installers, do not run
unknown programs with administrator privileges, and scan unfamiliar files with
the security tools appropriate for the selected platform. The server installer
only needs a user-supplied playable-client path and the separate extracted data
path; it does not need a third-party repack launcher or bundled server service.

Blizzard's current EULA restricts unauthorized servers, protocol emulation,
unauthorized connections, and transfers of Platform copies. Each operator is
responsible for reviewing the applicable terms and law before proceeding. This
project's source-only distribution boundary reduces what the project itself
redistributes; it does not grant permission to use Blizzard materials or make a
private server officially authorized.

Current Blizzard references:

- <https://www.blizzard.com/en-us/legal/08b946df-660a-40e4-a072-1fbde65173b1/blizzard-end-user-license-agreement>
- <https://worldofwarcraft.blizzard.com/start>

## The two separate prerequisites

Users often confuse the playable client with the server's extracted data. They
are related, but they are not interchangeable.

### 1. Playable client

This is the complete Windows x64 game directory. It runs directly on Windows or
through Proton on Steam Deck. Typical operator-owned locations are:

| Layout | User-facing location | Installer value |
| --- | --- | --- |
| Steam Deck | `/home/deck/Games/WoW-7.3.5-Legion/` | `/home/deck/Games/WoW-7.3.5-Legion` |
| Windows/WSL2 | `C:\Games\WoW-7.3.5-Legion-Client\` | `/mnt/c/Games/WoW-7.3.5-Legion-Client` |

The server installer does not need to write into this directory.

### 2. Extracted server data

The Linux `worldserver` requires four generated directory trees:

```text
LegionData/
`-- Data/
    |-- dbc/
    |-- maps/
    |-- vmaps/
    `-- mmaps/
```

The installer accepts the inner `Data` directory:

```bash
bash install/install.sh \
  --client-dir /absolute/path/to/WoW-7.3.5-Legion \
  --client-build 26365 \
  --data-source /absolute/path/to/LegionData/Data
```

The first two options are prerequisite validation metadata. The installer checks
the client directory in place, requires the user-reported build to be `26365`,
looks for a plausible x64 executable, and reports what it found. It does not
execute, hash, copy, upload, or modify the playable client. Because executable
metadata varies, `--client-build 26365` is the operator's confirmation of the
version visibly shown on the login screen, not a claim that the installer can
independently authenticate the client.

Headless server operators may omit both client options. Supplying only one is an
error: `--client-dir` and `--client-build` must be provided together.

The same information can be supplied non-interactively with environment
variables:

```bash
LEGION_CLIENT_DIR="/absolute/path/to/WoW-7.3.5-Legion" \
LEGION_CLIENT_BUILD=26365 \
LEGION_DATA_SOURCE="/absolute/path/to/LegionData/Data" \
  bash install/install.sh
```

Command-line options take precedence over the corresponding environment values.
The installer prints the detected values to the local terminal and records the
client **path** in the permission-restricted runtime file
`INSTALL_SUMMARY.txt`. It does not copy the client contents into the repository,
runtime, database, summary, or an upload. As with any shell command, users who
consider local paths sensitive should prefer environment variables, choose a
non-identifying directory name, or clear their own shell history.

### Platform path rules

On Steam Deck, enter the ordinary Linux path shown by Dolphin, normally under
`/home/deck` or `/run/media/deck`.

On Windows/WSL2, run the installer inside Ubuntu and translate the Windows drive
to its WSL mount. For example:

```text
Windows client: C:\Games\WoW-7.3.5-Legion-Client
Installer path: /mnt/c/Games/WoW-7.3.5-Legion-Client

Windows data:   C:\Games\LegionData\Data
Installer path: /mnt/c/Games/LegionData/Data
```

Do **not** point `--data-source` at the ordinary CASC `Data` directory inside a
playable client unless it genuinely contains the four extracted directories
shown above. A normal client `Data` directory containing CASC files is not the
server-data package expected by this installer.

The installer validates that all four trees exist and contain files, then copies
them to `~/legion-server-runtime/data` by default. These generated trees remain
local and must not be committed or included in a release.

## Why extraction is not one-click yet

The pinned public Legion core contains source for `mapextractor`,
`vmap4extractor`, `vmap4assembler`, and `mmaps_generator`. Inspection found that
its DB2 extraction path is disabled and part of the map extraction path retains
an older hard-coded build. Advertising those tools as a complete build-26365
pipeline could produce missing or mismatched data.

Until a reproducible extractor is implemented and validated against a client an
operator is authorized to use, the supported installer boundary is:

1. build the open-source server automatically;
2. stop cleanly if the four data trees are absent; and
3. resume with `--skip-build --data-source ...` after the operator supplies
   compatible local data.

No client or client-derived data is uploaded during this process.

## Installation prerequisite checklist

Before running the full installer, collect these three values:

| Installer input | How the user obtains it | Steam Deck example | Windows/WSL2 example |
| --- | --- | --- | --- |
| `--client-dir` | Absolute path to the complete operator-owned playable client | `/home/deck/Games/WoW-7.3.5-Legion` | `/mnt/c/Games/WoW-7.3.5-Legion-Client` |
| `--client-build` | Build visibly shown at the lower-left of the login screen | `26365` | `26365` |
| `--data-source` | Absolute path whose immediate children are `dbc/maps/vmaps/mmaps` | `/home/deck/Games/LegionData/Data` | `/mnt/c/Games/LegionData/Data` |

Run the read-only prerequisite check for the selected platform before compiling.

Steam Deck:

```bash
bash install/install.sh --check \
  --client-dir "/home/deck/Games/WoW-7.3.5-Legion" \
  --client-build 26365 \
  --data-source "/home/deck/Games/LegionData/Data"
```

After it passes, run the full installation with the same values and omit
`--check`:

```bash
bash install/install.sh \
  --client-dir "/home/deck/Games/WoW-7.3.5-Legion" \
  --client-build 26365 \
  --data-source "/home/deck/Games/LegionData/Data"
```

Windows/WSL2, entered in Ubuntu:

```bash
bash install/install.sh --check \
  --client-dir "/mnt/c/Games/WoW-7.3.5-Legion-Client" \
  --client-build 26365 \
  --data-source "/mnt/c/Games/LegionData/Data"
```

After it passes:

```bash
bash install/install.sh \
  --client-dir "/mnt/c/Games/WoW-7.3.5-Legion-Client" \
  --client-build 26365 \
  --data-source "/mnt/c/Games/LegionData/Data"
```

The `--check` command is read-only and should report a nonzero file count for
each of `dbc`, `maps`, `vmaps`, and `mmaps`. The full installer saves build logs
under the runtime `logs` directory and creates `INSTALL_SUMMARY.txt` containing
the actual local paths and routine management commands. It intentionally stores
no database or game-account passwords.

Do not launch the client until installation prints the exact success marker:

```text
LEGION SERVER READY
```

## Verify the client before server troubleshooting

### Visual check

Start the x64 executable directly and read the version displayed on the login
screen. It must say:

```text
Version 7.3.5 (26365) Release x64
```

If it reports another build, stop. Server configuration cannot make a different
protocol build compatible.

Some client executables have incomplete metadata, so the login-screen build is
the decisive check. This project does not publish a universal executable hash
because different authorized locale/install variants may not be identical.

Windows may also expose executable metadata. From PowerShell, substitute the
real path:

```powershell
(Get-Item 'C:\Games\WoW-7.3.5-Legion-Client\Wow-64.exe').VersionInfo |
  Select-Object FileVersion, ProductVersion
```

## Keep an untouched backup

Before changing configuration or installing addons:

1. keep an untouched backup of the operator-owned client;
2. work from a separate copy;
3. do not run the current Battle.net launcher against the legacy copy; and
4. do not place the only copy inside a generated Proton prefix.

A modern launcher may update or replace files. The lab cannot reconstruct a
damaged client.

## Configure the client

Both supported layouts run the client and server on the same physical device,
so both use the local portal address:

```text
SET portal "127.0.0.1"
```

### Windows PC with Ubuntu/WSL2

Close the Windows client. Open:

```text
CLIENT_FOLDER\WTF\Config.wtf
```

Legion uses `portal`; do not substitute the older WoTLK `realmlist.wtf`
instructions. Start the compatible Windows x64 executable directly rather than
the current Battle.net launcher. The Docker server remains inside Ubuntu/WSL2.

### Steam Deck

Close the client and open this file in Kate:

```text
/home/deck/Games/WoW-7.3.5-Legion/WTF/Config.wtf
```

Add the compatible x64 executable to Steam as a Non-Steam Game and launch it
through Proton. Follow [HOWTO-STEAM-DECK.md](../HOWTO-STEAM-DECK.md) for the
complete native server, Proton, controller, and Gaming Mode workflow.

### Account selection

Log in with the local Battle.net-format account created at the worldserver
console. The email-shaped name is only a record in the private server database;
it does not need to be a real mailbox. Use a non-personal example such as
`player@example.invalid` and a unique local password.

If the login screen shows a game-account selector such as `WoW1`, select the
game account created beneath that Battle.net account. That selector is normal.

## Error guide

| Client symptom | What it usually establishes | First checks |
| --- | --- | --- |
| Immediate disconnect / `BLZ51914001` | Authentication endpoint was not completed | `portal`, bnetserver, TCP 1119, exact build |
| `No realms are currently available` / `WOW51900309` | Authentication worked, realm discovery did not | bnetserver/worldserver status, advertised realm address, build 26365 |
| `World server is down` | Account and realm were found, world connection failed | worldserver readiness, ports 8085/8086, four data trees |
| Loading screen hangs and times out | Character handoff began but world session did not finish | worldserver logs, Docker port binding, data compatibility |
| Different version shown on login screen | Client mismatch | Obtain the matching operator-owned build; do not change server build blindly |

Useful server checks:

```bash
cd ~/legion-server-lab
docker compose ps
docker compose logs --tail=200 bnetserver worldserver
```

## Cache and configuration resets

Deleting the client cache is not part of normal installation and does not fix a
wrong client build or unreachable server. If maintainers specifically request a
cache test:

1. close every client process;
2. rename `Cache` to `Cache.old` rather than deleting it;
3. confirm the `portal` line again; and
4. launch the x64 client directly.

The renamed folder is recoverable until the test is complete.

## Client FAQ

### Where is the Legion client download link?

There is no legacy-client download link in this project. Blizzard's official
installer provides currently supported game versions, while this lab requires
the historical build 26365. The project will not direct users to repacks,
torrents, mirrors, or modified executables.

### Can the installer download the client for me?

No. The automation intentionally stops at the client and client-derived-data
boundary.

### Can I use my current retail or Classic client?

No. Matching the expansion name is not enough; the wire protocol must be build
26365.

### Can I share my working client or extracted data with other users?

Not through this project. Do not upload it to GitHub releases, issues, forks,
cloud-drive links, or community bundles.

### Does the server installer modify my client?

No. It inspects the `--client-dir` root and its `Data` subdirectory in place to
validate the prerequisite, but does not execute, copy, upload, or modify client
files. It separately reads the `--data-source` directory you explicitly supply
and copies those extracted server-data trees into Linux storage.

### Is private-server use officially authorized by Blizzard?

No such authorization is provided by this project. Blizzard's EULA expressly
addresses emulation and unauthorized connections. Operators must make their own
informed decision and comply with applicable agreements and law.
