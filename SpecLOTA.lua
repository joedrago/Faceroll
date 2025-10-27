-----------------------------------------------------------------------------------------
-- Ascension WoW Lava Sweep

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("LOTA", "ffaaff", "HERO-Legacy of the Arcanist")

spec.options = {
    "automd",
}

local NO_METEOR_FIRE   = 984394
local NO_METEOR_NATURE = 984268
local NO_METEOR_ARCANE = 984267
local NO_METEOR_FROST  = 984266

-----------------------------------------------------------------------------------------
-- States

spec.overlay = {
    "- options -",
    "automd",

    "- Combat -",
    "moonkinform",
    "targetingenemy",
    "combat",

    "- Abilities -",
    "sunfire",
    "earthshock",
    "fireblast",
    "arcaneorb",
    "barrage",
    "misdirection",

    -- "- Buffs -",
    -- "buffname",

    "- Dots -",
    "moonfiredot",
    "sunfiredot",
    "livingbombdot",

    "- Meteors -",
    "nofire",
    "nonature",
    "noarcane",
    "nofrost",
}

spec.calcState = function(state)
    -- Combat
    state.moonkinform = Faceroll.inShapeshiftForm("Moonkin Form")
    if Faceroll.targetingEnemy() then
        state.targetingenemy = true
    end
    if UnitAffectingCombat("player") then
        state.combat = true
    end

    -- Abilities
    if Faceroll.isSpellAvailable("Sunfire") then
        state.sunfire = true
    end
    if Faceroll.isSpellAvailable("Earth Shock") then
        state.earthshock = true
    end
    if Faceroll.isSpellAvailable("Fire Blast") then
        state.fireblast = true
    end
    if Faceroll.isSpellAvailable("Arcane Orb") then
        state.arcaneorb = true
    end
    if Faceroll.isSpellAvailable("Arcane Barrage") then
        state.barrage = true
    end
    if state.automd and Faceroll.isSpellAvailable("Misdirection") and UnitExists("focus") and not UnitIsDeadOrGhost("focus") then
        state.misdirection = true
    end

    -- Buffs
    -- if Faceroll.isBuffActive("Buff Name") then
    --     state.buffname = true
    -- end

    -- Dots
    if Faceroll.isDotActive("Moonfire") >= 0.1 then
        state.moonfiredot = true
    end
    if Faceroll.isDotActive("Sunfire") >= 0.1 then
        state.sunfiredot = true
    end
    if Faceroll.isDotActive("Living Bomb") >= 0.1 then
        state.livingbombdot = true
    end

    -- Meteors
    for auraIndex=1,40 do
        local name, rank, icon, stacks, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId = UnitAura("player", auraIndex, "HARMFUL")
        if name ~= nil then
            if     spellId == NO_METEOR_FIRE then
                state.nofire = true
            elseif spellId == NO_METEOR_NATURE then
                state.nonature = true
            elseif spellId == NO_METEOR_ARCANE then
                state.noarcane = true
            elseif spellId == NO_METEOR_FROST then
                state.nofrost = true
            end
        end
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "sunfire",
    "earthshock",
    "moonfire",
    "icelance",
    "fireblast",
    "barrage",
    "arcaneorb",
    "livingbomb",
    "moonkinform",
    "misdirection",
}

spec.calcAction = function(mode, state)
    local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)
    if st or aoe then
        if not state.moonkinform then
            return "moonkinform"
        end

        if state.misdirection then
            return "misdirection"
        end

        if state.targetingenemy then
            -- Meteor: Fire
            if not state.nofire then
                if state.sunfiredot then
                    if state.fireblast then
                        return "fireblast"
                    end
                    if state.sunfire then
                        return "sunfire"
                    end
                else
                    if state.sunfire then
                        return "sunfire"
                    end
                    if state.fireblast then
                        return "fireblast"
                    end
                end
            end

            -- Meteor: Nature
            if not state.nonature and state.earthshock then
                return "earthshock"
            end

            -- Meteor: Arcane
            if not state.noarcane then
                if state.moonfiredot and state.barrage then
                    return "barrage"
                end
                return "moonfire"
            end

            -- Meteor: Frost
            if not state.nofrost then
                return "icelance"
            end

            -- Stuff less important than meteors
            if state.arcaneorb then
                return "arcaneorb"
            end
            if not state.livingbombdot then
                return "livingbomb"
            end

            -- Burn meteor-sending spells if we have a "backup" sender
            if state.barrage then
                return "barrage" -- we'll just moonfire
            end
            if state.sunfire and state.fireblast then
                return "fireblast" -- we'll just sunfire
            end
            return "icelance" -- no CD on icelance, why not
        end
    end
    return nil
end
