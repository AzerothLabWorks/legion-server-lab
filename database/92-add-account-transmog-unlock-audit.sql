USE `legion_characters`;

-- Preserve each account's pre-bulk-unlock collection and keep a compact audit
-- of GM-triggered unlock runs. The command populates these tables before it
-- inserts any new build-matched appearances.

CREATE TABLE IF NOT EXISTS `azerothlab_account_transmogs_before_unlock`
    LIKE `account_transmogs`;

CREATE TABLE IF NOT EXISTS `azerothlab_account_transmog_unlock_log` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `account` INT UNSIGNED NOT NULL,
    `guid` INT UNSIGNED NOT NULL,
    `scanned` INT UNSIGNED NOT NULL,
    `eligible` INT UNSIGNED NOT NULL,
    `added` INT UNSIGNED NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_account_created` (`account`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SELECT
    (SELECT COUNT(*) FROM `azerothlab_account_transmogs_before_unlock`) AS `backed_up_appearances`,
    (SELECT COUNT(*) FROM `azerothlab_account_transmog_unlock_log`) AS `unlock_runs`;
