-----------------------------------------------------------------------------------------
-- Havoc Demon Hunter

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("HDH", "993300", "DEMONHUNTER-1")

spec.buffs = {
    "Metamorphosis",
    "Essence Break",
}

spec.abilities = {
    "throwglaive",
    "immolationaura",
    "chaosstrike",
    "felblade",
    "bladedance",
    "eyebeam",
    "sigilofflame",
    "metamorphosis",
    "thehunt",
    "essencebreak",
}

local bits = Faceroll.createBits({
    "metamorphosisbuff",
    "essencebreakbuff",
    "metamorphosis",
    "essencebreak",
    "thehunt",
    "sigilofflame",
    "eyebeam",
    "bladedance",
    "felblade",
    "immolationaura",
    "furyG40",
    "furyL130",
    "furyL140",
})

spec.calcBits = function()
    bits:reset()

    if Faceroll.isBuffActive("Metamorphosis") then
        bits:enable("metamorphosisbuff")
    end
    if Faceroll.isBuffActive("Essence Break") then
        bits:enable("essencebreakbuff")
    end

    if Faceroll.isSpellAvailable("Metamorphosis") then
        bits:enable("metamorphosis")
    end
    if Faceroll.isSpellAvailable("Essence Break") then
        bits:enable("essencebreak")
    end
    if Faceroll.isSpellAvailable("The Hunt") then
        bits:enable("thehunt")
    end
    if Faceroll.isSpellAvailable("Sigil of Flame") then
        bits:enable("sigilofflame")
    end
    if Faceroll.isSpellAvailable("Eye Beam") then
        bits:enable("eyebeam")
    end
    if Faceroll.isSpellAvailable("Blade Dance") then
        bits:enable("bladedance")
    end
    if Faceroll.isSpellAvailable("Felblade") then
        bits:enable("felblade")
    end
    if Faceroll.isSpellAvailable("Immolation Aura") then
        bits:enable("immolationaura")
    end

    local fury = UnitPower("player")
    if fury >= 40 then
        bits:enable("furyG40")
    end
    if fury < 130 then
        bits:enable("furyL130")
    end
    if fury < 140 then
        bits:enable("furyL140")
    end

    return bits.value
end

spec.nextAction = function(action, rawBits)
    local state = bits:parse(rawBits)

    if action == Faceroll.ACTION_ST then
        -- Single Target

        if state.essencebreakbuff and state.bladedance then
            -- Cast Death Sweep during Essence Break.
            return "bladedance"

        elseif state.essencebreakbuff and state.furyG40 then
            -- Cast Annihilation during Essence Break.
            return "chaosstrike"

        elseif state.thehunt then
            -- Cast The Hunt.
            return "thehunt"

        elseif state.metamorphosisbuff and state.sigilofflame then
            -- Cast Sigil of Doom in Metamorphosis.
            return "sigilofflame"

        elseif state.metamorphosisbuff and state.essencebreak then
            -- Cast Essence Break while in Metamorphosis.
            return "essencebreak"

        elseif state.metamorphosisbuff and state.bladedance then
            -- Cast Death Sweep.
            return "bladedance"

        elseif state.metamorphosis and not state.eyebeam then
            -- Cast Metamorphosis if Eye Beam is on cooldown.
            return "metamorphosis"

        elseif state.sigilofflame then
            -- Cast Sigil of Flame before an Eye Beam, should always sync these up.
            return "sigilofflame"

        elseif state.eyebeam then
            -- Cast Eye Beam or (Abyssal Gaze in Metamorphosis).
            return "eyebeam"

        elseif state.bladedance then
            -- Cast Blade Dance.
            return "bladedance"

        elseif state.metamorphosis and state.furyG40 then
            -- Cast Annihilation.
            return "chaosstrike"

        elseif state.furyL130 and state.felblade then
            -- Cast Felblade if under 130 Fury.
            return "felblade"

        elseif state.furyG40 then
            -- Cast Chaos Strike.
            return "chaosstrike"

        elseif state.immolationaura then
            -- Cast Immolation Aura or ( Consuming Fire in Metamorphosis).
            return "immolationaura"

        else
            -- Cast Throw Glaive if no other buttons are available.
            return "throwglaive"
        end

    elseif action == Faceroll.ACTION_AOE then
        -- AOE


        if state.essencebreakbuff and state.bladedance then
            -- Cast Death Sweep during Essence Break.
            return "bladedance"

        elseif state.essencebreakbuff and state.furyG40 then
            -- Cast Annihilation during Essence Break.
            return "chaosstrike"

        elseif state.thehunt then
            -- Cast The Hunt.
            return "thehunt"

        elseif state.metamorphosisbuff and state.sigilofflame then
            -- Cast Sigil of Doom in Metamorphosis.
            return "sigilofflame"

        elseif state.metamorphosisbuff and state.essencebreak then
            -- Cast Essence Break while in Metamorphosis.
            return "essencebreak"

        elseif state.metamorphosisbuff and state.bladedance then
            -- Cast Death Sweep.
            return "bladedance"

        elseif state.metamorphosis and not state.eyebeam and not state.sigilofflame then
            -- Cast Metamorphosis if Eye Beam and Sigil of Flame are on cooldown.
            return "metamorphosis"

        elseif state.eyebeam then
            -- Cast Eye Beam or (Abyssal Gaze in Metamorphosis).
            return "eyebeam"

        elseif state.bladedance then
            -- Cast Blade Dance.
            return "bladedance"

        elseif state.sigilofflame and state.furyL140 then
            -- Cast Sigil of Flame if under 140 fury.
            return "sigilofflame"

        elseif state.metamorphosis and state.furyG40 then
            -- Cast Annihilation.
            return "chaosstrike"

        elseif state.furyL130 and state.felblade then
            -- Cast Felblade if under 130 Fury.
            return "felblade"

        elseif state.furyG40 then
            -- Cast Chaos Strike.
            return "chaosstrike"

        elseif state.immolationaura then
            -- Cast Immolation Aura or (Consuming Fire in Metamorphosis).
            return "immolationaura"

        else
            -- Cast Throw Glaive if no other buttons are available.
            return "throwglaive"
        end
    end

    return nil
end

Faceroll.registerSpec(spec)
