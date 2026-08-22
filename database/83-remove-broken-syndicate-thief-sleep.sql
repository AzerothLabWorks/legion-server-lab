USE `legion_world`;

-- Syndicate Thief (24477) is an ordinary hostile quest creature, but the
-- imported template gives every spawn the permanent "Sleeping Sleep" aura.
-- No script removes that decoration on proximity or aggro, so all 22 thieves
-- remain asleep indefinitely. Other users of spell 42648 (for example,
-- Off-Duty Siegeworker) are intentionally left unchanged.

CREATE TABLE IF NOT EXISTS `azerothlab_removed_creature_template_addons`
    LIKE `creature_template_addon`;

CREATE TABLE IF NOT EXISTS `azerothlab_removed_creature_template_spells`
    LIKE `creature_template_spell`;

START TRANSACTION;

INSERT IGNORE INTO `azerothlab_removed_creature_template_addons`
SELECT `cta`.*
FROM `creature_template_addon` `cta`
WHERE `cta`.`entry` = 24477
  AND CONCAT(' ', TRIM(COALESCE(`cta`.`auras`, '')), ' ') LIKE '% 42648 %';

INSERT IGNORE INTO `azerothlab_removed_creature_template_spells`
SELECT `cts`.*
FROM `creature_template_spell` `cts`
WHERE `cts`.`entry` = 24477
  AND `cts`.`spell` = 42648;

UPDATE `creature_template_addon`
SET `auras` = NULLIF(
    TRIM(REPLACE(CONCAT(' ', TRIM(COALESCE(`auras`, '')), ' '), ' 42648 ', ' ')),
    ''
)
WHERE `entry` = 24477
  AND CONCAT(' ', TRIM(COALESCE(`auras`, '')), ' ') LIKE '% 42648 %';

SET @azerothlab_removed_thief_sleep_auras = ROW_COUNT();

DELETE FROM `creature_template_spell`
WHERE `entry` = 24477
  AND `spell` = 42648;

SET @azerothlab_removed_thief_sleep_spells = ROW_COUNT();

COMMIT;

SELECT
    @azerothlab_removed_thief_sleep_auras AS `removed_syndicate_thief_sleep_auras`,
    @azerothlab_removed_thief_sleep_spells AS `removed_syndicate_thief_sleep_spells`;
