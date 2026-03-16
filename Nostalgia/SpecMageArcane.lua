-----------------------------------------------------------------------------------------
-- Nostalgia Arcane Mage

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("ARC", "a674db", "MAGE-1")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    { "b_drink", "Drink" },
    { "b_missilebarrage", "Missile Barrage" },
    { "b_arcanepower", "Arcane Power" },
    { "b_icyveins", "Icy Veins" },
    { "b_pombuff", "Presence of Mind" },
    "abstacks",
    "casting",
    { "s_evocation", "Evocation" },
    { "s_pom", "Presence of Mind" },
    "amdeadzone",
})

local amDeadzone = Faceroll.deadzoneCreate("Arcane Missiles", 0.3, 2)

spec.calcState = function(state)
    local castingSpell, _, _, _, castingSpellEndTime = UnitCastingInfo("player")
    if castingSpell then
        state.casting = castingSpell
    else
        local channelingSpell, _, _, _, channelSpellEndTime = UnitChannelInfo("player")
        if channelingSpell then
            state.casting = channelingSpell
        end
    end

    state.abstacks = 0
    local abDebuff = Faceroll.getDebuff("Arcane Blast")
    if abDebuff ~= nil then
        state.abstacks = abDebuff.stacks
    end

    if Faceroll.deadzoneUpdate(amDeadzone) then
        state.amdeadzone = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "arcaneblast",
    "arcanemissiles",
    "evocation",
    "pom",
    "blizzard",
    "flamestrike",
    "drink",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        if st then
            if state.b_arcanepower or state.b_icyveins then
                return "arcaneblast"

            elseif state.mana <= 0.3 and state.s_evocation then
                return "evocation"

            elseif not state.s_evocation and not state.amdeadzone and state.b_missilebarrage then
                return "arcanemissiles"

            elseif not state.amdeadzone and ((state.abstacks == 4) or ((state.abstacks == 3) and state.casting == "Arcane Blast")) then
                return "arcanemissiles"

            else
                return "arcaneblast"

            end
        elseif aoe then
            if state.s_pom then
                return "pom"
            elseif state.b_pombuff and state.casting == "Blizzard" then
                return "flamestrike"
            else
                return "blizzard"
            end
        end

    elseif state.mana < 0.9 and not state.combat and not state.b_drink then
        return "drink"
    end
end
