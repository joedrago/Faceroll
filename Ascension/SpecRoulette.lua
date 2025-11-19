-----------------------------------------------------------------------------------------
-- Ascension WoW Roulette Auto Shot

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("ROU", "aaffaa", "HERO-Harbinger of Flame")
Faceroll.aliasSpec(spec, "HERO-Deathbringer")

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Combat -",
    "autoshot",
})

spec.calcState = function(state)
    if IsCurrentSpell(75) then -- autoshot
        state.autoshot = true
    end
    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "attack",
    "sic",
}

spec.calcAction = function(mode, state)
    if state.targetingenemy then
        if not state.combat then
            return "sic"
        elseif not state.autoshot then
            return "attack"
        end
    end
    return nil
end

-----------------------------------------------------------------------------------------
-- make roulette warnings calm down

-- local f = CreateFrame("Frame")

-- local function matchesForbiddenMessage(text)
--     if not text then return false end
--     text = text:lower()

--     return text:find("is now forbidden")
--         or text:find("is now deadly")
--         or text:find("is now perilous")
--         or text:find("is now lethal")
--         or text:find("is now a forbidden incantation")
--         or text:find("is now a spell of certain demise")
--         or text:find("is now ensnared by the curse")
--         or text:find("avoid casting")
--         or text:find("a dire warning")
--         or text:find("the curse has moved")
--         or text:find("the curse has found a new host")
--         or text:find("heed the warning")
--         or text:find("heed this omen")
--         or text:find("winds of fate")
--         or text:find("roulette has spun")
--         or text:find("a new spell is bound by the roulette")
--         or text:find("the forbidden seal has shifted")
--         or text:find("fatal gamble")
--         or text:find("next victim")
-- end

-- f:SetScript("OnUpdate", function()
--     local numChildren = select("#", UIParent:GetChildren())
--     for i = 1, numChildren do
--         local child = select(i, UIParent:GetChildren())

--         if type(child) == "table" and child:IsShown() and child.GetRegions then
--             local regions = { child:GetRegions() }

--             for _, region in ipairs(regions) do
--                 if type(region) == "table" and region.GetText then
--                     local text = region:GetText()
--                     if matchesForbiddenMessage(text) then
--                         child:Hide()
--                         break
--                     end
--                 end
--             end
--         end
--     end
-- end)

-- local original_PlaySound = PlaySound
-- PlaySound = function(id, ...)
--     local strId = tostring(id)
--     if strId:lower():find("raidbossemotewarning") then
--         -- Bloque ce son
--         return
--     end
--     return original_PlaySound(id, ...)
-- end
