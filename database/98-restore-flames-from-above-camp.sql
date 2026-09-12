USE `legion_world`;

-- Flames from Above (25574) retains Emerald Flameweaver 40856, its authored
-- flight path, and completion SmartAI, but the horn has no script binding and
-- the three Twilight Infiltrators that identify the camp are absent.

INSERT INTO `item_script_names` (`Id`, `ScriptName`)
VALUES (55122, 'item_tholos_horn')
ON DUPLICATE KEY UPDATE `ScriptName` = VALUES(`ScriptName`);

-- Restore a conservative three-NPC camp around the verified objective point.
-- Coordinate-based guards keep this migration repeatable without reserving
-- global creature GUIDs.
INSERT INTO `creature`
    (`id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `PhaseId`,
     `modelid`, `equipment_id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `spawntimesecs`, `spawndist`, `currentwaypoint`,
     `curhealth`, `curmana`, `MovementType`)
SELECT 40882, 1, 616, 5032, 1, 1, '', 0, 0,
       5723.0, -3328.0, 1601.8, 0.7, 300, 2, 0, 0, 0, 1
WHERE NOT EXISTS (
    SELECT 1 FROM `creature`
    WHERE `id` = 40882 AND `map` = 1
      AND `position_x` BETWEEN 5718.0 AND 5728.0
      AND `position_y` BETWEEN -3333.0 AND -3323.0
);

INSERT INTO `creature`
    (`id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `PhaseId`,
     `modelid`, `equipment_id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `spawntimesecs`, `spawndist`, `currentwaypoint`,
     `curhealth`, `curmana`, `MovementType`)
SELECT 40882, 1, 616, 5032, 1, 1, '', 0, 0,
       5740.0, -3331.0, 1601.8, 2.4, 300, 2, 0, 0, 0, 1
WHERE NOT EXISTS (
    SELECT 1 FROM `creature`
    WHERE `id` = 40882 AND `map` = 1
      AND `position_x` BETWEEN 5735.0 AND 5745.0
      AND `position_y` BETWEEN -3336.0 AND -3326.0
);

INSERT INTO `creature`
    (`id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `PhaseId`,
     `modelid`, `equipment_id`, `position_x`, `position_y`, `position_z`,
     `orientation`, `spawntimesecs`, `spawndist`, `currentwaypoint`,
     `curhealth`, `curmana`, `MovementType`)
SELECT 40882, 1, 616, 5032, 1, 1, '', 0, 0,
       5748.0, -3315.0, 1601.8, 3.8, 300, 2, 0, 0, 0, 1
WHERE NOT EXISTS (
    SELECT 1 FROM `creature`
    WHERE `id` = 40882 AND `map` = 1
      AND `position_x` BETWEEN 5743.0 AND 5753.0
      AND `position_y` BETWEEN -3320.0 AND -3310.0
);

SELECT `Id`, `ScriptName`
FROM `item_script_names`
WHERE `Id` = 55122;

SELECT `guid`, `id`, `map`, `zoneId`, `areaId`,
       `position_x`, `position_y`, `position_z`, `MovementType`
FROM `creature`
WHERE `id` = 40882 AND `map` = 1
ORDER BY `guid`;
