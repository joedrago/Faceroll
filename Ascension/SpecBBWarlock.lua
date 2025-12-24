-----------------------------------------------------------------------------------------
-- Ascension WoW Bronzebeard Warlock

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("WL", "aaaaff", "WARLOCK-ASCENSION")

Faceroll.enemyGridTrack(spec, "Corruption", "COR", "621518")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    "shadowtrance",

    "-- Dots --",
    "corruption",

    "- State -",
    "min",
    "shards",
    "deadsoon",
    "drainready",
    "drainingsoul",
    "drainsoulending",
    "wand",
    "needtap",

    "-- Options --",
    "burn",
})

spec.options = {
    "burn",
}

spec.calcState = function(state)
    -- Buffs
    if Faceroll.isBuffActive("Shadow Trance") or Faceroll.isBuffActive("Backlash") then
        state.shadowtrance = true
    end

    -- -- Debuffs
    if Faceroll.getDotRemainingNorm("Corruption") > 0.1 then
        state.corruption = true
    end

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

    if (hpnorm >= 0.25) and (mananorm < hpnorm) then
        state.needtap = true
    end

    if IsCurrentSpell(5019) then -- Shoot (wand)
        state.wand = true
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
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if (state.burn or not state.combat) and state.needtap then
        return "tap"
    elseif state.targetingenemy then
        if not state.burn and not state.combat then
            return "sic"
        elseif (state.burn or state.combat) and not state.corruption then
            return "corruption"
        elseif not state.burn and state.drainready then
            if not state.drainingsoul or state.drainsoulending then
                return "drainsoul"
            else
                return nil
            end
        elseif not state.burn and state.deadsoon then
            return "wand"
        elseif state.shadowtrance then
            return "shadowbolt"
        else
            return "shadowbolt"
        end
    end

    return nil
end
