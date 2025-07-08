-----------------------------------------------------------------------------------------
-- Vengeance Demon Hunter

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("VDH", "993399", "DEMONHUNTER-2")

spec.buffs = {
    "Metamorphosis",
    "Soul Fragments",
    "Demon Spikes",
}

-----------------------------------------------------------------------------------------
-- States

spec.states = {
    "metamorphosisbuff",
    "demonspikesbuff",
    "metamorphosiscd",
    "feldevastation",
    "sigilofflame",
    "immolationaura",
    "thehunt",
    "felblade",
    "fracture",
    "demonspikes",
    "furyG30",
    "furyG40",
    "furyG50",
    "furyL130",
    "soulfragments4plus",
    "soulfragmentszero",
    "fierybrand",
    "sigilofspite",
}

local demonspikesDeadzone = Faceroll.deadzoneCreate("Demon Spikes", 0.3, 0.5)

spec.calcState = function(state)
    if Faceroll.isBuffActive("Metamorphosis") then
        state.metamorphosisbuff = true
    end
    if Faceroll.getBuffRemaining("Demon Spikes") > 2 then
        state.demonspikesbuff = true
        Faceroll.deadzoneUpdate(demonspikesDeadzone)
    end

    if Faceroll.isSpellAvailable("Metamorphosis") then
        state.metamorphosiscd = true
    end
    if Faceroll.isSpellAvailable("Fel Devastation") then
        state.feldevastation = true
    end
    if Faceroll.isSpellAvailable("Sigil of Flame") then
        state.sigilofflame = true
    end
    if Faceroll.isSpellAvailable("Immolation Aura") then
        state.immolationaura = true
    end
    if Faceroll.isSpellAvailable("The Hunt") then
        state.thehunt = true
    end
    if Faceroll.isSpellAvailable("Felblade") then
        state.felblade = true
    end
    if Faceroll.spellCharges("Fracture") then
        state.fracture = true
    end
    if Faceroll.spellCharges("Demon Spikes") > 0 and not Faceroll.deadzoneActive(demonspikesDeadzone) then
        state.demonspikes = true
    end

    local fury = UnitPower("player")
    if fury >= 30 then
        state.furyG30 = true
    end
    if fury >= 40 then
        state.furyG40 = true
    end
    if fury >= 50 then
        state.furyG50 = true
    end
    if fury < 130 then
        state.furyL130 = true
    end

    if Faceroll.getBuffStacks("Soul Fragments") >= 4 then
        state.soulfragments4plus = true
    end
    if Faceroll.getBuffStacks("Soul Fragments") == 0 then
        state.soulfragmentszero = true
    end

    if Faceroll.isDotActive("Fiery Brand") <= 0 and Faceroll.isSpellAvailable("Fiery Brand") then
        state.fierybrand = true
    end

    if Faceroll.isSpellAvailable("Sigil of Spite") then
        state.sigilofspite = true
    end

    if Faceroll.debug then
        local o = ""
        local avl = "N"
        if Faceroll.isSpellAvailable("Fiery Brand") then
            avl = "Y"
        end
        o = o .. "dot(Fiery Brand): " .. Faceroll.isDotActive("Fiery Brand") .. "\n"
        o = o .. "avl(Fiery Brand): " .. avl .. "\n"
        Faceroll.setDebugText(o)
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "throwglaive",
    "felblade",
    "soulcleave",
    "fracture",
    "metamorphosis",
    "feldevastation",
    "sigilofflame",
    "immolationaura",
    "spiritbomb",
    "fierybrand",
    "sigilofspite",
    "demonspikes",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Single Target

        if not state.demonspikesbuff and state.demonspikes then
            return "demonspikes"

        elseif state.fierybrand then
            -- Use Fiery Brand if the debuff is not currently active.
            return "fierybrand"

        elseif state.immolationaura then
            -- Use Immolation Aura/ Consuming Fire.
            return "immolationaura"

        elseif state.sigilofflame then
            -- Use Sigil of Flame/ Sigil of Doom.
            return "sigilofflame"

        elseif state.sigilofspite then
            -- Use Sigil of Spite.
            return "sigilofspite"

        elseif state.metamorphosisbuff and state.furyL130 and state.fracture then
            --  Fracture while transformed if you won't cap Fury.
            return "fracture"

        elseif state.metamorphosisbuff and state.furyG30 then
            -- Use Soul Sunder while transformed  to spend Fury.
            return "soulcleave"

        elseif state.feldevastation and state.furyG50 then
            -- Use Fel Devastation if you have at least 50 Fury.
            return "feldevastation"

        elseif state.metamorphosiscd and not state.sigilofflame and not state.feldevastation then
            -- Use Metamorphosis only if Sigil of Flame and Fel Devastation are on cooldown.
            return "metamorphosis"

        elseif state.furyG30 then
            -- Spend Fury with Soul Cleave.
            return "soulcleave"

        elseif state.furyL130 and state.felblade then
            -- Felblade if you won't cap Fury.
            return "felblade"

        elseif state.furyL130 and state.fracture then
            --  Fracture if you won't cap Fury.
            return "fracture"

        else
            -- Throw Glaive for filler or when kiting.
            return "throwglaive"
        end

    elseif mode == Faceroll.MODE_AOE then
        -- AOE

        if not state.demonspikesbuff and state.demonspikes then
            return "demonspikes"

        elseif state.fierybrand then
            -- Use Fiery Brand if the debuff is not currently active.
            return "fierybrand"

        elseif state.furyG40 and state.soulfragments4plus then
            -- Use Spirit Bomb/ Spirit Burst with 4+ Souls.
            return "spiritbomb"

        elseif state.immolationaura then
            -- Use Immolation Aura/ Consuming Fire.
            return "immolationaura"

        elseif state.sigilofflame then
            -- Use Sigil of Flame/ Sigil of Doom.
            return "sigilofflame"

        elseif state.sigilofspite then
            -- Use Sigil of Spite.
            return "sigilofspite"

        elseif state.metamorphosisbuff and state.fracture then
            --  Fracture while transformed.
            return "fracture"

        elseif state.metamorphosisbuff and state.furyG30 then
            -- Use Soul Sunder while transformed  to spend Fury.
            return "soulcleave"

        elseif state.feldevastation and state.furyG50 then
            -- Use Fel Devastation if you have at least 50 Fury.
            return "feldevastation"

        elseif state.metamorphosiscd and not state.sigilofflame and not state.feldevastation then
            -- Use Metamorphosis only if Sigil of Flame and Fel Devastation are on cooldown.
            return "metamorphosis"

        elseif state.fracture and not state.soulfragments4plus then
            -- Fracture if you won't cap Souls.
            return "fracture"

        elseif state.furyG30 then
            -- Spend Fury with Soul Cleave.
            return "soulcleave"

        elseif state.furyL130 and state.felblade then
            -- Felblade if you won't cap Fury.
            return "felblade"

        else
            -- Throw Glaive for filler or when kiting.
            return "throwglaive"
        end
    end

    return nil
end
