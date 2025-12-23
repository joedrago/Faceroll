-----------------------------------------------------------------------------------------
-- Ascension WoW Bronzebeard Warlock

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("WL", "aaaaff", "WARLOCK-ASCENSION")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    -- "- Buffs -",
    -- "innerfire",
    -- "renewbuff",
    -- "weakenedsoulbuff",
    -- "shieldbuff",

    -- "- Debuffs -",
    -- "pain",

    -- "- Spells -",
    -- "shieldavailable",
    -- "mindblast",

    -- "- Target -",
    -- "targetingenemy",
    -- "target40",

    -- "- Combat -",
    -- "combat",
    -- "hp80",
    -- "mana90",
    -- "wand",
    -- "coast",
}

spec.options = {
    "coast",
}

spec.calcState = function(state)
    -- Buffs
    -- if Faceroll.isBuffActive("Inner Fire") then
    --     state.innerfire = true
    -- end
    -- if Faceroll.isBuffActive("Renew") then
    --     state.renewbuff = true
    -- end
    -- if Faceroll.isBuffActive("Weakened Soul") then
    --     state.weakenedsoulbuff = true
    -- end
    -- if Faceroll.isBuffActive("Power Word: Shield") then
    --     state.shieldbuff = true
    -- end

    -- -- Debuffs
    -- if Faceroll.getDotRemainingNorm("Shadow Word: Pain") > 0.1 then
    --     state.pain = true
    -- end

    -- -- Spells
    -- if Faceroll.isSpellAvailable("Power Word: Shield") then
    --     state.shieldavailable = true
    -- end
    -- if Faceroll.isSpellAvailable("Mind Blast") then
    --     state.mindblast = true
    -- end

    -- -- Target
    -- if Faceroll.targetingEnemy() then
    --     state.targetingenemy = true

    --     local targethp = UnitHealth("target")
    --     local targethpmax = UnitHealthMax("target")
    --     local targethpnorm = targethp / targethpmax
    --     if targethpnorm <= 0.40 then
    --         state.target40 = true
    --     end
    -- end

    -- -- Combat
    -- if Faceroll.inCombat() then
    --     state.combat = true
    -- end
    -- local hp = UnitHealth("player")
    -- local hpmax = UnitHealthMax("player")
    -- local hpnorm = hp / hpmax
    -- if hpnorm < 0.8 then
    --     state.hp80 = true
    -- end
    -- local mana = UnitPower("player", Enum.PowerType.Mana)
    -- local manamax = UnitPowerMax("player", Enum.PowerType.Mana)
    -- local mananorm = mana / manamax
    -- if mananorm >= 0.90 then
    --     state.mana90 = true
    -- end

    -- if IsCurrentSpell(5019) then -- Shoot (wand)
    --     state.wand = true
    -- end

    -- if not state.combat or Faceroll.targetChanged then
    --     Faceroll.setOption("coast", false)
    --     state.coast = false
    -- end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "shadowbolt",
}

spec.calcAction = function(mode, state)

    if state.targetingenemy then
        -- if not state.coast and not state.innerfire then
        --     return "innerfire"

        -- elseif not state.coast and not state.shieldbuff and not state.weakenedsoulbuff and state.shieldavailable then
        --     return "shield"

        -- elseif not state.coast and not state.combat and state.mindblast then
        --     return "mindblast"

        -- if not state.coast and not state.pain then
        --     return "pain"

        -- elseif not state.wand then
        --     return "shoot"

        -- elseif state.target40 and not state.coast then
        --     return "coast"

        return "shadowbolt"

        -- end
    end

    return nil
end
