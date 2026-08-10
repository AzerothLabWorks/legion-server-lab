# Level-1 Startup QoL

The Legion Lab world server grants an idempotent starter package whenever a character at level 1 or higher logs in.

## Rewards

- Apprentice, Journeyman, Expert, Artisan, and Master Riding
- Cold Weather Flying
- Bloodfang Widow
- Headless Horseman's Mount
- A minimum balance of 20,000 gold
- Four Hexweave Bags (30 slots each), delivered to the backpack for manual equipping
- Magma Rageling added directly to the account battle-pet journal

Existing characters at any level receive missing rewards on their next login. Repeated logins do not duplicate spells or the companion, do not reduce a higher gold balance, and only top the Hexweave Bag count up to four.

## Version limitation

Liquid Hot Magma Slug and Headless Horseman's Ghoulish Charger were released after Legion and do not exist in client build 7.3.5.26365. A server cannot safely grant assets the client does not contain. Headless Horseman's Mount (spell 48025) is used as the Legion-compatible charger.

## Configuration

The installer enables the package. The generated `worldserver.conf` supports:

```ini
StartupQoL.Enable = 1
StartupQoL.Level = 1
StartupQoL.Riding = 1
StartupQoL.Mounts = 1
StartupQoL.Money = 1
StartupQoL.Bags = 1
StartupQoL.MagmaRageling = 1
```

Set an individual feature to `0` and restart the world server to disable it. `StartupQoL.Level` is the minimum eligible level, not an exact-level restriction.

## IDs pinned for build 26365

| Reward | Type | ID |
|---|---|---:|
| Apprentice Riding | Spell | 33388 |
| Journeyman Riding | Spell | 33391 |
| Expert Riding | Spell | 34090 |
| Artisan Riding | Spell | 34091 |
| Master Riding | Spell | 90265 |
| Cold Weather Flying | Spell | 54197 |
| Bloodfang Widow | Spell | 213115 |
| Headless Horseman's Mount | Spell | 48025 |
| Hexweave Bag | Item | 114821 |
| Magma Rageling | Creature/species lookup | 115138 |
