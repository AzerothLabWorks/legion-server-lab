# Source Baseline

## Selected build candidate

- Repository: `https://github.com/Legion-Pandaria-Preservation-Project/LegionCore-7.3.5V2`
- Preservation mirror: `https://github.com/AzerothLabWorks/LegionCore-7.3.5V2-preservation`
- Branch: `V2`
- Commit: `6c41d0faa23474bf9e76a4811b144d43e9545bab`
- Commit date: 2025-03-11
- License declared by repository: GPL-2.0

The AzerothLabWorks preservation mirror retains the upstream branches, tags,
and pull-request snapshots. Tag `baseline-2025-03-11` resolves to the pinned
commit above. The mirror is private during provenance review, so the community
installer continues to use the public upstream by default. Authorized
maintainers can select the mirror without changing the installer:

```bash
LEGION_CORE_URL=https://github.com/AzerothLabWorks/LegionCore-7.3.5V2-preservation.git \
  bash install/install.sh
```

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

Low-level quest discovery is enabled in the generated runtime configuration by
setting `Quests.LowLevelHideDiff = -1`. The archived default is four levels, so
a level-54 character receives the low-level status for ordinary level 47–49
Tanaris quests. The client can then suppress their normal `!` unless its trivial
quest tracking option is enabled, even though the quests remain valid and award
XP. Disabling that presentation threshold preserves `CanSeeStartQuest`, accept
conditions, prerequisites, phases, events, race/class restrictions, and minimum
levels; it changes only the status icon for an otherwise-eligible starter.

Regression test: with a character above the original four-level threshold,
visit an NPC offering an otherwise-eligible lower-level quest. Confirm the `!`
is visible over the giver and on the minimap without enabling the client's
trivial-quest filter. Confirm that unmet prerequisites, wrong-faction quests,
inactive events, and quests above the character's permitted level remain hidden
or unavailable as before.

The idempotent startup QoL script now teaches the complete set of character
flight licenses checked by this build: Flight Master's License (90267), Wisdom
of the Four Winds (115913), Draenor Pathfinder (191645), and Broken Isles
Pathfinder (233368), in addition to the riding ranks and Cold Weather Flying it
already supplied. `StartupQoL.ZoneFlying` controls the added group independently.
The change does not modify `AREA_FLAG_NO_FLY_ZONE` or the hard exclusions used
for dungeons, battlegrounds, active battlefields, scenario maps, and Argus.

Regression test: log an existing character into Eastern Kingdoms or Kalimdor,
Pandaria, Draenor, and the Broken Isles and confirm a normal flying mount can
take off in an outdoor flyable area. Confirm the same mount is rejected in an
explicit no-fly area and on Argus, and verify that ground mounts remain usable.

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

Automatic caster fallback is restricted to the creature database's explicit
`UNIT_CLASS_MAGE` classification by
`0027-keep-melee-creatures-in-melee-ai.patch`. Imported
`creature_template_spell` rows include auxiliary and artifact abilities that
are not reliable evidence that a Warrior-, Rogue-, or Paladin-class creature is
a ranged caster. Without this guard, melee creatures such as **Syndicate
Thief** (entry 24477) could stop at spell range, occasionally cast a special
ability, and never close far enough to auto-attack.

Regression test: aggro one and then two **Syndicate Thieves** at Stromgarde
Keep. Every Thief must chase into melee range and auto-attack, while retaining
Backstab, Disarm, and Poison. Then pull a **Skeletal Mage** (entry 203) from
range and verify that it still stops to cast Frostbolt.

Melee special abilities are restored by
`0028-restore-melee-special-abilities.patch`. Some ordinary melee templates are
assigned `SmartAI` even though neither the template nor the individual spawn
has a SmartAI script. Those templates now fall through to the core's normal
`AggressorAI`. AggressorAI also merges and deduplicates the legacy
`spell1`-`spell8` fields with `creature_template_spell`, matching the behavior
already used for the caster fallback. This lets melee enemies chase and swing
while retaining their intended combat abilities.

