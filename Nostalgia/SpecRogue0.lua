-----------------------------------------------------------------------------------------
-- Nostalgia Classic Rogue (0)

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("ROG", "fff469", "ROGUE-CLASSIC")

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

["Attack"] = [[
/startAttack
]],

}

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
})

spec.calcState = function(state)
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    { "sinisterstrike", spell = "Sinister Strike" },
    { "eviscerate",     spell = "Eviscerate" },
}

spec.calcAction = function(mode, state)
    -- local st = (mode == Faceroll.MODE_ST)
    -- local aoe = (mode == Faceroll.MODE_AOE)

    if state.targetingenemy then
        if state.combopoints >= 5 and Faceroll.isActionAvailable("eviscerate") then
            return "eviscerate"

        else
            return "sinisterstrike"
        end

    end
end
