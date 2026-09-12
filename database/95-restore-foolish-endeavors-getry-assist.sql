USE `legion_world`;

-- Foolish Endeavors (11705) is only partially represented in the archived
-- Legion database. Accepting the quest wakes Varidus the Flenser (25618), but
-- Shadowstalker Getry (25729) never descends from the tower or joins combat.
-- Restore Getry's canonical 16-point descent and start his assisted attack at
-- the final point. Keep Varidus's existing visibility and quest-credit logic.
-- Explicitly stop the escort and make its endpoint Getry's temporary home so
-- combat evades cannot send him back up the tower. Start reciprocal combat:
-- Getry attacks Varidus and the encounter's intended High Overlord Saurfang
-- helper appears to take Varidus's attention and supply meaningful damage.

CREATE TABLE IF NOT EXISTS `azerothlab_foolish_endeavors_smartai_backup`
LIKE `smart_scripts`;

CREATE TABLE IF NOT EXISTS `azerothlab_foolish_endeavors_waypoints_backup`
LIKE `waypoints`;

CREATE TABLE IF NOT EXISTS `azerothlab_foolish_endeavors_template_backup`
LIKE `creature_template`;

START TRANSACTION;

INSERT IGNORE INTO `azerothlab_foolish_endeavors_smartai_backup`
SELECT `script`.*
FROM `smart_scripts` `script`
WHERE `script`.`entryorguid` IN (25618, 25729, 25749)
  AND `script`.`source_type` = 0;

INSERT IGNORE INTO `azerothlab_foolish_endeavors_waypoints_backup`
SELECT `path`.*
FROM `waypoints` `path`
WHERE `path`.`entry` = 25729;

INSERT IGNORE INTO `azerothlab_foolish_endeavors_template_backup`
SELECT `template`.*
FROM `creature_template` `template`
WHERE `template`.`entry` = 25749;

-- In the original encounter Saurfang inherits SmartAI by transforming from
-- the summoned necrolord. The compact repair summons his final template
-- directly, so it must opt into SmartAI itself.
UPDATE `creature_template`
SET `faction` = CASE `entry`
        WHEN 25618 THEN 1982 -- Varidus: Cult encounter faction
        WHEN 25749 THEN 1979 -- Saurfang: Warsong encounter faction
    END,
    `AIName` = CASE
        WHEN `entry` = 25749 THEN 'SmartAI'
        ELSE `AIName`
    END
WHERE `entry` IN (25618, 25749);

-- The path is preserved from the Wrath encounter and follows the tower ramp
-- to the farm below, ending within melee range of Varidus.
INSERT IGNORE INTO `waypoints`
    (`entry`, `pointid`, `position_x`, `position_y`, `position_z`, `point_comment`)
VALUES
    (25729,  1, 3111.10, 6580.77, 94.8496, 'Shadowstalker Getry - Foolish Endeavors'),
    (25729,  2, 3110.10, 6586.86, 91.3752, 'Shadowstalker Getry - Foolish Endeavors'),
    (25729,  3, 3113.44, 6592.44, 91.3642, 'Shadowstalker Getry - Foolish Endeavors'),
    (25729,  4, 3119.61, 6593.75, 91.3783, 'Shadowstalker Getry - Foolish Endeavors'),
    (25729,  5, 3125.42, 6589.70, 91.3783, 'Shadowstalker Getry - Foolish Endeavors'),
    (25729,  6, 3125.23, 6582.04, 88.7871, 'Shadowstalker Getry - Foolish Endeavors'),
    (25729,  7, 3118.36, 6581.91, 86.2718, 'Shadowstalker Getry - Foolish Endeavors'),
    (25729,  8, 3117.46, 6584.56, 85.5313, 'Shadowstalker Getry - Foolish Endeavors'),
    (25729,  9, 3118.02, 6589.55, 83.4635, 'Shadowstalker Getry - Foolish Endeavors'),
    (25729, 10, 3120.60, 6589.66, 82.7010, 'Shadowstalker Getry - Foolish Endeavors'),
    (25729, 11, 3127.65, 6590.03, 79.6948, 'Shadowstalker Getry - Foolish Endeavors'),
    (25729, 12, 3127.04, 6587.56, 79.2347, 'Shadowstalker Getry - Foolish Endeavors'),
    (25729, 13, 3125.78, 6583.56, 77.7368, 'Shadowstalker Getry - Foolish Endeavors'),
    (25729, 14, 3123.47, 6576.21, 78.2142, 'Shadowstalker Getry - Foolish Endeavors'),
    (25729, 15, 3122.13, 6567.54, 79.0694, 'Shadowstalker Getry - Foolish Endeavors'),
    (25729, 16, 3124.17, 6554.20, 78.9804, 'Shadowstalker Getry - Foolish Endeavors');

