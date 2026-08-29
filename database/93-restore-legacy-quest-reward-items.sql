USE `legion_hotfixes`;

-- Quest 10086 (I Work... For the Horde!) and its Alliance counterpart still
-- reference four canonical Burning Crusade rewards.  Their names remain in the
-- build-26365 client data, but the preservation database is missing both the
-- Item and indexed ItemSparse rows needed to construct server item templates.
-- Selecting one therefore reports "Item not found".
--
-- Restore the minimal original item definitions.  The names, quality, item
-- level, prices, armor classes, slots, and primary stats below are preserved
-- from the legacy item_template definitions for these exact item IDs.  Client
-- appearance data remains client-side and is not redistributed here.

INSERT INTO `item`
    (`ID`, `IconFileDataID`, `ClassID`, `SubclassID`, `SoundOverrideSubclass`,
     `Material`, `InventoryType`, `SheatheType`, `ItemGroupSoundsID`, `VerifiedBuild`)
VALUES
    (29931, 0, 4, 2, -1, 8, 1, 0,  7, 26365), -- Phantasmal Headdress (leather head)
    (29938, 0, 4, 2, -1, 8, 5, 0,  7, 26365), -- Battle Seeker Chestguard (leather chest)
    (29943, 0, 4, 3, -1, 5, 1, 0, 10, 26365), -- Legionnaire's Studded Helm (mail head)
    (29945, 0, 4, 4, -1, 6, 7, 0, 11, 26365)  -- Magistrate's Greaves (plate legs)
ON DUPLICATE KEY UPDATE
    `ClassID` = VALUES(`ClassID`),
    `SubclassID` = VALUES(`SubclassID`),
    `SoundOverrideSubclass` = VALUES(`SoundOverrideSubclass`),
    `Material` = VALUES(`Material`),
    `InventoryType` = VALUES(`InventoryType`),
    `SheatheType` = VALUES(`SheatheType`),
    `ItemGroupSoundsID` = VALUES(`ItemGroupSoundsID`),
    `VerifiedBuild` = VALUES(`VerifiedBuild`);

INSERT INTO `item_sparse`
    (`ID`, `AllowableRace`, `Display`, `VendorStackCount`, `BuyPrice`,
     `SellPrice`, `Stackable`, `AllowableClass`, `ItemLevel`,
     `ItemStatValue1`, `ItemStatValue2`, `ItemStatValue3`,
     `OverallQualityID`, `InventoryType`,
     `StatModifierBonusStat1`, `StatModifierBonusStat2`,
     `StatModifierBonusStat3`, `Bonding`, `Material`, `ExpansionID`,
     `VerifiedBuild`)
VALUES
    (29931, -1, 'Phantasmal Headdress',          1,  99275, 19855, 1, -1, 81,
        19, 19, 12, 2, 1, 5, 7, 6, 1, 8, 1, 26365),
    (29938, -1, 'Battle Seeker Chestguard',     1, 124923, 24984, 1, -1, 81,
        19, 30,  0, 2, 5, 3, 7, 0, 1, 8, 1, 26365),
    (29943, -1, 'Legionnaire''s Studded Helm',  1,  99275, 19855, 1, -1, 81,
        19, 30,  0, 2, 1, 3, 7, 0, 1, 5, 1, 26365),
    (29945, -1, 'Magistrate''s Greaves',        1, 124923, 24984, 1, -1, 81,
        19, 30, 19, 2, 7, 3, 7, 4, 1, 6, 1, 26365)
ON DUPLICATE KEY UPDATE
    `AllowableRace` = VALUES(`AllowableRace`),
    `Display` = VALUES(`Display`),
    `VendorStackCount` = VALUES(`VendorStackCount`),
    `BuyPrice` = VALUES(`BuyPrice`),
    `SellPrice` = VALUES(`SellPrice`),
    `Stackable` = VALUES(`Stackable`),
    `AllowableClass` = VALUES(`AllowableClass`),
    `ItemLevel` = VALUES(`ItemLevel`),
    `ItemStatValue1` = VALUES(`ItemStatValue1`),
    `ItemStatValue2` = VALUES(`ItemStatValue2`),
    `ItemStatValue3` = VALUES(`ItemStatValue3`),
    `OverallQualityID` = VALUES(`OverallQualityID`),
    `InventoryType` = VALUES(`InventoryType`),
    `StatModifierBonusStat1` = VALUES(`StatModifierBonusStat1`),
    `StatModifierBonusStat2` = VALUES(`StatModifierBonusStat2`),
    `StatModifierBonusStat3` = VALUES(`StatModifierBonusStat3`),
    `Bonding` = VALUES(`Bonding`),
    `Material` = VALUES(`Material`),
    `ExpansionID` = VALUES(`ExpansionID`),
    `VerifiedBuild` = VALUES(`VerifiedBuild`);

SELECT i.`ID`, s.`Display`, i.`ClassID`, i.`SubclassID`,
       i.`InventoryType`, s.`ItemLevel`, s.`VerifiedBuild`
FROM `item` i
JOIN `item_sparse` s ON s.`ID` = i.`ID`
WHERE i.`ID` IN (29931, 29938, 29943, 29945)
ORDER BY i.`ID`;
