USE `legion_world`;

-- The imported Vilebranch templates (2640-2647) declare SmartAI and carry
-- combat spells, but this archive contains no matching smart_scripts rows.
-- SmartAI therefore has no rotation to execute. Install a conservative,
-- old-core-compatible translation of the intended melee, caster, support,
-- and low-health behavior. Existing entry-level SmartAI is never replaced.

CREATE TABLE IF NOT EXISTS `azerothlab_vilebranch_smart_scripts_backup`
    LIKE `smart_scripts`;

START TRANSACTION;

INSERT IGNORE INTO `azerothlab_vilebranch_smart_scripts_backup`
SELECT `script`.*
FROM `smart_scripts` `script`
WHERE `script`.`source_type` = 0
  AND `script`.`entryorguid` IN (2640, 2641, 2642, 2643, 2644, 2645, 2646, 2647);

DROP TEMPORARY TABLE IF EXISTS `_alw_vilebranch_missing_smartai`;
CREATE TEMPORARY TABLE `_alw_vilebranch_missing_smartai` (
    `entry` BIGINT(20) NOT NULL,
    PRIMARY KEY (`entry`)
) ENGINE=MEMORY;

INSERT INTO `_alw_vilebranch_missing_smartai` (`entry`)
SELECT `candidate`.`entry`
FROM (
    SELECT 2640 AS `entry` UNION ALL
    SELECT 2641 UNION ALL
    SELECT 2642 UNION ALL
    SELECT 2643 UNION ALL
    SELECT 2644 UNION ALL
    SELECT 2645 UNION ALL
    SELECT 2646 UNION ALL
    SELECT 2647
) `candidate`
INNER JOIN `creature_template` `template`
    ON `template`.`entry` = `candidate`.`entry`
WHERE `template`.`AIName` = 'SmartAI'
  AND NOT EXISTS (
      SELECT 1
      FROM `smart_scripts` `existing`
      WHERE `existing`.`source_type` = 0
        AND `existing`.`entryorguid` = `candidate`.`entry`
  );

DROP TEMPORARY TABLE IF EXISTS `_alw_vilebranch_desired_smartai`;
CREATE TEMPORARY TABLE `_alw_vilebranch_desired_smartai`
    LIKE `smart_scripts`;

