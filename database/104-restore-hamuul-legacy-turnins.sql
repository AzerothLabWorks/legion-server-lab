USE `legion_world`;

-- The Sanctuary of Malorne contains two progression-era versions of Archdruid
-- Hamuul Runetotem. Entry 39858 ends the Mount Hyjal leveling quests, while
-- entry 52838 handles the later Molten Front unlocks. When the latter is the
-- interactable copy, its incomplete currency quest opens directly and hides
-- completed leveling turn-ins. Let the later Hamuul accept the same completed
-- quests; this makes the client show a quest-choice menu without changing any
-- quest prerequisites or reward requirements.

CREATE TABLE IF NOT EXISTS `azerothlab_hamuul_questender_backup`
LIKE `creature_questender`;

INSERT IGNORE INTO `azerothlab_hamuul_questender_backup`
SELECT * FROM `creature_questender`
WHERE `id` IN (39858, 52838);

INSERT IGNORE INTO `creature_questender` (`id`, `quest`)
SELECT 52838, legacy.`quest`
FROM `creature_questender` legacy
WHERE legacy.`id` = 39858;

SELECT ender.`id`, ender.`quest`, quest.`LogTitle`
FROM `creature_questender` ender
JOIN `quest_template` quest ON quest.`ID` = ender.`quest`
WHERE ender.`id` IN (39858, 52838)
ORDER BY ender.`quest`, ender.`id`;
