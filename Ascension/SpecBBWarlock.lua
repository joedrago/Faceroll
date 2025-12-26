-----------------------------------------------------------------------------------------
-- Ascension WoW Bronzebeard Warlock

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("WL", "aaaaff", "WARLOCK-ASCENSION")

Faceroll.enemyGridTrack(spec, "Corruption", "COR", "621518")
Faceroll.enemyGridTrack(spec, "Curse of Agony", "COA", "626218")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Spells -",
    "firestorm",

    "- Buffs -",
    "shadowtrance",

    "-- Dots --",
    "corruption",
    "agony",

    "- State -",
    "min",
    "shards",
    "deadsoon",
    "drainready",
    "drainingsoul",
    "drainsoulending",
    "wand",
    "needtap",
    "needlife",
    "darkharveststacks",
    "moving",
    "consumeshadows",
    "petdying",
    "consumingshadows",
    "picnic",
    "channeling",

    "-- Mode --",
    "grind",
    "trash",
    "boss",
})

spec.options = {
    "grind|mode",
    "trash|mode",
    "boss|mode",
}

spec.radioColors = {
    "ff8844",
    "ffffaa",
    "ffaaaa",
}

spec.calcState = function(state)
    -- Spells
    if Faceroll.isSpellAvailable("Fire Storm") then
        state.firestorm = true
    end

    -- Buffs
    if Faceroll.isBuffActive("Shadow Trance") or Faceroll.isBuffActive("Backlash") then
        state.shadowtrance = true
    end

    -- -- Debuffs
    if Faceroll.getDotRemainingNorm("Corruption") > 0.1 then
        state.corruption = true
    end
    if Faceroll.getDotRemainingNorm("Curse of Agony") > 0.1 then
        state.agony = true
    end

    state.darkharveststacks = Faceroll.getBuffStacks("Dark Harvest")
    state.moving = Faceroll.moving

    state.shards = GetItemCount("Soul Shard")

    if Faceroll.targetingEnemy() then
        local targethp = UnitHealth("target")
        local targethpmax = UnitHealthMax("target")
        local targethpnorm = targethp / targethpmax
        if targethpnorm <= 0.70 then
            state.deadsoon = true
        end

        -- if not state.deadsoon then
        --     local castingSpell, _, _, _, castingSpellEndTime = UnitCastingInfo("player")
        --     if castingSpell == "Shadow Bolt" and targethpnorm <= 0.70 then
        --         state.deadsoon = true
        --     end
        -- end

        local MIN_SHARDS = 32 -- in Ascension they stack to 32!
        if state.deadsoon and (state.shards < MIN_SHARDS) then
            state.drainready = true
        end
    end

    local channelingSpell, _, _, _, _, channelEndMS = UnitChannelInfo("player")
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

    local hpbias = 0
    if state.grind and (state.darkharveststacks > 3) then
        hpbias = 0.1
        if (hpnorm + hpbias) > 1.0 then
            hpbias = 1.0 - hpnorm
        end
    end

    if (hpnorm >= 0.25) and (mananorm < (hpnorm + hpbias)) then
        state.needtap = true
    end

    if hpnorm <= 0.75 then
        state.needlife = true
    end

    if IsCurrentSpell(5019) then -- Shoot (wand)
        state.wand = true
    end

    if UnitExists("pet") and not UnitIsDead("pet") and UnitCreatureFamily("pet") == "Voidwalker" then
        local pethp = UnitHealth("pet")
        local pethpmax = UnitHealthMax("pet")
        local pethpnorm = pethp / pethpmax
        if pethpnorm < 0.8 then
            state.consumeshadows = true
        end
        if pethpnorm < 0.4 then
            state.petdying = true
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
    local channelingSpell, _, _, _, channelEndMS = UnitChannelInfo("pet")
    if channelingSpell then
        state.channeling = true
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
    "wand",
    "tap",
    "rof",
    "firestorm",
    "agony",
    "drainlife",
    "consumeshadows",
    "food",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- get some mana back
    if state.needtap and not state.wand and not state.picnic and not state.channeling and (not state.combat or not state.targetingenemy or state.grind) then
        return "tap"

    -- Eat instead of drain life if your pet is very, very weak
    elseif state.grind and state.petdying and not state.combat and state.needlife and not state.picnic then
        return "food"

    -- Let your voidwalker heal itself if it is weak
    elseif state.grind and state.consumeshadows and not state.combat and ((state.darkharveststacks == 0) or not state.needlife or state.picnic) then
        return "consumeshadows"

    -- Give your voidwalker a chance to eat dinner
    elseif state.grind and state.consumingshadows then
        return nil

    elseif st then
        if state.targetingenemy then
            -- wait for pet to engage combat when grinding
            if state.grind and not state.combat and (state.darkharveststacks == 0) then
                return "sic"

            -- a big free heal when grinding
            elseif state.grind and state.needlife and state.darkharveststacks >= 6 and not state.deadsoon and state.combat and not state.moving then
                return "drainlife"

            -- spend procs immediately
            elseif state.shadowtrance then
                return "shadowbolt"

            -- maintain dots, but when grinding, wait for combat
            elseif not state.corruption then
                return "corruption"
            elseif state.boss and not state.agony then -- or state.grind
                return "agony"

            -- farm shards when grinding
            elseif state.grind and state.drainready then
                if not state.drainingsoul or state.drainsoulending then
                    return "drainsoul"
                else
                    return nil
                end

            -- wand when grinding
            elseif state.grind and state.deadsoon then
                return "wand"

            -- filler
            else
                return "shadowbolt"

            end
        end

    elseif aoe then
        if state.firestorm then
            return "firestorm"
        else
            return "rof"
        end
    end

    return nil
end
