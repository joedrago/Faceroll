-----------------------------------------------------------------------------------------
-- Ascension WoW Thunder Slam

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("TS", "aaaacc", "HERO-Thunder Slam")

spec.options = {}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    "- Resources -",
    "rage20",
    "rage35",
    "rage40",

    "- Buffs -",
    "instantlb",

    "- Abilities -",
    "hsqueued",
    "charge",
    "thunderclap",
    "chainlightning",
    "lightningblade",
    "thunderslam",
    "lightningshield",

    "- Combat -",
    "targetingenemy",
    "combat",
    "autoattack",
    "melee",
}

spec.calcState = function(state)
    local rage = UnitPower("PLAYER", Enum.PowerType.Rage)
    if rage >= 20 then
        state.rage20 = true
    end
    if rage >= 35 then
        state.rage35 = true
    end
    if rage >= 40 then
        state.rage40 = true
    end

    -- Buffs
    if Faceroll.isBuffActive("Assault and Battery") then
        state.instantlb = true
    end

    -- Abilities
    if IsCurrentSpell("Heroic Strike") then
        state.hsqueued = true
    end
    if Faceroll.isSpellAvailable("Charge") then
        state.charge = true
    end
    if Faceroll.isSpellAvailable("Thunder Clap") then
        state.thunderclap = true
    end
    if Faceroll.isSpellAvailable("Chain Lightning") then
        state.chainlightning = true
    end

    if Faceroll.isBuffActive("Storm Blade") then
        if Faceroll.isSpellAvailable("Lightning Blade") then
            state.lightningblade = true
        end
        if Faceroll.isSpellAvailable("Thunder Slam") then
            state.thunderslam = true
        end
    end
    if Faceroll.isSpellAvailable("Lightning Shield") and not Faceroll.isBuffActive("Lightning Shield") then
        state.lightningshield = true
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
    if IsSpellInRange("Strike", "target") == 1 then
        state.melee = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "charge",
    "attack",
    "thunderclap",
    -- "heroicstrike",
    "strike",
    "lightningbolt",
    "chainlightning",
    "lightningblade",
    "thunderslam",
    "lightningshield",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)
    if st or aoe then
        -- Single Target

        if state.lightningshield then
            return "lightningshield"
        end

        if state.targetingenemy then

            if not state.melee and state.charge then
                return "charge"

            elseif not state.autoattack and not state.hsqueued then
                return "attack"

            elseif state.thunderclap and state.melee and state.rage20 then
                return "thunderclap"

            elseif state.instantlb and aoe and state.chainlightning then
                return "chainlightning"

            elseif state.instantlb and st then
                return "lightningbolt"

            elseif state.lightningblade and st then
                return "lightningblade"

            elseif state.thunderslam and state.melee and aoe then
                return "thunderslam"

            -- elseif state.rage35 and not state.hsqueued then
            --     return "heroicstrike"

            elseif state.rage40 then
                return "strike"

            end
        end

    end

    return nil
end
