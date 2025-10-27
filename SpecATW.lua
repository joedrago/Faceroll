-----------------------------------------------------------------------------------------
-- Ascension WoW Tree of Wrath

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("ATW", "aaffaa", "HERO-Tree of Wrath")

spec.options = {
    -- "solo",
}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    -- "- Resources -",
    -- "rage20",
    -- "rage40",

    -- "- State -",
    -- "bear",
    -- "maulqueued",
    -- "solo",

    "- Abilities -",
    "lightningbolt",
    "chainlightning",

    -- "charge",
    -- "enrage",
    -- "regen",

    -- "- Debuffs -",
    -- "rend",
    -- "lacerateending",
    -- "laceratemax",

    "- Combat -",
    "targetingenemy",
    "combat",
    -- "autoattack",
    -- "melee",
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

    -- for i = 1, GetNumShapeshiftForms() do
    --     local icon, name, active = GetShapeshiftFormInfo(i)
    --     if active and (name == "Bear Form" or name == "Dire Bear Form") then
    --         state.bear = true
    --     end
    -- end

    -- if IsCurrentSpell("Maul") then
    --     state.maulqueued = true
    -- end

    if Faceroll.isSpellAvailable("Lightning Bolt") then
        state.lightningbolt = true
    end
    if Faceroll.isSpellAvailable("Chain Lightning") then
        state.chainlightning = true
    end
    -- if Faceroll.isSpellAvailable("Feral Charge - Bear") then
    --     state.charge = true
    -- end
    -- if Faceroll.isSpellAvailable("Enrage") then
    --     state.enrage = true
    -- end
    -- if Faceroll.isSpellAvailable("Frenzied Regeneration") then
    --     state.regen = true
    -- end

    -- if Faceroll.isDotActive("Rend (Carnage)") > 0 then
    --     state.rend = true
    -- end

    -- if Faceroll.isDotActive("Lacerate") < 0.2 then
    --     state.lacerateending = true
    -- end

    -- local maxLacerateStacks = 5
    -- if state.solo then
    --     maxLacerateStacks = 1
    -- end
    -- if Faceroll.dotStacks("Lacerate") >= maxLacerateStacks then
    --     state.laceratemax = true
    -- end

    -- Combat
    if Faceroll.targetingEnemy() then
        state.targetingenemy = true
    end
    if UnitAffectingCombat("player") then
        state.combat = true
    end
    -- if IsCurrentSpell(6603) then -- Autoattack
    --     state.autoattack = true
    -- end
    -- if IsSpellInRange("Rend (Carnage)", "target") == 1 then
    --     state.melee = true
    -- end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "lightningbolt",
    "chainlightning",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST  then
        -- Single Target

        if state.targetingenemy then
            if state.lightningbolt then
                return "lightningbolt"
            end
        end

    elseif mode == Faceroll.MODE_AOE then

        if state.targetingenemy then
            if state.chainlightning then
                return "chainlightning"
            end
            if state.lightningbolt then
                return "lightningbolt"
            end
        end

    end

    return nil
end
