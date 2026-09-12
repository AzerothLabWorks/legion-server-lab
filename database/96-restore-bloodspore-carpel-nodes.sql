USE `legion_world`;

-- The Wondrous Bloodspore (11716) asks the player to collect ten
-- Bloodspore Carpels (item 34974) from gameobject 187902. All 25 authored
-- Borean Tundra spawns are present, but the preservation database converted
-- the legacy consumable quest object from CHEST (type 3) to the Legion
-- GATHERING_NODE type (50). That conversion prevents these Wrath-era plants
-- from behaving like their original click-to-loot quest nodes.
--
-- The template still references loot id 23169, while its only guaranteed
-- quest-item row was imported under the unrelated key 187902. Restore the
-- original interaction type and place the quest loot under the key the
-- template actually loads. The orphaned 187902 loot row is retained because
-- it is harmless and keeping it makes this migration non-destructive.

CREATE TABLE IF NOT EXISTS `azerothlab_bloodspore_template_backup`
LIKE `gameobject_template`;

INSERT IGNORE INTO `azerothlab_bloodspore_template_backup`
SELECT *
FROM `gameobject_template`
WHERE `entry` = 187902;

CREATE TABLE IF NOT EXISTS `azerothlab_bloodspore_loot_backup`
LIKE `gameobject_loot_template`;

INSERT IGNORE INTO `azerothlab_bloodspore_loot_backup`
SELECT *
FROM `gameobject_loot_template`
WHERE `entry` IN (187902, 23169)
  AND `item` = 34974;

UPDATE `gameobject_template`
SET `type` = 3,
    `Data0` = 259,
    `Data1` = 23169,
    `Data3` = 1
WHERE `entry` = 187902
  AND `name` = 'Bloodspore Carpel';

INSERT INTO `gameobject_loot_template`
    (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`,
     `mincountOrRef`, `maxcount`)
VALUES
    (23169, 34974, -100, 1, 0, 1, 1)
ON DUPLICATE KEY UPDATE
    `ChanceOrQuestChance` = VALUES(`ChanceOrQuestChance`),
    `lootmode` = VALUES(`lootmode`),
    `groupid` = VALUES(`groupid`),
    `mincountOrRef` = VALUES(`mincountOrRef`),
    `maxcount` = VALUES(`maxcount`);

SELECT `entry`, `type`, `name`, `Data0`, `Data1`, `Data3`
FROM `gameobject_template`
WHERE `entry` = 187902;

SELECT `entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`,
       `mincountOrRef`, `maxcount`
FROM `gameobject_loot_template`
WHERE `entry` = 23169
  AND `item` = 34974;
