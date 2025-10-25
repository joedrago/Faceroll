-----------------------------------------------------------------------------------------
-- Ascension WoW Dark Apotheosis

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("DA", "ffaaff", "HERO-Dark Apotheosis")

spec.options = {}

-----------------------------------------------------------------------------------------
-- States

spec.states = {
    -- "- Resources -",
    -- "rage20",
    -- "rage40",

    "- State -",
    "demonform",
    "scqueued",

    "- Abilities -",
    "shadowcleave",
    "immolationaura",
    "charge",

    -- "- Debuffs -",
    -- "rend",
    -- "lacerateending",
    -- "laceratemax",

    "- Combat -",
    "targetingenemy",
    "combat",
    "autoattack",
    "melee",
}

spec.calcState = function(state)
    -- local rage = UnitPower("PLAYER", Enum.PowerType.Rage)
    -- local cp = GetComboPoints("PLAYER", "TARGET")

    -- if rage >= 20 then
    --     state.rage20 = true
    -- end
    -- if rage >= 40 then
    --     state.rage40 = true
    -- end

    for i = 1, GetNumShapeshiftForms() do
        local icon, name, active = GetShapeshiftFormInfo(i)
        if active and (name == "Dark Apotheosis") then
            state.demonform = true
        end
    end

    if IsCurrentSpell("Shadow Cleave") then
        state.scqueued = true
    end

    if Faceroll.isSpellAvailable("Shadow Cleave") then
        state.shadowcleave = true
    end
    if Faceroll.isSpellAvailable("Immolation Aura (Dark Apotheosis)") then
        state.immolationaura = true
    end
    if Faceroll.isSpellAvailable("Demon Charge") then
        state.charge = true
    end

    -- Combat
    if Faceroll.targetingEnemy() then
        state.targetingenemy = true
    end
    if UnitAffectingCombat("player") then
        state.combat = true
    end
    if IsCurrentSpell(6603) then -- Autoattack
        state.autoattack = true
    end
    if IsSpellInRange("Demon Charge", "target") ~= 1 then
        state.melee = true
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
    "charge",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST or mode == Faceroll.MODE_AOE then
        -- Single Target

        if state.targetingenemy then

            if not state.demonform then
                return "demonform"

            elseif not state.melee and state.charge then
                return "charge"

            elseif not state.autoattack and not state.scqueued then
                return "attack"

            elseif state.immolationaura then
                return "immolationaura"

            elseif state.shadowcleave and not state.scqueued then
                return "shadowcleave"

            end
        end

    end

    return nil
end
