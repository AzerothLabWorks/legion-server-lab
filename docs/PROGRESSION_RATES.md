# Progression Rates

The lab provides safe progression presets so operators do not need to edit
`worldserver.conf` by hand. New installations use the `balanced` preset unless
another preset is selected explicitly.

| Preset | Reputation | Profession skill gain | XP | Intended experience |
| --- | ---: | ---: | ---: | --- |
| `blizzlike` | 1x | 1 point | 1x | Original source rates |
| `balanced` | 2x | 2 points | 1.25x | Recommended local-lab pacing |
| `accelerated` | 3x | 3 points | 1.5x | Faster alternate-character progression |

The XP rate applies equally to kills, quests, exploration, and gathering. The
profession value is the number of skill points awarded when a normal crafting
or gathering skill-up succeeds; it does not make grey recipes grant skill and
does not bypass profession caps. Reputation rewards retain their normal faction,
quest, and standing restrictions. Low-level reputation modifiers remain at 1x
so they do not multiply the selected global reputation rate a second time.

## Change an existing server

Run one of these commands from the repository:

```bash
bash scripts/configure-rates.sh balanced
bash scripts/configure-rates.sh blizzlike
bash scripts/configure-rates.sh accelerated
```

The helper updates the local `.env` and generated runtime configuration. If no
characters are online, it safely restarts only `worldserver` and the rates take
effect immediately. If anyone is online, it leaves the session running and asks
an administrator to run `.reload config` in game, or the operator to run the
helper again after logout.

For custom values:

```bash
bash scripts/configure-rates.sh custom \
  --reputation 4 \
  --profession 3 \
  --xp 1.25
```

Reputation accepts 0.1 through 10, profession skill gain accepts whole numbers
from 1 through 10, and XP accepts 0.1 through 5. Use `--no-restart` to save and
apply the generated config without restarting a running worldserver.

## Select a preset during installation

The community installer accepts the same named presets:

```bash
bash install/install.sh \
  --rate-preset balanced \
  --client-dir /path/to/client \
  --client-build 26365 \
  --data-source /path/to/Data
```

The chosen values are recorded in `.env` and in the permission-restricted
installation summary. Custom numeric rates can be selected after installation
with `scripts/configure-rates.sh`.
