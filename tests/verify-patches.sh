#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_repo="${LEGION_SOURCE_DIR:-$HOME/legion-server-sources/LegionCore-7.3.5V2}"
expected_commit="6c41d0faa23474bf9e76a4811b144d43e9545bab"
verify_dir="$(mktemp -d /tmp/legion-patch-verify.XXXXXX)"

cleanup() {
    case "$verify_dir" in
        /tmp/legion-patch-verify.*) rm -rf -- "$verify_dir" ;;
        *) echo "Refusing to remove unexpected verification path: $verify_dir" >&2 ;;
    esac
}
trap cleanup EXIT

git clone -q --shared "$source_repo" "$verify_dir/source"
git -C "$verify_dir/source" reset -q --hard "$expected_commit"

for patch_file in "$repo_root"/patches/*.patch; do
    git -C "$verify_dir/source" apply "$patch_file"
done

install -m 0644 "$repo_root/overlays/companion_autoloot.cpp" \
    "$verify_dir/source/src/server/scripts/Custom/companion_autoloot.cpp"
install -m 0644 "$repo_root/overlays/startup_qol.cpp" \
    "$verify_dir/source/src/server/scripts/Custom/startup_qol.cpp"

git -C "$verify_dir/source" diff --check
grep -q 'AddSC_companion_autoloot' "$verify_dir/source/src/server/scripts/ScriptLoader.cpp"
grep -q 'AddSC_startup_qol' "$verify_dir/source/src/server/scripts/ScriptLoader.cpp"
grep -q 'StartupQoL.Enable = 0' "$verify_dir/source/src/server/worldserver/worldserver.conf.dist"
grep -q 'silentRemote' "$verify_dir/source/src/server/game/Entities/Player/Player.cpp"
grep -q 'lootPesonal->isOpen = true' "$verify_dir/source/src/server/game/Entities/Player/Player.cpp"
grep -q 'DoLootRelease(ObjectGuid lguid, bool ignoreDistance' "$verify_dir/source/src/server/game/Handlers/LootHandler.cpp"
grep -q 'CompanionAutoLoot.Radius = 40' "$verify_dir/source/src/server/worldserver/worldserver.conf.dist"
grep -q '!questItem && item->is_blocked' "$verify_dir/source/src/server/scripts/Custom/companion_autoloot.cpp"
grep -q 'loot->AllowedForPlayer(player' "$verify_dir/source/src/server/scripts/Custom/companion_autoloot.cpp"
grep -q 'PlayedTimeReward] You received' "$verify_dir/source/src/server/game/Entities/Player/Player.cpp"
grep -q 'Redeemed 10 Nordrassil Coins' "$verify_dir/source/src/server/scripts/World/custom_events.cpp"
grep -q 'Your Shop balance is:' "$verify_dir/source/src/server/game/BattlePay/BattlePayMgr.cpp"
grep -q 'restart chase movement and combat after death cleanup' "$verify_dir/source/src/server/game/Entities/Creature/Creature.cpp"
grep -q 'Adds 10 coins to your in-game Shop balance' "$repo_root/database/70-nordrassil-coin-localization.sql"
grep -q '7005056, 2442913102, 505056' "$repo_root/database/70-nordrassil-coin-localization.sql"

echo "fresh patch verification passed"
