# Source Baseline

## Selected build candidate

- Repository: `https://github.com/Legion-Pandaria-Preservation-Project/LegionCore-7.3.5V2`
- Branch: `V2`
- Commit: `6c41d0faa23474bf9e76a4811b144d43e9545bab`
- Commit date: 2025-03-11
- License declared by repository: GPL-2.0

The source configuration lists client builds 26124, 26365, 26654, 26822,
26899, and 26972 as available. Its named full world/hotfix database snapshots
are labeled for build 26124, so configuration-level protocol support does not
prove that all DB2/hotfix content is correct for build 26365.

## Relationship to SPP V2

The downloaded SPP V2 Year 5 Update 3 server identifies itself as PraeviusCore
V2. No matching public source revision was found. Community discussions describe
the SPP V2 source as unpublished. Therefore, the public V2 core is a build
candidate, not a source-equivalent reproduction of the repack.

The SPP database and extracted data will not be imported until the public core
successfully compiles and its expected schema is compared with the repack.

## Source checkout

```text
~/legion-server-sources/LegionCore-7.3.5V2
```

The source checkout is intentionally outside the lab repository. The lab pins
the revision and owns only the reproducible build/runtime orchestration.

The build container uses Ubuntu 18.04 because this code relies on the legacy
Boost.Asio strand API. Ubuntu 20.04's Boost 1.71 fails at `boost::asio::strand`
before the core itself can compile; Ubuntu 18.04 provides Boost 1.65, close to
the upstream project's stated Boost 1.64 toolchain.

Repository-owned compatibility patches are kept under `patches/` and applied
idempotently by the build script. The first patch corrects the upstream cotire
module path for CMake versions older than 3.16.

The lab also carries a creature lifecycle guard for the pinned core. Periodic
damage can kill a creature inside `Unit::Update`; the upstream Legion branch
then runs that dead creature's AI once before checking its death state. That
final AI pass can restart chase movement and combat after death cleanup, making
a corpse follow the player and retain combat until its leash resets. Patch
`0017-stop-dead-creature-ai-update.patch` checks the death state immediately
after `Unit::Update` and leaves the later post-AI death check in place.

Regression test: kill ordinary creatures with direct damage and with a
damage-over-time effect. In both cases the corpse must stop immediately and the
player must leave combat when no other hostile creature is engaged.

Native Legion bag cleanup is restored by
`0018-fix-native-bag-sorting.patch`. Upstream disabled backpack sorting after
the implementation treated normal backpack item slots as equipped bag IDs.
The patch uses the four equipped bag slots when consolidating items and
re-enables the existing `CMSG_SORT_BAGS` handler. This also restores the sort
button included with Bagnon 7.3.5 without requiring a client-side addon fork.

Regression test: place items and partial stacks across the backpack and all
four equipped bags, click Bagnon's **Clean Up Bags** button, and confirm that
stacks consolidate and items reorder without disappearing. Log out and back in
once to confirm that the sorted inventory persists.

Legion quest POI cache invalidation is restored by
`0019-refresh-quest-poi-on-status-change.patch`. The core defines the
zero-payload `SMSG_QUEST_POI_CHANGED` packet and supports the client's follow-up
quest POI and completion-NPC queries, but the pinned source never sends the
invalidation packet. The patch sends it shortly after every native quest update
so the client discards an objective-area marker after completion and re-queries
the configured quest ender.

Regression test: accept a quest with a mapped objective away from its turn-in
NPC, complete the final objective, and confirm that the map/minimap `?` moves
from the objective area to the quest giver without relogging or reloading the
UI. Also abandon an incomplete mapped quest and confirm its POI disappears.

Multi-quest NPC acceptance flow is restored by
`0020-refresh-quest-menu-after-accept.patch`. The pinned handler previously
closed the quest interaction unconditionally after accepting any quest. The
patch rebuilds the same giver's quest menu and sends it again when a different
starter quest remains available. It also honors Legion's explicit launch and
suppress-gossip-on-accept flags so scripted quest interactions retain control.

Regression test: interact with an NPC offering at least two simultaneously
available quests, accept the first, and confirm the next quest or remaining
quest list appears without closing and re-engaging the NPC. Accept the final
quest and confirm the dialog closes normally. Also accept a quest from an item
and confirm no NPC menu is opened.

Feral Lunge travel speed is corrected by
`0021-speed-up-feral-lunge.patch`. The pinned core computes most parabolic jump
speeds from distance and vertical speed, but already overrides charge-like
jumps such as Wild Charge to 45 yards per second. Spell 196884 was absent from
that override, allowing an NPC aggroed during the slower arc to run beneath the
fixed melee-contact destination. The patch adds only Feral Lunge to the
existing fast-jump group. It does not change destination selection, landing
callbacks, player facing, creature chase logic, or other movement spells.

Regression test: stand still and cast Feral Lunge from near maximum range at a
stationary hostile NPC that begins running toward the shaman. Confirm the
parabolic animation remains, the target does not cross beneath the shaman, and
the shaman lands in melee range with the target in front. Repeat several times
on flat terrain and compare ordinary Lightning Bolt pulls and normal melee
combat; non-Feral-Lunge movement and creature approach behavior must remain
unchanged.

