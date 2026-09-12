USE `legion_world`;

-- From the Mouth of Madness (25297) requires Stonebloom item 52726 from
-- gameobject 202702. The four authored spawns and guaranteed quest loot are
-- present, but this single ingredient was converted from an ordinary
-- Cataclysm quest chest (type 3) to a Legion gathering node (type 50).

CREATE TABLE IF NOT EXISTS `azerothlab_stonebloom_template_backup`
LIKE `gameobject_template`;

INSERT IGNORE INTO `azerothlab_stonebloom_template_backup`
SELECT *
FROM `gameobject_template`
WHERE `entry` = 202702;

UPDATE `gameobject_template`
SET `type` = 3
WHERE `entry` = 202702
  AND `name` = 'Stonebloom'
  AND `type` IN (3, 50)
  AND `Data1` = 202702;

SELECT `entry`, `type`, `name`, `Data0`, `Data1`, `Data2`, `Data8`
FROM `gameobject_template`
WHERE `entry` = 202702;

SELECT `guid`, `id`, `map`, `zoneId`, `areaId`,
       `position_x`, `position_y`, `position_z`, `phaseMask`
FROM `gameobject`
WHERE `id` = 202702
ORDER BY `guid`;
