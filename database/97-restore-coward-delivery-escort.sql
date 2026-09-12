USE `legion_world`;

-- Coward Delivery... Under 30 Minutes or it's Free (11711) retains its quest
-- item and objective in the preservation database, but the authored escort
-- and handoff data is absent. The quest consequently gives the player a flare
-- gun without summoning Alliance Deserter 25761, and the flare cannot summon
-- Valiance Keep Officer 25759 or award delivery credit.
--
-- Restore the canonical, quest-scoped sequence:
--   * cast Call Alliance Deserter (45975) when the quest is accepted;
--   * let Warden Nork's existing recovery gossip summon a lost deserter;
--   * require the deserter aura before firing the flare;
--   * link flare spell 45958 to Alliance signal spell 45956;
--   * summon the officer at the authored crossroads position; and
--   * have the officer approach, award quest credit, and dismiss the escort.

CREATE TABLE IF NOT EXISTS `azerothlab_coward_delivery_quest_backup`
LIKE `quest_template_addon`;

CREATE TABLE IF NOT EXISTS `azerothlab_coward_delivery_template_backup`
LIKE `creature_template`;

CREATE TABLE IF NOT EXISTS `azerothlab_coward_delivery_smartai_backup`
LIKE `smart_scripts`;

CREATE TABLE IF NOT EXISTS `azerothlab_coward_delivery_conditions_backup`
LIKE `conditions`;

CREATE TABLE IF NOT EXISTS `azerothlab_coward_delivery_spell_link_backup`
LIKE `spell_linked_spell`;

CREATE TABLE IF NOT EXISTS `azerothlab_coward_delivery_target_position_backup`
LIKE `spell_target_position`;

CREATE TABLE IF NOT EXISTS `azerothlab_coward_delivery_text_backup`
LIKE `creature_text`;

INSERT IGNORE INTO `azerothlab_coward_delivery_quest_backup`
SELECT * FROM `quest_template_addon` WHERE `ID` = 11711;

INSERT IGNORE INTO `azerothlab_coward_delivery_template_backup`
SELECT * FROM `creature_template` WHERE `entry` IN (25379, 25759, 25761);

INSERT IGNORE INTO `azerothlab_coward_delivery_smartai_backup`
SELECT * FROM `smart_scripts`
WHERE (`entryorguid` = 25379 AND `source_type` = 0 AND `id` BETWEEN 0 AND 2)
   OR (`entryorguid` = 25759 AND `source_type` = 0 AND `id` BETWEEN 0 AND 4);

INSERT IGNORE INTO `azerothlab_coward_delivery_conditions_backup`
SELECT * FROM `conditions`
WHERE (`SourceTypeOrReferenceId` = 15 AND `SourceGroup` = 9184)
   OR (`SourceTypeOrReferenceId` = 17 AND `SourceEntry` = 45958);

INSERT IGNORE INTO `azerothlab_coward_delivery_spell_link_backup`
SELECT * FROM `spell_linked_spell`
WHERE `spell_trigger` = 45958 AND `spell_effect` = 45956;

INSERT IGNORE INTO `azerothlab_coward_delivery_target_position_backup`
SELECT * FROM `spell_target_position` WHERE `id` = 45956;

INSERT IGNORE INTO `azerothlab_coward_delivery_text_backup`
SELECT * FROM `creature_text`
WHERE `Entry` IN (25379, 25759) AND `GroupID` = 0 AND `ID` = 0;

START TRANSACTION;

UPDATE `quest_template_addon`
SET `SourceSpellID` = 45975
WHERE `ID` = 11711;

-- Keep the summoned officer outside player/NPC combat while it performs the
-- delivery event, matching the original quest implementation.
UPDATE `creature_template`
SET `unit_flags` = `unit_flags` | 768,
    `AIName` = 'SmartAI'
WHERE `entry` = 25759;

DELETE FROM `conditions`
WHERE (`SourceTypeOrReferenceId` = 15
       AND `SourceGroup` = 9184
       AND `ConditionTypeOrReference` = 9
       AND `ConditionValue1` = 11711)
   OR (`SourceTypeOrReferenceId` = 17
       AND `SourceEntry` = 45958
       AND `ConditionTypeOrReference` = 1
       AND `ConditionValue1` = 45957);

