-----------------------------------------------------------------------------------------
-- Nostalgia Arcane Mage

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("ARC", "a674db", "MAGE-1")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "drink",
    "missilebarrage",
    "arcanepower",
    "icyveins",
    "pombuff",
    "normana",
    "abstacks",
    "casting",
    "evocation",
    "pom",
    "amdeadzone",
})

local amDeadzone = Faceroll.deadzoneCreate("Arcane Missiles", 0.3, 2)

spec.calcState = function(state)
    if Faceroll.isBuffActive("Drink") then
        state.drink = true
    end

    if Faceroll.isBuffActive("Missile Barrage") then
        state.missilebarrage = true
    end
    if Faceroll.isBuffActive("Arcane Power") then
        state.arcanepower = true
    end
    if Faceroll.isBuffActive("Icy Veins") then
        state.icyveins = true
    end
    if Faceroll.isBuffActive("Presence of Mind") then
        state.pombuff = true
    end

    local curMana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    state.normana = curMana / maxMana

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

    if Faceroll.isSpellAvailable("Evocation") then
        state.evocation = true
    end
    if Faceroll.isSpellAvailable("Presence of Mind") then
        state.pom = true
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
            if state.arcanepower or state.icyveins then
                return "arcaneblast"

            elseif state.normana <= 0.3 and state.evocation then
                return "evocation"

            elseif not state.evocation and not state.amdeadzone and state.missilebarrage then
                return "arcanemissiles"

            elseif not state.amdeadzone and ((state.abstacks == 4) or ((state.abstacks == 3) and state.casting == "Arcane Blast")) then
                return "arcanemissiles"

            else
                return "arcaneblast"

            end
        elseif aoe then
            if state.pom then
                return "pom"
            elseif state.pombuff and state.casting == "Blizzard" then
                return "flamestrike"
            else
                return "blizzard"
            end
        end

    elseif state.normana < 0.9 and not state.combat and not state.drink then
        return "drink"
    end
end
