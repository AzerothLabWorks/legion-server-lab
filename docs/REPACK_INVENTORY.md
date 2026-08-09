# Repack Inventory

Inspection date: 2026-08-09

## Location

The archive was extracted outside the Git repository at:

```text
C:\Games\WoW-7.3.5-Legion\[7.3.5] SPP V2 Legion Core
```

Keeping it there avoids copying 52.5 GiB into OneDrive or the repository. Treat
this directory as read-only, untrusted reference material. Do not execute its
programs or startup scripts.

## Archive contents

The archive is a collection of nine separate Windows repacks, not one server:

| Tree | Files | Approx. size |
| --- | ---: | ---: |
| SPP V2 Year 5 Update 3 Repack | 100,109 | 24.67 GiB |
| Thorignir Legion 7.3.5 Repack v2 | 4,873 | 5.29 GiB |
| Thorignir Legion 7.3.5 Repack | 4,531 | 4.12 GiB |
| DekkCoreLegionRepack | 17,610 | 3.76 GiB |
| UnifiedCore Legion Repack | 4,244 | 3.76 GiB |
| Legion Emucoach (26124) | 14,079 | 3.66 GiB |
| LegionCore_7.3.5_Repack_2020_04_25 | 17,268 | 3.33 GiB |
| 1n-game | 4,947 | 2.15 GiB |
| Legioncore | 3,931 | 1.77 GiB |

These trees must not be mixed. Their binaries, schemas, and extracted client
data may come from different source revisions and client builds.

## Primary candidate

The best match for the advertised package is:

```text
SPP V2 Year 5 Update 3 Repack
```

Observed configuration:

- Product metadata: `SPP Legion V2 World Server` and `SPP Legion V2 Battle.net Server`
- Server executable version: `2.0.0.0`
- Core/database label in scripts: `PraeviusCore V2`
- `Game.Build.Version = 26365` in both server configurations
- Battle.net port: `1119`
- Database port: `3310`
- Database names: `legion_auth`, `legion_characters`, `legion_hotfixes`, and
  `legion_world`
- Data path: `..\Data`

The checked-in project must use new credentials rather than the repack's
plaintext defaults.

## Candidate game-data set

The SPP candidate includes:

| Directory | Files | Approx. size |
| --- | ---: | ---: |
| `dbc` | 6,719 | 1.78 GiB |
| `maps` | 17,538 | 0.84 GiB |
| `mmaps` | 14,444 | 8.66 GiB |
| `vmaps` | 43,752 | 10.50 GiB |
| `cameras` | 27 | negligible |
| `gt` | 32 | negligible |

This data is a compatibility candidate only. It should be mounted read-only
during the first controlled startup and must not be committed.

## Open questions

1. Identify a source repository and exact revision matching PraeviusCore/SPP
   Legion V2.
2. Determine whether that source builds on Linux without relying on untracked
   private changes.
3. Export the four databases from the bundled MySQL data directory without
   running the bundled server stack.
4. Verify database server/version compatibility before importing into an
   isolated container.
5. Confirm that the available client executable is actually build 26365.

