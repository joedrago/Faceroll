-----------------------------------------------------------------------------------------
-- Classic Feral Druid

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("FERAL", "00aa00", "DRUID-2")

Faceroll.enemyGridTrack(spec, "Rake", "RAKE", "621518")
Faceroll.enemyGridTrack(spec, "Rip", "RIP", "626218")

-----------------------------------------------------------------------------------------
-- Macros

-- /fr ST

-- /fr AE

-- /fra

-- /cleartarget
-- /targetenemy [noexists][dead]
-- /startAttack
-- /fr TAE

-- #showtooltip Prowl
-- /cast [noform:3] !Cat Form
-- /cast [form:3] Prowl

-----------------------------------------------------------------------------------------
-- States

-- f_ form
-- s_ spell
-- b_ buff
-- d_ debuff

spec.overlay = Faceroll.createOverlay({
    "- Options -",
    "nobleed",
    "bear",

    "- Form -",
    "f_bear",
    "f_cat",

    "- Shared -",
    "b_rejuv",
    "s_charge",
    "s_fff",
    "d_fff",
    "s_berserk",
    "b_berserk",

    "- Bear -",
    "s_enrage",
    "s_mangle",
    "s_roar",
    "d_roar",

    "- Cat -",
    "b_prowl",
    "s_tigersfury",
    "b_tigersfury",
    "d_rake",
    "d_rip",
    "s_kick",

    "targetcasting",
})

spec.options = {
    "nobleed",
    "bear",
}

spec.calcState = function(state)
    -- Form --
    if GetShapeshiftForm() == 1 then
        state.f_bear = true
    end
    if GetShapeshiftForm() == 3 then
        state.f_cat = true
    end

    -- Shared --
    if Faceroll.isBuffActive("Rejuvenation") then
        state.b_rejuv = true
    end
    if state.f_bear then
        if Faceroll.isSpellAvailable("Feral Charge - Bear") then
            state.s_charge = true
        end
    elseif state.f_cat then
        if Faceroll.isSpellAvailable("Feral Charge - Cat") then
            state.s_charge = true
        end
    end
    if Faceroll.isSpellAvailable("Faerie Fire (Feral)") then
        state.s_fff = true
    end
    if Faceroll.getDotRemainingNorm("Faerie Fire (Feral)") > 0.1 then
        state.d_fff = true
    end
    if Faceroll.isSpellAvailable("Berserk") then
        state.s_berserk = true
    end
    if Faceroll.isBuffActive("Berserk") then
        state.b_berserk = true
    end

    -- Bear --
    if Faceroll.isSpellAvailable("Enrage") then
        state.s_enrage = true
    end
    if Faceroll.isSpellAvailable("Mangle (Bear)") then
        state.s_mangle = true
    end
    if Faceroll.isSpellAvailable("Demoralizing Roar") then
        state.s_roar = true
    end
    if Faceroll.getDotRemainingNorm("Demoralizing Roar") > 0.1 then
        state.d_roar = true
    end

    -- Cat --
    if Faceroll.isBuffActive("Prowl") then
        state.b_prowl = true
    end
    if Faceroll.isSpellAvailable("Tiger's Fury") then
        state.s_tigersfury = true
    end
    if Faceroll.isBuffActive("Tiger's Fury") then
        state.b_tigersfury = true
    end
    if Faceroll.getDotRemainingNorm("Rake") > 0.1 then
        state.d_rake = true
    end
    if Faceroll.getDotRemainingNorm("Rip") > 0.1 then
        state.d_rip = true
    end
    if Faceroll.isSpellAvailable("Skull Bash") then
        state.s_kick = true
    end

    local targetCastingSpell, _, _, _, targetCastingSpellEndTime = UnitCastingInfo("target")
    local targetCastingSpellDone = 0
    if targetCastingSpell then
        state.targetcasting = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    -- #showtooltip
    -- /cast !Bear Form
    "bear",

    -- #showtooltip
    -- /cast [form:1] Feral Charge - Bear
    -- /cast [form:3] Feral Charge - Cat
    "charge",

    -- #showtooltip
    -- /cast !Maul
    -- /startAttack
    "maul",

    -- #showtooltip
    -- /cast [form:1] Swipe (Bear)
    -- /cast [form:3] Swipe (Cat)
    "swipe",

    -- Before having Mangle, make this macro but name it Mangle anyway:
    -- #showtooltip
    -- /cast Claw
    -- /startAttack
    --
    -- then change it to...
    ---
    -- #showtooltip
    -- /cast [form:1] Mangle (Bear)
    -- /cast [form:3] Mangle (Cat)
    "mangle",

    -- #showtooltip
    -- /cast !Cat Form
    "cat",

    "fff",
    "enrage",
    "roar",
    "tigersfury",
    "rip",
    "bite",   -- make rip until you get this
    "rake",   -- make Mangle macro until you get it
    "ravage", -- make Mangle macro until you get it
    "rejuv",
    "kick",   -- Skull Bash
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    local wantsbear = state.bear or (state.level < 20)

    if wantsbear then
        -- Bear

        if not state.group and not state.targetingenemy and state.hp < 0.9 and not state.combat and not state.b_rejuv then
            return "rejuv"

        elseif state.targetingenemy then
            if not state.f_bear then
                return "bear"

            elseif state.s_charge and not state.melee then
                return "charge"

            -- elseif not state.s_charge and not state.melee and state.s_fff and not state.d_fff then
            --     return "fff"

            elseif state.s_enrage then
                return "enrage"

            elseif state.melee and state.s_roar and not state.d_roar then
                return "roar"
            elseif aoe and state.melee then
                return "swipe"
            else
                return "maul"
            end
        end

    else
        -- Cat

        if not state.group and not state.targetingenemy and state.hp < 0.9 and not state.combat and not state.b_rejuv then
            return "rejuv"

        elseif state.targetingenemy then
            -- state.nobleed means "I am fighting bleed immune targets"

            if not state.f_cat then
                return "cat"

            elseif state.s_charge and not state.melee then
                return "charge"

            elseif state.b_prowl and not state.combat then
                return "ravage"

            elseif not aoe and state.targetcasting and state.s_kick then
                return "kick"

            -- elseif not state.s_charge and not state.melee and state.s_fff and not state.d_fff then
            --     return "fff"

            elseif not state.b_berserk and state.s_tigersfury and not state.b_tigersfury and state.energy <= 30 then
                return "tigersfury"

            elseif aoe and state.melee then
                return "swipe"

            elseif not state.nobleed and not state.d_rip and state.combopoints >= 5 then
                return "rip"

            elseif state.combopoints >= 5 then
                return "bite"

            elseif not state.nobleed and not state.d_rake then
                return "rake"

            else
                return "mangle"
            end
        end
    end
end
