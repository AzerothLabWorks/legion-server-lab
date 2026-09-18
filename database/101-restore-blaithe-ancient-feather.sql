USE `legion_world`;

-- A Prayer and a Wing (25664) correctly summons Blaithe (41084), whose loot
-- table contains the Ancient Feather (55210) with an explicit quest-active
-- condition. The row was imported with lootmode 0 and legacy negative quest
-- chance encoding, so it is never eligible on this summoned-creature path.

CREATE TABLE IF NOT EXISTS `azerothlab_blaithe_loot_backup`
LIKE `creature_loot_template`;

INSERT IGNORE INTO `azerothlab_blaithe_loot_backup`
SELECT *
FROM `creature_loot_template`
WHERE `entry` = 41084
  AND `item` = 55210;

UPDATE `creature_loot_template`
SET `ChanceOrQuestChance` = 100,
    `lootmode` = 1
WHERE `entry` = 41084
  AND `item` = 55210
  AND `ChanceOrQuestChance` IN (-100, 100)
  AND `lootmode` IN (0, 1);

SELECT `entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`,
       `mincountOrRef`, `maxcount`
FROM `creature_loot_template`
WHERE `entry` = 41084
  AND `item` = 55210;
