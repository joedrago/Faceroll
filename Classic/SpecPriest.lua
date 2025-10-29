-----------------------------------------------------------------------------------------
-- Classic Priest

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("CP", "ccccaa", "PRIEST-CLASSIC")

spec.buffs = {
    "Inner Fire",
    "Renew",
    "Weakened Soul",
    "Power Word: Shield",
}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    "- Buffs -",
    "innerfire",
    "renewbuff",
    "weakenedsoulbuff",
    "shieldbuff",

    "- Debuffs -",
    "pain",

    "- Spells -",
    "shieldavailable",
    "mindblast",

    "- Target -",
    "targetingenemy",
    "target40",

    "- Combat -",
    "combat",
    "hp80",
    "mana90",
    "wand",
    "coast",
}

local coasting = false

spec.options = {
    "coast",
}

spec.calcState = function(state)
    -- Buffs
    if Faceroll.isBuffActive("Inner Fire") then
        state.innerfire = true
    end
    if Faceroll.isBuffActive("Renew") then
        state.renewbuff = true
    end
    if Faceroll.isBuffActive("Weakened Soul") then
        state.weakenedsoulbuff = true
    end
    if Faceroll.isBuffActive("Power Word: Shield") then
        state.shieldbuff = true
    end

    -- Debuffs
    if Faceroll.isDotActive("Shadow Word: Pain") > 0.1 then
        state.pain = true
    end

    -- Spells
    if Faceroll.isSpellAvailable("Power Word: Shield") then
        state.shieldavailable = true
    end
    if Faceroll.isSpellAvailable("Mind Blast") then
        state.mindblast = true
    end

    -- Target
    if Faceroll.targetingEnemy() then
        state.targetingenemy = true

        local targethp = UnitHealth("target")
        local targethpmax = UnitHealthMax("target")
        local targethpnorm = targethp / targethpmax
        if targethpnorm <= 0.40 then
            state.target40 = true
        end
    end

    -- Combat
    if Faceroll.inCombat() then
        state.combat = true
    end
    local hp = UnitHealth("player")
    local hpmax = UnitHealthMax("player")
    local hpnorm = hp / hpmax
    if hpnorm < 0.8 then
        state.hp80 = true
    end
    local mana = UnitPower("player", Enum.PowerType.Mana)
    local manamax = UnitPowerMax("player", Enum.PowerType.Mana)
    local mananorm = mana / manamax
    if mananorm >= 0.90 then
        state.mana90 = true
    end

    if IsCurrentSpell(5019) then -- Shoot (wand)
        state.wand = true
    end

    if not state.combat or Faceroll.targetChanged then
        Faceroll.setOption("coast", false)
        state.coast = false
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "shield",
    "renew",
    "mindblast",
    "pain",
    "shoot",
    "innerfire",
    "coast",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Grind

        -- "Coasting" means to simply just wand a mob down for the last few
        -- percent of its HP in order to ensure we're outside of the 5 second
        -- rule when combat drops. Don't spend mana on a late-fight shield or
        -- renew or SW:P, etc. Coasting will automatically self-disable on
        -- target change or when combat drops, or if a macro with "/frf coast"
        -- is pressed.

        -- Also avoid casting Renew *right* when combat drops, and instead give
        -- Spirit Tap + FSR a chance to enjoy that juicy spirit. This is what
        -- the mana check is for.

        if not state.coast and state.hp80 and not state.renewbuff and (state.combat or state.mana90) then
            return "renew"

        elseif state.targetingenemy then
            if not state.coast and not state.innerfire then
                return "innerfire"

            elseif not state.coast and not state.shieldbuff and not state.weakenedsoulbuff and state.shieldavailable then
                return "shield"

            elseif not state.coast and not state.combat and state.mindblast then
                return "mindblast"

            elseif not state.coast and not state.pain then
                return "pain"

            elseif not state.wand then
                return "shoot"

            elseif state.target40 and not state.coast then
                return "coast"

            end
        end

    elseif mode == Faceroll.MODE_AOE then
        -- Chill

        if not state.innerfire then
            return "innerfire"

        elseif not state.coast and not state.pain then
            return "pain"

        elseif state.targetingenemy then
            return "shoot"

        end
    end

    return nil
end
