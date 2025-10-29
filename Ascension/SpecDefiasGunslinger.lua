-----------------------------------------------------------------------------------------
-- Ascension WoW Defias Gunslinger

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("DG", "ffaa66", "HERO-Defias Gunslinger")

spec.buffs = {}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    "- Resources -",
    "energyL50",
    "cp3",
    "cp5",

    "- Abilities -",
    "charge",
    "mongoosebite",
    "grapeshot",
    "raptorstrike",
    "raptorqueued",

    -- "- Procs -",
    -- "eruption",
    -- "maelstrom",
    -- "hotstreak",

    -- "- Totems -",
    -- "searingtotem",
    -- "magmatotem",
    -- "firetotem",

    -- "- Dots -",
    -- "flameshock",

    "- Combat -",
    "targetingenemy",
    "combat",
    "melee",
}

spec.calcState = function(state)
    local energy = UnitPower("PLAYER", 3)
    local cp = GetComboPoints("PLAYER", "TARGET")

    if energy <= 50 then
        state.energyL50 = true
    end

    if cp >= 3 then
        state.cp3 = true
    end
    if cp >= 5 then
        state.cp5 = true
    end

    if Faceroll.isSpellAvailable("Charge") then
        state.charge = true
    end
    if Faceroll.isSpellAvailable("Mongoose Bite") then
        state.charge = true
    end
    if Faceroll.isSpellAvailable("Grape Shot") then
        state.grapeshot = true
    end
    if Faceroll.isSpellAvailable("Raptor Strike") then
        state.raptorstrike = true
    end
    if IsCurrentSpell("Raptor Strike") then
        state.raptorqueued = true
    end

    -- if Faceroll.getBuffStacks("Eruption") >= 3 then
    --     state.eruption = true
    -- end
    -- if Faceroll.getBuffStacks("Maelstrom Weapon") >= 5 then
    --     state.maelstrom = true
    -- end
    -- if Faceroll.isBuffActive("Hot Streak") then
    --     state.hotstreak = true
    -- end


    -- for i=1,4 do
    --     local haveTotem, totemName, startTime, duration = GetTotemInfo(i)
    --     if type(totemName) == "string" then
    --         if string.find(totemName, "Searing Totem") == 1 then
    --             state.searingtotem = true
    --             state.firetotem = true
    --         elseif string.find(totemName, "Magma Totem") == 1 then
    --             state.magmatotem = true
    --             state.firetotem = true
    --         end
    --     end
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
    if IsSpellInRange("Eviscerate", "target") == 1 then
        state.melee = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "pistolshot",
    "grapeshot",
    "charge",
    "mongoosebite",
    "raptorstrike",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)
    if st or aoe then
        if state.targetingenemy then
            if not state.melee and state.charge then
                return "charge"

            elseif state.energyL50 and state.raptorstrike and not state.raptorqueued then
                return "raptorstrike"

            elseif state.mongoosebite then
                return "mongoosebite"

            elseif state.grapeshot and state.cp5 then
                return "grapeshot"

            else
                return "pistolshot"

            end
        end

    end

    return nil
end
