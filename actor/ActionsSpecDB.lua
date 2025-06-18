-----------------------------------------------------------------------------------------
-- Druid Bear

local function press(button, name)
    -- print("Press: " .. name)
    return button
end

local function nextAction(action, bits)
    local ggending = bitand(bits, 0x1)
    local needsif = bitand(bits, 0x2)
    local needsfr = bitand(bits, 0x4)

    if action == ACTION_ST then
        -- Single Target

        -- if essencebreakbuff > 0 and bladedance > 0 then
        --     -- Cast Death Sweep during Essence Break.
        --     return press("-", "death sweep EB (blade dance during meta)")

        -- elseif essencebreakbuff > 0 and furyG40 > 0 then
        --     -- Cast Annihilation during Essence Break.
        --     return press("9", "annihilation EB (chaos strike during meta)")

        -- elseif thehunt > 0 then
        --     -- Cast The Hunt.
        --     return press("f7", "the hunt")

        -- elseif metamorphosisbuff > 0 and sigilofflame > 0 then
        --     -- Cast Sigil of Doom in Metamorphosis.
        --     return press("pad7", "sigil of doom (sigil of flame in meta)")

        -- elseif metamorphosisbuff > 0 and essencebreak > 0 then
        --     -- Cast Essence Break while in Metamorphosis.
        --     return press("f8", "essence break")

        -- elseif metamorphosisbuff > 0 and bladedance > 0 then
        --     -- Cast Death Sweep.
        --     return press("-", "death sweep (blade dance during meta)")

        -- elseif metamorphosis > 0 and eyebeam == 0 then
        --     -- Cast Metamorphosis if Eye Beam is on cooldown.
        --     return press("pad8", "meta")

        -- elseif sigilofflame > 0 then
        --     -- Cast Sigil of Flame before an Eye Beam, should always sync these up.
        --     return press("pad7", "sigil of flame")

        -- elseif eyebeam > 0 then
        --     -- Cast Eye Beam or (Abyssal Gaze in Metamorphosis).
        --     return press("=", "eye beam")

        -- elseif bladedance > 0 then
        --     -- Cast Blade Dance.
        --     return press("-", "blade dance")

        -- elseif metamorphosis > 0 and furyG40 > 1 then
        --     -- Cast Annihilation.
        --     return press("9", "annihilation (chaos strike during meta)")

        -- elseif furyL130 > 1 and felblade > 1 then
        --     -- Cast Felblade if under 130 Fury.
        --     return press("0", "felblade")

        -- elseif furyG40 > 1 then
        --     -- Cast Chaos Strike.
        --     return press("9", "chaos strike")

        -- elseif immolationaura > 0 then
        --     -- Cast Immolation Aura or ( Consuming Fire in Metamorphosis).
        --     return press("8", "immolation aura")

        -- else
        --     -- Cast Throw Glaive if no other buttons are available.
        --     return press("7", "throw glaive")
        -- end

    elseif action == ACTION_AOE then
        -- AOE

        if needsif > 0 then
            return press("9", "ironfur")

        elseif needsfr > 0 then
            return press("9", "frenzied regeneration")

        elseif ggending > 0 then
            -- Only use your Galactic Guardian procs if the buff is about to expire.
            return press("8", "moonfire")

        else
            -- Cast Swipe or Moonfire if you have empty GCDs.
            return press("7", "swipe")
        end
    end

    return nil
end

return nextAction
