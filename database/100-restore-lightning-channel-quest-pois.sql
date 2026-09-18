USE `legion_world`;

-- Lightning in a Bottle (Alliance 25353, Horde 25355) has correct Lightning
-- Channel objective coordinates, but the newest compatible POI metadata row
-- disables the objective-area display flag. Preserve both faction variants
-- and repair only the Charged Condenser Jar objective for build 26124.

CREATE TABLE IF NOT EXISTS `azerothlab_lightning_channel_poi_backup`
LIKE `quest_poi`;

INSERT IGNORE INTO `azerothlab_lightning_channel_poi_backup`
SELECT *
FROM `quest_poi`
WHERE `QuestID` IN (25353, 25355)
  AND `ObjectiveIndex` = 0
  AND `QuestObjectiveID` IN (251768, 253075)
  AND `QuestObjectID` = 52834
  AND `VerifiedBuild` = 26124;

UPDATE `quest_poi`
SET `Flags` = `Flags` | 1
WHERE `QuestID` IN (25353, 25355)
  AND `ObjectiveIndex` = 0
  AND `QuestObjectiveID` IN (251768, 253075)
  AND `QuestObjectID` = 52834
  AND `VerifiedBuild` = 26124;

SELECT `QuestID`, `BlobIndex`, `Idx1`, `ObjectiveIndex`,
       `QuestObjectiveID`, `QuestObjectID`, `Flags`, `VerifiedBuild`
FROM `quest_poi`
WHERE `QuestID` IN (25353, 25355)
  AND `QuestObjectID` = 52834
ORDER BY `QuestID`, `VerifiedBuild`, `Idx1`;
