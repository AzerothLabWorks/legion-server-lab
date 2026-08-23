USE `legion_world`;

-- Give ordinary unscripted outdoor combat creatures a small amount of idle
-- life. This is intentionally narrower than a global MovementType rewrite:
-- services, quest givers, scripted actors, rares/elites, vehicles, events,
-- formations, phased actors, instances, authored paths, and posed creatures
-- are excluded. Three yards is enough to break the static mannequin effect
-- without materially moving a pack or changing its intended encounter area.

CREATE TABLE IF NOT EXISTS `azerothlab_ambient_wander_creature_backup`
    LIKE `creature`;

-- Maintainers may set this to 1 in the same mysql session to inspect the
-- filtered candidates without changing creature movement.
SET @azerothlab_ambient_wander_dry_run =
    COALESCE(@azerothlab_ambient_wander_dry_run, 0);

START TRANSACTION;

DROP TEMPORARY TABLE IF EXISTS `_alw_ambient_wander_candidates`;
CREATE TEMPORARY TABLE `_alw_ambient_wander_candidates` (
    `guid` BIGINT(20) UNSIGNED NOT NULL,
    `entry` MEDIUMINT(8) UNSIGNED NOT NULL,
    PRIMARY KEY (`guid`),
    KEY `idx_ambient_entry` (`entry`)
) ENGINE=InnoDB;

INSERT INTO `_alw_ambient_wander_candidates` (`guid`, `entry`)
SELECT `creature`.`guid`, `creature`.`id`
FROM `creature`
INNER JOIN `creature_template` `template`
    ON `template`.`entry` = `creature`.`id`
INNER JOIN `creature_template_wdb` `wdb`
    ON `wdb`.`Entry` = `creature`.`id`
WHERE `creature`.`MovementType` = 0
  AND `creature`.`spawndist` = 0
  AND `creature`.`map` IN (0, 1, 530, 571, 870, 1116, 1220)
  AND `creature`.`zoneId` <> 0
  AND `creature`.`areaId` <> 0
  AND `creature`.`spawnMask` = 1
  AND `creature`.`phaseMask` = 1
  AND COALESCE(`creature`.`PhaseId`, '') = ''
  AND `creature`.`npcflag` = 0
  AND `creature`.`npcflag2` = 0
  AND `creature`.`unit_flags` = 0
  AND `creature`.`unit_flags3` = 0
  AND `creature`.`dynamicflags` = 0
  AND COALESCE(`creature`.`ScriptName`, '') = ''
  AND `creature`.`skipClone` = 0
  AND `creature`.`isTeemingSpawn` = 0
  AND `template`.`npcflag` = 0
  AND `template`.`npcflag2` = 0
  AND `template`.`lootid` <> 0
  AND `template`.`VehicleId` = 0
  AND (`template`.`InhabitType` & 1) <> 0
  AND `template`.`ScriptName` = ''
  AND `template`.`AIName` IN ('', 'SmartAI', 'AggressorAI')
  AND `wdb`.`Type` NOT IN (8, 10)
  AND `wdb`.`Classification` = 0
  AND `wdb`.`FlagQuest` = 0;

-- Remove every candidate that participates in authored or spawn-specific
-- behavior. Separate indexed deletes keep this practical on MySQL 5.7.
DELETE `candidate` FROM `_alw_ambient_wander_candidates` `candidate`
INNER JOIN `creature_addon` `reference` ON `reference`.`guid` = `candidate`.`guid`
WHERE `reference`.`path_id` <> 0
   OR `reference`.`mount` <> 0
   OR `reference`.`emote` <> 0
   OR COALESCE(TRIM(`reference`.`auras`), '') <> '';

DELETE `candidate` FROM `_alw_ambient_wander_candidates` `candidate`
INNER JOIN `creature_template_addon` `reference` ON `reference`.`entry` = `candidate`.`entry`
WHERE `reference`.`path_id` <> 0
   OR `reference`.`mount` <> 0
   OR `reference`.`emote` <> 0
   OR COALESCE(TRIM(`reference`.`auras`), '') <> '';

DELETE `candidate` FROM `_alw_ambient_wander_candidates` `candidate`
INNER JOIN `waypoint_data` `reference` ON `reference`.`id` = `candidate`.`guid`;

DELETE `candidate` FROM `_alw_ambient_wander_candidates` `candidate`
INNER JOIN `smart_scripts` `reference`
    ON `reference`.`source_type` = 0
   AND `reference`.`entryorguid` = `candidate`.`entry`;

