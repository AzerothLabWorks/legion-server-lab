USE `legion_world`;

-- The imported world marks many spawns as waypoint movers but omits the
-- creature_addon.path_id link consumed by the core. The corresponding
-- waypoint_data path is still present under the conventional spawn GUID ID.
-- Restore only paths with at least two nodes whose first node is within 25
-- yards of the spawn. This rejects unrelated path-ID collisions while
-- reactivating the authored patrol instead of inventing new movement.

CREATE TABLE IF NOT EXISTS `azerothlab_restored_creature_waypoint_links` (
    `guid` BIGINT(20) UNSIGNED NOT NULL,
    `entry` MEDIUMINT(8) UNSIGNED NOT NULL,
    `restored_path_id` INT(10) UNSIGNED NOT NULL,
    `had_creature_addon` TINYINT(1) UNSIGNED NOT NULL,
    `original_path_id` INT(10) UNSIGNED NOT NULL,
    `first_point_distance` FLOAT NOT NULL,
    `restored_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`guid`),
    KEY `idx_restored_path` (`restored_path_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Maintainers may set this to 1 in the same mysql session to report the
-- candidate count without changing creature_addon.
SET @azerothlab_waypoint_restore_dry_run =
    COALESCE(@azerothlab_waypoint_restore_dry_run, 0);

START TRANSACTION;

DROP TEMPORARY TABLE IF EXISTS `_alw_dormant_waypoint_candidates`;
CREATE TEMPORARY TABLE `_alw_dormant_waypoint_candidates` (
    `guid` BIGINT(20) UNSIGNED NOT NULL,
    `entry` MEDIUMINT(8) UNSIGNED NOT NULL,
    `path_id` INT(10) UNSIGNED NOT NULL,
    `had_creature_addon` TINYINT(1) UNSIGNED NOT NULL,
    `original_path_id` INT(10) UNSIGNED NOT NULL,
    `first_point_distance` FLOAT NOT NULL,
    PRIMARY KEY (`guid`)
) ENGINE=InnoDB;

INSERT INTO `_alw_dormant_waypoint_candidates`
    (`guid`, `entry`, `path_id`, `had_creature_addon`,
     `original_path_id`, `first_point_distance`)
SELECT
    `creature`.`guid`,
    `creature`.`id`,
    `creature`.`guid`,
    IF(`addon`.`guid` IS NULL, 0, 1),
    COALESCE(`addon`.`path_id`, 0),
    SQRT(
        POW(`creature`.`position_x` - `first_node`.`position_x`, 2)
        + POW(`creature`.`position_y` - `first_node`.`position_y`, 2)
        + POW(`creature`.`position_z` - `first_node`.`position_z`, 2)
    )
FROM `creature`
LEFT JOIN `creature_addon` `addon`
    ON `addon`.`guid` = `creature`.`guid`
INNER JOIN (
    SELECT `id`, MIN(`point`) AS `first_point`, COUNT(*) AS `node_count`
    FROM `waypoint_data`
    GROUP BY `id`
    HAVING COUNT(*) >= 2
) `path`
    ON `path`.`id` = `creature`.`guid`
INNER JOIN `waypoint_data` `first_node`
    ON `first_node`.`id` = `path`.`id`
   AND `first_node`.`point` = `path`.`first_point`
WHERE `creature`.`MovementType` = 2
  AND COALESCE(`addon`.`path_id`, 0) = 0
  AND POW(`creature`.`position_x` - `first_node`.`position_x`, 2)
    + POW(`creature`.`position_y` - `first_node`.`position_y`, 2)
    + POW(`creature`.`position_z` - `first_node`.`position_z`, 2) <= 625;

SELECT COUNT(*) INTO @azerothlab_waypoint_restore_candidates
FROM `_alw_dormant_waypoint_candidates`;

INSERT IGNORE INTO `azerothlab_restored_creature_waypoint_links`
    (`guid`, `entry`, `restored_path_id`, `had_creature_addon`,
     `original_path_id`, `first_point_distance`)
SELECT
    `guid`, `entry`, `path_id`, `had_creature_addon`,
    `original_path_id`, `first_point_distance`
FROM `_alw_dormant_waypoint_candidates`
WHERE @azerothlab_waypoint_restore_dry_run = 0;

UPDATE `creature_addon` `addon`
INNER JOIN `_alw_dormant_waypoint_candidates` `candidate`
    ON `candidate`.`guid` = `addon`.`guid`
SET `addon`.`path_id` = `candidate`.`path_id`
WHERE `candidate`.`had_creature_addon` = 1
  AND @azerothlab_waypoint_restore_dry_run = 0;

SET @azerothlab_updated_waypoint_addons = ROW_COUNT();

INSERT INTO `creature_addon`
    (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `auras`)
SELECT
    `guid`, `path_id`, 0, 0, 0, 0, NULL
FROM `_alw_dormant_waypoint_candidates`
WHERE `had_creature_addon` = 0
  AND @azerothlab_waypoint_restore_dry_run = 0;

SET @azerothlab_inserted_waypoint_addons = ROW_COUNT();

COMMIT;

SELECT
    @azerothlab_waypoint_restore_candidates AS `validated_waypoint_candidates`,
    @azerothlab_updated_waypoint_addons AS `updated_waypoint_links`,
    @azerothlab_inserted_waypoint_addons AS `inserted_waypoint_links`;

DROP TEMPORARY TABLE IF EXISTS `_alw_dormant_waypoint_candidates`;