Regression test: fight **Syndicate Thief** (entry 24477), **Syndicate Prowler**
(entry 2588), and **Boulderfist Brute** (entry 2566). They must close into melee,
auto-attack, and intermittently use abilities such as Backstab, Disarm, Poison,
Fist of Stone, and Stomp without spamming them. Fight a **Skeletal Mage** (entry
203) and **Boulderfist Magus** (entry 2567) to verify that ranged casters still
use Frostbolt plus their other configured abilities.

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

Permanently sleeping Syndicate Thieves are corrected by
`database/83-remove-broken-syndicate-thief-sleep.sql`. Entry 24477 inherited
the `Sleeping Sleep` aura (spell 42648) from `creature_template_addon`, but has
no proximity or aggro script capable of removing it. The migration preserves
the original addon and spell rows in repository-owned backup tables, removes
the aura from this one hostile template, and removes the same decorative spell
from its combat spell list. Other templates that intentionally sleep, such as
Off-Duty Siegeworkers, are not changed.

Regression test: approach several **Syndicate Thieves** in Stromgarde Keep.
They must be standing and must aggro normally at the expected hostile range.
Fight at least one to confirm that Backstab, Disarm, and Poison remain available
without the creature applying a permanent sleep state. Confirm that unrelated
ambient sleeping creatures retain their intended pose.

Dormant authored creature patrols are restored by
`database/84-restore-dormant-creature-waypoints.sql`. The archived world marks
thousands of spawns as waypoint movers while omitting the
`creature_addon.path_id` link required by the core, even though their
`waypoint_data` remains present under the conventional spawn-GUID path ID. The
migration restores only paths with at least two nodes whose first node lies
within 25 yards of the spawn, avoiding unrelated path-ID collisions. Existing
addon state is preserved and every restored link is recorded in a dedicated
audit table.

Regression test: visit several outdoor camps and settlements that contain
restored waypoint candidates. Patrol-capable creatures must follow their local
authored routes, pause normally at configured nodes, enter combat when engaged,
and return to their paths after evade. No creature should run toward a distant
or unrelated area after spawning.

Safe outdoor ambient movement is added by
`database/85-add-safe-outdoor-ambient-wander.sql`. The source database leaves
many ordinary combat creatures at `MovementType = 0`, producing stationary
rows of enemies that never vary their facing or position. The migration gives
only normal, ground-capable, loot-bearing creatures on outdoor continent maps
a three-yard random wander. It excludes services, quest starters and enders,
rares and elites, vehicles, phased or instanced actors, scripts, active
movement/pose addons, authored paths, formations, events, pools, transports,
linked respawns, and conversation actors. Harmless addon bytes such as weapon
sheath state do not prevent movement. Original rows are retained for recovery.

Regression test: observe ordinary unscripted outdoor enemies such as the
Vilebranch mobs around Jintha'Alor. They should occasionally move and turn
within a few yards of their spawn while retaining normal aggro, melee or caster
behavior, evade, and respawn. Vendors, quest givers, posed NPCs, elites,
dungeon actors, and scripted encounters must remain unchanged.

Missing Vilebranch combat rotations are restored by
`database/86-restore-vilebranch-combat-ai.sql`. Entries 2640 through 2647 are
marked `SmartAI` and retain their spell lists, but the archived world contains
no entry- or spawn-level `smart_scripts` for them. Generic fallback AI keeps
the creatures attackable, but cannot reproduce their intended range,
friendly-health, positional, and low-health conditions. The migration installs
an old-core-compatible SmartAI translation only for entries that still have no
script rows. It uses the valid Legion Shoot spell (74613) instead of the
forbidden legacy Shoot spell (15547), and backs up any pre-existing rows before
making a change.

