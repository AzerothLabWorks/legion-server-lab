# Companion Auto-Loot

The Legion lab includes a conservative server-side auto-loot prototype inspired
by the companion-triggered quality-of-life feature used in the WoTLK QA stack.

## Behavior

Auto-loot runs only when all of the following are true:

- `CompanionAutoLoot.Enable` is enabled;
- the player is alive, in the world, and not already looting;
- the player has an active non-combat companion;
- combat state satisfies the configurable `OutOfCombatOnly` policy; and
- an eligible creature corpse is within the configured radius.

The radius is a maximum distance: with `Radius = 40`, eligible corpses from
melee range through 40 yards away are included. It is not a 40-yard-only ring.

The implementation processes at most one corpse per interval. It uses the
normal Legion loot and inventory paths so quest eligibility, inventory capacity,
personal loot, blocked group rolls, achievements, and corpse cleanup continue
to be handled by the core.

Quest items receive special treatment matching Legion's native loot opcode:
their `is_blocked` field is used for quest-loot bookkeeping and does not mean
the item is waiting for a group roll. This allows a companion pass that first
collects currency to also collect an eligible quest drop as soon as the core
makes it available. A corpse that still contains eligible loot remains in the
normal interval scan for another bounded pass.

The first version deliberately excludes game-object chests, gathering nodes,
skinning, pickpocketing, and item-created loot.

## Configuration

The local lab enables these settings in `worldserver.conf`:

```ini
CompanionAutoLoot.Enable = 1
CompanionAutoLoot.Radius = 40
CompanionAutoLoot.IntervalMs = 1500
CompanionAutoLoot.OutOfCombatOnly = 0
CompanionAutoLoot.RequireNonCombatCompanion = 1
```

The private lab deliberately permits looting during combat. Set
`OutOfCombatOnly` back to `1` if concurrent loot windows interfere with an
encounter or another addon.

Changes require `.reload config` if supported by the running core, or a
worldserver restart.

## Test Procedure

1. Empty several bag slots and record the current money amount.
2. Dismiss all non-combat companions, kill a normal creature, and verify its
   corpse remains lootable.
3. Summon any non-combat companion and wait near the corpse. Verify its money
   and eligible items enter the normal inventory.
4. While fighting multiple creatures, kill one and remain within 40 yards.
   Verify it is looted within roughly two seconds even though combat continues.
5. Kill a creature at approximately 35-40 yards with a ranged character. Verify
   the companion retrieves its eligible loot without opening the loot window.
6. Fill the bags, kill another creature, and verify items are not lost when the
   inventory rejects them.
7. In a group, verify items requiring a roll are not silently assigned.
8. For a quest that drops an item and currency from the same creature, verify
   both rewards are collected without manually opening the corpse.
9. Dismiss the companion and verify automatic looting stops.

Report the character, map, creature, group loot mode, item IDs, and exact steps
for any duplication, loss, stuck corpse, or loot-window behavior.
