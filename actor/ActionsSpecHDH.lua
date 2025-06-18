-----------------------------------------------------------------------------------------
-- Havoc Demon Hunter

local function press(button, name)
    -- print("Press: " .. name)
    return button
end

local function nextAction(action, bits)
    local metamorphosisbuff = bitand(bits, 0x1)
    local essencebreakbuff = bitand(bits, 0x2)
    local metamorphosis = bitand(bits, 0x4)
    local essencebreak = bitand(bits, 0x8)
    local thehunt = bitand(bits, 0x10)
    local sigilofflame = bitand(bits, 0x20)
    local eyebeam = bitand(bits, 0x40)
    local bladedance = bitand(bits, 0x80)
    local felblade = bitand(bits, 0x100)
    local immolationaura = bitand(bits, 0x200)
    local furyG40 = bitand(bits, 0x400)
    local furyL130 = bitand(bits, 0x800)
    local furyL140 = bitand(bits, 0x1000)

    if action == ACTION_ST then
        -- Single Target

        if essencebreakbuff > 0 and bladedance > 0 then
            -- Cast Death Sweep during Essence Break.
            return press("-", "death sweep EB (blade dance during meta)")

        elseif essencebreakbuff > 0 and furyG40 > 0 then
            -- Cast Annihilation during Essence Break.
            return press("9", "annihilation EB (chaos strike during meta)")

        elseif thehunt > 0 then
            -- Cast The Hunt.
            return press("f7", "the hunt")

        elseif metamorphosisbuff > 0 and sigilofflame > 0 then
            -- Cast Sigil of Doom in Metamorphosis.
            return press("pad7", "sigil of doom (sigil of flame in meta)")

        elseif metamorphosisbuff > 0 and essencebreak > 0 then
            -- Cast Essence Break while in Metamorphosis.
            return press("f8", "essence break")

        elseif metamorphosisbuff > 0 and bladedance > 0 then
            -- Cast Death Sweep.
            return press("-", "death sweep (blade dance during meta)")

        elseif metamorphosis > 0 and eyebeam == 0 then
            -- Cast Metamorphosis if Eye Beam is on cooldown.
            return press("pad8", "meta")

        elseif sigilofflame > 0 then
            -- Cast Sigil of Flame before an Eye Beam, should always sync these up.
            return press("pad7", "sigil of flame")

        elseif eyebeam > 0 then
            -- Cast Eye Beam or (Abyssal Gaze in Metamorphosis).
            return press("=", "eye beam")

        elseif bladedance > 0 then
            -- Cast Blade Dance.
            return press("-", "blade dance")

        elseif metamorphosis > 0 and furyG40 > 1 then
            -- Cast Annihilation.
            return press("9", "annihilation (chaos strike during meta)")

        elseif furyL130 > 1 and felblade > 1 then
            -- Cast Felblade if under 130 Fury.
            return press("0", "felblade")

        elseif furyG40 > 1 then
            -- Cast Chaos Strike.
            return press("9", "chaos strike")

        elseif immolationaura > 0 then
            -- Cast Immolation Aura or ( Consuming Fire in Metamorphosis).
            return press("8", "immolation aura")

        else
            -- Cast Throw Glaive if no other buttons are available.
            return press("7", "throw glaive")
        end

    elseif action == ACTION_AOE then
        -- AOE


        if essencebreakbuff > 0 and bladedance > 0 then
            -- Cast Death Sweep during Essence Break.
            return press("-", "death sweep EB (blade dance during meta)")

        elseif essencebreakbuff > 0 and furyG40 > 0 then
            -- Cast Annihilation during Essence Break.
            return press("9", "annihilation EB (chaos strike during meta)")

        elseif thehunt > 0 then
            -- Cast The Hunt.
            return press("f7", "the hunt")

        elseif metamorphosisbuff > 0 and sigilofflame > 0 then
            -- Cast Sigil of Doom in Metamorphosis.
            return press("pad7", "sigil of doom (sigil of flame in meta)")

        elseif metamorphosisbuff > 0 and essencebreak > 0 then
            -- Cast Essence Break while in Metamorphosis.
            return press("f8", "essence break")

        elseif metamorphosisbuff > 0 and bladedance > 0 then
            -- Cast Death Sweep.
            return press("-", "death sweep (blade dance during meta)")

        elseif metamorphosis > 0 and eyebeam == 0 and sigilofflame == 0 then
            -- Cast Metamorphosis if Eye Beam and Sigil of Flame are on cooldown.
            return press("pad8", "meta")

        elseif eyebeam > 0 then
            -- Cast Eye Beam or (Abyssal Gaze in Metamorphosis).
            return press("=", "eye beam")

        elseif bladedance > 0 then
            -- Cast Blade Dance.
            return press("-", "blade dance")

        elseif sigilofflame > 0 and furyL140 > 0 then
            -- Cast Sigil of Flame if under 140 fury.
            return press("pad7", "sigil of flame")

        elseif metamorphosis > 0 and furyG40 > 1 then
            -- Cast Annihilation.
            return press("9", "annihilation (chaos strike during meta)")

        elseif furyL130 > 1 and felblade > 1 then
            -- Cast Felblade if under 130 Fury.
            return press("0", "felblade")

        elseif furyG40 > 1 then
            -- Cast Chaos Strike.
            return press("9", "chaos strike")

        elseif immolationaura > 0 then
            -- Cast Immolation Aura or (Consuming Fire in Metamorphosis).
            return press("8", "immolation aura")

        else
            -- Cast Throw Glaive if no other buttons are available.
            return press("7", "throw glaive")
        end
    end

    return nil
end

return nextAction
