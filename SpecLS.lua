-----------------------------------------------------------------------------------------
-- Ascension WoW Lava Sweep

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("LS", "ffaa66", "HERO-Lava Sweep")

spec.buffs = {}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    "- Abilities -",
    "lavasweep",
    "charge",
    "fireblast",
    "ragefirenova",
    "sundering",
    "meteor",

    "- Procs -",
    "eruption",
    "maelstrom",
    "hotstreak",

    "- Totems -",
    "searingtotem",
    "magmatotem",
    "firetotem",

    "- Dots -",
    "flameshock",

    "- Combat -",
    "targetingenemy",
    "combat",
    "melee",
}

spec.calcState = function(state)

    if Faceroll.isSpellAvailable("Lava Sweep") then
        state.lavasweep = true
    end
    if Faceroll.isSpellAvailable("Charge") then
        state.charge = true
    end
    if Faceroll.isSpellAvailable("Fire Blast") then
        state.fireblast = true
    end
    if Faceroll.isSpellAvailable("Ragefire Nova") then
        state.ragefirenova = true
    end
    if Faceroll.isSpellAvailable("Sundering") then
        state.sundering = true
    end
    if Faceroll.isSpellAvailable("Meteor") then
        state.meteor = true
    end
    if Faceroll.isSpellAvailable("Flame Shock") and Faceroll.isDotActive("Flame Shock") < 0.1 then
        state.flameshock = true
    end

    if Faceroll.getBuffStacks("Eruption") >= 3 then
        state.eruption = true
    end
    if Faceroll.getBuffStacks("Maelstrom Weapon") >= 5 then
        state.maelstrom = true
    end
    if Faceroll.isBuffActive("Hot Streak") then
        state.hotstreak = true
    end


    for i=1,4 do
        local haveTotem, totemName, startTime, duration = GetTotemInfo(i)
        if type(totemName) == "string" then
            if string.find(totemName, "Searing Totem") == 1 then
                state.searingtotem = true
                state.firetotem = true
            elseif string.find(totemName, "Magma Totem") == 1 then
                state.magmatotem = true
                state.firetotem = true
            end
        end
    end

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
    if IsSpellInRange("Lava Sweep", "target") == 1 then
        state.melee = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "pyroblast",
    "lavasweep",
    "charge",
    "fireblast",
    "searingtotem",
    "magmatotem",
    "ragefirenova",
    "flameshock",
    "sundering",
    "destroytotems",
    "fireball",
    "meteor",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)
    if st or aoe then
        if state.targetingenemy then

            if not state.melee and state.charge then
                return "charge"

            elseif state.lavasweep then
                return "lavasweep"

            elseif state.meteor then
                return "meteor"

            elseif state.hotstreak then
                return "pyroblast"

            elseif not state.searingtotem and st then
                return "searingtotem"

            elseif not state.magmatotem and aoe then
                return "magmatotem"

            elseif state.sundering then
                return "sundering"

            elseif state.maelstrom then
                return "fireball"

            elseif state.fireblast then
                return "fireblast"

            elseif state.flameshock then
                return "flameshock"

            elseif state.firetotem and state.ragefirenova then
                return "ragefirenova"

            end

        elseif not state.combat then -- and state.firetotem then
            return "destroytotems"

        end

    end

    return nil
end
