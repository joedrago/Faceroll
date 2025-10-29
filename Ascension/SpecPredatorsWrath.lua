-----------------------------------------------------------------------------------------
-- Ascension WoW Predator's Wrath

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("PW", "77ff77", "HERO-Predator's Wrath")

spec.options = {}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    "- Resources -",
    "cp3",
    "cp5",

    "- State -",
    "cat",

    "- Abilities -",
    "charge",

    "- Buffs -",
    "taintedswipe",
    "slice",
    "predator",

    "- Debuffs -",
    "taintedwound",
    "rake",
    "rip",
    "mangle",

    "- Combat -",
    "targetingenemy",
    "combat",
    "autoattack",
    "melee",
}

spec.calcState = function(state)
    local cp = GetComboPoints("PLAYER", "TARGET")
    if cp >= 3 then
        state.cp3 = true
    end
    if cp >= 5 then
        state.cp5 = true
    end

    if Faceroll.inShapeshiftForm("Cat Form") then
        state.cat = true
    end

    if Faceroll.isSpellAvailable("Charge") then
        state.charge = true
    end

    if Faceroll.isBuffActive("Tainted Swipe") then
        state.taintedswipe = true
    end
    if Faceroll.isBuffActive("Slice and Dice") then
        state.slice = true
    end
    if Faceroll.isBuffActive("Predator's Swiftness") then
        state.predator = true
    end

    if Faceroll.isDotActive("Tainted Wound") > 0 then
        state.taintedwound = true
    end
    if Faceroll.isDotActive("Rake") > 0 then
        state.rake = true
    end
    if Faceroll.isDotActive("Rip") > 0 then
        state.rip = true
    end
    if Faceroll.isDotActive("Mangle (Cat)") > 0 then
        state.mangle = true
    end

    -- Combat
    if Faceroll.targetingEnemy() then
        state.targetingenemy = true
    end
    if Faceroll.inCombat() then
        state.combat = true
    end
    if IsCurrentSpell(6603) then -- Autoattack
        state.autoattack = true
    end
    if IsSpellInRange("Claw", "target") == 1 then
        state.melee = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "cat",
    "attack",
    "swipe",
    "charge",
    "claw",
    "bite",
    "wrath",
    "rake",
    "rip",
    "mangle",
    "slice",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)
    if st or aoe then
        -- Single Target

        if not state.cat then
            return "cat"

        elseif state.targetingenemy then
            if state.predator then
                return "wrath"

            elseif not state.melee and state.charge then
                return "charge"

            elseif not state.autoattack and not state.maulqueued then
                return "attack"

            elseif not state.taintedwound and state.taintedswipe then
                return "swipe"

            elseif not state.mangle then
                return "mangle"

            elseif state.cp5 then
                -- if not state.slice then
                --     return "slice"
                if not state.rip then
                    return "rip"
                else
                    return "bite"
                end

            elseif aoe then
                return "swipe"
            else
                if not state.rake then
                    return "rake"
                else
                    return "claw"
                end

            end
        end

    end

    return nil
end
