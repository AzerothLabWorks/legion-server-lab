USE `legion_world`;

-- Remove same-entry spawn rows that were imported again in a later GUID
-- generation at effectively the same location. This deliberately does not
-- compare different creature entries: mixed packs such as Nightbane Vile Fang
-- plus Nightbane Tainted One are legitimate gameplay and must remain intact.
-- Every removed row is archived for recovery.
CREATE TABLE IF NOT EXISTS `azerothlab_removed_creature_spawns` LIKE `creature`;

-- Maintainers can set this to 1 in the same mysql session to audit candidate
-- counts without archiving or deleting rows.
SET @azerothlab_cross_generation_dry_run =
    COALESCE(@azerothlab_cross_generation_dry_run, 0);

START TRANSACTION;

DROP TEMPORARY TABLE IF EXISTS `_alw_cross_generation_entries`;
CREATE TEMPORARY TABLE `_alw_cross_generation_entries` ENGINE=InnoDB AS
SELECT `id`
FROM `creature`
WHERE `skipClone` = 0
GROUP BY `id`
HAVING MAX(`guid`) - MIN(`guid`) > 1000;

ALTER TABLE `_alw_cross_generation_entries`
    ADD PRIMARY KEY (`id`);

-- MySQL 5.7 cannot reference one temporary table twice in the same query, so
-- build two indexed copies of the spatial grid used by the self-join.
DROP TEMPORARY TABLE IF EXISTS `_alw_spawn_grid_older`;
CREATE TEMPORARY TABLE `_alw_spawn_grid_older` ENGINE=InnoDB AS
SELECT
    `c`.*,
    FLOOR(`c`.`position_x` / 3) AS `cell_x`,
    FLOOR(`c`.`position_y` / 3) AS `cell_y`,
    FLOOR(`c`.`position_z` / 3) AS `cell_z`
FROM `creature` `c`
INNER JOIN `_alw_cross_generation_entries` `entry_set`
    ON `entry_set`.`id` = `c`.`id`
WHERE `c`.`skipClone` = 0;

ALTER TABLE `_alw_spawn_grid_older`
    ADD PRIMARY KEY (`guid`),
    ADD INDEX `idx_nearby_spawn` (`id`, `map`, `areaId`, `cell_x`, `cell_y`, `cell_z`);

DROP TEMPORARY TABLE IF EXISTS `_alw_spawn_grid_newer`;
CREATE TEMPORARY TABLE `_alw_spawn_grid_newer` ENGINE=InnoDB AS
SELECT * FROM `_alw_spawn_grid_older`;

ALTER TABLE `_alw_spawn_grid_newer`
    ADD PRIMARY KEY (`guid`),
    ADD INDEX `idx_nearby_spawn` (`id`, `map`, `areaId`, `cell_x`, `cell_y`, `cell_z`);

DROP TEMPORARY TABLE IF EXISTS `_alw_cross_generation_candidates`;
CREATE TEMPORARY TABLE `_alw_cross_generation_candidates` (
    `guid` BIGINT(20) UNSIGNED NOT NULL,
    `keep_guid` BIGINT(20) UNSIGNED NOT NULL,
    `entry` MEDIUMINT(8) UNSIGNED NOT NULL,
    `distance` FLOAT NOT NULL,
    `reason` VARCHAR(120) NOT NULL,
    PRIMARY KEY (`guid`)
) ENGINE=InnoDB;

INSERT IGNORE INTO `_alw_cross_generation_candidates`
    (`guid`, `keep_guid`, `entry`, `distance`, `reason`)
SELECT
    `newer`.`guid`,
    `older`.`guid`,
    `older`.`id`,
    SQRT(
        POW(`newer`.`position_x` - `older`.`position_x`, 2)
        + POW(`newer`.`position_y` - `older`.`position_y`, 2)
        + POW(`newer`.`position_z` - `older`.`position_z`, 2)
    ),
    'same-entry cross-generation spawn within three yards'
FROM `_alw_spawn_grid_older` `older`
INNER JOIN `_alw_spawn_grid_newer` `newer`
    ON `newer`.`id` = `older`.`id`
   AND `newer`.`map` = `older`.`map`
   AND `newer`.`areaId` = `older`.`areaId`
   AND `newer`.`cell_x` BETWEEN `older`.`cell_x` - 1 AND `older`.`cell_x` + 1
   AND `newer`.`cell_y` BETWEEN `older`.`cell_y` - 1 AND `older`.`cell_y` + 1
   AND `newer`.`cell_z` BETWEEN `older`.`cell_z` - 1 AND `older`.`cell_z` + 1
INNER JOIN `creature_template` `template`
    ON `template`.`entry` = `older`.`id`
INNER JOIN `creature_template_wdb` `wdb`
    ON `wdb`.`Entry` = `older`.`id`
