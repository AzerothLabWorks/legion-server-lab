/*
 * Copyright (C) 2026 AzerothLabWorks
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 */

#include "CellImpl.h"
#include "Config.h"
#include "Creature.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "LootMgr.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldSession.h"

#include <algorithm>
#include <list>
#include <unordered_map>

namespace
{
    bool Enabled = false;
    float Radius = 30.0f;
    uint32 IntervalMs = 1500;
    bool OutOfCombatOnly = true;
    bool RequireCompanion = true;
    std::unordered_map<uint32, uint32> Timers;

    void LoadConfig()
    {
        Enabled = sConfigMgr->GetBoolDefault("CompanionAutoLoot.Enable", false);
        Radius = std::max(1.0f, std::min(40.0f, sConfigMgr->GetFloatDefault("CompanionAutoLoot.Radius", 30.0f)));
        IntervalMs = std::max<uint32>(250, std::min<uint32>(10000, sConfigMgr->GetIntDefault("CompanionAutoLoot.IntervalMs", 1500)));
        OutOfCombatOnly = sConfigMgr->GetBoolDefault("CompanionAutoLoot.OutOfCombatOnly", true);
        RequireCompanion = sConfigMgr->GetBoolDefault("CompanionAutoLoot.RequireNonCombatCompanion", true);
    }

    bool HasActiveCompanion(Player* player)
    {
        if (!RequireCompanion)
            return true;

        ObjectGuid guid = player->GetCritterGUID();
        if (!guid)
            return false;

        Creature* companion = ObjectAccessor::GetCreature(*player, guid);
        return companion && companion->isAlive() && companion->IsInWorld() && companion->GetOwnerGUID() == player->GetGUID();
    }

    bool CanLoot(Player* player, Creature* creature)
    {
        if (!creature || creature->isAlive() || !creature->IsWithinDistInMap(player, Radius))
            return false;

        if (!creature->IsDamageEnoughForLootingAndReward() || !player->isAllowedToLoot(creature))
            return false;

        if (!creature->HasFlag(OBJECT_FIELD_DYNAMIC_FLAGS, UNIT_DYNFLAG_LOOTABLE))
            return false;

        if (creature->loot.loot_type == LOOT_SKINNING || creature->loot.loot_type == LOOT_PICKPOCKETING)
            return false;

        return true;
    }

    void StoreAvailableItems(Player* player, Loot* loot)
    {
        if (!loot)
            return;

        uint32 maxSlot = loot->GetMaxSlotInLootFor(player);
        for (uint32 slot = 0; slot < maxSlot; ++slot)
        {
            LootItem* item = loot->LootItemInSlot(slot, player);
            if (!item || item->is_looted || item->is_blocked || !item->AllowedForPlayer(player))
                continue;

            player->StoreLootItem(static_cast<uint8>(slot), loot);
        }
    }

    bool TryLoot(Player* player, Creature* creature)
    {
        if (!CanLoot(player, creature))
            return false;

        ObjectGuid guid = creature->GetGUID();
        player->SendLoot(guid, LOOT_CORPSE, false);
        player->GetGoldFromLoot();
        StoreAvailableItems(player, player->GetPersonalLoot(guid));
        StoreAvailableItems(player, &creature->loot);
        player->GetSession()->DoLootRelease(guid);
        return true;
    }

    void Process(Player* player, uint32 diff)
    {
        if (!Enabled || !player || !player->IsInWorld() || !player->isAlive())
            return;

        uint32& timer = Timers[player->GetGUIDLow()];
        if (timer > diff)
        {
            timer -= diff;
            return;
        }
        timer = IntervalMs;

        if (player->GetLootGUID() || (OutOfCombatOnly && player->isInCombat()) || !HasActiveCompanion(player))
            return;

        std::list<Creature*> creatures;
        player->GetCorpseCreatureInGrid(creatures, Radius);

        for (Creature* creature : creatures)
            if (TryLoot(player, creature))
                break;
    }
}

class CompanionAutoLootWorldScript : public WorldScript
{
public:
    CompanionAutoLootWorldScript() : WorldScript("CompanionAutoLootWorldScript") { }

    void OnConfigLoad(bool /*reload*/) override
    {
        LoadConfig();
    }
};

class CompanionAutoLootPlayerScript : public PlayerScript
{
public:
    CompanionAutoLootPlayerScript() : PlayerScript("CompanionAutoLootPlayerScript") { }

    void OnUpdate(Player* player, uint32 diff) override
    {
        Process(player, diff);
    }

    void OnLogout(Player* player) override
    {
        if (player)
            Timers.erase(player->GetGUIDLow());
    }
};

void AddSC_companion_autoloot()
{
    new CompanionAutoLootWorldScript();
    new CompanionAutoLootPlayerScript();
}
