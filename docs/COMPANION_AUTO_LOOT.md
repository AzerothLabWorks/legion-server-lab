# Companion Auto-Loot

The Legion lab includes a conservative server-side auto-loot prototype inspired
by the companion-triggered quality-of-life feature used in the WoTLK QA stack.

## Behavior

Auto-loot runs only when all of the following are true:

- `CompanionAutoLoot.Enable` is enabled;
- the player is alive, in the world, and not already looting;
- the player has an active non-combat companion;
- the player is out of combat when `OutOfCombatOnly` is enabled; and
- an eligible creature corpse is within the configured radius.

The implementation processes at most one corpse per interval. It uses the
normal Legion loot and inventory paths so quest eligibility, inventory capacity,
personal loot, blocked group rolls, achievements, and corpse cleanup continue
to be handled by the core.

The first version deliberately excludes game-object chests, gathering nodes,
skinning, pickpocketing, and item-created loot.

## Configuration

The local lab enables these settings in `worldserver.conf`:

```ini
CompanionAutoLoot.Enable = 1
CompanionAutoLoot.Radius = 30
CompanionAutoLoot.IntervalMs = 1500
CompanionAutoLoot.OutOfCombatOnly = 1
CompanionAutoLoot.RequireNonCombatCompanion = 1
```

Changes require `.reload config` if supported by the running core, or a
worldserver restart.

## Test Procedure

1. Empty several bag slots and record the current money amount.
2. Dismiss all non-combat companions, kill a normal creature, and verify its
   corpse remains lootable.
3. Summon any non-combat companion and wait near the corpse. Verify its money
   and eligible items enter the normal inventory.
4. Kill a creature at range and walk within 30 yards after combat. Verify the
   corpse is looted within roughly two seconds.
5. Fill the bags, kill another creature, and verify items are not lost when the
   inventory rejects them.
6. In a group, verify items requiring a roll are not silently assigned.
7. Dismiss the companion and verify automatic looting stops.

Report the character, map, creature, group loot mode, item IDs, and exact steps
for any duplication, loss, stuck corpse, or loot-window behavior.
