# Nordrassil Coins

Nordrassil Coins are custom account-shop tokens inherited from the Nordrassil
server base. They are functional in this lab rather than ordinary vendor trash.

## How they work

- The played-time reward grants item `505056` every five minutes by default.
- Right-clicking item `505056` consumes it and adds 10 coins to the Battle.net
  account's Shop balance.
- The balance is shared at the Battle.net-account level, not stored on an
  individual character.
- The in-game **Shop** button displays products that can be purchased with the
  balance.
- Opening the Shop also reports `Your Shop balance is: N coins` in chat. This
  is the authoritative account-wide balance even when the Shop panel does not
  display a separate balance counter.

The other supported token denominations are item IDs `505051` through `505055`
and redeem for 1, 2, 3, 4, and 5 Shop coins respectively.

## Localization

The upstream custom DB2 records and redemption notifications were Spanish.
The lab applies English descriptions through
`database/70-nordrassil-coin-localization.sql` and publishes new ItemSparse
hotfix IDs so an existing client will request the translated records.

If an already-running client still displays the old text, fully exit the client
and reconnect. Clearing the client Cache directory should only be needed as a
last resort.
