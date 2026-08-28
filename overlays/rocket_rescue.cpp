/*
 * Copyright (C) 2026 AzerothLabWorks
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 */

#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "Spell.h"
#include "SpellScript.h"

#include <limits>
#include <list>

namespace
{
    constexpr uint32 QUEST_ROCKET_RESCUE = 25050;
    constexpr uint32 SPELL_DELIVER_LIFE_ROCKET = 75560;
    constexpr uint32 SPELL_PIRATE_DESTROYING_BOMB = 73257;
    constexpr uint32 NPC_STEAMWHEEDLE_SURVIVOR = 38571;
    constexpr uint32 NPC_SOUTHSEA_BLOCKADER = 40583;
    constexpr float MIN_PAYLOAD_RANGE = 10.0f;
    constexpr float MAX_PAYLOAD_RANGE = 70.0f;
}

class spell_rocket_rescue_guided_payload : public SpellScriptLoader
{
public:
    spell_rocket_rescue_guided_payload() : SpellScriptLoader("spell_rocket_rescue_guided_payload") { }

    class spell_rocket_rescue_guided_payload_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_rocket_rescue_guided_payload_SpellScript);

        static bool IsValidTarget(Unit* caster, Unit* target, uint32 expectedEntry)
        {
            if (!caster || !target || !target->isAlive() || target->GetEntry() != expectedEntry)
                return false;

            float distance = caster->GetDistance(target);
            return distance >= MIN_PAYLOAD_RANGE && distance <= MAX_PAYLOAD_RANGE;
        }

        Unit* FindPayloadTarget(Unit* caster, Player* player, uint32 expectedEntry)
        {
            if (Unit* selected = player->GetSelectedUnit())
                if (IsValidTarget(caster, selected, expectedEntry))
                    return selected;

            std::list<Creature*> candidates;
            GetCreatureListWithEntryInGrid(candidates, caster, expectedEntry, MAX_PAYLOAD_RANGE);

            Creature* nearest = nullptr;
            float nearestDistance = std::numeric_limits<float>::max();
            for (Creature* candidate : candidates)
            {
                if (!IsValidTarget(caster, candidate, expectedEntry))
                    continue;

                float distance = caster->GetDistance(candidate);
                if (distance < nearestDistance)
                {
                    nearest = candidate;
                    nearestDistance = distance;
                }
            }

            return nearest;
        }

        void RedirectPayload()
        {
            Unit* caster = GetCaster();
            if (!caster)
                return;

            Player* player = caster->GetCharmerOrOwnerPlayerOrPlayerItself();
            if (!player || player->GetQuestStatus(QUEST_ROCKET_RESCUE) != QUEST_STATUS_INCOMPLETE)
                return;

            uint32 expectedEntry = 0;
            switch (GetSpellInfo()->Id)
            {
                case SPELL_DELIVER_LIFE_ROCKET:
                    expectedEntry = NPC_STEAMWHEEDLE_SURVIVOR;
                    break;
                case SPELL_PIRATE_DESTROYING_BOMB:
                    expectedEntry = NPC_SOUTHSEA_BLOCKADER;
                    break;
                default:
                    return;
            }

            Unit* target = FindPayloadTarget(caster, player, expectedEntry);
            if (!target)
                return;

            WorldLocation const* currentDestination = GetExplTargetDest();
            if (!currentDestination)
                return;

            WorldLocation destination = *currentDestination;
            destination.Relocate(*target);
            SetExplTargetDest(destination);

            // The archived core shortens TARGET_DEST_TRAJ using the vehicle's
            // forward orientation. Once a valid quest target is selected, keep
            // the exact destination and let the original triggered impact spell
            // provide damage or credit at that point.
            GetSpell()->m_targets.SetSpeed(0.0f);
            GetSpell()->m_targets.SetPitch(0.0f);
        }

        void Register() override
        {
            BeforeCast += SpellCastFn(spell_rocket_rescue_guided_payload_SpellScript::RedirectPayload);
        }
    };

    SpellScript* GetSpellScript() const override
    {
        return new spell_rocket_rescue_guided_payload_SpellScript();
    }
};

void AddSC_rocket_rescue()
{
    new spell_rocket_rescue_guided_payload();
}
