-----------------------------------------------------------------------------------------
-- Ascension WoW Bronzebeard Shadow Priest

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("SPVE", "dd88dd", "PRIEST-Void Eruption")

Faceroll.enemyGridTrack(spec, "Shadow Word: Pain", "SWP", "621518")
Faceroll.enemyGridTrack(spec, "Devouring Plague", "DP", "621562")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Buffs -",
    "innerfire",
    "darkfocus",

    "- Debuffs -",
    "pain",
    "devouringplague",
    "vampirictouch",

    "- Spells -",
    "mindblast",
    "vtdeadzone",
})

local vtDeadzone = Faceroll.deadzoneCreate("Vampiric Touch", 1.5, 0.5)

spec.calcState = function(state)
    -- Buffs
    if Faceroll.isBuffActive("Inner Fire") then
        state.innerfire = true
    end
    if Faceroll.isBuffActive("Dark Focus") then
        state.darkfocus = true
    end

    -- Debuffs
    if Faceroll.getDotRemainingNorm("Shadow Word: Pain") > 0.1 then
        state.pain = true
    end
    if Faceroll.getDotRemainingNorm("Devouring Plague") > 0.1 then
        state.devouringplague = true
    end
    if Faceroll.getDotRemainingNorm("Vampiric Touch") > 0.1 then
        state.vampirictouch = true
    end

    -- Spells
    if Faceroll.isSpellAvailable("Mind Blast") then
        state.mindblast = true
    end
    if Faceroll.deadzoneUpdate(vtDeadzone) then
        state.vtdeadzone = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "innerfire",
    "pain",
    "devouringplague",
    "mindblast",
    "mindflay",
    "mindsear",
    "vampirictouch",
}

spec.calcAction = function(mode, state)
    local aoe = (mode == Faceroll.MODE_AOE)

    if not state.innerfire then
        return "innerfire"

    elseif state.targetingenemy then
        if aoe then
            return "mindsear"

        elseif not state.pain then
            return "pain"

        elseif not state.vampirictouch and not state.vtdeadzone then
            return "vampirictouch"

        elseif not aoe and not state.devouringplague then
            return "devouringplague"

        elseif state.mindblast then
            return "mindblast"

        else
            return "mindflay"

        end
    end

    return nil
end