WHERE
    -- A large GUID gap distinguishes a later import from deliberate adjacent
    -- spawn packs created together.
    `newer`.`guid` > `older`.`guid` + 1000
    -- Critters and not-specified helper/pre-load entries commonly overlap by
    -- design. C++-scripted and world-boss entries require encounter review.
    AND `wdb`.`Type` NOT IN (8, 10)
    AND `wdb`.`Classification` <> 3
    AND COALESCE(`template`.`ScriptName`, '') = ''
    AND `newer`.`spawnMask` = `older`.`spawnMask`
    AND `newer`.`phaseMask` = `older`.`phaseMask`
    AND COALESCE(`newer`.`PhaseId`, '') = COALESCE(`older`.`PhaseId`, '')
    AND POW(`newer`.`position_x` - `older`.`position_x`, 2)
      + POW(`newer`.`position_y` - `older`.`position_y`, 2)
      + POW(`newer`.`position_z` - `older`.`position_z`, 2) <= 9
    -- Permit harmless snapshot differences from separate imports, including
    -- facing, model choice, respawn time, and saved health/mana. All fields
    -- that alter behavior or participation in world systems must still match.
    AND `newer`.`equipment_id` = `older`.`equipment_id`
    AND `newer`.`spawndist` = `older`.`spawndist`
    AND `newer`.`currentwaypoint` = `older`.`currentwaypoint`
    AND `newer`.`MovementType` = `older`.`MovementType`
    AND `newer`.`npcflag` = `older`.`npcflag`
    AND `newer`.`npcflag2` = `older`.`npcflag2`
    AND `newer`.`unit_flags` = `older`.`unit_flags`
    AND `newer`.`dynamicflags` = `older`.`dynamicflags`
    AND COALESCE(`newer`.`ScriptName`, '') = COALESCE(`older`.`ScriptName`, '')
    AND `newer`.`AiID` = `older`.`AiID`
    AND `newer`.`MovementID` = `older`.`MovementID`
    AND `newer`.`MeleeID` = `older`.`MeleeID`
    AND `newer`.`isActive` = `older`.`isActive`
    AND `newer`.`personal_size` = `older`.`personal_size`
    AND `newer`.`isTeemingSpawn` = `older`.`isTeemingSpawn`
    AND `newer`.`unit_flags3` = `older`.`unit_flags3`
    -- A spawn-specific reference is stronger evidence than proximity. Keep
    -- both members of such a pair for manual encounter review.
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
                   ) OR (`x`.`entryorguid` = `older`.`id` AND `x`.`source_type` = 0))
        OR EXISTS (SELECT 1 FROM `game_event_model_equip` `x`
                   WHERE `x`.`guid` IN (`older`.`guid`, `newer`.`guid`))
        OR EXISTS (SELECT 1 FROM `game_event_npcflag` `x`
                   WHERE `x`.`guid` IN (`older`.`guid`, `newer`.`guid`))
        OR EXISTS (SELECT 1 FROM `game_event_npc_vendor` `x`
                   WHERE `x`.`guid` IN (`older`.`guid`, `newer`.`guid`))
    );

SELECT COUNT(*) INTO @azerothlab_cross_generation_candidate_count
FROM `_alw_cross_generation_candidates`;

SELECT
    `candidate`.`entry`,
    COALESCE(`wdb`.`Name1`, '') AS `creature_name`,
    COUNT(*) AS `candidate_count`
FROM `_alw_cross_generation_candidates` `candidate`
LEFT JOIN `creature_template_wdb` `wdb`
    ON `wdb`.`Entry` = `candidate`.`entry`
GROUP BY `candidate`.`entry`, `wdb`.`Name1`
ORDER BY `candidate_count` DESC, `candidate`.`entry`
LIMIT 25;

INSERT IGNORE INTO `azerothlab_removed_creature_spawns`
SELECT `creature`.*
FROM `creature`
INNER JOIN `_alw_cross_generation_candidates` `candidate`
    ON `candidate`.`guid` = `creature`.`guid`
WHERE @azerothlab_cross_generation_dry_run = 0;

DELETE `creature`
FROM `creature`
INNER JOIN `_alw_cross_generation_candidates` `candidate`
    ON `candidate`.`guid` = `creature`.`guid`
WHERE @azerothlab_cross_generation_dry_run = 0;

SET @azerothlab_removed_cross_generation_count = ROW_COUNT();

COMMIT;

SELECT @azerothlab_removed_cross_generation_count
    AS `removed_cross_generation_creature_spawns`,
    @azerothlab_cross_generation_candidate_count
    AS `cross_generation_creature_candidates`;

DROP TEMPORARY TABLE IF EXISTS `_alw_cross_generation_candidates`;
DROP TEMPORARY TABLE IF EXISTS `_alw_spawn_grid_newer`;
DROP TEMPORARY TABLE IF EXISTS `_alw_spawn_grid_older`;
DROP TEMPORARY TABLE IF EXISTS `_alw_cross_generation_entries`;
