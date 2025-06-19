-----------------------------------------------------------------------------------------
-- Vengeance Demon Hunter

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("VDH", "993399", "DEMONHUNTER-2")

spec.buffs = {
    "Metamorphosis",
    "Soul Fragments",
}

spec.abilities = {
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
}

local bits = Faceroll.createBits({
    "metamorphosisbuff",
    "metamorphosiscd",
    "feldevastation",
    "sigilofflame",
    "immolationaura",
    "thehunt",
    "felblade",
    "fracture",
    "furyG30",
    "furyG40",
    "furyG50",
    "furyL130",
    "soulfragments4plus",
    "soulfragmentszero",
    "fierybrand",
    "sigilofspite",
})

spec.calcBits = function()
    bits:reset()

    if Faceroll.isBuffActive("Metamorphosis") then
        bits:enable("metamorphosisbuff")
    end

    if Faceroll.isSpellAvailable("Metamorphosis") then
        bits:enable("metamorphosiscd")
    end
    if Faceroll.isSpellAvailable("Fel Devastation") then
        bits:enable("feldevastation")
    end
    if Faceroll.isSpellAvailable("Sigil of Flame") then
        bits:enable("sigilofflame")
    end
    if Faceroll.isSpellAvailable("Immolation Aura") then
        bits:enable("immolationaura")
    end
    if Faceroll.isSpellAvailable("The Hunt") then
        bits:enable("thehunt")
    end
    if Faceroll.isSpellAvailable("Felblade") then
        bits:enable("felblade")
    end
    if Faceroll.spellCharges("Fracturestate.") then
        bits:enable("fracture")
    end

    local fury = UnitPower("player")
    if fury >= 30 then
        bits:enable("furyG30")
    end
    if fury >= 40 then
        bits:enable("furyG40")
    end
    if fury >= 50 then
        bits:enable("furyG50")
    end
    if fury < 130 then
        bits:enable("furyL130")
    end

    if Faceroll.getBuffStacks("Soul Fragments") >= 4 then
        bits:enable("soulfragments4plus")
    end
    if Faceroll.getBuffStacks("Soul Fragments") == 0 then
        bits:enable("soulfragmentszero")
    end

    if Faceroll.isDotActive("Fiery Brand") <= 0 and Faceroll.isSpellAvailable("Fiery Brand") then
        bits:enable("fierybrand")
    end

    if Faceroll.isSpellAvailable("Sigil of Spite") then
        bits:enable("sigilofspite")
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

    return bits.value
end

spec.nextAction = function(action, rawBits)
    local state = bits:parse(rawBits)

    if action == Faceroll.ACTION_ST then
        -- Single Target

        if state.fierybrand then
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

    elseif action == Faceroll.ACTION_AOE then
        -- AOE

        if state.fierybrand then
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
