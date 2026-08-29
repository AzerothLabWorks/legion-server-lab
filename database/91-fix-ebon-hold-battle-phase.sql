USE `legion_world`;

-- The imported spell_area data keeps Death Knights in the Battle for the
-- Ebon Hold phase after the faction-specific follow-up quest is complete.
-- That makes the restored Ebon Blade population coexist with Patchwerk and
-- the hostile battle population on the upper floor of Acherus.
--
-- Normalize only the verified Ebon Hold rows to the reference quest-state
-- progression. Keep Legion's expanded allied-race masks rather than replacing
-- them with legacy WotLK race masks. Existing characters are corrected the
-- next time spell-area requirements are evaluated (login/map load).

CREATE TABLE IF NOT EXISTS `azerothlab_ebon_hold_spell_area_backup`
    LIKE `spell_area`;

START TRANSACTION;

INSERT IGNORE INTO `azerothlab_ebon_hold_spell_area_backup`
SELECT *
FROM `spell_area`
WHERE (`spell` = 53642 AND `area` = 4281 AND `quest_start` = 13166)
   OR (`spell` = 58361 AND `area` = 4281 AND `quest_start` = 13166)
   OR (`spell` = 58354 AND `area` = 4281 AND `quest_end` IN (13188, 13189));

-- 53642 is an older Might of Mograine combat buff, not the phase aura used by
-- this quest sequence. Remove only the erroneous Battle for Ebon Hold mapping;
-- the separate Light of Dawn area mapping remains untouched.
DELETE FROM `spell_area`
WHERE `spell` = 53642
  AND `area` = 4281
  AND `quest_start` = 13166;

-- Remove the malformed phase rows before installing the corrected progression.
DELETE FROM `spell_area`
WHERE `spell` = 58354
  AND `area` = 4281
  AND `quest_end` IN (13188, 13189);

INSERT INTO `spell_area` (
    `spell`, `area`, `quest_start`, `quest_end`, `aura_spell`,
    `racemask`, `classmask`, `active_event`, `gender`, `autocast`,
    `quest_start_status`, `quest_end_status`
) VALUES
    -- Battle quest combat buff. This is intentionally not the phase aura.
    (58361, 4281, 13166, 13166, 0, 0, 0, 0, 2, 1, 74, 11),
    -- Alliance and Horde Ebon Hold phase progression. The race masks include
    -- the Legion 7.3.5 allied races supported by this build.
    (58354, 4281, 12801, 13188, 0, 2098253, 0, 0, 2, 1, 64, 11),
    (58354, 4281, 12801, 13189, 0, 946, 0, 0, 2, 1, 64, 11)
ON DUPLICATE KEY UPDATE
    `quest_end` = VALUES(`quest_end`),
    `autocast` = VALUES(`autocast`),
    `quest_start_status` = VALUES(`quest_start_status`),
    `quest_end_status` = VALUES(`quest_end_status`);

COMMIT;

SELECT
    `spell`, `area`, `quest_start`, `quest_start_status`,
    `quest_end`, `quest_end_status`, `racemask`, `autocast`
FROM `spell_area`
WHERE (`spell` = 58361 AND `area` = 4281 AND `quest_start` = 13166)
   OR (`spell` = 58354 AND `area` = 4281 AND `quest_end` IN (13188, 13189))
ORDER BY `spell`, `racemask`;
