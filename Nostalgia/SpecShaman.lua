-----------------------------------------------------------------------------------------
-- Classic Shaman

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("SHAM", "333399", "SHAMAN-1")
Faceroll.aliasSpec(spec, "SHAMAN-CLASSIC")

-----------------------------------------------------------------------------------------
-- Enemy Grid

-- Faceroll.enemyGridTrack(spec, "Rake", "RAKE", "621518")

-----------------------------------------------------------------------------------------
-- Macros (/frm)

spec.macros = {

-- ["OBear"] = [[
-- /fro bear
-- ]],

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
    { "lightningbolt", spell = "Lightning Bolt" },
}

spec.calcAction = function(mode, state)
    return "lightningbolt"
end
