-----------------------------------------------------------------------------------------
-- Havoc Demon Hunter

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("HDH", "993300", "DEMONHUNTER-1")

spec.buffs = {
    "Metamorphosis",
    "Immolation Aura",
}

-----------------------------------------------------------------------------------------
-- States

spec.states = {
    "- Buffs -",
    "metamorphosisbuff",
    "immolationaurabuff",

    "- Spells -",
    "metamorphosis",
    "thehunt",
    "sigilofflame",
    "eyebeam",
    "eyebeamsoon",
    "bladedance",
    "felblade",
    "immocharges2",
    "immocharges1",

    "- Resources -",
    "furyG35",
    "furyG40",
    "furyL80",

    "- State -",
    "hold",
}

spec.calcState = function(state)
    if Faceroll.isBuffActive("Metamorphosis") then
        state.metamorphosisbuff = true
    end
    if Faceroll.isBuffActive("Immolation Aura") then
        state.immolationaurabuff = true
    end

    if Faceroll.isSpellAvailable("Metamorphosis") then
        state.metamorphosis = true
    end
    if Faceroll.isSpellAvailable("The Hunt") then
        state.thehunt = true
    end
    if Faceroll.isSpellAvailable("Sigil of Flame") then
        state.sigilofflame = true
    end
    if Faceroll.isSpellAvailable("Eye Beam", true) then
        state.eyebeam = true
    end
    if Faceroll.spellCooldown("Eye Beam") <= 3 then
        state.eyebeamsoon = true
    end
    if Faceroll.isSpellAvailable("Blade Dance") then
        state.bladedance = true
    end
    if Faceroll.isSpellAvailable("Felblade") then
        state.felblade = true
    end

    local immoCharges = Faceroll.spellCharges("Immolation Aura")
    if immoCharges >= 2 then
        state.immocharges2 = true
    end
    if immoCharges >= 1 then
        state.immocharges1 = true
    end

    local fury = UnitPower("player")
    if fury >= 35 then
        state.furyG35 = true
    end
    if fury >= 40 then
        state.furyG40 = true
    end
    if fury < 80 then
        state.furyL80 = true
    end
    if Faceroll.hold then
        state.hold = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "throwglaive",
    "immolationaura",
    "chaosstrike",
    "felblade",
    "bladedance",
    "eyebeam",
    "sigilofflame",
    "metamorphosis",
    "thehunt",
}

spec.calcAction = function(mode, state)
    if mode == Faceroll.MODE_ST then
        -- Single Target

        if state.immocharges2 then
            -- Cast Immolation Aura or ( Consuming Fire in Metamorphosis) if
            -- capped at 2 charges.
            return "immolationaura"

        elseif state.immocharges1 and not state.immolationaurabuff and state.eyebeamsoon then
            -- Cast Immolation Aura or ( Consuming Fire in Metamorphosis) if you
            -- do not currently have it active and Eye Beam is coming up within
            -- 3 seconds.
            return "immolationaura"

        elseif state.metamorphosisbuff and state.bladedance and state.furyG35 then
            -- Cast Death Sweep.
            return "bladedance"

        elseif not state.hold and state.thehunt then
            -- Cast The Hunt.
            return "thehunt"

        elseif not state.hold and state.metamorphosis and not state.eyebeam then
            -- Cast Metamorphosis if Eye Beam is on cooldown.
            return "metamorphosis"

        elseif not state.hold and state.eyebeam then
            -- Cast Eye Beam (or Abyssal Gaze in Metamorphosis).
            return "eyebeam"

        elseif state.bladedance and state.furyG35 then
            -- Cast Blade Dance.
            return "bladedance"

        elseif state.furyG40 then
            -- Cast Annihilation.
            return "chaosstrike"

        elseif state.felblade and state.furyL80 then
            -- Cast Felblade if under 80 Fury.
            return "felblade"

        elseif state.furyG40 then
            -- Cast Chaos Strike.
            return "chaosstrike"

        elseif state.immocharges1 then
            -- Cast Immolation Aura or ( Consuming Fire in Metamorphosis).
            return "immolationaura"

        elseif state.sigilofflame then
            -- Cast Sigil of Flame (or Sigil of Doom in Metamorphosis) if under
            -- 40 Fury.
            return "sigilofflame"

        else
            -- Cast Throw Glaive or Fel Rush if no other abilities are
            -- available.
            return "throwglaive"

        end

    elseif mode == Faceroll.MODE_AOE then
        -- AOE

        if state.metamorphosisbuff and state.bladedance and state.furyG35 then
            -- Cast Death Sweep.
            return "bladedance"

        elseif state.immocharges1 then
            -- Cast Immolation Aura or ( Consuming Fire in Metamorphosis).
            return "immolationaura"

        elseif not state.hold and state.thehunt then
            -- Cast The Hunt.
            return "thehunt"

        elseif not state.hold and state.metamorphosis and not state.eyebeam then
            -- Cast Metamorphosis if Eye Beam is on cooldown.
            return "metamorphosis"

        elseif state.bladedance and state.furyG35 then
            -- Cast Blade Dance.
            return "bladedance"

        elseif not state.hold and state.eyebeam then
            -- Cast Eye Beam (or Abyssal Gaze in Metamorphosis).
            return "eyebeam"

        elseif state.sigilofflame then
            -- Cast Sigil of Flame (or Sigil of Doom in Metamorphosis).
            return "sigilofflame"

        elseif state.furyG40 then
            -- Cast Annihilation.
            return "chaosstrike"

        elseif state.felblade then
            -- Cast Felblade.
            return "felblade"

        else
            -- Cast Throw Glaive or Fel Rush if no other abilities are
            -- available.
            return "throwglaive"

        end

    end

    return nil
end
