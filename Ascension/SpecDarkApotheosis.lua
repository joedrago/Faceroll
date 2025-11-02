-----------------------------------------------------------------------------------------
-- Ascension WoW Dark Apotheosis

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("DA", "ffaaff", "HERO-Dark Apotheosis")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- State -",
    "demonform",
    "scqueued",

    "- Buffs -",
    "shadowtrance",

    "- Abilities -",
    "shadowcleave",
    "immolationaura",
    "meteor",
    "shadowflame",

    "potion",
})

spec.calcState = function(state)
    state.demonform = Faceroll.inShapeshiftForm("Dark Apotheosis")
    state.scqueued = Faceroll.isSpellQueued("Shadow Cleave")

    state.shadowtrance = Faceroll.isBuffActive("Shadow Trance") or Faceroll.isBuffActive("Backlash")

    state.shadowcleave = Faceroll.isSpellAvailable("Shadow Cleave")
    state.immolationaura = Faceroll.isSpellAvailable("Immolation Aura (Dark Apotheosis)")
    state.meteor = Faceroll.isSpellAvailable("Meteor")
    state.shadowflame = Faceroll.isSpellAvailable("Shadowflame")

    local potionStart = GetActionCooldown(1)
    if potionStart > 0 then
        local potionRemaining = GetTime() - potionStart
        if potionRemaining < 1.6 then -- mana potion in slot 1
            state.potion = true
        end
    else
        state.potion = true
    end
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "demonform",
    "attack",
    "shadowcleave",
    "immolationaura",
    "potion",
    "meteor",
    "shadowflame",
    "incinerate",
    "shadowbolt",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then

        if not state.demonform then
            return "demonform"

        elseif not state.autoattack and not state.scqueued then
            return "attack"

        elseif state.potion then
            return "potion"

        elseif state.shadowtrance then
            return "shadowbolt"

        elseif state.immolationaura then
            return "immolationaura"

        elseif state.meteor then
            return "meteor"

        elseif state.shadowflame then
            return "shadowflame"

        elseif state.shadowcleave and not state.scqueued then
            return "shadowcleave"

        else
            return "incinerate"

        end
    end

    return nil
end
