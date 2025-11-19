-----------------------------------------------------------------------------------------
-- Ascension WoW Lucifur

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("LUC", "ff7744", "HERO-Lucifur")
spec.melee = "Claw"

spec.options = {
    "boss",
}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- State -",
    "cat",

    "- Buffs -",
    "devilsclaws",
    "devilsember",

    "- Abilities -",
    "charge",

    "- Totems -",
    "searingtotem",
    "magmatotem",
})

spec.calcState = function(state)
    state.cat = Faceroll.inShapeshiftForm("Cat Form")

    if Faceroll.isSpellAvailable("Charge") then
        state.charge = true
    end

    if Faceroll.isBuffActive("Devil's Claws") then
        state.devilsclaws = true
    end
    if Faceroll.isBuffActive("Devil's Ember") then
        state.devilsember = true
    end

    if Faceroll.isTotemActive("Searing Totem") then
        state.searingtotem = true
    end
    if Faceroll.isTotemActive("Magma Totem") then
        state.magmatotem = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "cat",
    "attack",
    "mangle",
    "swipe",
    "charge",
    "bite",
    "searingtotem",
    "magmatotem",
    "destroytotems",
    "ignition",
    "searingpain",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        if not state.devilsclaws or (not state.combat and not state.melee) then
            return "searingpain"

        elseif not state.cat then
            return "cat"

        elseif not state.melee and state.charge then
            return "charge"

        elseif not state.autoattack then
            return "attack"

        elseif st and not state.searingtotem then
            return "searingtotem"

        elseif aoe and not state.magmatotem then
            return "magmatotem"

        elseif aoe then
            return "swipe"

        elseif state.combopoints >= 5 or (not state.boss and (state.combopoints >= 3)) then
            return "bite"

        elseif state.devilsember then
            return "ignition"

        else
            return "mangle"

        end

    elseif not state.combat and (state.searingtotem or state.magmatotem) then
        return "destroytotems"

    end

    return nil
end
