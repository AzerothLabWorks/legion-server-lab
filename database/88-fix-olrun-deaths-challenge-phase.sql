USE `legion_world`;

-- Olrun the Battlecaller (entry 29047) starts and ends Death's Challenge
-- (quest 12733) in the first Death's Breach phase. The imported Legion world
-- assigns his single spawn the catch-all legacy phase mask 65535, unlike the
-- surrounding chapter-one NPCs and the reference WotLK spawn, which use phase
-- 1. On this core that leaves the quest POI visible while Olrun himself is not
-- materialized for a newly created Death Knight.
--
-- Repair only the verified Olrun spawn. Preserve the original row first so the
-- migration remains auditable and reversible, and do not mutate player quest
-- history or grant quest credit.

CREATE TABLE IF NOT EXISTS `azerothlab_olrun_phase_backup`
    LIKE `creature`;

START TRANSACTION;

INSERT IGNORE INTO `azerothlab_olrun_phase_backup`
SELECT `spawn`.*
FROM `creature` `spawn`
WHERE `spawn`.`guid` = 260740
  AND `spawn`.`id` = 29047
  AND `spawn`.`map` = 609
  AND `spawn`.`zoneId` = 4298
  AND `spawn`.`areaId` = 4356
  AND `spawn`.`spawnMask` = 1
  AND `spawn`.`phaseMask` = 65535
  AND `spawn`.`PhaseId` = ''
  AND ABS(`spawn`.`position_x` - 2376.74) < 0.05
  AND ABS(`spawn`.`position_y` + 5789.40) < 0.05
  AND ABS(`spawn`.`position_z` - 154.895) < 0.05
  AND EXISTS (
      SELECT 1
      FROM `creature_queststarter` `starter`
      WHERE `starter`.`id` = 29047
        AND `starter`.`quest` = 12733
  )
  AND EXISTS (
      SELECT 1
      FROM `creature_questender` `ender`
      WHERE `ender`.`id` = 29047
        AND `ender`.`quest` = 12733
  );

UPDATE `creature` `spawn`
SET `spawn`.`phaseMask` = 1
WHERE `spawn`.`guid` = 260740
  AND `spawn`.`id` = 29047
  AND `spawn`.`map` = 609
  AND `spawn`.`zoneId` = 4298
  AND `spawn`.`areaId` = 4356
  AND `spawn`.`phaseMask` = 65535
  AND `spawn`.`PhaseId` = ''
  AND EXISTS (
      SELECT 1
      FROM `azerothlab_olrun_phase_backup` `backup`
      WHERE `backup`.`guid` = `spawn`.`guid`
        AND `backup`.`id` = `spawn`.`id`
        AND `backup`.`phaseMask` = 65535
  );

SET @azerothlab_olrun_phase_rows_repaired = ROW_COUNT();

COMMIT;

SELECT
    @azerothlab_olrun_phase_rows_repaired AS `olrun_phase_rows_repaired`,
    `spawn`.`guid`,
    `spawn`.`id`,
    `spawn`.`phaseMask`,
    `spawn`.`position_x`,
    `spawn`.`position_y`,
    `spawn`.`position_z`
FROM `creature` `spawn`
WHERE `spawn`.`guid` = 260740
  AND `spawn`.`id` = 29047;
