USE `legion_world`;

-- Between the Trees (29125) asks the player to intercept three fast, ghostly
-- Spirits of Malorne (52176). The imported template uses a hostile faction,
-- does not select SmartAI despite retaining capture rows, and limits each
-- spirit to a three-yard wander. Restore the friendly proximity encounter.

CREATE TABLE IF NOT EXISTS `azerothlab_malorne_spirit_template_backup`
LIKE `creature_template`;

INSERT IGNORE INTO `azerothlab_malorne_spirit_template_backup`
SELECT * FROM `creature_template` WHERE `entry` = 52176;

CREATE TABLE IF NOT EXISTS `azerothlab_malorne_spirit_spawn_backup`
LIKE `creature`;

INSERT IGNORE INTO `azerothlab_malorne_spirit_spawn_backup`
SELECT * FROM `creature` WHERE `id` = 52176;

CREATE TABLE IF NOT EXISTS `azerothlab_malorne_spirit_smartai_backup`
LIKE `smart_scripts`;

INSERT IGNORE INTO `azerothlab_malorne_spirit_smartai_backup`
SELECT * FROM `smart_scripts`
WHERE `entryorguid` = 52176 AND `source_type` = 0;

CREATE TABLE IF NOT EXISTS `azerothlab_malorne_spirit_condition_backup`
LIKE `conditions`;

INSERT IGNORE INTO `azerothlab_malorne_spirit_condition_backup`
SELECT * FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` = 52176;

-- Faction 2252 is used by the two other Spirit of Malorne templates and by
-- Malorne himself in this database. Flags 0x00000002 (non-attackable) and
-- 0x00000200 (immune to NPCs) keep players and nearby fire creatures from
-- pulling the quest spirits. The existing fast run speed is retained.
UPDATE `creature_template`
SET `faction` = 2252,
    `AIName` = 'SmartAI',
    `unit_flags` = `unit_flags` | 514
WHERE `entry` = 52176;

-- Preserve the seven authored locations while allowing the spirits to travel
-- far enough for their original interception gameplay to be visible.
UPDATE `creature`
SET `spawndist` = 25,
    `MovementType` = 1
WHERE `id` = 52176
  AND `map` = 1
  AND `zoneId` = 616
  AND `areaId` = 4861;

-- Presence of Malorne (96990) can reach the spirit only while it is attackable,
-- making the imported spell-hit event incompatible with NPC immunity. Use one
-- explicit out-of-combat proximity event instead: grant one credit to the
-- nearby player, then immediately despawn the captured spirit.
DELETE FROM `smart_scripts`
WHERE `entryorguid` = 52176
  AND `source_type` = 0
  AND `id` IN (0, 1, 2, 3);

INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`,
     `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`,
     `action_type`, `action_param1`, `action_param2`, `action_param3`,
     `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`,
     `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    (52176, 0, 0, 1, 10, 0, 100, 1, 1, 4, 1000, 1000,
     33, 52176, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0,
     'Spirit of Malorne - Player within 4 yards - Grant one capture credit'),
    (52176, 0, 1, 0, 61, 0, 100, 1, 0, 0, 0, 0,
     41, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
     'Spirit of Malorne - Linked - Despawn immediately after capture');

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 22
  AND `SourceGroup` IN (1, 3)
  AND `SourceEntry` = 52176
  AND `SourceId` = 0;

INSERT INTO `conditions`
    (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`,
     `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`,
     `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
     `NegativeCondition`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
    (22, 1, 52176, 0, 0, 9, 0, 29125, 0, 0, 0, 0, '',
     'Spirit of Malorne proximity capture requires Between the Trees');

SELECT `entry`, `faction`, `speed_walk`, `speed_run`, `AIName`, `unit_flags`, `ScriptName`
FROM `creature_template`
WHERE `entry` = 52176;

SELECT `guid`, `id`, `position_x`, `position_y`, `position_z`,
       `spawndist`, `MovementType`
FROM `creature`
WHERE `id` = 52176
ORDER BY `guid`;
