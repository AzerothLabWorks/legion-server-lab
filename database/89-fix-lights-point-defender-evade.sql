USE `legion_world`;

-- Massacre At Light's Point (quest 12701) uses Scarlet Cannons (entry 28833)
-- to kill Scarlet Fleet Defenders (entry 28834). The cannon's 100-yard range
-- is authored spell behavior and remains unchanged.
--
-- The imported defender SmartAI stops movement on aggro, then contradicts that
-- state with four range events that repeatedly enable and disable combat
-- movement. Defenders engaged from the ship consequently try to path across
-- inaccessible shoreline/ship geometry and enter evade, making later cannon
-- impacts ineffective. Keep the defenders stationary as the initial aggro row
-- requires, while preserving their ranged attack, death credit, and respawns.

CREATE TABLE IF NOT EXISTS `azerothlab_lightspoint_defender_smartai_backup`
    LIKE `smart_scripts`;

START TRANSACTION;

INSERT IGNORE INTO `azerothlab_lightspoint_defender_smartai_backup`
SELECT `script`.*
FROM `smart_scripts` `script`
WHERE `script`.`entryorguid` = 28834
  AND `script`.`source_type` = 0
  AND `script`.`id` IN (4, 5, 6, 7)
  AND `script`.`link` = 0
  AND `script`.`event_type` = 9
  AND `script`.`action_type` = 21
  AND EXISTS (
      SELECT 1
      FROM `smart_scripts` `stop_on_aggro`
      WHERE `stop_on_aggro`.`entryorguid` = 28834
        AND `stop_on_aggro`.`source_type` = 0
        AND `stop_on_aggro`.`id` = 1
        AND `stop_on_aggro`.`event_type` = 4
        AND `stop_on_aggro`.`action_type` = 21
        AND `stop_on_aggro`.`action_param1` = 0
  )
  AND EXISTS (
      SELECT 1
      FROM `smart_scripts` `ranged_attack`
      WHERE `ranged_attack`.`entryorguid` = 28834
        AND `ranged_attack`.`source_type` = 0
        AND `ranged_attack`.`id` = 3
        AND `ranged_attack`.`event_type` = 9
        AND `ranged_attack`.`action_type` = 11
        AND `ranged_attack`.`action_param1` = 52566
  )
  AND EXISTS (
      SELECT 1
      FROM `smart_scripts` `quest_credit`
      WHERE `quest_credit`.`entryorguid` = 28834
        AND `quest_credit`.`source_type` = 0
        AND `quest_credit`.`id` = 8
        AND `quest_credit`.`event_type` = 6
        AND `quest_credit`.`action_type` = 33
        AND `quest_credit`.`action_param1` = 28849
  );

DELETE `script`
FROM `smart_scripts` `script`
JOIN `azerothlab_lightspoint_defender_smartai_backup` `backup`
  ON `backup`.`entryorguid` = `script`.`entryorguid`
 AND `backup`.`source_type` = `script`.`source_type`
 AND `backup`.`id` = `script`.`id`
 AND `backup`.`link` = `script`.`link`
WHERE `script`.`entryorguid` = 28834
  AND `script`.`source_type` = 0
  AND `script`.`id` IN (4, 5, 6, 7)
  AND `script`.`event_type` = 9
  AND `script`.`action_type` = 21;

SET @azerothlab_lightspoint_movement_rows_removed = ROW_COUNT();

COMMIT;

SELECT
    @azerothlab_lightspoint_movement_rows_removed
        AS `lightspoint_movement_rows_removed`,
    (SELECT COUNT(*)
     FROM `azerothlab_lightspoint_defender_smartai_backup`
     WHERE `entryorguid` = 28834
       AND `source_type` = 0
       AND `id` IN (4, 5, 6, 7)) AS `movement_rows_backed_up`,
    (SELECT COUNT(*)
     FROM `smart_scripts`
     WHERE `entryorguid` = 28834
       AND `source_type` = 0
       AND `id` IN (0, 1, 2, 3, 8)) AS `essential_rows_preserved`;