DELETE `candidate` FROM `_alw_ambient_wander_candidates` `candidate`
INNER JOIN `smart_scripts` `reference`
    ON `reference`.`source_type` = 0
   AND `reference`.`entryorguid` = -CAST(`candidate`.`guid` AS SIGNED);

DELETE `candidate` FROM `_alw_ambient_wander_candidates` `candidate`
INNER JOIN `creature_queststarter` `reference` ON `reference`.`id` = `candidate`.`entry`;

DELETE `candidate` FROM `_alw_ambient_wander_candidates` `candidate`
INNER JOIN `creature_questender` `reference` ON `reference`.`id` = `candidate`.`entry`;

DELETE `candidate` FROM `_alw_ambient_wander_candidates` `candidate`
INNER JOIN `game_event_creature` `reference` ON `reference`.`guid` = `candidate`.`guid`;

DELETE `candidate` FROM `_alw_ambient_wander_candidates` `candidate`
INNER JOIN `pool_creature` `reference` ON `reference`.`guid` = `candidate`.`guid`;

DELETE `candidate` FROM `_alw_ambient_wander_candidates` `candidate`
INNER JOIN `creature_formations` `reference`
    ON `reference`.`memberGUID` = `candidate`.`guid`
    OR `reference`.`leaderGUID` = `candidate`.`guid`;

DELETE `candidate` FROM `_alw_ambient_wander_candidates` `candidate`
INNER JOIN `creature_transport` `reference` ON `reference`.`guid` = `candidate`.`guid`;

DELETE `candidate` FROM `_alw_ambient_wander_candidates` `candidate`
INNER JOIN `linked_respawn` `reference`
    ON `reference`.`guid` = `candidate`.`guid`
    OR `reference`.`linkedGuid` = `candidate`.`guid`;

DELETE `candidate` FROM `_alw_ambient_wander_candidates` `candidate`
INNER JOIN `conversation_creature` `reference`
    ON `reference`.`creatureGuid` = `candidate`.`guid`;

DELETE `candidate` FROM `_alw_ambient_wander_candidates` `candidate`
INNER JOIN `game_event_model_equip` `reference` ON `reference`.`guid` = `candidate`.`guid`;

DELETE `candidate` FROM `_alw_ambient_wander_candidates` `candidate`
INNER JOIN `game_event_npcflag` `reference` ON `reference`.`guid` = `candidate`.`guid`;

DELETE `candidate` FROM `_alw_ambient_wander_candidates` `candidate`
INNER JOIN `game_event_npc_vendor` `reference` ON `reference`.`guid` = `candidate`.`guid`;

SELECT COUNT(*) INTO @azerothlab_ambient_wander_candidates
FROM `_alw_ambient_wander_candidates`;

SELECT
    `candidate`.`entry`,
    COALESCE(`wdb`.`Name1`, '') AS `creature_name`,
    COUNT(*) AS `candidate_count`
FROM `_alw_ambient_wander_candidates` `candidate`
LEFT JOIN `creature_template_wdb` `wdb`
    ON `wdb`.`Entry` = `candidate`.`entry`
GROUP BY `candidate`.`entry`, `wdb`.`Name1`
ORDER BY `candidate_count` DESC, `candidate`.`entry`
LIMIT 25;

INSERT IGNORE INTO `azerothlab_ambient_wander_creature_backup`
SELECT `creature`.*
FROM `creature`
INNER JOIN `_alw_ambient_wander_candidates` `candidate`
    ON `candidate`.`guid` = `creature`.`guid`
WHERE @azerothlab_ambient_wander_dry_run = 0;

UPDATE `creature`
INNER JOIN `_alw_ambient_wander_candidates` `candidate`
    ON `candidate`.`guid` = `creature`.`guid`
SET
    `creature`.`MovementType` = 1,
    `creature`.`spawndist` = 3
WHERE @azerothlab_ambient_wander_dry_run = 0;

SET @azerothlab_ambient_wander_updated = ROW_COUNT();

COMMIT;

SELECT
    @azerothlab_ambient_wander_candidates AS `safe_ambient_wander_candidates`,
    @azerothlab_ambient_wander_updated AS `ambient_wander_spawns_updated`;

DROP TEMPORARY TABLE IF EXISTS `_alw_ambient_wander_candidates`;
