USE `legion_world`;

-- Scarlet Armies Approach... (quest 12757) asks Orbaz Bloodbane to open a
-- temporary portal to Acherus. The imported Legion world DB has the initial
-- quest-accept action and the recovery gossip option, but lacks the SmartAI
-- gossip-select actions that recover the player. LegionCore 7.3.5 does not
-- register the old WotLK 53097/53099 portal spell scripts, so recasting the
-- spell produces no usable gate. Teleport the gossip invoker directly to
-- Highlord Darion Mograine's quest location in Acherus instead.

CREATE TABLE IF NOT EXISTS `azerothlab_orbaz_smartai_backup`
    LIKE `smart_scripts`;

START TRANSACTION;

-- Without SmartAI assigned on the template, neither the imported quest-accept
-- row nor the recovery gossip rows can execute on this Legion world DB.
UPDATE `creature_template`
SET `AIName` = 'SmartAI'
WHERE `entry` = 28914
  AND (`AIName` = '' OR `AIName` IS NULL);

INSERT IGNORE INTO `azerothlab_orbaz_smartai_backup`
SELECT * FROM `smart_scripts`
WHERE `entryorguid` = 28914 AND `source_type` = 0 AND `id` IN (1, 2);

DELETE FROM `smart_scripts`
WHERE `entryorguid` = 28914 AND `source_type` = 0 AND `id` IN (1, 2);

INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`,
    `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`,
    `action_type`, `action_param1`, `action_param2`, `action_param3`,
    `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`,
    `target_x`, `target_y`, `target_z`, `target_o`, `comment`
) VALUES
    (28914, 0, 1, 2, 62, 0, 100, 0, 9769, 0, 0, 0,
     62, 609, 0, 0, 0, 0, 0, 7, 0, 0, 0,
     2460.5, -5593.47, 367.476, 3.66519,
     'Orbaz Bloodbane - On recovery gossip select - Teleport player to Acherus'),
    (28914, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0,
     72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0,
     'Orbaz Bloodbane - After recovery gossip select - Close gossip');

COMMIT;

SELECT COUNT(*) AS `orbaz_gate_recovery_rows`
FROM `smart_scripts`
WHERE `entryorguid` = 28914 AND `source_type` = 0 AND `id` IN (1, 2);
