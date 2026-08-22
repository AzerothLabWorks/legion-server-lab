USE `legion_world`;

-- This second pass targets nearby duplicates that are not byte-identical
-- because their position or facing differs slightly. Keep the rule narrow:
-- the entry must have exactly two static spawns in the entire world, both
-- rows must otherwise be structurally equal, and neither row may have
-- GUID-specific behavior.
CREATE TABLE IF NOT EXISTS `azerothlab_removed_creature_spawns` LIKE `creature`;

START TRANSACTION;

DROP TEMPORARY TABLE IF EXISTS `_alw_two_spawn_entries`;
CREATE TEMPORARY TABLE `_alw_two_spawn_entries` ENGINE=InnoDB AS
SELECT `id`
FROM `creature`
WHERE `skipClone` = 0
GROUP BY `id`
HAVING COUNT(*) = 2;

ALTER TABLE `_alw_two_spawn_entries`
    ADD PRIMARY KEY (`id`);

DROP TEMPORARY TABLE IF EXISTS `_alw_nearby_singleton_candidates`;
CREATE TEMPORARY TABLE `_alw_nearby_singleton_candidates` (
    `guid` BIGINT(20) UNSIGNED NOT NULL,
    `keep_guid` BIGINT(20) UNSIGNED NOT NULL,
    `entry` MEDIUMINT(8) UNSIGNED NOT NULL,
    `reason` VARCHAR(120) NOT NULL,
    PRIMARY KEY (`guid`)
) ENGINE=InnoDB;

INSERT INTO `_alw_nearby_singleton_candidates` (`guid`, `keep_guid`, `entry`, `reason`)
SELECT
    `newer`.`guid`,
    `older`.`guid`,
    `older`.`id`,
    'nearby structurally-equivalent singleton NPC'
FROM `_alw_two_spawn_entries` `pair_entry`
INNER JOIN `creature` `older`
    ON `older`.`id` = `pair_entry`.`id` AND `older`.`skipClone` = 0
INNER JOIN `creature` `newer`
    ON `newer`.`id` = `older`.`id`
   AND `newer`.`guid` > `older`.`guid`
   AND `newer`.`skipClone` = 0
INNER JOIN `creature_template` `template`
    ON `template`.`entry` = `older`.`id`
LEFT JOIN `creature_template_wdb` `wdb`
    ON `wdb`.`Entry` = `older`.`id`
