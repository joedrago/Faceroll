-----------------------------------------------------------------------------------------
-- Frost Death Knight

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("FDK", "5DC4FF", "DEATHKNIGHT-2")

spec.buffs = {
    "Pillar of Frost",
    "Killing Machine",
    "Rime",
    "Frostbane",
}

-----------------------------------------------------------------------------------------
-- States

spec.states = {
    "- Buffs -",
    "pillaroffrostbuff",
    "killingmachine1",
    "killingmachine2",
    "rime",
    "frostbane",

    " - Dots -",
    "razorice5",

    "- Spells -",
    "erw1",
    "erw2soon",
    "frostwyrmsfury",
    "pillaroffrost",
    "pillaroffrostsoon",

    "- Resources -",
    "rune1",
    "rune2",
    "rune3",
    "rpG35",
}

spec.calcState = function(state)
    if Faceroll.isBuffActive("Pillar of Frost") then
        state.pillaroffrostbuff = true
    end

    local kmstacks = Faceroll.getBuffStacks("Killing Machine")
    if kmstacks > 0 then
        state.killingmachine1 = true
    end
    if kmstacks > 1 then
        state.killingmachine2 = true
    end

    if Faceroll.isBuffActive("Rime") then
        state.rime = true
    end

    if Faceroll.isBuffActive("Frostbane") then
        state.frostbane = true
    end

    if Faceroll.dotStacks("Razorice") >= 5 then
        state.razorice5 = true
    end

    if Faceroll.spellCharges("Empower Rune Weapon") > 0 then
        state.erw1 = true
    end
    if Faceroll.spellChargesSoon("Empower Rune Weapon", 2, 3) then
        state.erw2soon = true
    end

    if Faceroll.isSpellAvailable("Frostwyrm's Fury") then
        state.frostwyrmsfury = true
    end

    if Faceroll.isSpellAvailable("Pillar of Frost") then
        state.pillaroffrost = true
    end

    if Faceroll.spellCooldown("Pillar of Frost") < 5 then
        state.pillaroffrostsoon = true
    end

    local runes = UnitPower("player", Enum.PowerType.Runes)
    if runes >= 1 then
        state.rune1 = true
    end
    if runes >= 2 then
        state.rune2 = true
    end
    if runes >= 3 then
        state.rune3 = true
    end

    local rp = UnitPower("player", Enum.PowerType.RunicPower)
    if rp >= 35 then
        state.rpG35 = true
    end

    -- if Faceroll.hold then
    --     state.hold = true
    -- end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "erw",
    "pillaroffrost",
    "obliterate",
    "howlingblast",
    "froststrike",
    "frostscythe",
    "glacialadvance",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Single Target

        if state.erw2soon then
            -- Empower Rune Weapon if you are about to reach 2 charges to avoid cooldown waste
            return "erw"

        elseif state.pillaroffrost then
            -- Pillar of Frost
            return "pillaroffrost"

        elseif state.rune2 and (state.killingmachine2 or (state.killingmachine1 and state.rune3)) then
            -- Obliterate if you have 2 Killing Machine procs, or 1 proc and 3 Runes
            return "obliterate"

        elseif state.rime then
            -- Howling Blast with Rime
            return "howlingblast"

        elseif state.rpG35 and state.razorice5 then
            -- Frost Strike if the target has 5 stacks of Razorice
            return "froststrike"

        elseif state.rune2 and state.killingmachine1 then
            -- Obliterate with Killing Machine
            return "obliterate"

        elseif state.rune2 and not state.killingmachine1 and not state.pillaroffrostbuff then
            -- Obliterate without Killing Machine if Pillar of Frost is not active
            return "obliterate"

        elseif state.rpG35 then
            -- Frost Strike
            return "froststrike"

        elseif state.erw1 then
            -- Empower Rune Weapon to generate Runic Power
            return "erw"

        elseif not state.rime and state.rune1 and state.pillaroffrostbuff then
            -- Howling Blast without Rime during Pillar of Frost
            return "howlingblast"

        end

    elseif mode == Faceroll.MODE_AOE then
        -- AOE

        if state.erw2soon then
            -- Empower Rune Weapon if you are about to reach 2 charges to avoid cooldown waste
            return "erw"

        elseif state.pillaroffrost then
            -- Pillar of Frost
            return "pillaroffrost"

        elseif state.rune2 and (state.killingmachine2 or (state.killingmachine1 and state.rune3)) then
            -- Frostscythe if you have 2 Killing Machine procs, or 1 proc and 3 Runes
            return "frostscythe"

        elseif state.rime then
            -- Howling Blast with Rime
            return "howlingblast"

        elseif state.rpG35 and state.frostbane then
            -- Frostbane when it procs
            return "froststrike"

        elseif state.rpG35  then
            -- Glacial Advance
            return "glacialadvance"

        elseif state.rune2 and state.killingmachine1 then
            -- Frostscythe with Killing Machine
            return "frostscythe"

        elseif state.erw1 then
            -- Empower Rune Weapon to generate Runic Power
            return "erw"

        elseif state.rune2 and not state.killingmachine1 and not state.pillaroffrostbuff then
            -- Frostscythe without Killing Machine if Pillar of Frost is not active
            return "frostscythe"

        elseif not state.rime and state.rune1 and state.pillaroffrostbuff then
            -- Howling Blast without Rime during Pillar of Frost
            return "howlingblast"

        end

    end

    return nil
end
