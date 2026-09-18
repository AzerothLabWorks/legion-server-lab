USE `legion_world`;

-- Perfecting Your Howl (29164) uses Fang of the Wolf spell 97605 on one of
-- five valid Firelands corpses. The imported SmartAI tries to grant credit from
-- SpellHit on a dead creature, but dead creatures do not dispatch that event in
-- this core. Register the core spell handler and remove the inert fallback so
-- each valid cast has exactly one credit path.

CREATE TABLE IF NOT EXISTS `azerothlab_perfecting_howl_template_backup`
LIKE `creature_template`;

INSERT IGNORE INTO `azerothlab_perfecting_howl_template_backup`
SELECT * FROM `creature_template`
WHERE `entry` IN (46910, 52791);

UPDATE `creature_template`
SET `AIName` = 'SmartAI'
WHERE `entry` IN (46910, 52791)
  AND `AIName` = '';

CREATE TABLE IF NOT EXISTS `azerothlab_perfecting_howl_smartai_backup`
LIKE `smart_scripts`;

INSERT IGNORE INTO `azerothlab_perfecting_howl_smartai_backup`
SELECT * FROM `smart_scripts`
WHERE `entryorguid` IN (39939, 46910, 46911, 52791, 52816)
  AND `source_type` = 0
  AND `event_type` = 8
  AND `event_param1` = 97605
  AND `action_type` = 33
  AND `action_param1` = 52819;

DELETE FROM `smart_scripts`
WHERE `entryorguid` IN (39939, 46910, 46911, 52791, 52816)
  AND `source_type` = 0
  AND `event_type` = 8
  AND `event_param1` = 97605
  AND `action_type` = 33
  AND `action_param1` = 52819;

-- The spell handler replaces creature-side credit, so restore the templates'
-- original AI selection rather than leaving combat creatures on empty SmartAI.
UPDATE `creature_template` template
JOIN `azerothlab_perfecting_howl_template_backup` backup
  ON backup.`entry` = template.`entry`
SET template.`AIName` = backup.`AIName`
WHERE template.`entry` IN (46910, 52791);

CREATE TABLE IF NOT EXISTS `azerothlab_perfecting_howl_condition_backup`
LIKE `conditions`;

INSERT IGNORE INTO `azerothlab_perfecting_howl_condition_backup`
SELECT * FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 7
  AND `SourceEntry` = 97605
  AND `ConditionTypeOrReference` = 31;

-- The imported rows all share ElseGroup 0, which ANDs five mutually exclusive
-- creature entries and prevents the spell from selecting any corpse. Give each
-- permitted invader its own OR group and include Charbringer, which populates
-- the Ashen Lake portion of the quest's displayed objective area.
DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 7
  AND `SourceEntry` = 97605
  AND `ConditionTypeOrReference` = 31;

INSERT INTO `conditions`
    (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`,
     `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`,
     `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
     `NegativeCondition`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
    (13, 7, 97605, 0, 0, 31, 0, 3, 39939, 0, 0, 0, '', 'Fury of the Wolf - Raging Firestorm corpse'),
    (13, 7, 97605, 0, 1, 31, 0, 3, 46910, 0, 0, 0, '', 'Fury of the Wolf - Core Hound corpse'),
    (13, 7, 97605, 0, 2, 31, 0, 3, 46911, 0, 0, 0, '', 'Fury of the Wolf - Lava Surger corpse'),
    (13, 7, 97605, 0, 3, 31, 0, 3, 52791, 0, 0, 0, '', 'Fury of the Wolf - Charred Flamewaker corpse'),
    (13, 7, 97605, 0, 4, 31, 0, 3, 52816, 0, 0, 0, '', 'Fury of the Wolf - Charred Invader corpse'),
    (13, 7, 97605, 0, 5, 31, 0, 3, 40336, 0, 0, 0, '', 'Fury of the Wolf - Charbringer corpse');

CREATE TABLE IF NOT EXISTS `azerothlab_perfecting_howl_spell_script_backup`
LIKE `spell_script_names`;

INSERT IGNORE INTO `azerothlab_perfecting_howl_spell_script_backup`
SELECT * FROM `spell_script_names` WHERE `spell_id` = 97605;

DELETE FROM `spell_script_names`
WHERE `spell_id` = 97605
  AND `ScriptName` = 'spell_fury_of_the_wolf';

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`)
VALUES (97605, 'spell_fury_of_the_wolf');

SELECT template.`entry`, names.`Name1`, template.`AIName`
FROM `creature_template` template
JOIN `creature_template_wdb` names ON names.`Entry` = template.`entry`
WHERE template.`entry` IN (46910, 52791)
ORDER BY template.`entry`;

SELECT `spell_id`, `ScriptName`
FROM `spell_script_names`
WHERE `spell_id` = 97605;

SELECT `ElseGroup`, `ConditionValue2`, `Comment`
FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 7
  AND `SourceEntry` = 97605
  AND `ConditionTypeOrReference` = 31
ORDER BY `ElseGroup`;
