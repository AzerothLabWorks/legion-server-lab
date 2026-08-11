USE `legion_hotfixes`;

-- The repack's Nordrassil Coin records are custom DB2 hotfix rows. Keep the
-- functional account-shop tokens, but expose their purpose in English.
UPDATE `item_sparse`
SET `Description` = CASE `ID`
    WHEN 505051 THEN '|cff00FF00Use: Adds 1 coin to your in-game Shop balance.|r'
    WHEN 505052 THEN '|cff00FF00Use: Adds 2 coins to your in-game Shop balance.|r'
    WHEN 505053 THEN '|cff00FF00Use: Adds 3 coins to your in-game Shop balance.|r'
    WHEN 505054 THEN '|cff00FF00Use: Adds 4 coins to your in-game Shop balance.|r'
    WHEN 505055 THEN '|cff00FF00Use: Adds 5 coins to your in-game Shop balance.|r'
    WHEN 505056 THEN '|cff00FF00Use: Adds 10 coins to your in-game Shop balance.|r'
END
WHERE `ID` BETWEEN 505051 AND 505056;

-- Publish fresh hotfix IDs for ItemSparse (table hash 0x919BE54E). Clients
-- that cached the repack's original records will request these new IDs and
-- receive the English descriptions without requiring a cache reset.
INSERT INTO `hotfix_data` (`Id`, `TableHash`, `RecordID`, `Timestamp`, `Deleted`) VALUES
    (7005051, 2442913102, 505051, 0, 0),
    (7005052, 2442913102, 505052, 0, 0),
    (7005053, 2442913102, 505053, 0, 0),
    (7005054, 2442913102, 505054, 0, 0),
    (7005055, 2442913102, 505055, 0, 0),
    (7005056, 2442913102, 505056, 0, 0)
ON DUPLICATE KEY UPDATE
    `RecordID` = VALUES(`RecordID`),
    `Deleted` = VALUES(`Deleted`);
