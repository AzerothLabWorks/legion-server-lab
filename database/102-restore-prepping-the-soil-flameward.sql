USE `legion_world`;

-- Prepping the Soil (25502) advertises several Flameward locations, but this
-- database retains only gameobject 202902 and its nearby event controller.
-- Restore the missing ward at the verified Regrowth POI (about 33,53) and
-- reuse the complete activation/defense SmartAI already authored for 202902.

CREATE TABLE IF NOT EXISTS `azerothlab_flameward_template_backup`
LIKE `gameobject_template`;

INSERT IGNORE INTO `azerothlab_flameward_template_backup`
SELECT * FROM `gameobject_template` WHERE `entry` = 202927;

CREATE TABLE IF NOT EXISTS `azerothlab_flameward_smartai_backup`
LIKE `smart_scripts`;

INSERT IGNORE INTO `azerothlab_flameward_smartai_backup`
SELECT * FROM `smart_scripts`
WHERE `entryorguid` = 202927 AND `source_type` = 1;

UPDATE `gameobject_template`
SET `AIName` = 'SmartGameObjectAI'
WHERE `entry` = 202927 AND `name` = 'Flameward';

DELETE FROM `smart_scripts`
WHERE `entryorguid` = 202927 AND `source_type` = 1;

INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`,
     `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`,
     `action_type`, `action_param1`, `action_param2`, `action_param3`,
     `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`,
     `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    (202927, 1, 0, 1, 64, 0, 100, 0, 0, 0, 0, 0,
     45, 1, 1, 0, 0, 0, 0, 11, 40461, 15, 0, 0, 0, 0, 0,
     'Flameward - Gossip Hello - Start nearby defense controller'),
    (202927, 1, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0,
     85, 75470, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0,
     'Flameward - Linked - Cast Flameward Activated on player'),
    (202927, 1, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0,
     33, 40461, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0,
     'Flameward - Linked - Grant Flameward Activated credit');

-- The quest POI is centered at (4678,-2536). The first reported character
-- position was airborne; the post-defense logout position below is verified
-- ground inside the same marker. The invisible controller sits 3.6 yards above
-- the ward, matching the surviving authored pair.
INSERT INTO `gameobject`
    (`id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `PhaseId`,
     `position_x`, `position_y`, `position_z`, `orientation`,
     `rotation0`, `rotation1`, `rotation2`, `rotation3`,
     `spawntimesecs`, `animprogress`, `AiID`, `state`, `ScriptName`,
     `isActive`, `personal_size`)
SELECT 202927, 1, 616, 4861, 1, 1, '',
       4642.33, -2499.20, 1145.58, 0.0,
       0.0, 0.0, 0.0, 1.0, 300, 255, 0, 1, '', 0, 0
WHERE NOT EXISTS (
    SELECT 1 FROM `gameobject`
    WHERE `id` = 202927 AND `map` = 1
      AND `position_x` BETWEEN 4637.0 AND 4647.0
      AND `position_y` BETWEEN -2504.0 AND -2494.0
);

-- Relocate the initial repair if it was installed using the airborne report.
UPDATE `gameobject`
SET `position_x` = 4642.33,
    `position_y` = -2499.20,
    `position_z` = 1145.58
WHERE `id` = 202927
  AND `map` = 1
  AND `position_x` BETWEEN 4640.0 AND 4650.0
  AND `position_y` BETWEEN -2560.0 AND -2550.0
  AND `position_z` BETWEEN 1160.0 AND 1170.0;

DELETE duplicate_ward
FROM `gameobject` duplicate_ward
JOIN `gameobject` retained_ward
  ON retained_ward.`id` = duplicate_ward.`id`
 AND retained_ward.`map` = duplicate_ward.`map`
 AND retained_ward.`position_x` = duplicate_ward.`position_x`
 AND retained_ward.`position_y` = duplicate_ward.`position_y`
 AND retained_ward.`position_z` = duplicate_ward.`position_z`
 AND retained_ward.`guid` < duplicate_ward.`guid`
WHERE duplicate_ward.`id` = 202927
  AND duplicate_ward.`map` = 1
  AND duplicate_ward.`position_x` = 4642.33
  AND duplicate_ward.`position_y` = -2499.20
  AND duplicate_ward.`position_z` = 1145.58;

INSERT INTO `creature`
    (`id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `PhaseId`,
     `modelid`, `equipment_id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `spawntimesecs`, `spawndist`, `currentwaypoint`,
     `curhealth`, `curmana`, `MovementType`, `ScriptName`)
SELECT 40461, 1, 616, 4861, 1, 65535, '',
       0, 0, 4642.33, -2499.20, 1149.18,
       0.0, 1, 0, 0, 0, 0, 0, ''
WHERE NOT EXISTS (
    SELECT 1 FROM `creature`
    WHERE `id` = 40461 AND `map` = 1
      AND `position_x` BETWEEN 4637.0 AND 4647.0
      AND `position_y` BETWEEN -2504.0 AND -2494.0
);

UPDATE `creature`
SET `position_x` = 4642.33,
    `position_y` = -2499.20,
    `position_z` = 1149.18
WHERE `id` = 40461
  AND `map` = 1
  AND `position_x` BETWEEN 4640.0 AND 4650.0
  AND `position_y` BETWEEN -2560.0 AND -2550.0
  AND `position_z` BETWEEN 1160.0 AND 1175.0;

DELETE duplicate_controller
FROM `creature` duplicate_controller
JOIN `creature` retained_controller
  ON retained_controller.`id` = duplicate_controller.`id`
 AND retained_controller.`map` = duplicate_controller.`map`
 AND retained_controller.`position_x` BETWEEN 4637.0 AND 4647.0
 AND retained_controller.`position_y` BETWEEN -2504.0 AND -2494.0
 AND retained_controller.`position_z` BETWEEN 1144.0 AND 1154.0
 AND retained_controller.`guid` < duplicate_controller.`guid`
WHERE duplicate_controller.`id` = 40461
  AND duplicate_controller.`map` = 1
  AND duplicate_controller.`position_x` BETWEEN 4637.0 AND 4647.0
  AND duplicate_controller.`position_y` BETWEEN -2504.0 AND -2494.0
  AND duplicate_controller.`position_z` BETWEEN 1144.0 AND 1154.0;

SELECT `entry`, `name`, `AIName`
FROM `gameobject_template` WHERE `entry` = 202927;

SELECT `guid`, `id`, `position_x`, `position_y`, `position_z`, `phaseMask`
FROM `gameobject` WHERE `id` = 202927 ORDER BY `guid`;

SELECT `guid`, `id`, `position_x`, `position_y`, `position_z`, `phaseMask`
FROM `creature` WHERE `id` = 40461 ORDER BY `guid`;