Completed quest turn-in markers are anchored to their configured ender spawns
by `0022-anchor-quest-turnin-pois-to-enders.patch`. The world database contains
POI rows gathered from multiple verified client builds, and some historical
completion blobs share a point index with newer objective geometry. The stock
loader merges those points, which can place the completion marker between the
real quest giver and an unrelated objective area. The patch leaves objective
and navigation POIs unchanged. For an `ObjectiveIndex = -1` completion blob it
selects the nearest configured creature or gameobject ender on the same map and
uses that precise spawn position. This is faction-neutral and applies to all
quests with a static configured ender.

Regression test: complete **Fine Linen Goods** (quest 83) without turning it in
and open the Elwynn Forest map. Its selected completion marker must be at Sara
Timberlain in Eastvale Logging Camp, not between Eastvale and Goldshire. Confirm
that **The Jasperlode Mine** still points to Marshal Dughan in Goldshire and
that an incomplete quest continues to show its normal objective area.

Incomplete objective markers are isolated to their matching captured client
build by `0025-match-quest-pois-to-verified-build.patch`. The archived database
combines `quest_poi` and `quest_poi_points` records from several builds, but its
point-table primary key does not include `VerifiedBuild`. Reused point indexes
can consequently attach a build-26124 objective to a build-23877 completion
point at the quest giver. The loader now groups coordinates by quest, point
index, and verified build; rejects cross-build point attachment; and retains
all shapes from only the newest usable build of each logical POI blob. A
build-zero coordinate remains available as the narrow legacy fallback.

Regression test: while **Wanted! Marez Cowl** (quest 26024), **Wand over Fist**
(quest 26036), and **Wanted! Otto and Falconcrest** (quest 26079) are incomplete,
open the Arathi Highlands map at Refuge Pointe. Their objective markers must
identify their remote objective areas rather than Captain Nials or Skuerto.
Move away from the camp and reopen the map to confirm that the same objective
locations remain visible. After completing a quest, its `?` must still move to
the configured turn-in NPC.

Unscripted enemy caster behavior is restored by
`0024-restore-unscripted-caster-ai.patch`. The archived world database assigns
many creatures to `SmartAI` without providing an entry-level or spawn-level
SmartAI script. Those creatures previously ignored valid ranged combat spells
in `creature_template_spell`, ran into melee range, and only auto-attacked. The
fallback selects `CasterAI` only for ordinary hostile creatures with a real
offensive ranged spell and no working C++ or SmartAI script. Pets, summons,
vehicles, guards, triggers, critters, world bosses, and scripted encounters
retain their existing AI. `CasterAI` now merges both Legion creature-spell
storage formats, maintains a usable casting distance, and can still make a
melee swing if its victim closes the gap. Set
`CreatureAI.CasterFallback.Enable = 0` for an immediate configuration rollback.

Regression test: pull a **Skeletal Mage** (entry 203) from outside melee range.
It must stop at casting distance and use Frostbolt rather than running directly
to the player and relying only on melee. Repeat with an ordinary melee creature
and a scripted caster; the melee creature must retain normal chase behavior and
the scripted caster must retain its encounter AI.

Zero-cooldown creature spell loops are prevented by
`0026-enforce-caster-ai-cooldowns.patch`. Much of the imported Legion spell data
has no native recovery time, which previously caused `CasterAI` to reschedule an
instant ability after only 500 milliseconds. The scheduler now preserves real
cooldowns when present and otherwise uses the core's existing AI safeguards:
5-10 seconds for utility abilities, 10-20 seconds for damage, and 15-30 seconds
for control. It also skips recasting a positive combat buff while that aura is
already active.

Regression test: fight a **Boulderfist Brute** (entry 2566), **Boulderfist
Magus** (entry 2567), **Syndicate Prowler** (entry 2588), and **Syndicate Thief**
(entry 24477). Fire Blast, Knockdown, Stomp, Disarm, and other special abilities
must be separated by visible normal attacks instead of repeating every combat
update. Enrage- or Bloodlust-style buffs must not be reapplied continuously
while active. Each creature must remain capable of using its special abilities.

## Verified build

The pinned revision successfully built on 2026-08-09 using the repository's
Ubuntu 18.04 build container with precompiled headers enabled. The install tree
is kept outside Git at `~/legion-server-runtime/server` and contains:

- `bin/worldserver` (Linux x86-64 ELF, approximately 74 MiB)
- `bin/bnetserver` (Linux x86-64 ELF, approximately 5.8 MiB)
- distribution configuration files under `etc/`

The binaries intentionally link against Ubuntu 18.04-era libraries, including
Boost 1.65, OpenSSL 1.1, and MySQL client 20. They therefore need an Ubuntu
18.04-compatible runtime container and should not be launched directly on the
SteamOS host.

Build command:

```bash
LEGION_BUILD_JOBS=2 bash "$HOME/legion-server-lab/scripts/build-core.sh"
```