-- Chain the already-correct quest-accept event into Getry's movement. The
-- original action continues to reveal Varidus before the descent begins.
UPDATE `smart_scripts`
SET `link` = 1
WHERE `entryorguid` = 25729
  AND `source_type` = 0
  AND `id` = 0
  AND `link` = 0
  AND `event_type` = 19
  AND `event_param1` = 11705
  AND `action_type` = 45
  AND `action_param1` = 1
  AND `action_param2` = 1
  AND `target_type` = 11
  AND `target_param1` = 25618;

SET @azerothlab_getry_accept_event_linked = (
    SELECT COUNT(*)
    FROM `smart_scripts`
    WHERE `entryorguid` = 25729
      AND `source_type` = 0
      AND `id` = 0
      AND `link` = 1
      AND `event_type` = 19
      AND `event_param1` = 11705
);

-- Replace only rows owned by this migration. This makes the repair safe to
-- reapply to an installation that received its original movement-only form.
DELETE FROM `smart_scripts`
WHERE `entryorguid` = 25729
  AND `source_type` = 0
  AND `id` BETWEEN 1 AND 7
  AND (`comment` LIKE 'Shadowstalker Getry - Foolish Endeavors%'
       OR `comment` LIKE 'Shadowstalker Getry - Waypoint 16 reached - %');

DELETE FROM `smart_scripts`
WHERE `entryorguid` = 25618
  AND `source_type` = 0
  AND `id` BETWEEN 3 AND 4
  AND `comment` LIKE 'Varidus the Flenser - Foolish Endeavors - Engage%';

DELETE FROM `smart_scripts`
WHERE `entryorguid` = 25749
  AND `source_type` = 0
  AND `id` BETWEEN 0 AND 3
  AND `comment` LIKE 'High Overlord Saurfang - Foolish Endeavors%';

INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`,
     `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`,
     `action_type`, `action_param1`, `action_param2`, `action_param3`,
     `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`,
     `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    -- Linked from quest acceptance: follow the restored path at running speed.
    (25729, 0, 1, 0, 61, 0, 100, 1,
     0, 0, 0, 0,
     53, 1, 25729, 0, 0, 0, 0,
     1, 0, 0, 0, 0, 0, 0, 0,
     'Shadowstalker Getry - Foolish Endeavors accepted - Start descent path'),

    -- At the farm: anchor the endpoint, stop the escort, become aggressive,
    -- summon the encounter's intended Saurfang helper, and start combat.
    (25729, 0, 2, 3, 40, 0, 100, 1,
     16, 0, 0, 0,
     101, 0, 0, 0, 0, 0, 0,
     1, 0, 0, 0, 0, 0, 0, 0,
     'Shadowstalker Getry - Foolish Endeavors endpoint - Set home position'),
    (25729, 0, 3, 4, 61, 0, 100, 1,
     0, 0, 0, 0,
     55, 0, 0, 0, 0, 0, 0,
     1, 0, 0, 0, 0, 0, 0, 0,
     'Shadowstalker Getry - Foolish Endeavors endpoint - Stop descent path'),
    (25729, 0, 4, 5, 61, 0, 100, 1,
     0, 0, 0, 0,
     8, 2, 0, 0, 0, 0, 0,
     1, 0, 0, 0, 0, 0, 0, 0,
     'Shadowstalker Getry - Foolish Endeavors endpoint - Set aggressive'),
    (25729, 0, 5, 6, 61, 0, 100, 1,
     0, 0, 0, 0,
     12, 25749, 4, 300000, 0, 0, 0,
     8, 0, 0, 0, 3126.00, 6539.00, 80.05, 1.52,
     'Shadowstalker Getry - Foolish Endeavors endpoint - Summon Saurfang'),
    (25729, 0, 6, 7, 61, 0, 100, 1,
     0, 0, 0, 0,
     45, 2, 1, 0, 0, 0, 0,
     19, 25618, 40, 0, 0, 0, 0, 0,
     'Shadowstalker Getry - Foolish Endeavors endpoint - Signal Varidus'),
    (25729, 0, 7, 0, 61, 0, 100, 1,
     0, 0, 0, 0,
     49, 0, 0, 0, 0, 0, 0,
     19, 25618, 40, 0, 0, 0, 0, 0,
     'Shadowstalker Getry - Foolish Endeavors endpoint - Attack Varidus'),

    -- Direct Varidus toward the durable helper. The player's tap remains the
    -- loot recipient used by Varidus's existing quest-credit action.
    (25618, 0, 3, 4, 38, 0, 100, 1,
     2, 1, 0, 0,
     2, 1982, 0, 0, 0, 0, 0,
     1, 0, 0, 0, 0, 0, 0, 0,
     'Varidus the Flenser - Foolish Endeavors - Engage Saurfang faction'),
    (25618, 0, 4, 0, 61, 0, 100, 1,
     0, 0, 0, 0,
     49, 0, 0, 0, 0, 0, 0,
     19, 25749, 60, 0, 0, 0, 0, 0,
     'Varidus the Flenser - Foolish Endeavors - Engage Saurfang attack'),

    -- Saurfang is the original encounter's decisive helper. Apply his authored
    -- encounter faction and rage effect, then immediately engage Varidus.
    (25749, 0, 0, 1, 54, 0, 100, 1,
     0, 0, 0, 0,
     2, 1979, 0, 0, 0, 0, 0,
     1, 0, 0, 0, 0, 0, 0, 0,
     'High Overlord Saurfang - Foolish Endeavors summoned - Set faction'),
    (25749, 0, 1, 2, 61, 0, 100, 1,
     0, 0, 0, 0,
     11, 45950, 2, 0, 0, 0, 0,
     1, 0, 0, 0, 0, 0, 0, 0,
     'High Overlord Saurfang - Foolish Endeavors summoned - Cast rage'),
    (25749, 0, 2, 3, 61, 0, 100, 1,
     0, 0, 0, 0,
     8, 2, 0, 0, 0, 0, 0,
     1, 0, 0, 0, 0, 0, 0, 0,
     'High Overlord Saurfang - Foolish Endeavors summoned - Set aggressive'),
    (25749, 0, 3, 0, 61, 0, 100, 1,
     0, 0, 0, 0,
     49, 0, 0, 0, 0, 0, 0,
     19, 25618, 60, 0, 0, 0, 0, 0,
     'High Overlord Saurfang - Foolish Endeavors summoned - Attack Varidus');

COMMIT;

SELECT
    @azerothlab_getry_accept_event_linked AS `getry_accept_event_linked`,
    (SELECT COUNT(*) FROM `waypoints` WHERE `entry` = 25729)
        AS `getry_descent_waypoints`,
    (SELECT COUNT(*) FROM `smart_scripts`
     WHERE `entryorguid` = 25729
       AND `source_type` = 0
       AND `id` BETWEEN 0 AND 7) AS `getry_event_rows`,
    (SELECT COUNT(*) FROM `smart_scripts`
     WHERE `entryorguid` = 25618
       AND `source_type` = 0
       AND `event_type` = 6
       AND `action_type` = 15
       AND `action_param1` = 11705) AS `varidus_credit_rows_preserved`,
    (SELECT COUNT(*) FROM `smart_scripts`
     WHERE `entryorguid` = 25618
       AND `source_type` = 0
       AND `id` = 4
       AND `event_type` = 61
       AND `link` = 0
       AND `action_type` = 49
       AND `target_param1` = 25749) AS `varidus_engage_helper_rows`,
    (SELECT COUNT(*) FROM `smart_scripts`
     WHERE `entryorguid` = 25749
       AND `source_type` = 0
       AND `id` BETWEEN 0 AND 3) AS `saurfang_helper_rows`,
    (SELECT COUNT(*) FROM `creature_template`
     WHERE `entry` = 25749
       AND `faction` = 1979
       AND `AIName` = 'SmartAI') AS `saurfang_smartai_enabled`,
    (SELECT COUNT(*) FROM `creature_template`
     WHERE `entry` = 25618
       AND `faction` = 1982) AS `varidus_encounter_faction_enabled`;
