USE `legion_world`;

-- Rocket Rescue (quest 25050) already has a complete database-driven vehicle
-- chain in the archived world:
--
--   40604 Steamwheedle Rescue Balloon --spell click--> summon 40511
--   40511 Balloon Throwing Station     --46598-------> board the player
--
-- The click proxy has SmartAI rows but an empty AIName. The core therefore
-- creates NullCreatureAI for the spell-click creature and never runs the
-- SMART_EVENT_SPELLCLICK action chain. The summoned moving vehicle also uses
-- an invisible throwing-station display even though the archived database has
-- the matching visible rescue-balloon display on entries 40505 and 40604.
-- Repair only this fully verified layout; do not promote unrelated templates.

CREATE TABLE IF NOT EXISTS `azerothlab_rocket_rescue_template_backup`
    LIKE `creature_template`;

CREATE TABLE IF NOT EXISTS `azerothlab_rocket_rescue_wdb_backup`
    LIKE `creature_template_wdb`;

START TRANSACTION;

INSERT IGNORE INTO `azerothlab_rocket_rescue_template_backup`
SELECT `template`.*
FROM `creature_template` `template`
WHERE `template`.`entry` = 40604
  AND `template`.`AIName` = ''
  AND `template`.`ScriptName` = ''
  AND (`template`.`npcflag` & 16777216) <> 0
  AND EXISTS (
      SELECT 1
      FROM `npc_spellclick_spells` `click_spell`
      WHERE `click_spell`.`npc_entry` = 40604
        AND `click_spell`.`spell_id` = 75600
  )
  AND EXISTS (
      SELECT 1
      FROM `smart_scripts` `click_event`
      WHERE `click_event`.`source_type` = 0
        AND `click_event`.`entryorguid` = 40604
        AND `click_event`.`event_type` = 73
        AND `click_event`.`action_type` = 12
        AND `click_event`.`action_param1` = 40511
  )
  AND EXISTS (
      SELECT 1
      FROM `smart_scripts` `board_event`
      WHERE `board_event`.`source_type` = 0
        AND `board_event`.`entryorguid` = 40604
        AND `board_event`.`event_type` = 61
        AND `board_event`.`action_type` = 85
        AND `board_event`.`action_param1` = 46598
        AND `board_event`.`target_param1` = 40511
  )
  AND EXISTS (
      SELECT 1
      FROM `creature_template` `vehicle`
      WHERE `vehicle`.`entry` = 40511
        AND `vehicle`.`AIName` = 'SmartAI'
        AND `vehicle`.`VehicleId` = 752
  );

UPDATE `creature_template` `template`
SET `template`.`AIName` = 'SmartAI'
WHERE `template`.`entry` = 40604
  AND `template`.`AIName` = ''
  AND `template`.`ScriptName` = ''
  AND EXISTS (
      SELECT 1
      FROM `azerothlab_rocket_rescue_template_backup` `backup`
      WHERE `backup`.`entry` = `template`.`entry`
  );

SET @azerothlab_rocket_rescue_templates_repaired = ROW_COUNT();

INSERT IGNORE INTO `azerothlab_rocket_rescue_wdb_backup`
SELECT `wdb`.*
FROM `creature_template_wdb` `wdb`
WHERE `wdb`.`Entry` = 40511
  AND `wdb`.`Name1` = 'Balloon Throwing Station'
  AND `wdb`.`Displayid1` = 37126
  AND EXISTS (
      SELECT 1
      FROM `creature_template` `vehicle`
      WHERE `vehicle`.`entry` = 40511
        AND `vehicle`.`AIName` = 'SmartAI'
        AND `vehicle`.`VehicleId` = 752
  );

UPDATE `creature_template_wdb` `wdb`
SET `wdb`.`Displayid1` = 31757
WHERE `wdb`.`Entry` = 40511
  AND `wdb`.`Displayid1` = 37126
  AND EXISTS (
      SELECT 1
      FROM `azerothlab_rocket_rescue_wdb_backup` `backup`
      WHERE `backup`.`Entry` = `wdb`.`Entry`
  );

SET @azerothlab_rocket_rescue_displays_repaired = ROW_COUNT();

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (75560, 'spell_rocket_rescue_guided_payload'),
    (73257, 'spell_rocket_rescue_guided_payload');

SET @azerothlab_rocket_rescue_spell_scripts_registered = ROW_COUNT();

COMMIT;

SELECT
    @azerothlab_rocket_rescue_templates_repaired
        AS `rocket_rescue_templates_repaired`,
    @azerothlab_rocket_rescue_displays_repaired
        AS `rocket_rescue_displays_repaired`,
    @azerothlab_rocket_rescue_spell_scripts_registered
        AS `rocket_rescue_spell_scripts_registered`,
    (SELECT `AIName`
     FROM `creature_template`
     WHERE `entry` = 40604)
        AS `rocket_rescue_ai`,
    (SELECT `Displayid1`
     FROM `creature_template_wdb`
     WHERE `Entry` = 40511)
        AS `moving_balloon_display`;
