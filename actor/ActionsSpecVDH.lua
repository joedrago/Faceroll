-----------------------------------------------------------------------------------------
-- Vengeance Demon Hunter

local function press(button, name)
    -- print("Press: " .. name)
    return button
end

local function nextAction(action, bits)
    local metamorphosisbuff = bitand(bits, 0x1)
    local metamorphosiscd = bitand(bits, 0x2)
    local feldevastation = bitand(bits, 0x4)
    local sigilofflame = bitand(bits, 0x8)

    local immolationaura = bitand(bits, 0x10)
    local thehunt = bitand(bits, 0x20)
    local felblade = bitand(bits, 0x40)
    local fracture = bitand(bits, 0x80)

    local furyG30 = bitand(bits, 0x100)
    local furyG40 = bitand(bits, 0x200)
    local furyG50 = bitand(bits, 0x400)
    local furyL130 = bitand(bits, 0x800)

    local soulfragments4plus = bitand(bits, 0x1000)
    local soulfragmentszero = bitand(bits, 0x2000)
    local fierybrand = bitand(bits, 0x4000)
    local sigilofspite = bitand(bits, 0x8000)

    if action == ACTION_Q then
        -- Single Target

        if fierybrand > 0 then
            -- Use Fiery Brand if the debuff is not currently active.
            return press("f8", "fiery brand")

        elseif immolationaura > 0 then
            -- Use Immolation Aura/ Consuming Fire.
            return press("pad8", "immolation aura")

        elseif sigilofflame > 0 then
            -- Use Sigil of Flame/ Sigil of Doom.
            return press("pad7", "sigil of flame")

        elseif sigilofspite > 0 then
            -- Use Sigil of Spite.
            return press("f9", "sigil of spite")

        elseif metamorphosisbuff > 0 and furyL130 > 0 and fracture > 0 then
            --  Fracture while transformed if you won't cap Fury.
            return press("0", "fracture while transformed")

        elseif metamorphosisbuff > 0 and furyG30 > 0 then
            -- Use Soul Sunder while transformed  to spend Fury.
            return press("9", "soul sunder (soul cleave)")

        elseif feldevastation > 0 and furyG50 > 0 then
            -- Use Fel Devastation if you have at least 50 Fury.
            return press("=", "fel devastation")

        elseif metamorphosiscd > 0 and sigilofflame == 0 and feldevastation == 0 then
            -- Use Metamorphosis only if Sigil of Flame and Fel Devastation are on cooldown.
            return press("-", "meta")

        elseif furyG30 > 0 then
            -- Spend Fury with Soul Cleave.
            return press("9", "soul cleave")

        elseif furyL130 > 0 and felblade > 0 then
            -- Felblade if you won't cap Fury.
            return press("8", "felblade")

        elseif furyL130 > 0 and fracture > 0 then
            --  Fracture if you won't cap Fury.
            return press("0", "fracture")

        else
            -- Throw Glaive for filler or when kiting.
            return press("7", "throw glaive")
        end

    elseif action == ACTION_E then
        -- AOE

        if fierybrand > 0 then
            -- Use Fiery Brand if the debuff is not currently active.
            return press("f8", "fiery brand")

        elseif furyG40 > 0 and soulfragments4plus > 0 then
            -- Use Spirit Bomb/ Spirit Burst with 4+ Souls.
            return press("f7", "spirit bomb")

        elseif immolationaura > 0 then
            -- Use Immolation Aura/ Consuming Fire.
            return press("pad8", "immolation aura")

        elseif sigilofflame > 0 then
            -- Use Sigil of Flame/ Sigil of Doom.
            return press("pad7", "sigil of flame")

        elseif sigilofspite > 0 then
            -- Use Sigil of Spite.
            return press("f9", "sigil of spite")

        elseif metamorphosisbuff > 0 and fracture > 0 then
            --  Fracture while transformed.
            return press("0", "fracture while transformed")

        elseif metamorphosisbuff > 0 and furyG30 > 0 then
            -- Use Soul Sunder while transformed  to spend Fury.
            return press("9", "soul sunder (soul cleave)")

        elseif feldevastation > 0 and furyG50 > 0 then
            -- Use Fel Devastation if you have at least 50 Fury.
            return press("=", "fel devastation")

        elseif metamorphosiscd > 0 and sigilofflame == 0 and feldevastation == 0 then
            -- Use Metamorphosis only if Sigil of Flame and Fel Devastation are on cooldown.
            return press("-", "meta")

        elseif fracture > 0 and soulfragments4plus == 0 then
            -- Fracture if you won't cap Souls.
            return press("0", "fracture wont cap souls")

        elseif furyG30 > 0 then
            -- Spend Fury with Soul Cleave.
            return press("9", "soul cleave")

        elseif furyL130 > 0 and felblade > 0 then
            -- Felblade if you won't cap Fury.
            return press("8", "felblade")

        else
            -- Throw Glaive for filler or when kiting.
            return press("7", "throw glaive")
        end
    end

    return nil
end

return nextAction
