USE `legion_world`;

-- High Overlord Saurfang (25256) is the quest giver for The Defense of
-- Warsong Hold.  The preservation baseline assigns his older display 14732
-- to the template.  At the canonical Wrath Warsong Hold spawn that model can
-- fail to render in the 7.3.5 client even though the quest marker and spawn
-- are both present.
--
-- Keep the template unchanged and override only the single authored
-- Warsong Hold spawn with its Wrath display (23033).  This avoids changing
-- any summoned or scripted uses of entry 25256 elsewhere.
--
-- Some clients still omit the spawned unit even with its Wrath display while
-- rendering Garrosh Hellscream (25237), who stands seven yards away in the
-- same base phase.  Preserve Saurfang as the canonical starter and add the
-- generic Horde quest variant (11596) to Garrosh as a progression fallback.
-- All three Saurfang variants share the same objective, next quest, and
-- Warsong Offensive reward; the generic variant avoids title-specific text.

CREATE TABLE IF NOT EXISTS `azerothlab_warsong_saurfang_spawn_backup`
LIKE `creature`;

INSERT IGNORE INTO `azerothlab_warsong_saurfang_spawn_backup`
SELECT *
FROM `creature`
WHERE `guid` = 68460
  AND `id` = 25256;

CREATE TABLE IF NOT EXISTS `azerothlab_warsong_saurfang_model_backup`
LIKE `creature_model_info`;

INSERT IGNORE INTO `azerothlab_warsong_saurfang_model_backup`
SELECT *
FROM `creature_model_info`
WHERE `DisplayID` = 23033;

-- Supply the canonical model dimensions when the archived Legion database
-- does not already contain an entry for this Wrath display.
INSERT IGNORE INTO `creature_model_info`
    (`DisplayID`, `BoundingRadius`, `CombatReach`,
     `DisplayID_Other_Gender`, `hostileId`)
VALUES
    (23033, 0.4092, 1.65, 0, 0);

UPDATE `creature`
SET `modelid` = 23033
WHERE `guid` = 68460
  AND `id` = 25256
  AND `map` = 571
  AND `zoneId` = 3537
  AND `areaId` = 4129
  AND `position_x` BETWEEN 2834.5 AND 2835.5
  AND `position_y` BETWEEN 6181.9 AND 6182.9
  AND `modelid` IN (0, 14732, 23033);

CREATE TABLE IF NOT EXISTS `azerothlab_warsong_queststarter_backup`
LIKE `creature_queststarter`;

INSERT IGNORE INTO `azerothlab_warsong_queststarter_backup`
SELECT *
FROM `creature_queststarter`
WHERE (`id` = 25256 AND `quest` IN (11595, 11596, 11597))
   OR (`id` = 25237 AND `quest` = 11596);

INSERT IGNORE INTO `creature_queststarter` (`id`, `quest`)
VALUES (25237, 11596);

SELECT c.`guid`, c.`id`, w.`Name1`, c.`map`, c.`zoneId`, c.`areaId`,
       c.`position_x`, c.`position_y`, c.`position_z`, c.`modelid`,
       m.`BoundingRadius`, m.`CombatReach`
FROM `creature` c
JOIN `creature_template_wdb` w ON w.`Entry` = c.`id`
LEFT JOIN `creature_model_info` m ON m.`DisplayID` = c.`modelid`
WHERE c.`guid` = 68460
  AND c.`id` = 25256;

SELECT `id`, `quest`
FROM `creature_queststarter`
WHERE (`id` = 25256 AND `quest` IN (11595, 11596, 11597))
   OR (`id` = 25237 AND `quest` = 11596)
ORDER BY `id`, `quest`;