Regression test: fight a **Vilebranch Blood Drinker** (2646) in melee for at
least 15 seconds and confirm it casts Blood Leech. Fight a **Vilebranch Soul
Eater** (2647) for at least 12 seconds and confirm Soul Bite; Dark Offering is
conditional on an injured friendly creature within 10 yards. Also test a
**Witch Doctor** (2640) or **Shadowcaster** (2642) from range, a **Headhunter**
(2641) or **Shadow Hunter** (2645) from both ranged and melee distance, and a
**Berserker** (2643) below 30 percent health. Their special abilities must be
interleaved at the documented cooldowns, ranged enemies must reposition when
outside their attack range, and none may spam an ability every update.

Rocket Rescue's vehicle interaction is restored by
`database/87-restore-rocket-rescue-vehicle-smartai.sql`. The Steamwheedle
Rescue Balloon (40604) has a valid spell-click action that summons the Balloon
Throwing Station vehicle (40511), boards the player with spell 46598, and
starts its authored path. Its template nevertheless has an empty `AIName`, so
the core selects `NullCreatureAI` and never executes that existing action
chain. The migration enables SmartAI only for entry 40604 and only after
verifying every expected click, summon, boarding, and vehicle record. The
original template is retained in an audit table.

The summoned entry is a vehicle named **Balloon Throwing Station** whose
archived display is invisible, while the visible rescue-balloon model remains
on the stationary click proxy. The same migration backs up the WDB row and
assigns that matching model to the moving vehicle. The original Life-Rocket
and Pirate-Destroying Bomb use trajectory destinations that the archived core
shortens along the vehicle's facing rather than the player's intended target.
`0031-load-rocket-rescue-script.patch` and `overlays/rocket_rescue.cpp` add a
quest-only correction: a selected valid survivor or blockader is preferred,
with the nearest valid target in the original 10–70 yard range as a fallback.
The original triggered impact spells remain responsible for credit and damage.

Regression test: accept **Rocket Rescue** (25050) in Gadgetzan and click the
**Steamwheedle Rescue Balloon**. The click must summon the Balloon Throwing
Station, expose the quest vehicle actions, show the moving balloon, and begin
the authored flight. Select a **Steamwheedle
Survivor** and use **Deliver Life-Rocket**; then select a **Southsea Blockader**
and use **Pirate-Destroying Bomb**. Each payload must resolve against the chosen
valid target and advance the matching objective. Repeat once without a
selection to verify the nearby-target fallback. The quest is semi-functional:
the client may render the character below the balloon and may animate payloads
straight ahead even though the intended target receives server-side credit.
Confirm that ordinary spell-click NPCs, vehicles, and trajectory spells
elsewhere retain their previous behavior.

BattlePay profession delivery is repaired by
`0029-fix-battlepay-professions.patch` and
`0030-load-battlepay-scripts.patch`. The archived core added profession product
objects to the generic script registry but never added them to the name-indexed
registry used by shop validation and delivery. Its BattlePay loader was also
orphaned by a mismatched function name and never called during startup.
Purchases could therefore deduct coins while silently skipping all profession
rewards. Product scripts now load during startup and register with both systems.

Profession products explicitly teach the base profession spell, set the skill
to the product's 800-point cap, learn its available trade spells, and retain the
normal two-primary-profession limit. The repack's unrelated level-90 shop gate
is removed so secondary professions and valid primary profession slots can be
learned during ordinary lab play. Tool-bearing professions grant one
Blacksmith Hammer (`5956`), Mining Pick (`2901`), Skinning Knife (`7005`), or
Fishing Pole (`6256`), checking bags and bank first to prevent duplicates.

Regression test: use a low-level character with at least one free bag slot and
purchase First Aid. Confirm that coins are deducted once, First Aid appears at
800, and its spells are available. Purchase Fishing and confirm that one
Fishing Pole is added. On a character with free primary-profession slots,
purchase Blacksmithing, Mining, or Skinning and confirm that its matching tool
is granted. Repeat validation from the shop and confirm an already-maxed skill
is rejected before another charge.

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
