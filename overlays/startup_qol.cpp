#include "ScriptMgr.h"
#include "Player.h"
#include "Config.h"
#include "DB2Stores.h"
#include "WorldSession.h"

#include <array>

namespace
{
constexpr std::array<uint32, 6> RidingSpells =
{
    33388, // Apprentice Riding
    33391, // Journeyman Riding
    34090, // Expert Riding
    34091, // Artisan Riding
    90265, // Master Riding
    54197  // Cold Weather Flying
};

constexpr std::array<uint32, 2> LegionMountSpells =
{
    213115, // Bloodfang Widow
    48025   // Headless Horseman's Mount (Legion-era alternative)
};

constexpr uint32 HexweaveBagItem = 114821;
constexpr uint32 MagmaRagelingCreature = 115138;
constexpr int64 TwentyThousandGold = 200000000;

class StartupQoLPlayerScript : public PlayerScript
{
public:
    StartupQoLPlayerScript() : PlayerScript("StartupQoLPlayerScript") { }

    void OnLogin(Player* player, bool /*firstLogin*/) override
    {
        if (!sConfigMgr->GetBoolDefault("StartupQoL.Enable", false) ||
            player->getLevel() != sConfigMgr->GetIntDefault("StartupQoL.Level", 1))
            return;

        bool changed = false;

        if (sConfigMgr->GetBoolDefault("StartupQoL.Riding", true))
            for (uint32 spellId : RidingSpells)
                if (!player->HasSpell(spellId))
                {
                    player->learnSpell(spellId, false);
                    changed = true;
                }

        if (sConfigMgr->GetBoolDefault("StartupQoL.Mounts", true))
            for (uint32 spellId : LegionMountSpells)
                if (!player->HasSpell(spellId))
                {
                    player->learnSpell(spellId, false);
                    changed = true;
                }

        if (sConfigMgr->GetBoolDefault("StartupQoL.Money", true) && player->GetMoney() < TwentyThousandGold)
        {
            player->SetMoney(TwentyThousandGold);
            changed = true;
        }

        if (sConfigMgr->GetBoolDefault("StartupQoL.Bags", true))
        {
            uint32 currentBags = player->GetItemCount(HexweaveBagItem, true);
            if (currentBags < 4 && player->AddItem(HexweaveBagItem, 4 - currentBags))
                changed = true;
        }

        if (sConfigMgr->GetBoolDefault("StartupQoL.MagmaRageling", true))
            if (BattlePetSpeciesEntry const* species = sDB2Manager.GetSpeciesByCreatureID(MagmaRagelingCreature))
                if (!player->GetBattlePetCountForSpecies(species->ID) && player->AddBattlePetByCreatureId(MagmaRagelingCreature))
                    changed = true;

        if (changed && player->GetSession())
            player->GetSession()->SendNotification("Legion Lab level-1 quality-of-life rewards have been granted.");
    }
};
}

void AddSC_startup_qol()
{
    new StartupQoLPlayerScript();
}