WHERE
    `older`.`map` = `newer`.`map`
    AND `older`.`zoneId` = `newer`.`zoneId`
    AND `older`.`areaId` = `newer`.`areaId`
    AND `older`.`spawnMask` = `newer`.`spawnMask`
    AND `older`.`phaseMask` = `newer`.`phaseMask`
    AND COALESCE(`older`.`PhaseId`, '') = COALESCE(`newer`.`PhaseId`, '')
    -- At most 15 yards apart, including elevation.
    AND POW(`older`.`position_x` - `newer`.`position_x`, 2)
      + POW(`older`.`position_y` - `newer`.`position_y`, 2)
      + POW(`older`.`position_z` - `newer`.`position_z`, 2) <= 225
    -- Adjacent GUIDs are commonly intentional paired spawns in the source DB.
    AND CAST(`newer`.`guid` AS SIGNED) - CAST(`older`.`guid` AS SIGNED) > 25
    -- Position and orientation may differ; every other spawn property must match.
    AND `older`.`modelid` = `newer`.`modelid`
    AND `older`.`equipment_id` = `newer`.`equipment_id`
    AND `older`.`spawntimesecs` = `newer`.`spawntimesecs`
    AND `older`.`spawndist` = `newer`.`spawndist`
    AND `older`.`currentwaypoint` = `newer`.`currentwaypoint`
    AND `older`.`curhealth` = `newer`.`curhealth`
    AND `older`.`curmana` = `newer`.`curmana`
    AND `older`.`MovementType` = `newer`.`MovementType`
    AND `older`.`npcflag` = `newer`.`npcflag`
    AND `older`.`npcflag2` = `newer`.`npcflag2`
    AND `older`.`unit_flags` = `newer`.`unit_flags`
    AND `older`.`dynamicflags` = `newer`.`dynamicflags`
    AND COALESCE(`older`.`ScriptName`, '') = COALESCE(`newer`.`ScriptName`, '')
    AND `older`.`AiID` = `newer`.`AiID`
    AND `older`.`MovementID` = `newer`.`MovementID`
    AND `older`.`MeleeID` = `newer`.`MeleeID`
    AND `older`.`isActive` = `newer`.`isActive`
    AND `older`.`personal_size` = `newer`.`personal_size`
    AND `older`.`isTeemingSpawn` = `newer`.`isTeemingSpawn`
    AND `older`.`unit_flags3` = `newer`.`unit_flags3`
    -- Prefer interactable/service/quest NPCs. For very widely separated GUID
    -- generations, a gossip flag or unique NPC title is also strong evidence.
    AND (
        EXISTS (SELECT 1 FROM `npc_vendor` `x` WHERE `x`.`entry` = `older`.`id`)
        OR EXISTS (SELECT 1 FROM `creature_queststarter` `x` WHERE `x`.`id` = `older`.`id`)
        OR EXISTS (SELECT 1 FROM `creature_questender` `x` WHERE `x`.`id` = `older`.`id`)
        OR (
            CAST(`newer`.`guid` AS SIGNED) - CAST(`older`.`guid` AS SIGNED) > 1000
            AND (`template`.`npcflag` <> 0 OR COALESCE(`wdb`.`Title`, '') <> '')
        )
    )
    -- Preserve both rows if either has spawn-specific behavior.
    AND NOT (
        EXISTS (SELECT 1 FROM `creature_addon` `x`
                WHERE `x`.`guid` IN (`older`.`guid`, `newer`.`guid`))
        OR EXISTS (SELECT 1 FROM `game_event_creature` `x`
                   WHERE `x`.`guid` IN (`older`.`guid`, `newer`.`guid`))
        OR EXISTS (SELECT 1 FROM `pool_creature` `x`
                   WHERE `x`.`guid` IN (`older`.`guid`, `newer`.`guid`))
        OR EXISTS (SELECT 1 FROM `creature_formations` `x`
                   WHERE `x`.`memberGUID` IN (`older`.`guid`, `newer`.`guid`)
                      OR `x`.`leaderGUID` IN (`older`.`guid`, `newer`.`guid`))
        OR EXISTS (SELECT 1 FROM `creature_transport` `x`
                   WHERE `x`.`guid` IN (`older`.`guid`, `newer`.`guid`))
        OR EXISTS (SELECT 1 FROM `linked_respawn` `x`
                   WHERE `x`.`guid` IN (`older`.`guid`, `newer`.`guid`)
                      OR `x`.`linkedGuid` IN (`older`.`guid`, `newer`.`guid`))
        OR EXISTS (SELECT 1 FROM `conversation_creature` `x`
                   WHERE `x`.`creatureGuid` IN (`older`.`guid`, `newer`.`guid`))
        OR EXISTS (SELECT 1 FROM `smart_scripts` `x`
                   WHERE `x`.`entryorguid` IN (
                       -CAST(`older`.`guid` AS SIGNED),
                       -CAST(`newer`.`guid` AS SIGNED)
                   ))
        OR EXISTS (SELECT 1 FROM `game_event_model_equip` `x`
                   WHERE `x`.`guid` IN (`older`.`guid`, `newer`.`guid`))
        OR EXISTS (SELECT 1 FROM `game_event_npcflag` `x`
                   WHERE `x`.`guid` IN (`older`.`guid`, `newer`.`guid`))
        OR EXISTS (SELECT 1 FROM `game_event_npc_vendor` `x`
                   WHERE `x`.`guid` IN (`older`.`guid`, `newer`.`guid`))
    );

INSERT IGNORE INTO `azerothlab_removed_creature_spawns`
SELECT `creature`.*
FROM `creature`
INNER JOIN `_alw_nearby_singleton_candidates` `candidate`
    ON `candidate`.`guid` = `creature`.`guid`;

DELETE `creature`
FROM `creature`
INNER JOIN `_alw_nearby_singleton_candidates` `candidate`
    ON `candidate`.`guid` = `creature`.`guid`;

SET @azerothlab_removed_nearby_singleton_count = ROW_COUNT();

COMMIT;

SELECT @azerothlab_removed_nearby_singleton_count
    AS `removed_nearby_singleton_npc_spawns`;

DROP TEMPORARY TABLE IF EXISTS `_alw_nearby_singleton_candidates`;
DROP TEMPORARY TABLE IF EXISTS `_alw_two_spawn_entries`;