INSERT INTO `conditions`
    (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`,
     `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`,
     `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
     `NegativeCondition`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
    (15, 9184, 0, 0, 0, 9, 0, 11711, 0, 0, 0, 0, '',
     'Coward Delivery - Show lost-deserter recovery while quest is incomplete'),
    (17, 0, 45958, 0, 0, 1, 0, 45957, 0, 0, 0, 0, '',
     'Coward Delivery - Flare requires Alliance Deserter aura');

DELETE FROM `spell_linked_spell`
WHERE `spell_trigger` = 45958 AND `spell_effect` = 45956;

INSERT INTO `spell_linked_spell`
    (`spell_trigger`, `spell_effect`, `type`, `comment`)
VALUES
    (45958, 45956, 1, 'Coward Delivery - Signal Alliance');

INSERT INTO `spell_target_position`
    (`id`, `target_map`, `target_position_x`, `target_position_y`,
     `target_position_z`, `target_orientation`)
VALUES
    (45956, 571, 2921.65, 5347.06, 61.282, 1.07)
ON DUPLICATE KEY UPDATE
    `target_map` = VALUES(`target_map`),
    `target_position_x` = VALUES(`target_position_x`),
    `target_position_y` = VALUES(`target_position_y`),
    `target_position_z` = VALUES(`target_position_z`),
    `target_orientation` = VALUES(`target_orientation`);

DELETE FROM `creature_text`
WHERE `Entry` IN (25379, 25759) AND `GroupID` = 0 AND `ID` = 0;

INSERT INTO `creature_text`
    (`Entry`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`,
     `Emote`, `Duration`, `Sound`, `BroadcastTextID`, `MinTimer`, `MaxTimer`,
     `SpellID`, `comment`)
VALUES
    (25379, 0, 0,
     'Try to not lose this one, $n. It is important that we at least try and keep up appearances with the Alliance.',
     15, 1, 100, 0, 0, 0, 24977, 0, 0, 0,
     'Warden Nork Bloodfrenzy - Lost deserter replacement'),
    (25759, 0, 0,
     'Thank you, $r. I will take this miserable cur from you now.',
     12, 1, 100, 1, 0, 0, 24966, 0, 0, 0,
     'Valiance Keep Officer - Coward Delivery handoff');

DELETE FROM `smart_scripts`
WHERE (`entryorguid` = 25379 AND `source_type` = 0 AND `id` BETWEEN 0 AND 2)
   OR (`entryorguid` = 25759 AND `source_type` = 0 AND `id` BETWEEN 0 AND 4);

INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`,
     `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`,
     `action_type`, `action_param1`, `action_param2`, `action_param3`,
     `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`,
     `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    -- Warden Nork's existing gossip option is the canonical recovery path for
    -- an escort lost after accepting the quest.
    (25379, 0, 0, 1, 62, 0, 100, 0,
     9184, 0, 0, 0,
     1, 0, 0, 0, 0, 0, 0,
     7, 0, 0, 0, 0, 0, 0, 0,
     'Warden Nork - Coward Delivery recovery - Talk'),
    (25379, 0, 1, 2, 61, 0, 100, 0,
     0, 0, 0, 0,
     11, 45975, 0, 0, 0, 0, 0,
     7, 0, 0, 0, 0, 0, 0, 0,
     'Warden Nork - Coward Delivery recovery - Call Alliance Deserter'),
    (25379, 0, 2, 0, 61, 0, 100, 1,
     0, 0, 0, 0,
     72, 0, 0, 0, 0, 0, 0,
     7, 0, 0, 0, 0, 0, 0, 0,
     'Warden Nork - Coward Delivery recovery - Close gossip'),

    -- The signal summons an officer at the crossroads. It approaches the
    -- summoner, speaks, awards credit, and dismisses the nearby deserter.
    (25759, 0, 0, 0, 60, 0, 100, 1,
     0, 0, 0, 0,
     69, 1, 0, 0, 0, 0, 0,
     8, 0, 0, 0, 2937.55, 5377.94, 60.64, 0,
     'Valiance Keep Officer - Coward Delivery - Move to handoff'),
    (25759, 0, 1, 2, 34, 0, 100, 1,
     8, 1, 0, 0,
     1, 0, 0, 0, 0, 0, 0,
     21, 40, 0, 0, 0, 0, 0, 0,
     'Valiance Keep Officer - Coward Delivery - Announce handoff'),
    (25759, 0, 2, 3, 61, 0, 100, 1,
     0, 0, 0, 0,
     15, 11711, 0, 0, 0, 0, 0,
     18, 40, 0, 0, 0, 0, 0, 0,
     'Valiance Keep Officer - Coward Delivery - Award delivery credit'),
    (25759, 0, 3, 4, 61, 0, 100, 1,
     0, 0, 0, 0,
     41, 5000, 0, 0, 0, 0, 0,
     11, 25761, 50, 0, 0, 0, 0, 0,
     'Valiance Keep Officer - Coward Delivery - Dismiss deserter'),
    (25759, 0, 4, 0, 61, 0, 100, 1,
     0, 0, 0, 0,
     41, 5000, 0, 0, 0, 0, 0,
     1, 0, 0, 0, 0, 0, 0, 0,
     'Valiance Keep Officer - Coward Delivery - Despawn');

COMMIT;

SELECT `ID`, `SourceSpellID`
FROM `quest_template_addon`
WHERE `ID` = 11711;

SELECT
    (SELECT COUNT(*) FROM `smart_scripts`
     WHERE `entryorguid` = 25379 AND `source_type` = 0
       AND `id` BETWEEN 0 AND 2) AS `recovery_rows`,
    (SELECT COUNT(*) FROM `smart_scripts`
     WHERE `entryorguid` = 25759 AND `source_type` = 0
       AND `id` BETWEEN 0 AND 4) AS `handoff_rows`,
    (SELECT COUNT(*) FROM `spell_linked_spell`
     WHERE `spell_trigger` = 45958 AND `spell_effect` = 45956)
       AS `signal_links`,
    (SELECT COUNT(*) FROM `spell_target_position`
     WHERE `id` = 45956 AND `target_map` = 571) AS `signal_positions`;
