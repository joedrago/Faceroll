-----------------------------------------------------------------------------------------
-- Ascension WoW Bronzebeard Warlock (Grind)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("WG", "aaaaff", "WARLOCK-Crazy Cultist")

Faceroll.enemyGridTrack(spec, "Corruption", "COR", "621518")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    "shadowtrance",

    "-- Dots --",
    "corruption",

    "- Dark Harvest -",
    "darkharveststacks",
    "moving",
    "channeling",
    "needhp",

    "- Spells -",
    "soulfire",
    "demonicempowerment",

    "- State -",
    "deadsoon",
    "drainingsoul",
    "drainsoulending",
    "needtap",
    "consumeshadows",
    "consumingshadows",
    "picnic",
    "channeling",
    "group",

    "-- Options --",
    "burn",
    "shards",
})

spec.options = {
    "burn",
    "shards",
}

local soulfireDeadzone = Faceroll.deadzoneCreate("Soul Fire", 0.3, 1)

spec.calcState = function(state)
    -- Buffs
    if Faceroll.isBuffActive("Shadow Trance") or Faceroll.isBuffActive("Backlash") then
        state.shadowtrance = true
    end

    -- -- Debuffs
    if Faceroll.getDotRemainingNorm("Corruption") > 0.1 then
        state.corruption = true
    end

    state.darkharveststacks = Faceroll.getBuffStacks("Dark Harvest")
    state.moving = Faceroll.moving
    if IsInGroup() then
        state.group = true
    end

    if Faceroll.targetingEnemy() then
        local targethp = UnitHealth("target")
        local targethpmax = UnitHealthMax("target")
        local targethpnorm = targethp / targethpmax
        if targethpnorm <= 0.40 then
            state.deadsoon = true
        end
    end

    local channelingSpell, _, _, _, _, channelEndMS = UnitChannelInfo("player")
    if channelingSpell then
        state.channeling = true
    end
    if channelingSpell == "Drain Soul" then
        local channelFinish = (channelEndMS / 1000) - GetTime()
        state.drainingsoul = true
        if channelFinish < 5 then
            state.drainsoulending = channelFinish
        end
    end

    local hp = UnitHealth("player")
    local hpmax = UnitHealthMax("player")
    local hpnorm = hp / hpmax
    local mana = UnitPower("player", Enum.PowerType.Mana)
    local manamax = UnitPowerMax("player", Enum.PowerType.Mana)
    local mananorm = mana / manamax
    local hpbias = 0.1
    if (hpnorm + hpbias) > 1.0 then
        hpbias = 1.0 - hpnorm
    end
    if (hpnorm >= 0.25) and (mananorm < (hpnorm + hpbias)) then
        state.needtap = true
    end
    if hpnorm < 0.7 then
        state.needhp = true
    end

    Faceroll.deadzoneUpdate(soulfireDeadzone)
    if (Faceroll.isBuffActive("Decisive Decimation") or Faceroll.isBuffActive("Decimation")) and Faceroll.isSpellAvailable("Soul Fire") and not Faceroll.deadzoneActive(soulfireDeadzone) then
        state.soulfire = true
    end

    if Faceroll.isSpellAvailable("Demonic Empowerment") then
        state.demonicempowerment = true
    end

    if UnitExists("pet") and not UnitIsDead("pet") and UnitCreatureFamily("pet") == "Voidwalker" then
        local pethp = UnitHealth("pet")
        local pethpmax = UnitHealthMax("pet")
        local pethpnorm = pethp / pethpmax
        if pethpnorm < 0.8 then
            state.consumeshadows = true
        end

        local channelingSpell, _, _, _, channelEndMS = UnitChannelInfo("pet")
        if channelingSpell then
            -- local channelFinish = channelEndMS/1000 - GetTime()
            state.consumingshadows = true
        end
    end

    if Faceroll.isBuffActive("Food") or Faceroll.isBuffActive("Drink") then
        state.picnic = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "sic",
    "shadowbolt",
    "corruption",
    "drainsoul",
    "tap",
    "seed",
    "drainlife",
    "soulfire",
    "demonicempowerment",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.shards then
        if not state.drainingsoul then
            return "drainsoul"
        else
            return nil
        end
    end

    local needdrain = state.needhp and (state.darkharveststacks >= 8) and not state.deadsoon and not state.moving and not state.channeling

    -- get some mana back
    if state.needtap and not state.picnic and not state.channeling and (not state.combat or not state.targetingenemy) then
        return "tap"

    -- Let your voidwalker heal itself if it is weak
    -- elseif state.consumeshadows and not state.combat then
    --     return "consumeshadows"

    -- Give your voidwalker a chance to eat dinner, unless we have a juicy proc
    elseif state.consumingshadows and not state.shadowtrance and not needdrain then
        return nil

    elseif st then
        if state.targetingenemy then
            -- spend procs immediately
            if state.shadowtrance then
                return "shadowbolt"

            elseif needdrain then
                return "drainlife"

            -- wait for pet to engage combat when grinding
            elseif not state.combat and not state.group then
                return "sic"

            elseif state.demonicempowerment then
                return "demonicempowerment"

            -- maintain dots
            elseif not state.corruption then
                return "corruption"

            -- farm shards/mana, but skip this when burning
            elseif state.deadsoon and not state.burn then
                if not state.channeling then
                    return "drainsoul"
                else
                    return nil
                end

            -- filler
            elseif state.soulfire then
                return "soulfire"
            else
                return "shadowbolt"

            end
        end

    elseif aoe then
        return "seed"
    end

    return nil
end