INSERT INTO `_alw_vilebranch_desired_smartai`
    -- Vilebranch Witch Doctor: hold casting range, use Shadow Bolt and Hex.
    SELECT 2640,0,0,0,4,0,100,1,0,0,0,0,22,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Witch Doctor - On aggro - Set caster phase' UNION ALL
    SELECT 2640,0,1,0,4,1,100,1,0,0,0,0,21,0,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Witch Doctor - On aggro - Stop at casting range' UNION ALL
    SELECT 2640,0,2,0,4,1,100,1,0,0,0,0,11,9613,0,0,0,0,0,2,0,0,0,0,0,0,0,'Vilebranch Witch Doctor - On aggro - Cast Shadow Bolt' UNION ALL
    SELECT 2640,0,3,0,9,1,100,0,0,40,3400,4800,11,9613,0,0,0,0,0,2,0,0,0,0,0,0,0,'Vilebranch Witch Doctor - In range - Cast Shadow Bolt' UNION ALL
    SELECT 2640,0,4,0,9,1,100,0,40,100,500,500,21,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Witch Doctor - Outside casting range - Chase' UNION ALL
    SELECT 2640,0,5,0,9,1,100,0,0,40,500,500,21,0,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Witch Doctor - In casting range - Hold position' UNION ALL
    SELECT 2640,0,6,0,0,1,100,0,9000,13000,22000,28000,11,18503,0,0,0,0,0,2,0,0,0,0,0,0,0,'Vilebranch Witch Doctor - In combat - Cast Hex' UNION ALL
    SELECT 2640,0,7,0,2,0,100,1,0,15,0,0,25,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Witch Doctor - Below 15 percent health - Flee for assistance' UNION ALL

    -- Vilebranch Headhunter: fight at throwing range, stab if engaged closely.
    SELECT 2641,0,0,0,4,0,100,1,0,0,0,0,22,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Headhunter - On aggro - Set ranged phase' UNION ALL
    SELECT 2641,0,1,0,4,1,100,1,0,0,0,0,21,0,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Headhunter - On aggro - Stop for ranged attack' UNION ALL
    SELECT 2641,0,2,0,4,1,100,1,0,0,0,0,11,10277,0,0,0,0,0,2,0,0,0,0,0,0,0,'Vilebranch Headhunter - On aggro - Cast Throw' UNION ALL
    SELECT 2641,0,3,0,9,1,100,0,5,30,2300,3900,11,10277,0,0,0,0,0,2,0,0,0,0,0,0,0,'Vilebranch Headhunter - At ranged distance - Cast Throw' UNION ALL
    SELECT 2641,0,4,0,9,1,100,0,30,100,500,500,21,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Headhunter - Outside throwing range - Chase' UNION ALL
    SELECT 2641,0,5,0,9,1,100,0,0,5,500,500,21,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Headhunter - Inside throwing range - Close distance' UNION ALL
    SELECT 2641,0,6,0,9,1,100,0,5,30,500,500,21,0,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Headhunter - At throwing range - Hold position' UNION ALL
    SELECT 2641,0,7,0,9,0,100,0,0,5,15000,18000,11,7357,0,0,0,0,0,2,0,0,0,0,0,0,0,'Vilebranch Headhunter - In melee range - Cast Poisonous Stab' UNION ALL
    SELECT 2641,0,8,0,2,0,100,1,0,15,0,0,25,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Headhunter - Below 15 percent health - Flee for assistance' UNION ALL

    -- Vilebranch Shadowcaster: hold casting range, use Shadow Bolt and Shrink.
    SELECT 2642,0,0,0,4,0,100,1,0,0,0,0,22,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Shadowcaster - On aggro - Set caster phase' UNION ALL
    SELECT 2642,0,1,0,4,1,100,1,0,0,0,0,21,0,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Shadowcaster - On aggro - Stop at casting range' UNION ALL
    SELECT 2642,0,2,0,4,1,100,1,0,0,0,0,11,9613,0,0,0,0,0,2,0,0,0,0,0,0,0,'Vilebranch Shadowcaster - On aggro - Cast Shadow Bolt' UNION ALL
    SELECT 2642,0,3,0,9,1,100,0,0,40,3400,4800,11,9613,0,0,0,0,0,2,0,0,0,0,0,0,0,'Vilebranch Shadowcaster - In range - Cast Shadow Bolt' UNION ALL
    SELECT 2642,0,4,0,9,1,100,0,40,100,500,500,21,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Shadowcaster - Outside casting range - Chase' UNION ALL
    SELECT 2642,0,5,0,9,1,100,0,0,40,500,500,21,0,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Shadowcaster - In casting range - Hold position' UNION ALL
    SELECT 2642,0,6,0,0,1,100,0,2500,10000,35000,40000,11,7289,0,0,0,0,0,2,0,0,0,0,0,0,0,'Vilebranch Shadowcaster - In combat - Cast Shrink' UNION ALL
    SELECT 2642,0,7,0,2,0,100,1,0,15,0,0,25,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Shadowcaster - Below 15 percent health - Flee for assistance' UNION ALL

    -- Vilebranch Berserker: enrage once at low health and then seek help.
    SELECT 2643,0,0,0,2,0,100,1,0,30,0,0,11,8599,32,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Berserker - Below 30 percent health - Cast Enrage' UNION ALL
    SELECT 2643,0,1,0,2,0,100,1,0,15,0,0,25,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Berserker - Below 15 percent health - Flee for assistance' UNION ALL

    -- Vilebranch Hideskinner: use Poison and positional Backstab.
    SELECT 2644,0,0,0,0,0,100,0,2000,5000,15000,20000,11,744,32,0,0,0,0,2,0,0,0,0,0,0,0,'Vilebranch Hideskinner - In combat - Cast Poison' UNION ALL
    SELECT 2644,0,1,0,67,0,100,0,5000,9000,0,0,11,7159,0,0,0,0,0,2,0,0,0,0,0,0,0,'Vilebranch Hideskinner - Behind target - Cast Backstab' UNION ALL
    SELECT 2644,0,2,0,2,0,100,1,0,15,0,0,25,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Hideskinner - Below 15 percent health - Flee for assistance' UNION ALL

    -- Vilebranch Shadow Hunter: use the valid Legion Shoot spell plus support magic.
    SELECT 2645,0,0,0,4,0,100,1,0,0,0,0,22,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Shadow Hunter - On aggro - Set ranged phase' UNION ALL
    SELECT 2645,0,1,0,4,1,100,1,0,0,0,0,21,0,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Shadow Hunter - On aggro - Stop for ranged attack' UNION ALL
    SELECT 2645,0,2,0,4,1,100,1,0,0,0,0,11,74613,0,0,0,0,0,2,0,0,0,0,0,0,0,'Vilebranch Shadow Hunter - On aggro - Cast Shoot' UNION ALL
    SELECT 2645,0,3,0,9,1,100,0,5,30,2300,3900,11,74613,0,0,0,0,0,2,0,0,0,0,0,0,0,'Vilebranch Shadow Hunter - At ranged distance - Cast Shoot' UNION ALL
    SELECT 2645,0,4,0,9,1,100,0,30,100,500,500,21,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Shadow Hunter - Outside shooting range - Chase' UNION ALL
    SELECT 2645,0,5,0,9,1,100,0,0,5,500,500,21,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Shadow Hunter - Inside shooting range - Create distance' UNION ALL
    SELECT 2645,0,6,0,9,1,100,0,5,30,500,500,21,0,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Shadow Hunter - At shooting range - Hold position' UNION ALL
    SELECT 2645,0,7,0,9,0,100,0,0,30,21000,26000,11,14032,32,0,0,0,0,2,0,0,0,0,0,0,0,'Vilebranch Shadow Hunter - In range - Cast Shadow Word Pain' UNION ALL
    SELECT 2645,0,8,0,0,0,100,0,4000,9000,15000,21000,11,9657,32,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Shadow Hunter - In combat - Cast Shadow Shell' UNION ALL
    SELECT 2645,0,9,0,2,0,100,1,0,15,0,0,25,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Shadow Hunter - Below 15 percent health - Flee for assistance' UNION ALL

    -- Vilebranch Blood Drinker and Soul Eater: restore their missing melee kits.
    SELECT 2646,0,0,0,9,0,100,0,0,5,7000,15000,11,11015,0,0,0,0,0,2,0,0,0,0,0,0,0,'Vilebranch Blood Drinker - In melee range - Cast Blood Leech' UNION ALL
    SELECT 2646,0,1,0,2,0,100,1,0,15,0,0,25,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Blood Drinker - Below 15 percent health - Flee for assistance' UNION ALL
    SELECT 2647,0,0,0,9,0,100,0,0,5,8000,12000,11,11016,0,0,0,0,0,2,0,0,0,0,0,0,0,'Vilebranch Soul Eater - In melee range - Cast Soul Bite' UNION ALL
    SELECT 2647,0,1,0,14,0,100,0,600,10,12000,15000,11,7154,1,0,0,0,0,7,0,0,0,0,0,0,0,'Vilebranch Soul Eater - Injured nearby ally - Cast Dark Offering' UNION ALL
    SELECT 2647,0,2,0,2,0,100,1,0,15,0,0,25,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Vilebranch Soul Eater - Below 15 percent health - Flee for assistance';

INSERT INTO `smart_scripts`
SELECT `desired`.*
FROM `_alw_vilebranch_desired_smartai` `desired`
INNER JOIN `_alw_vilebranch_missing_smartai` `missing`
    ON `missing`.`entry` = `desired`.`entryorguid`;

SET @azerothlab_vilebranch_scripts_inserted = ROW_COUNT();

COMMIT;

SELECT
    @azerothlab_vilebranch_scripts_inserted AS `vilebranch_smart_scripts_inserted`,
    (SELECT COUNT(*)
     FROM `smart_scripts`
     WHERE `source_type` = 0
       AND `entryorguid` IN (2640, 2641, 2642, 2643, 2644, 2645, 2646, 2647))
        AS `vilebranch_smart_scripts_total`;

DROP TEMPORARY TABLE IF EXISTS `_alw_vilebranch_missing_smartai`;
DROP TEMPORARY TABLE IF EXISTS `_alw_vilebranch_desired_smartai`;
