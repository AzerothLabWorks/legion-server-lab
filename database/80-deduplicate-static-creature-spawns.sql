USE `legion_world`;

-- Preserve every removed row so this conservative cleanup remains reversible.
CREATE TABLE IF NOT EXISTS `azerothlab_removed_creature_spawns` LIKE `creature`;

START TRANSACTION;

DROP TEMPORARY TABLE IF EXISTS `_alw_creature_signatures`;
CREATE TEMPORARY TABLE `_alw_creature_signatures` ENGINE=InnoDB AS
SELECT
    `guid`,
    SHA2(CONCAT_WS('|',
        `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `PhaseId`,
        `modelid`, `equipment_id`, `position_x`, `position_y`, `position_z`,
        `orientation`, `spawntimesecs`, `spawndist`, `currentwaypoint`,
        `curhealth`, `curmana`, `MovementType`, `npcflag`, `npcflag2`,
        `unit_flags`, `dynamicflags`, COALESCE(`ScriptName`, ''), `AiID`,
        `MovementID`, `MeleeID`, `isActive`, `skipClone`, `personal_size`,
        `isTeemingSpawn`, `unit_flags3`
    ), 256) AS `signature`
FROM `creature`
WHERE `skipClone` = 0;

ALTER TABLE `_alw_creature_signatures`
    ADD PRIMARY KEY (`guid`),
    ADD INDEX `idx_signature` (`signature`);

DROP TEMPORARY TABLE IF EXISTS `_alw_duplicate_groups`;
CREATE TEMPORARY TABLE `_alw_duplicate_groups` ENGINE=InnoDB AS
SELECT `signature`, MIN(`guid`) AS `keep_guid`, COUNT(*) AS `copies`
FROM `_alw_creature_signatures`
GROUP BY `signature`
HAVING COUNT(*) > 1;

ALTER TABLE `_alw_duplicate_groups`
    ADD PRIMARY KEY (`signature`);

-- If any member of an otherwise identical group has GUID-specific behavior,
-- preserve the complete group for manual review.
DROP TEMPORARY TABLE IF EXISTS `_alw_protected_groups`;
CREATE TEMPORARY TABLE `_alw_protected_groups` ENGINE=InnoDB AS
SELECT DISTINCT `s`.`signature`
FROM `_alw_creature_signatures` `s`
INNER JOIN `_alw_duplicate_groups` `g`
    ON `g`.`signature` = `s`.`signature`
WHERE
    EXISTS (SELECT 1 FROM `creature_addon` `x` WHERE `x`.`guid` = `s`.`guid`)
    OR EXISTS (SELECT 1 FROM `game_event_creature` `x` WHERE `x`.`guid` = `s`.`guid`)
    OR EXISTS (SELECT 1 FROM `pool_creature` `x` WHERE `x`.`guid` = `s`.`guid`)
    OR EXISTS (SELECT 1 FROM `creature_formations` `x`
               WHERE `x`.`memberGUID` = `s`.`guid` OR `x`.`leaderGUID` = `s`.`guid`)
    OR EXISTS (SELECT 1 FROM `creature_transport` `x` WHERE `x`.`guid` = `s`.`guid`)
    OR EXISTS (SELECT 1 FROM `linked_respawn` `x`
               WHERE `x`.`guid` = `s`.`guid` OR `x`.`linkedGuid` = `s`.`guid`)
    OR EXISTS (SELECT 1 FROM `conversation_creature` `x`
               WHERE `x`.`creatureGuid` = `s`.`guid`)
    OR EXISTS (SELECT 1 FROM `smart_scripts` `x`
               WHERE `x`.`entryorguid` = -CAST(`s`.`guid` AS SIGNED))
    OR EXISTS (SELECT 1 FROM `game_event_model_equip` `x` WHERE `x`.`guid` = `s`.`guid`)
    OR EXISTS (SELECT 1 FROM `game_event_npcflag` `x` WHERE `x`.`guid` = `s`.`guid`)
    OR EXISTS (SELECT 1 FROM `game_event_npc_vendor` `x` WHERE `x`.`guid` = `s`.`guid`);

ALTER TABLE `_alw_protected_groups`
    ADD PRIMARY KEY (`signature`);

DROP TEMPORARY TABLE IF EXISTS `_alw_duplicate_candidates`;
CREATE TEMPORARY TABLE `_alw_duplicate_candidates` (
    `guid` BIGINT(20) UNSIGNED NOT NULL,
    `reason` VARCHAR(80) NOT NULL,
    PRIMARY KEY (`guid`)
) ENGINE=InnoDB;

INSERT INTO `_alw_duplicate_candidates` (`guid`, `reason`)
SELECT `s`.`guid`, 'byte-equivalent unreferenced static spawn'
FROM `_alw_creature_signatures` `s`
INNER JOIN `_alw_duplicate_groups` `g`
    ON `g`.`signature` = `s`.`signature`
LEFT JOIN `_alw_protected_groups` `p`
    ON `p`.`signature` = `s`.`signature`
WHERE `s`.`guid` <> `g`.`keep_guid`
  AND `p`.`signature` IS NULL;

-- Confirmed by in-game observation and database inspection. The lower GUID
-- 1660 remains as Chef Grual; 125434 is an unreferenced second copy 3.65 yards
-- away in the same map, area, spawn mask, and phase.
INSERT IGNORE INTO `_alw_duplicate_candidates` (`guid`, `reason`)
SELECT `guid`, 'confirmed near-duplicate Chef Grual'
FROM `creature`
WHERE `guid` = 125434
  AND `id` = 272
  AND `map` = 0
  AND `areaId` = 42
  AND ABS(`position_x` - (-10499.3)) < 0.01
  AND ABS(`position_y` - (-1157.98)) < 0.01
  AND ABS(`position_z` - 28.0867) < 0.01;

INSERT IGNORE INTO `azerothlab_removed_creature_spawns`
SELECT `c`.*
FROM `creature` `c`
INNER JOIN `_alw_duplicate_candidates` `d` ON `d`.`guid` = `c`.`guid`;

DELETE `c`
FROM `creature` `c`
INNER JOIN `_alw_duplicate_candidates` `d` ON `d`.`guid` = `c`.`guid`;

SET @azerothlab_removed_creature_count = ROW_COUNT();

COMMIT;

SELECT @azerothlab_removed_creature_count AS `removed_duplicate_creature_spawns`;

DROP TEMPORARY TABLE IF EXISTS `_alw_duplicate_candidates`;
DROP TEMPORARY TABLE IF EXISTS `_alw_protected_groups`;
DROP TEMPORARY TABLE IF EXISTS `_alw_duplicate_groups`;
DROP TEMPORARY TABLE IF EXISTS `_alw_creature_signatures`;
