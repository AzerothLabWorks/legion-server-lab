# Distribution Boundary

This project publishes reproducible source-build automation and original lab
improvements. It does not publish a turnkey repack.

## Included in this repository

- build and Docker orchestration;
- configuration templates;
- patches and source overlays for the pinned GPL-licensed core;
- versioned, original database migrations;
- validation and smoke tests; and
- installation, operation, and development documentation.

The installer clones the public upstream source from its original repository at
a pinned commit and builds the Linux server locally.

## Not included

- World of Warcraft clients or launchers;
- modified client executables;
- Blizzard assets or archives;
- repack archives or repack binaries;
- prebuilt server binaries;
- client-derived data such as `dbc`, `maps`, `vmaps`, or `mmaps`;
- database dumps or live runtime volumes; or
- passwords, account records, or other secrets.

## Client-derived data

Every operator must supply compatible build-26365 data from a client they are
authorized to use. The installer may copy that data between the operator's own
Steam Deck storage locations, but the project does not upload, mirror, seed, or
bundle it. Generated data must not be attached to issues or committed to forks.
The practical version and configuration requirements are documented in
[CLIENT_SETUP.md](CLIENT_SETUP.md).

The pinned core's extraction utilities are not represented as a complete
build-26365 solution. Its DB2 extraction code is disabled and an older build is
hard-coded in part of the map extractor, so automatic extraction remains an
open engineering item rather than an advertised feature.

## Database and dependencies

The pinned upstream source currently contains a base database archive consumed
by the build workflow. The lab repository does not mirror that archive. Other
dependencies and container images are fetched from their stated upstream
projects or registries at installation time and remain subject to their own
licenses and terms.

## Release rules

Project releases should contain only the Git-tracked source materials in this
repository. Do not create a release zip or installer that adds a client, repack,
extracted data, database dump, compiled server tree, or populated `.env` file.

Contributors should run these checks before publishing:

```bash
bash tests/install-smoke.sh
bash tests/verify-patches.sh
git status --short
git ls-files | grep -Ei '\.(exe|dll|7z|rar|zip|dump|sql\.gz)$' && \
  echo 'Review unexpected binary/archive files' || true
```

The repository `.gitignore` is a guardrail, not a substitute for reviewing the
actual commit and release contents.

## Independence and operator responsibility

World of Warcraft and Blizzard Entertainment are trademarks or property of
their respective owners. AzerothLabWorks is independent and is not affiliated
with or endorsed by Blizzard Entertainment. Operators and contributors are
responsible for complying with applicable licenses, terms, and local law. This
document describes the project's technical distribution boundary and is not
legal advice.
