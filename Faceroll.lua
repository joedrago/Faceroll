if Faceroll == nil then
    _, Faceroll = ...
end

local eventFrame = nil

-----------------------------------------------------------------------------------------
-- Faceroll Globals

Faceroll.keys = {}
Faceroll.options = {}
Faceroll.classic = false
Faceroll.ascension = false
if WOW_PROJECT_ID == nil then
    Faceroll.classic = true
    if MysticEnchantUtil ~= nil then
        Faceroll.ascension = true
    end
elseif WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    Faceroll.classic = true
end
Faceroll.leftCombat = 0
Faceroll.moving = false
Faceroll.movingStopped = 0
Faceroll.updateBitsCounter = 0
Faceroll.targetChanged = false
Faceroll.active = false
Faceroll.kickedRadios = false
Faceroll.combatJustEnded = false

local nextSpec = 0
Faceroll.availableSpecs = {}
Faceroll.activeSpecs = {}
Faceroll.specAliases = {}

-----------------------------------------------------------------------------------------
-- Helpers

Faceroll.textColor = function(text, color)
    return "\124cff" .. color .. text .. "\124r"
end

Faceroll.isSeparatorName = function(name)
    return (string.find(name, "^[- ]") ~= nil)
end

Faceroll.pad = function(text, count)
    text = tostring(text)
    while strlenutf8(text) < count do
        text = " " .. text
    end
    return text
end

-----------------------------------------------------------------------------------------
-- Spec Management

Faceroll.createSpec = function(name, color, specKey)
    local spec = {
        ["name"]=name,
        ["color"]=color,
        ["key"]=specKey,
        ["calcState"]=nil,
        ["calcAction"]=nil,
        ["melee"]=nil,
        ["buffs"]=nil,
        ["overlay"]={},
        ["actions"]={},
        ["options"]={},
        ["enemyGrid"]=nil,
        ["keys"]={},
        ["index"]=nil,
        ["keepRanks"]=nil,
    }
    table.insert(Faceroll.availableSpecs, spec)
    return spec
end

Faceroll.createSpec("OFF", "333333", "OFF")

Faceroll.aliasSpec = function(spec, key)
    Faceroll.specAliases[key] = spec
end

Faceroll.createState = function(spec, specKey)
    local state = {}
    state.key = specKey
    for _, rawName in ipairs(spec.options) do
        local name, radio = strsplit("|", rawName)
        if Faceroll.options[name] ~= nil then
            state[name] = true
        end
    end

    -- Add in standard state for each wow version
    if Faceroll.ascension or Faceroll.classic then
        -- Combat
        state.level = UnitLevel("player")
        if Faceroll.targetingEnemy() then
            state.targetingenemy = true
        end
        local targetCastingSpell = UnitCastingInfo("target")
        if targetCastingSpell then
            state.targetcasting = true
        end
        if Faceroll.inCombat() then
            state.combat = true
        end
        if IsInGroup() then
            state.group = true
        end
        if IsCurrentSpell(6603) then -- Autoattack
            state.autoattack = true
        end
        if spec.melee == nil then
            if IsItemInRange(37727) == 1 then -- Ruby Acorn
                state.melee = true
            end
        else
            if IsSpellInRange(spec.melee, "target") == 1 then
                state.melee = true
            end
        end

        -- Resources
        local curHP = UnitHealth("player")
        local maxHP = UnitHealthMax("player")
        state.hp = maxHP > 0 and curHP / maxHP or 0
        local curMana = UnitPower("player", 0)
        local maxMana = UnitPowerMax("player", 0)
        state.mana = maxMana > 0 and curMana / maxMana or 0
        state.rage = UnitPower("PLAYER", 1)
        state.energy = UnitPower("PLAYER", 3)
        state.runicpower = UnitPower("PLAYER", 6)
        state.combopoints = GetComboPoints("PLAYER", "TARGET")

        -- Auto-state from overlay table entries
        if spec.overlay then
            for _, entry in ipairs(spec.overlay) do
                if type(entry) == "table" then
                    local k = entry[1]
                    local v = entry[2]
                    local prefix = string.sub(k, 1, 2)
                    if prefix == "s_" then
                        if Faceroll.isSpellAvailable(v) then
                            state[k] = true
                        end
                    elseif prefix == "b_" then
                        if Faceroll.isBuffActive(v) then
                            state[k] = true
                        end
                    elseif prefix == "d_" then
                        if Faceroll.getDotRemainingNorm(v) > 0.1 then
                            state[k] = true
                        end
                    elseif prefix == "f_" then
                        if GetShapeshiftForm() == v then
                            state[k] = true
                        end
                    end
                end
            end
        end

        -- Auto-state from action deadzone declarations.
        -- `deadzone = true` uses defaults; `{th, dur}` overrides; `spell="..."` overrides the spell name.
        if spec.actions then
            for _, entry in ipairs(spec.actions) do
                if type(entry) == "table" and entry.deadzone then
                    local dz = entry._dz
                    if dz == nil then
                        local d = entry.deadzone
                        local spellName, castThreshold, duration
                        if d == true then
                            spellName = entry.spell
                            castThreshold = 1.5
                            duration = 0.5
                        else
                            spellName = d.spell or entry.spell
                            castThreshold = d[1] or 1.5
                            duration = d[2] or 0.5
                        end
                        dz = Faceroll.deadzoneCreate(spellName, castThreshold, duration)
                        entry._dz = dz
                    end
                    if Faceroll.deadzoneUpdate(dz) then
                        state["z_" .. entry[1]] = true
                    end
                end
            end
        end
    end

    return state
end

Faceroll.createOverlay = function(extras)
    local overlay = {}

    -- Add in standard state for each wow version
    if Faceroll.ascension or Faceroll.classic then
        overlay = {
            "- Combat -",
            "targetingenemy",
            "targetcasting",
            "combat",
            "group",
            "autoattack",
            "autoshot",
            "melee",

            "- Resources -",
            "level",
            "hp", -- normalized
            "mana", -- normalized
            "rage",
            "energy",
            "combopoints",
        }
    end

    for _,extra in ipairs(extras) do
        table.insert(overlay, extra)
    end
    return overlay
end

-----------------------------------------------------------------------------------------
-- Key-to-slot resolution (used by startup, /frb, /frbc)
-- Supports vanilla action bars (ACTIONBUTTON7) and Bartender4 (CLICK BT4Button109:LeftButton)

local function facerollKeyToBlizzKey(frKey)
    local upper = string.upper(frKey)
    upper = string.gsub(upper, "^PAD", "NUMPAD")
    return upper
end

local vanillaSlots = {
    ACTIONBUTTON = 0,
    BONUSACTIONBUTTON = 0,
    MULTIACTIONBAR1BUTTON = 60,
    MULTIACTIONBAR2BUTTON = 48,
    MULTIACTIONBAR3BUTTON = 36,
    MULTIACTIONBAR4BUTTON = 24,
}

local function bindingToSlot(binding)
    local bt4num = string.match(binding, "^CLICK BT4Button(%d+):")
    if bt4num then return tonumber(bt4num) end
    for prefix, offset in pairs(vanillaSlots) do
        local num = string.match(binding, "^" .. prefix .. "(%d+)$")
        if num then return offset + tonumber(num) end
    end
    return nil
end

local function buildKeyToSlotMap(spec)
    local keyToSlot = {}
    local keysToCheck = {}
    for index, entry in ipairs(spec.actions) do
        local action = type(entry) == "table" and entry[1] or entry
        local key = spec.keys[action]
        if key then keysToCheck[key] = true end
    end
    for key, _ in pairs(keysToCheck) do
        local blizzKey = facerollKeyToBlizzKey(key)
        local binding = GetBindingAction(blizzKey)
        if binding and binding ~= "" then
            local slot = bindingToSlot(binding)
            if slot then
                keyToSlot[key] = slot
            end
        end
    end
    return keyToSlot
end

-----------------------------------------------------------------------------------------

Faceroll.startup = function()
    for _, spec in ipairs(Faceroll.availableSpecs) do
        if Faceroll.activeSpecs[spec.key] ~= nil then
            print("WARNING: Multiple specs for the same key active! Overriding preexisting spec key: " .. spec.key)
        end
        Faceroll.activeSpecs[spec.key] = spec
        -- print("Enabling Spec: " .. spec.name .. " (" .. Faceroll.SPEC_LAST .. "), ".. bitCount .. "/28 bits, " .. actionCount .. " actions")
    end
    for key, spec in pairs(Faceroll.specAliases) do
        if Faceroll.activeSpecs[key] ~= nil then
            print("WARNING: Multiple specs for the same key active! Overriding preexisting spec key: " .. key)
        end
        Faceroll.activeSpecs[key] = spec
        -- print("Enabling Spec: " .. spec.name .. " (" .. Faceroll.SPEC_LAST .. "), ".. bitCount .. "/28 bits, " .. actionCount .. " actions")
    end

    for _, spec in ipairs(Faceroll.availableSpecs) do
        if spec.actions ~= nil then
            for index, entry in ipairs(spec.actions) do
                local action = type(entry) == "table" and entry[1] or entry
                local key = Faceroll.keys[action]
                if key == nil then
                    key = Faceroll.keys[index]
                end
                if key ~= nil then
                    -- print("["..spec.name.."] " .. action .. " -> " .. key)
                    spec.keys[action] = key
                else
                    -- print("["..spec.name.."] " .. action .. " -> UNMAPPED")
                end
            end

        end
    end

    -- Auto-append deadzone state names to each spec's overlay, prefixed by a separator
    for _, spec in ipairs(Faceroll.availableSpecs) do
        if spec.actions and spec.overlay then
            local appended = false
            for _, entry in ipairs(spec.actions) do
                if type(entry) == "table" and entry.deadzone then
                    if not appended then
                        table.insert(spec.overlay, "- Deadzones -")
                        appended = true
                    end
                    table.insert(spec.overlay, "z_" .. entry[1])
                end
            end
        end
    end

    print("Faceroll.startup(): " .. #Faceroll.availableSpecs .. " available specs.")
end

Faceroll.isActionAvailable = function(action)
    local spec = Faceroll.activeSpec()
    if spec and spec.actionAvailable then
        return spec.actionAvailable[action] == true
    end
    return false
end

Faceroll.activeSpec = function()
    local _, playerClass = UnitClass("player")
    local specIndex = "CLASSIC"
    if Faceroll.ascension then
        specIndex = "ASCENSION"
        local mysticLego = MysticEnchantUtil.GetLegendaryEnchantID("player")
        if mysticLego ~= nil then
            local mysticLegoName = GetSpellInfo(mysticLego)
            if mysticLegoName ~= nil then
                specIndex = mysticLegoName
            end
        end
    elseif Faceroll.classic then
        local _, _, pointsTree1 = GetTalentTabInfo(1)
        local _, _, pointsTree2 = GetTalentTabInfo(2)
        local _, _, pointsTree3 = GetTalentTabInfo(3)
        if (pointsTree1 > pointsTree2) and (pointsTree1 > pointsTree3) then
            specIndex = "1"
        elseif (pointsTree2 > pointsTree1) and (pointsTree2 > pointsTree3) then
            specIndex = "2"
        elseif (pointsTree3 > pointsTree1) and (pointsTree3 > pointsTree2) then
            specIndex = "3"
        end
    else
        if GetSpecialization ~= nil then
            specIndex = GetSpecialization()
        end
    end
    if playerClass == nil or specIndex == nil then
        return nil
    end
    local specKey = playerClass .. "-" .. specIndex
    local spec = Faceroll.activeSpecs[specKey]
    return spec, specKey
end

-----------------------------------------------------------------------------------------
-- Generic "Frame" Creation (UI Elements)

local FONTS = {
    ["firamono"]="Interface\\AddOns\\Faceroll\\fonts\\FiraMono-Medium.ttf",
    ["forcedsquare"]="Interface\\AddOns\\Faceroll\\fonts\\FORCED SQUARE.ttf",
}

Faceroll.createFrame = function(
    width, height,
    corner, x, y,
    strata, alpha,
    justify, font, fontSize)

    local frFrame = {}

    local frame = CreateFrame("Frame")
    frame:SetPoint(corner, x, y)
    frame:SetWidth(width)
    frame:SetHeight(height)
    frame:SetFrameStrata(strata)
    local text = frame:CreateFontString(nil, "ARTWORK")
    text:SetFont(FONTS[font], fontSize, "OUTLINE")
    text:SetPoint(justify, 0,0)
    if justify == "TOPLEFT" then
        text:SetJustifyH("LEFT")
        text:SetJustifyV("TOP")
    end
    frame.texture = frame:CreateTexture()
    frame.texture:SetTexture("Interface/BUTTONS/WHITE8X8")
    frame.texture:SetVertexColor(0.0, 0.0, 0.0, alpha)
    frame.texture:SetAllPoints(text)
    text:Show()
    frame:Show()

    frFrame.frame = frame
    frFrame.text = text
    frFrame.setText = function(self, text)
        self.text:SetText(text)
    end
    return frFrame
end

-----------------------------------------------------------------------------------------
-- Debug Overlay Shenanigans

Faceroll.DEBUG_OFF = 0
Faceroll.DEBUG_ON = 1
Faceroll.DEBUG_MINIMAL = 2
Faceroll.DEBUG_LAST = 2

Faceroll.debug = Faceroll.DEBUG_OFF
Faceroll.debugOverlay = nil
Faceroll.debugState = ""
Faceroll.debugLines = {}
Faceroll.debugUpdateText = ""
Faceroll.debugLastUpdateBitsCounter = 0
Faceroll.debugLastUpdateBitsTime = 0

Faceroll.debugLastUpdateEventsEnabled = false
Faceroll.debugLastUpdateWho = {}

Faceroll.updateDebugOverlay = function()
    if Faceroll.debugOverlay == nil then
        return
    end

    if Faceroll.debug ~= Faceroll.DEBUG_OFF then
        local o = "\124cff444444      - Faceroll -      \124r\n\n"

        local updatesSince = Faceroll.updateBitsCounter - Faceroll.debugLastUpdateBitsCounter
        local now = GetTime()
        if Faceroll.debugLastUpdateBitsTime == 0 then
            Faceroll.debugLastUpdateBitsTime = now
        end
        local updateTimeDelta = now - Faceroll.debugLastUpdateBitsTime
        if updateTimeDelta > 1 then
            local updatesPerSec = updatesSince / updateTimeDelta
            Faceroll.debugUpdateText = string.format("Updates/sec: %.2f\n", updatesPerSec)
            Faceroll.debugLastUpdateBitsTime = now
            Faceroll.debugLastUpdateBitsCounter = Faceroll.updateBitsCounter

            if Faceroll.debugLastUpdateEventsEnabled then
                local REALLY_BAD = 50
                if updatesPerSec > REALLY_BAD then
                    print("---")
                end

                for who,count in pairs(Faceroll.debugLastUpdateWho) do
                    Faceroll.debugUpdateText = Faceroll.debugUpdateText .. who .. ": " .. count .. "\n"
                    if updatesPerSec > REALLY_BAD then
                        print("BAD: " .. who .. ": " .. count .. "\n")
                    end
                end
                Faceroll.debugLastUpdateWho = {}
            end
        end

        if Faceroll.debug == Faceroll.DEBUG_MINIMAL then
            o = o .. Faceroll.debugState .. "\n"
        else
            local debugLines = ""
            for _,line in ipairs(Faceroll.debugLines) do
                debugLines = debugLines .. line .. "\n"
            end
            o = o .. Faceroll.debugState .. "\n" .. debugLines .. Faceroll.debugUpdateText
        end

        Faceroll.debugOverlay:setText(o)
        Faceroll.debugOverlay.frame:Show()
    else
        Faceroll.debugOverlay.frame:Hide()
    end
end

Faceroll.clearDebugLines = function()
    Faceroll.debugLines = {}
end

Faceroll.addDebugLine = function(line)
    table.insert(Faceroll.debugLines, line)
end

Faceroll.prettyFloat = function(f)
    local s = string.format("%.3f", f)
    s = s:gsub("0+$", "")
    s = s:gsub("%.$", "")
    return s
end

Faceroll.setDebugState = function(spec, state)
    if Faceroll.debug == Faceroll.DEBUG_OFF then
        return
    end

    local function bt(b)
        if b then
            return "\124cffffff00T\124r"
        end
        return "\124cff777777F\124r"
    end

    local o = ""

    if Faceroll.debug ~= Faceroll.DEBUG_MINIMAL then
        for _,entry in ipairs(spec.overlay) do
            local k = type(entry) == "table" and entry[1] or entry
            local v = state[k]
            if Faceroll.isSeparatorName(k) then
                if strlenutf8(o) > 0 then
                    o = o .. "\n"
                end
                o = o .. "\124cffffffaa" .. Faceroll.pad(k, 18) .. "\124r\n"
            elseif type(v) == "number" then
                o = o .. Faceroll.pad(k, 18) .. "  : " .. Faceroll.textColor(Faceroll.prettyFloat(v), "ffffaa") .. "\n"
            elseif type(v) == "string" then
                o = o .. Faceroll.pad(k, 18) .. "  : " .. Faceroll.textColor(v, "ffaaff") .. "\n"
            else
                o = o .. Faceroll.pad(k, 18) .. "  : " .. bt(v) .. "\n"
            end
        end
        o = o .. "\n"
    end

    if spec.calcAction then
        o = o .. "\124cffffaaff - Next -\124r\n"

        local actionST = spec.calcAction(Faceroll.MODE_ST, state)
        if actionST == nil then
            actionST = "--"
        end
        o = o .. "\124cffffaaff * ST \124r" .. "  : \124cffaaffaa" .. actionST .. "\124r\n"

        local actionAOE = spec.calcAction(Faceroll.MODE_AOE, state)
        if actionAOE == nil then
            actionAOE = "--"
        end
        o = o .. "\124cffffaaff * AOE\124r" .. "  : \124cffaaffaa" .. actionAOE .. "\124r\n"
    end

    Faceroll.debugState = o
    Faceroll.updateDebugOverlay()
end


Faceroll.debugInit = function()
    Faceroll.debugOverlay = Faceroll.createFrame(200, 220,                  -- size
                                                    "TOPLEFT", 0, 0,           -- position
                                                    "TOOLTIP", 0.7,            -- strata/alpha
                                                    "TOPLEFT", "firamono", 13) -- text
    Faceroll.updateDebugOverlay()
end

-----------------------------------------------------------------------------------------
-- EnemyGrid

Faceroll.enemyGridOverlay = nil

Faceroll.enemyGridInit = function()
    Faceroll.enemyGridOverlay = Faceroll.createFrame(400, 220,                 -- size
                                                    "RIGHT", 0, 0,           -- position
                                                    "MEDIUM", 0.7,            -- strata/alpha
                                                    "TOPLEFT", "firamono", 13) -- text
    Faceroll.enemyGridUpdate()
end

Faceroll.enemyGridTrack = function(spec, spellName, shortName, color)
    if spec.enemyGrid == nil then
        spec.enemyGrid = {}
    end
    local e = {}
    e.spellName = spellName
    e.shortName = shortName
    e.color = color
    table.insert(spec.enemyGrid, e)
end

Faceroll.enemyGridUpdate = function()
    local kui = _G.KuiNameplates
    local spec = Faceroll.activeSpec()
    if (Faceroll.enemyGridOverlay == nil) or (spec == nil) or (spec.enemyGrid == nil) or (kui == nil) or not Faceroll.inCombat() then
        Faceroll.enemyGridOverlay.frame:Hide()
        return
    end

    local spellLookup = {}
    for i, e in ipairs(spec.enemyGrid) do
        spellLookup[e.spellName] = 0
    end

    -- find tracked spell IDs based on what is on the bars
    for i = 1,120 do
        local actionType, _, subType, id = GetActionInfo(i)
        if id ~= nil then
            local infoName = GetSpellInfo(id)
            if infoName ~= nil and spellLookup[infoName] ~= nil then
                spellLookup[infoName] = id
            end
        end
    end

    -- build a table of "wanted" spell IDs
    local wantedIDs = {}
    for k,v in pairs(spellLookup) do
        if v ~= 0 then
            wantedIDs[v] = k
        end
    end

    -- Figure out who is targeted, if anyone
    local targetGUID = UnitGUID("target")
    if targetGUID == nil then
        targetGUID = "NOBODY_TARGETED" -- sentinel
    end

    -- Make a list of mobs we can see along with the expirations of our wanted IDs
    local mobs = {}
    for frameIndex, frame in pairs(kui.frameList) do
        if frame:IsVisible() then
            local fguid = frame.kui.guid
            if fguid == nil then
                fguid = "--"
            end

            local mob = {}
            mob.name = frame.kui.oldName:GetText()
            mob.target = (fguid == targetGUID)
            mob.total = 0
            mob.expirations = {}
            for k,id in pairs(spellLookup) do
                mob.expirations[id] = 0
            end
            for id,aura in pairs(frame.kui.auras.spellids) do
                if mob.expirations[id] ~= nil and aura.expirationTime ~= nil then
                    mob.expirations[id] = aura.expirationTime - GetTime()
                    mob.total = mob.total + mob.expirations[id]
                end
            end
            table.insert(mobs, mob)
        end
    end

    -- Sort mobs
    table.sort(mobs, function(a, b)
            local lowestA = 999
            local lowestB = 999
            for _,wantedID in ipairs(wantedIDs) do
                if lowestA > a.expirations[wantedID] then
                    lowestA = a.expirations[wantedID]
                end
                if lowestB > b.expirations[wantedID] then
                    lowestB = b.expirations[wantedID]
                end
            end
            if lowestA ~= lowestB then
                return lowestA < lowestB
            end
            if a.total ~= b.total then
                return a.total < b.total
            end
            return a.name < b.name
    end)

    local function durationToColor(duration)
        local expColor = "ff5555"
        if duration < 4 then
            expColor = "ffff00"
        elseif duration < 7 then
            expColor = "999977"
        else
            expColor = "777777"
        end
        return expColor
    end

    -- header
    local o = ""
    -- o = o .. "" .. GetTime() .. "\n"
    for i, e in ipairs(spec.enemyGrid) do
        o = o .. Faceroll.textColor(Faceroll.pad(e.shortName, 6), e.color)
    end
    -- TODO: single here
    o = o .. "\n"

    for _, mob in ipairs(mobs) do
        local expirations = mob.expirations
        for i, e in ipairs(spec.enemyGrid) do
            local wantedColor = e.color
            local expStr = "    XX"
            local expColor = "ff5555"
            local exp = expirations[spellLookup[e.spellName]]
            if exp ~= nil and exp > 0 then
                expStr = string.format("%6.1f", exp)
                expColor = durationToColor(exp)
            end
            o = o .. Faceroll.textColor(expStr, expColor)
        end

        local color = "777777"
        if mob.target then
            color = "77dd77"
        end
        o = o .. " " .. Faceroll.textColor(string.sub(mob.name, 0, 8), color)

        o = o .. "\n"
    end

    Faceroll.enemyGridOverlay:setText(o)
    Faceroll.enemyGridOverlay.frame:Show()
end

-----------------------------------------------------------------------------------------
-- Missing-buff reminder stripe
--
-- spec.buffs is an optional list of "tracks". Each track is either a bare spell name
-- or a list of spell names (a cascade — first one the player has learned wins).
-- Any candidate string may use "A|B" to declare synonyms — buffs that count as the
-- same thing (e.g. "Arcane Intellect|Arcane Brilliance"). The first synonym supplies
-- the icon; any of them being active satisfies the track.
-- For each track whose winner is learned but whose buff is missing, an icon is shown
-- on the right edge, stacking upward from the configured anchor. Active buffs leave
-- the stack and the remaining icons reflow downward.

Faceroll.buffsFrames = {}

local function buffsSplitSynonyms(candidate)
    local synonyms = {}
    for name in string.gmatch(candidate, "[^|]+") do
        table.insert(synonyms, name)
    end
    return synonyms
end

local function buffsResolveTrack(entry)
    local candidates = (type(entry) == "string") and { entry } or entry
    for _, candidate in ipairs(candidates) do
        local synonyms = buffsSplitSynonyms(candidate)
        for _, name in ipairs(synonyms) do
            if Faceroll.isSpellLearned(name) then
                return synonyms
            end
        end
    end
    return nil
end

local function buffsGetIconFrame(index)
    local frame = Faceroll.buffsFrames[index]
    if frame ~= nil then
        return frame
    end

    local size = Faceroll.buffsFrameIconSize or 64
    local spacing = Faceroll.buffsFrameSpacing or 4
    local anchor = Faceroll.buffsFrameAnchor or "BOTTOMRIGHT"
    local x = Faceroll.buffsFrameX or 0
    local y = Faceroll.buffsFrameY or 0

    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetWidth(size)
    frame:SetHeight(size)
    frame:SetFrameStrata("MEDIUM")
    frame:SetPoint(anchor, UIParent, anchor, x, y + (index - 1) * (size + spacing))

    frame.texture = frame:CreateTexture(nil, "ARTWORK")
    frame.texture:SetAllPoints(frame)

    frame:Hide()
    Faceroll.buffsFrames[index] = frame
    return frame
end

Faceroll.buffsInit = function()
    -- Frames are created lazily on demand in buffsUpdate. Nothing to do up front.
end

Faceroll.buffsUpdate = function()
    local spec = Faceroll.activeSpec()
    if spec == nil or spec.buffs == nil then
        for _, frame in pairs(Faceroll.buffsFrames) do
            frame:Hide()
        end
        return
    end

    local missing = {}
    for _, entry in ipairs(spec.buffs) do
        local synonyms = buffsResolveTrack(entry)
        if synonyms ~= nil then
            local active = false
            for _, name in ipairs(synonyms) do
                if Faceroll.isBuffActive(name) then
                    active = true
                    break
                end
            end
            if not active then
                table.insert(missing, synonyms[1])
            end
        end
    end

    for i, spellName in ipairs(missing) do
        local frame = buffsGetIconFrame(i)
        frame.texture:SetTexture(GetSpellTexture(spellName))
        frame:Show()
    end
    for i, frame in pairs(Faceroll.buffsFrames) do
        if i > #missing then
            frame:Hide()
        end
    end
end

-----------------------------------------------------------------------------------------
-- Shims for builtin functions that maybe don't exist in some versions

local builtinGSC = nil
if C_Spell ~= nil then
    builtinGSC = C_Spell.GetSpellCooldown
end
if builtinGSC == nil then
    builtinGSC = function(spellName)
        local startTime, duration = GetSpellCooldown(spellName)
        return { ["duration"]=duration, ["startTime"]=startTime, }
    end
end

local builtinISU = nil
if C_Spell ~= nil then
    builtinISU = C_Spell.IsSpellUsable
end
if builtinISU == nil then
    builtinISU = function(spellName)
        local isuResult = IsUsableSpell(spellName)
        if isuResult == 1 then
            return true
        end
        return false
    end
end

local builtinGSCharges = nil
if C_Spell ~= nil then
    builtinGSCharges = C_Spell.GetSpellCharges
end
if builtinGSCharges ~= nil then
    builtinGSCharges = function(spellName)
        local chargeInfo = C_Spell.GetSpellCharges(spellName)
        if chargeInfo == nil then
            return 0
        end
        return chargeInfo.currentCharges, chargeInfo.maxCharges
    end
else
    builtinGSCharges = function(spellName)
        if not Faceroll.ascension then
            return 0, 0
        end
        local chargeCount, maxCharges = GetSpellCharges(C_Spell:GetSpellID(spellName))
        return chargeCount, maxCharges
    end
end

Faceroll.ascensionFindAura = function(reqUnit, reqName, reqFilter)
    if not Faceroll.ascension and not Faceroll.classic then
        print("ERROR: Faceroll.ascensionFindAura()")
        return
    end
    for auraIndex=1,40 do
        local name, rank, icon, stacks, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod = UnitAura(reqUnit, auraIndex, reqFilter)
        if name == reqName then
            -- DevTools_Dump({UnitAura("player", auraIndex, reqFilter)})
            return { ["duration"]=duration, ["stacks"]=stacks, ["expirationTime"]=expirationTime, }
        end
    end
    return nil
end


local builtinSpellPowerCost = nil
if C_Spell ~= nil then
    builtinSpellPowerCost = C_Spell.GetSpellPowerCost
end
if builtinSpellPowerCost == nil then
    builtinSpellPowerCost = function(spellName)
        local name, _, _, cost = GetSpellInfo(spellName)
        if name == nil then
            return nil
        end
        return { [1]={ ["cost"]=cost } }
    end
end

-----------------------------------------------------------------------------------------
-- Queries

Faceroll.getBuff = function(buffName)
    if Faceroll.ascension or Faceroll.classic then
        return Faceroll.ascensionFindAura("player", buffName, "HELPFUL")
    else
        print("FIXME: Faceroll.getBuff("..buffName..")")
    end
    return nil
end

Faceroll.getDebuff = function(buffName)
    if Faceroll.ascension or Faceroll.classic then
        return Faceroll.ascensionFindAura("player", buffName, "HARMFUL")
    else
        print("FIXME: Faceroll.getDebuff("..buffName..")")
    end
    return nil
end

Faceroll.getDot = function(dotName)
    if Faceroll.ascension or Faceroll.classic then
        return Faceroll.ascensionFindAura("target", dotName, "HARMFUL|PLAYER")
    else
        local name, _, stacks, _, duration, expirationTime = AuraUtil.FindAuraByName(spellName, "target", "HARMFUL|PLAYER")
        if name ~= nil then
            return { ["duration"]=duration, ["stacks"]=stacks, ["expirationTime"]=expirationTime, }
        end
    end
    return nil
end

Faceroll.isBuffActive = function(buffName)
    return (Faceroll.getBuff(buffName) ~= nil)
end

Faceroll.getBuffStacks = function(buffName)
    local buff = Faceroll.getBuff(buffName)
    if buff then
        return buff.stacks
    end
    return 0
end

Faceroll.getBuffRemaining = function(buffName)
    local buff = Faceroll.getBuff(buffName)
    if buff then
        local remaining = math.max(buff.expirationTime - GetTime(), 0)
        return remaining
    end
    return 0
end

Faceroll.getDotRemainingNorm = function(spellName)
    local dot = Faceroll.getDot(spellName)
    if dot ~= nil and dot.duration > 0 then
        local remainingDuration = dot.expirationTime - GetTime()
        local normalizedDuration = remainingDuration / dot.duration
        if normalizedDuration < 0 then
            normalizedDuration = 0
        end
        return normalizedDuration
    end
    return -1
end

Faceroll.isDotActive = function(spellName)
    return (Faceroll.getDotRemainingNorm(spellName) > 0)
end

Faceroll.getDotStacks = function(spellName)
    local dot = Faceroll.getDot(spellName)
    if dot ~= nil and dot.duration > 0 then
        return dot.stacks
    end
    return 0
end

Faceroll.isSpellQueued = function(spellName) -- "on next melee" stuff like Heroic Strikd
    if IsCurrentSpell(spellName) then
        return true
    end
    return false
end

local _isSpellLearnedGSBI = GetSpellBookItemName or GetSpellName

Faceroll.isSpellLearned = function(spellName)
    if _isSpellLearnedGSBI == nil then
        return false
    end
    local i = 1
    while true do
        local bookName = _isSpellLearnedGSBI(i, BOOKTYPE_SPELL)
        if bookName == nil then
            return false
        end
        if bookName == spellName then
            return true
        end
        i = i + 1
    end
end

Faceroll.isSpellAvailable = function(spellName, ignoreUsable)
    if not builtinISU(spellName) and not ignoreUsable then
        return false
    end
    local currentCharges, maxCharges = Faceroll.getSpellCharges(spellName)
    if maxCharges > 0 then
        if Faceroll.getSpellCharges(spellName) > 0 then
            return true
        end
        return false
    end

    if builtinGSC(spellName).duration > 1.5 then
        return false
    end
    return true
end

Faceroll.getSpellCharges = function(spellName)
    return builtinGSCharges(spellName)
end

Faceroll.getSpellCooldown = function(spellName)
    local cd = builtinGSC(spellName)
    if cd == nil then
        return 0
    end
    local duration = cd.duration
    if duration > 0 then
        local since = GetTime() - cd.startTime
        return duration - since
    end
    return 0
end

Faceroll.getSpellChargesSoon = function(spellName, count, seconds)
    local chargeInfo = C_Spell.GetSpellCharges(spellName)
    if chargeInfo == nil then
        return false
    end
    if chargeInfo.currentCharges < count - 1 then
        return false
    end
    if Faceroll.getSpellCooldown(spellName) > seconds then
        return false
    end
    return true
end

Faceroll.hasManaForSpell = function(spellName)
    local curMana = UnitPower("player", 0)
    local spellCost = builtinSpellPowerCost(spellName)
    if spellCost ~= nil and spellCost[1] ~= nil and spellCost[1].cost > 0 then
        if curMana >= spellCost[1].cost then
            return true
        end
    end
    return false
end

Faceroll.inShapeshiftForm = function(formName)
    local inform = false
    for i = 1, GetNumShapeshiftForms() do
        local icon, name, active = GetShapeshiftFormInfo(i)
        if active and name == formName then
            inform = true
        end
    end
    return inform
end

Faceroll.isTotemActive = function(searchName)
    for i=1,4 do
        local haveTotem, totemName, startTime, duration = GetTotemInfo(i)
        if type(totemName) == "string" then
            if string.find(totemName, searchName) == 1 then
                return true
            end
        end
    end
    return false
end

Faceroll.targetingEnemy = function()
    return UnitExists("target") and not UnitIsDead("target") and not UnitIsFriend("player", "target")
end

Faceroll.inCombat = function()
    if UnitAffectingCombat("player") then
        return true
    end
    return false
end

-----------------------------------------------------------------------------------------
-- Dead Zones

-- Spellcasting "dead zones", aka windows of time where we should consider this spell unavailable/dead
-- This is useful for when we don't want to cast a spell *twice* but we don't know we shouldn't
-- press it until some dot appears or travel time finishes, etc.
-- WARNING: be sure to use /frkick in the macro for the spell you're trying to put in a deadzone!
Faceroll.deadzoneCreate = function(spellName, normalizedCastTimeRemaining, deadzoneDuration)
    return {
        ["spellName"]=spellName,
        ["castTimeRemaining"]=normalizedCastTimeRemaining,
        ["duration"]=deadzoneDuration,
        ["endTime"]=0,
    }
end

-- Safe to call any time
Faceroll.deadzoneActive = function(deadzone)
    return (deadzone.endTime > GetTime())
end

-- Only call this when all other state means you're interested in *starting* the deadzone,
-- e.g. you're trying to only cast Wrath twice to proc Eclipse and the wrath count has 1 left
Faceroll.deadzoneUpdate = function(deadzone)
    local castingSpell, _, _, _, castingSpellEndTime = UnitCastingInfo("player")
    local castingSpellDone = 0
    if castingSpell then
        castingSpellDone = castingSpellEndTime / 1000 - GetTime()
        -- print("castingSpell " .. castingSpell .. " castingSpellDone " .. castingSpellDone)
    else
        local channelingSpell, _, _, _, channelSpellEndTime = UnitChannelInfo("player")
        if channelingSpell then
            castingSpell = channelingSpell
            castingSpellDone = channelSpellEndTime / 1000 - GetTime()
        end
    end
    if castingSpell == deadzone.spellName and castingSpellDone < deadzone.castTimeRemaining then
        deadzone.endTime = GetTime() + deadzone.duration
    end
    return Faceroll.deadzoneActive(deadzone)
end

-----------------------------------------------------------------------------------------
-- The little "OFF" / "SV" text and the options list above it

local enabledFrame = nil
local optionsFrame = nil

local function enabledFrameCreate()
    enabledFrame = Faceroll.createFrame(34, 34,
                                        Faceroll.enabledFrameAnchor, Faceroll.enabledFrameX, Faceroll.enabledFrameY,
                                        "TOOLTIP", 0.0,
                                        "CENTER", "firamono", Faceroll.enabledFrameFontSize)

    optionsFrame = Faceroll.createFrame(34, 34,
                                        Faceroll.optionsFrameAnchor, Faceroll.optionsFrameX, Faceroll.optionsFrameY,
                                        "TOOLTIP", 0.0,
                                        "BOTTOM", "firamono", Faceroll.optionsFrameFontSize)
end

local function enabledFrameUpdate()
    if enabledFrame ~= nil and optionsFrame ~= nil then
        local spec = Faceroll.activeSpec()
        local offSpec = Faceroll.activeSpecs["OFF"]
        local displayColor = offSpec.color
        if spec == nil then
            spec = offSpec
        end
        if Faceroll.active then
            displayColor = spec.color
        end

        enabledFrame:setText(Faceroll.textColor(spec.name, displayColor))

        local optionsFrameColor = Faceroll.optionsFrameColor
        if optionsFrameColor == nil then
            optionsFrameColor = spec.color
        end

        local optionsText = ""
        local radioColorIndex = 0
        local radioFrameColors = Faceroll.optionsFrameRadioColors
        if spec.radioColors ~= nil then
            radioFrameColors = spec.radioColors
        end

        for _, rawName in ipairs(spec.options) do
            local name, radio = strsplit("|", rawName)
            if Faceroll.optionsFrameShowAll then
                local color = optionsFrameColor
                if radio ~= nil then
                    local radioColor = spec.color
                    if radioFrameColors ~= nil then
                        radioColor = radioFrameColors[radioColorIndex + 1]
                        radioColorIndex = mod(radioColorIndex + 1, #radioFrameColors)
                    end
                    color = radioColor
                end
                if not Faceroll.options[name] then
                    color = "222222"
                end
                optionsText = optionsText .. Faceroll.textColor(string.upper(name), color) .. "\n"
            else
                local color = optionsFrameColor
                if radio ~= nil then
                    local radioColor = spec.color
                    if radioFrameColors ~= nil then
                        radioColor = radioFrameColors[radioColorIndex + 1]
                        radioColorIndex = mod(radioColorIndex + 1, #radioFrameColors)
                    end
                    color = radioColor
                end
                if Faceroll.options[name] then
                    optionsText = optionsText .. Faceroll.textColor(string.upper(name), color) .. "\n"
                end
            end
        end
        optionsFrame:setText(Faceroll.textColor(optionsText, optionsFrameColor))
    end
end

-----------------------------------------------------------------------------------------
-- The text in the center of the screen saying "FR AE", etc

local activeFrame = nil
local activeFrameTime = 0

local function activeFrameCreate()
    activeFrame = Faceroll.createFrame(100, 20,
                                       Faceroll.activeFrameAnchor, Faceroll.activeFrameX, Faceroll.activeFrameY,
                                       "TOOLTIP", 0.0,               -- strata/alpha
                                       "CENTER", "forcedsquare", Faceroll.activeFrameFontSize) -- text
end

function activeFrameSet(text)
    local activeText = "FR " .. text
    activeFrameTime = GetTime()
    activeFrame:setText(Faceroll.textColor(activeText, Faceroll.activeFrameColor))
end

-- This timer auto-resets the active frame text after ~500ms,
-- making this behave like a keepalive/heartbeat
C_Timer.NewTicker(0.25, function()
    if activeFrameTime > 0 then
        local since = GetTime() - activeFrameTime
        if since > 0.5 then
            activeFrameTime = 0
            activeFrame:setText("")
        end
    end
end, nil)

-----------------------------------------------------------------------------------------
-- The wabits interface grid of bits!

local bitsBG = nil
local bitsCells = {}

local function createBits()
    bitsBG = CreateFrame("Frame")
    bitsBG:SetPoint(Faceroll.bitsPanelAnchor, Faceroll.bitsPanelX, Faceroll.bitsPanelY)
    bitsBG:SetHeight(32)
    bitsBG:SetWidth(16)
    bitsBG:SetFrameStrata("TOOLTIP")
    bitsBG.texture = bitsBG:CreateTexture()
    bitsBG.texture:SetTexture("Interface/BUTTONS/WHITE8X8")
    bitsBG.texture:SetVertexColor(0.0, 0.0, 0.0, 1.0)
    bitsBG.texture:SetAllPoints(bitsBG)
    bitsBG:Show()

    for bitIndex = 0,31 do
        local bitX = bitIndex % 4
        local bitY = floor(bitIndex / 4)
        local bitName = "bit" .. bitIndex
        local cell = CreateFrame("Frame", bitName, bitsBG)
        cell:SetPoint("TOPLEFT", bitX * 4, bitY * -4)
        cell:SetHeight(4)
        cell:SetWidth(4)
        cell.texture = cell:CreateTexture()
        cell.texture:SetTexture("Interface/BUTTONS/WHITE8X8")
        cell.texture:SetVertexColor(1.0, 1.0, 1.0, 1.0)
        cell.texture:SetAllPoints(cell)
        cell:Hide()
        bitsCells[bitIndex] = cell
    end
end

local function showBits(bits)
    -- print("showBits: " .. bits)
    bitsBG:Show()
    local b = 1
    for bitIndex = 0,31 do
        if Faceroll.bitand(bits, b)==0 then
            bitsCells[bitIndex]:Hide()
        else
            bitsCells[bitIndex]:Show()
        end
        b = b * 2
    end
end

local function hideBits()
    bitsBG:Hide()
    for bitIndex = 0,31 do
        bitsCells[bitIndex]:Hide()
    end
end

local function actionKey(spec, mode, state)
    local action = spec.calcAction(mode, state)
    if action == nil then
        return Faceroll.BRIDGE_KEY_NONE
    end
    local key = spec.keys[action]
    if key == nil then
        print("Faceroll: Unknown action: " .. action)
        return Faceroll.BRIDGE_KEY_NONE
    end
    return key
end

local function updateBits(who)
    Faceroll.combatJustEnded = (who == "PLAYER_REGEN_ENABLED")
    if Faceroll.debugLastUpdateEventsEnabled then
        if Faceroll.debugLastUpdateWho[who] == nil then
            Faceroll.debugLastUpdateWho[who] = 0
        end
        Faceroll.debugLastUpdateWho[who] = Faceroll.debugLastUpdateWho[who] + 1
    end

    local spec, specKey = Faceroll.activeSpec()
    if spec and spec.calcAction then
        Faceroll.clearDebugLines()
        local state = Faceroll.createState(spec, specKey)
        if spec.calcState then
            state = spec.calcState(state)
        end

        local bridgeState = {}
        bridgeState.key0 = actionKey(spec, Faceroll.MODE_ST, state)
        bridgeState.key1 = actionKey(spec, Faceroll.MODE_AOE, state)
        bridgeState.active = Faceroll.active
        -- Faceroll.bridgeStateDump(bridgeState)
        bits = Faceroll.bridgeStatePack(bridgeState)

        showBits(bits)
        Faceroll.setDebugState(spec, state)
    else
        hideBits()
    end

    Faceroll.enemyGridUpdate()
    Faceroll.buffsUpdate()

    Faceroll.updateBitsCounter = Faceroll.updateBitsCounter + 1
end

-----------------------------------------------------------------------------------------
-- Options (/fro)

local function radioKillOthers(option)
    local spec = Faceroll.activeSpec()
    if spec == nil then
        return
    end

    -- Find the radio associated with option
    local radioToKill = nil
    for _, rawName in ipairs(spec.options) do
        local name, radio = strsplit("|", rawName)
        if option == name then
            radioToKill = radio
        end
    end

    if radioToKill ~= nil then
        for _, rawName in ipairs(spec.options) do
            local name, radio = strsplit("|", rawName)
            if name ~= option and radio == radioToKill then
                Faceroll.options[name] = nil
            end
        end
    end
end

Faceroll.setOption = function(option, enabled)
    if enabled then
        Faceroll.options[option] = true
        radioKillOthers(option)
    else
        Faceroll.options[option] = nil
    end
    enabledFrameUpdate()
end

local function toggleOption(option)
    if Faceroll.options[option] ~= nil then
        Faceroll.options[option] = nil
    else
        Faceroll.options[option] = true
        radioKillOthers(option)
    end
    enabledFrameUpdate()
    updateBits("toggleOption")
end

local function setOptionTrue(option)
    Faceroll.options[option] = true
    radioKillOthers(option)
    enabledFrameUpdate()
    updateBits("setOptionTrue")
end

local function setOptionFalse(option)
    Faceroll.options[option] = nil
    enabledFrameUpdate()
    updateBits("setOptionFalse")
end

local function setOptionString(raw)
    local spec = Faceroll.activeSpec()
    if (spec == nil) or spec.setOption == nil then
        print("/frs: Active spec doesn't support this.")
    else
        spec.setOption(raw)
    end
end

local function toggleRadioOption(radioToToggle)
    local spec = Faceroll.activeSpec()
    if spec == nil then
        return
    end

    -- Find the radio associated with option
    local firstRadioName = nil
    local nextRadio = false
    for _, rawName in ipairs(spec.options) do
        local name, radio = strsplit("|", rawName)
        if radioToToggle == radio then
            if nextRadio then
                setOptionTrue(name)
                return
            end

            if firstRadioName == nil then
                firstRadioName = name
            end

            if Faceroll.options[name] ~= nil then
                nextRadio = true
            end
        end
    end

    -- wrap!
    if firstRadioName ~= nil then
        setOptionTrue(firstRadioName)
    end
end

Faceroll.kickRadios = function()
    if Faceroll.kickedRadios then
        return
    end
    Faceroll.kickedRadios = true

    local spec = Faceroll.activeSpec()
    if spec == nil then
        return
    end

    local radioSeen = {}
    for _, rawName in ipairs(spec.options) do
        local name, radio = strsplit("|", rawName)
        if radio ~= nil then
            if radioSeen[radio] == nil then
                radioSeen[radio] = true
                -- print("kickRadios: Enabling " .. name)
                setOptionTrue(name)
            end
        end
    end
end

-----------------------------------------------------------------------------------------
-- Extra ticks (/frtick)

local remainingTicks = 0
local function tick()
    -- print("tick! " .. remainingTicks)
    updateBits("tick")

    remainingTicks = remainingTicks - 1
    if remainingTicks > 0 then
        C_Timer.After(0.1, tick)
    end
end
local function tickReset()
    if remainingTicks == 0 then
        C_Timer.After(0.1, tick)
    end
    remainingTicks = 20
end

-----------------------------------------------------------------------------------------
-- Debug Overlay Toggle (/frd)

local function toggleDebug()
    Faceroll.debug = Faceroll.debug + 1
    if Faceroll.debug > Faceroll.DEBUG_LAST then
        Faceroll.debug = 0
    end
    Faceroll.updateDebugOverlay()
    updateBits("toggleDebug")
end

-----------------------------------------------------------------------------------------
-- Action Availability

local function buildActionAvailability()
    for _, spec in ipairs(Faceroll.availableSpecs) do
        if spec.actions ~= nil then
            spec.actionAvailable = {}
            local keyToSlot = buildKeyToSlotMap(spec)
            for index, entry in ipairs(spec.actions) do
                local action = type(entry) == "table" and entry[1] or entry
                local key = spec.keys[action]
                if key then
                    local slot = keyToSlot[key]
                    spec.actionAvailable[action] = (slot ~= nil and HasAction(slot) ~= nil)
                else
                    spec.actionAvailable[action] = false
                end
            end
        end
    end
end

-----------------------------------------------------------------------------------------
-- Keybind dumping (/frk)

local function dumpKeybinds(arg)
    local spec = Faceroll.activeSpec()
    if not spec or not spec.actions then
        print("Faceroll [/frk]: No active spec!")
        return
    end

    local tag = Faceroll.textColor("[frk] ", "333333")
    local debug = (arg == "debug")

    if arg == "refresh" then
        buildActionAvailability()
        print(tag .. Faceroll.textColor("Refreshed action availability. ", "ffffaa") .. Faceroll.textColor("(/frk refresh)", "555555"))
    end

    local keyToSlot = debug and buildKeyToSlotMap(spec) or nil

    for actionIndex, entry in ipairs(spec.actions) do
        local action = type(entry) == "table" and entry[1] or entry
        local key = Faceroll.keys[action]
        if key == nil then
            key = Faceroll.keys[actionIndex]
        end
        if key == nil then
            key = "UNKNOWN"
        end

        local avail = Faceroll.isActionAvailable(action)
        local availText
        if avail then
            availText = Faceroll.textColor("available", "aaffaa")
        elseif type(entry) == "string" then
            availText = Faceroll.textColor("unavailable ", "ff5555") .. Faceroll.textColor("(", "777777") .. Faceroll.textColor("MANUAL", "ffaa55") .. Faceroll.textColor(")", "777777")
        else
            availText = Faceroll.textColor("unavailable", "ff5555")
        end

        local debugText = ""
        if debug then
            local blizzKey = facerollKeyToBlizzKey(key)
            local binding = GetBindingAction(blizzKey) or ""
            local slot = keyToSlot[key]
            local hasAction = slot and HasAction(slot)
            debugText = Faceroll.textColor(
                " [blizz=" .. blizzKey .. " bind=" .. binding .. " slot=" .. tostring(slot) .. " has=" .. tostring(hasAction) .. "]",
                "777777")
        end

        print(tag .. Faceroll.textColor(action, "aaffff") .. " " .. Faceroll.textColor(key, "ffffaa") .. " " .. availText .. debugText)
    end
end

-----------------------------------------------------------------------------------------
-- Faceroll Activation (default: F5)

function facerollActivate()
    if Faceroll.activeSpec() ~= nil then
        Faceroll.active = true
        Faceroll.kickRadios()
    else
        Faceroll.active = false
    end
    enabledFrameUpdate()
    updateBits("activate")
end

function facerollDeactivate()
    Faceroll.active = false
    enabledFrameUpdate()
    updateBits("deactivate")
end

function facerollActivateToggle()
    if Faceroll.active then
        facerollDeactivate()
    else
        facerollActivate()
    end
end

-- this is a weird hack but I'm curious
function facerollStop()
    if Faceroll.active then
        facerollDeactivate()
        C_Timer.After(0.6, function()
            facerollActivate()
        end)
    end
end

-----------------------------------------------------------------------------------------
-- onLoaded() - the entry point which doesn't fire until we're loaded/logged-in

local function onLoaded()
    Faceroll.debugInit()
    Faceroll.enemyGridInit()
    Faceroll.buffsInit()

    enabledFrameCreate()
    enabledFrameUpdate()
    activeFrameCreate()

    createBits()
    updateBits("init()")
end

-----------------------------------------------------------------------------------------
-- Spellbook scanning (used by /frur, /frm)

local gsbin = GetSpellBookItemName
if gsbin == nil then
    gsbin = GetSpellName
end

local function scanSpellbook()
    local bestRanks = {}
    local idRanks = {}

    local i = 1
    while true do
        local spellName, spellSubName = gsbin(i, BOOKTYPE_SPELL)
        if not spellName then
            break
        end
        local id = nil
        if Faceroll.ascension then
            _, id = GetSpellBookItemInfo(i, BOOKTYPE_SPELL)
        elseif Faceroll.classic then
            local link = GetSpellLink(i, BOOKTYPE_SPELL)
            if link then
                id = tonumber(link:match("spell:(%d+)"))
            end
        end
        if id == nil then
            break
        end
        local infoName = GetSpellInfo(id)
        if infoName == nil then
            break
        end

        local _, _, rank = string.find(spellSubName or "", "Rank (%d+)")
        rank = rank and tonumber(rank) or 0

        if bestRanks[infoName] == nil then
            bestRanks[infoName] = {}
            bestRanks[infoName].name = infoName
            bestRanks[infoName].rank = -1
        end
        if rank > bestRanks[infoName].rank then
            bestRanks[infoName].rank = rank
            bestRanks[infoName].id = id
        end
        if rank > 0 then
            idRanks[id] = rank
        end

        i = i + 1
    end

    return bestRanks, idRanks
end

-----------------------------------------------------------------------------------------
-- Upgrade Ranks Action Bar Spell Helper

local function upgradeRanks()
    local bestRanks, idRanks = scanSpellbook()

    local keepRanks = {}
    local spec = Faceroll.activeSpec()
    if spec ~= nil and spec.keepRanks ~= nil then
        for _, spellName in ipairs(spec.keepRanks) do
            keepRanks[spellName] = true
        end
    end

    local upgradedCount = 0
    for i = 1,120 do
        local actionType, _, subType, id = GetActionInfo(i)
        if id ~= nil then
            local infoName = GetSpellInfo(id)
            if infoName ~= nil and not keepRanks[infoName] then
                -- print("Action Bar " .. i .. " is " .. infoName .. "(id " .. id .. ")")
                local rank = idRanks[id]
                if rank ~= nil then
                    local bestRank = bestRanks[infoName]
                    if bestRank ~= nil then
                        if rank < bestRank.rank then
                            print("Upgrading["..i..", "..bestRank.id.."]: " .. infoName .. " " .. rank .. " => " .. bestRank.rank)
                            -- PickupSpell(bestRank.id)
                            PickupSpell(infoName)
                            PlaceAction(i)
                            ClearCursor()

                            upgradedCount = upgradedCount + 1
                        end
                    end
                end
            end
        end
    end

    print("UpgradeRanks slots fixed: " .. upgradedCount)
end

-----------------------------------------------------------------------------------------
-- Babysit zone boundaries to maintain Faceroll active state, if necessary

local lastTimeChatDisabledFaceroll = 0

function onPlayerEnteringWorld()
    if lastTimeChatDisabledFaceroll > 0 then
        local timeSinceChatDisable = GetTime() - lastTimeChatDisabledFaceroll
        if timeSinceChatDisable < 0.1 then
            -- print("Faceroll: Restoring active state on zone boundary.")
            facerollActivate()
        end
    end
    lastTimeChatDisabledFaceroll = 0
end

-----------------------------------------------------------------------------------------
-- Core event registration and handling

eventFrame = CreateFrame("Frame")
local initialized = false
local spellsChangedTimer = nil

local function syncMacros(dry)
    local spec = Faceroll.activeSpec()
    if spec == nil or spec.macros == nil then
        return false
    end

    local AUTO_ICON = 1

    local function trim(s)
        return s:match("^%s*(.-)%s*$")
    end

    -- Scan spellbook once for :SpellName: resolution
    local bestRanks = scanSpellbook()

    for name, body in pairs(spec.macros) do
        local macroName = name .. " FR"
        body = trim(body)
        local tag = Faceroll.textColor("[frm] ", "333333")
        local nameText = Faceroll.textColor(macroName, "aaffff")

        -- Resolve @SpellA|SpellB@ patterns (check-only, keeps first known spell name)
        -- Resolve @@SpellA|SpellB@@ patterns (replaces with best-rank spell ID of first known)
        -- Pipe-separated fallbacks: tries each name left-to-right, uses first found
        local resolveNotes = {}
        local resolveFailed = false

        local function findBestMatch(candidates)
            for _, spellName in ipairs(candidates) do
                local best = bestRanks[spellName]
                if best then return spellName, best end
            end
            return nil, nil
        end

        local function splitCandidates(str)
            local candidates = {}
            for name in string.gmatch(str, "[^|]+") do
                table.insert(candidates, name)
            end
            return candidates
        end

        body = string.gsub(body, "@@([^@]+)@@", function(pattern)
            local candidates = splitCandidates(pattern)
            local matched, best = findBestMatch(candidates)
            if matched then
                if not dry then
                    table.insert(resolveNotes, Faceroll.textColor(matched, "ffffaa")
                        .. " -> " .. Faceroll.textColor("rank " .. best.rank .. " (id " .. best.id .. ")", "aaffaa"))
                end
                return tostring(best.id)
            else
                resolveFailed = true
                if not dry then
                    table.insert(resolveNotes, Faceroll.textColor(pattern, "ffffaa")
                        .. " " .. Faceroll.textColor("not in spellbook", "ff5555"))
                end
                return "@@" .. pattern .. "@@"
            end
        end)
        body = string.gsub(body, "@([^@]+)@", function(pattern)
            local candidates = splitCandidates(pattern)
            local matched, best = findBestMatch(candidates)
            if matched then
                if not dry then
                    local rankText = best.rank > 0
                        and "known (rank " .. best.rank .. ")"
                        or "known"
                    table.insert(resolveNotes, Faceroll.textColor(matched, "ffffaa")
                        .. " " .. Faceroll.textColor(rankText, "aaffaa"))
                end
                return matched
            else
                resolveFailed = true
                if not dry then
                    table.insert(resolveNotes, Faceroll.textColor(pattern, "ffffaa")
                        .. " " .. Faceroll.textColor("not in spellbook", "ff5555"))
                end
                return "@" .. pattern .. "@"
            end
        end)

        if resolveFailed then
            if not dry then
                print(tag .. nameText .. " " .. Faceroll.textColor("Skipped (unlearned spell)", "777777"))
                for _, note in ipairs(resolveNotes) do
                    print(tag .. "  " .. note)
                end
            end
        else
            local index = GetMacroIndexByName(macroName)
            if index and index > 0 then
                local _, existingIcon, existingBody = GetMacroInfo(index)
                if trim(existingBody) ~= body then
                    if dry then
                        return true
                    end
                    EditMacro(index, macroName, existingIcon, body)
                    print(tag .. nameText .. " " .. Faceroll.textColor("Updated", "ffffaa"))
                else
                    if not dry then
                        print(tag .. nameText .. " " .. Faceroll.textColor("OK", "777777"))
                    end
                end
            else
                if dry then
                    return true
                end
                local _, numCharacter = GetNumMacros()
                if numCharacter >= 18 then
                    print(tag .. nameText .. " " .. Faceroll.textColor("FAILED - no character macro slots", "ff5555"))
                else
                    CreateMacro(macroName, AUTO_ICON, body, 1)
                    print(tag .. nameText .. " " .. Faceroll.textColor("Created", "aaffaa"))
                end
            end
            if not dry then
                for _, note in ipairs(resolveNotes) do
                    print(tag .. "  " .. note)
                end
            end
        end
    end

    return false
end

local function syncActionBars(dry)
    local spec = Faceroll.activeSpec()
    if spec == nil or spec.actions == nil then
        return false
    end

    local keyToSlot = buildKeyToSlotMap(spec)
    local tag = Faceroll.textColor("[frb] ", "333333")
    local placed = 0

    for actionIndex, entry in ipairs(spec.actions) do
        if type(entry) == "table" then
            local action = entry[1]
            local macroName = entry.macro
            local spellName = entry.spell

            local key = spec.keys[action]
            if key == nil then
                if not dry then
                    print(tag .. Faceroll.textColor(action, "aaffff") .. " " .. Faceroll.textColor("no keybind", "ff5555"))
                end
            else
                local slot = keyToSlot[key]
                if slot == nil then
                    if not dry then
                        print(tag .. Faceroll.textColor(action, "aaffff") .. " key " .. Faceroll.textColor(key, "ffffaa") .. " " .. Faceroll.textColor("not bound to any bar slot", "ff5555"))
                    end
                elseif macroName then
                    local fullName = macroName .. " FR"
                    local macroIndex = GetMacroIndexByName(fullName)
                    if macroIndex and macroIndex > 0 then
                        local actionType, actionId = GetActionInfo(slot)
                        if actionType ~= "macro" or actionId ~= macroIndex then
                            if dry then
                                return true
                            end
                            PickupMacro(macroIndex)
                            PlaceAction(slot)
                            ClearCursor()
                            placed = placed + 1
                            print(tag .. Faceroll.textColor(action, "aaffff") .. " " .. Faceroll.textColor(fullName, "ffffaa") .. " -> slot " .. slot .. " " .. Faceroll.textColor("OK", "aaffaa"))
                        end
                    else
                        if not dry then
                            print(tag .. Faceroll.textColor(action, "aaffff") .. " " .. Faceroll.textColor("macro not found: " .. fullName .. " (run /frm first)", "ff5555"))
                        end
                    end
                elseif spellName then
                    if GetSpellInfo(spellName) then
                        local actionType, actionId, subType, actionSpellId = GetActionInfo(slot)
                        local currentName = actionSpellId and GetSpellInfo(actionSpellId) or nil
                        if currentName ~= spellName then
                            if dry then
                                return true
                            end
                            PickupSpell(spellName)
                            PlaceAction(slot)
                            ClearCursor()
                            placed = placed + 1
                            print(tag .. Faceroll.textColor(action, "aaffff") .. " " .. Faceroll.textColor(spellName, "ffffaa") .. " -> slot " .. slot .. " " .. Faceroll.textColor("OK", "aaffaa"))
                        end
                    else
                        if not dry then
                            print(tag .. Faceroll.textColor(action, "aaffff") .. " " .. Faceroll.textColor(spellName .. " (not learned yet)", "777777"))
                        end
                    end
                end
            end
        end
    end

    if not dry then
        print(tag .. "Placed " .. placed .. " action(s).")
    end
    return false
end
local function onEvent(self, event, arg1, arg2, ...)
    Faceroll.targetChanged = false
    if not initialized and ((event == "ADDON_LOADED" and arg1 == "Faceroll") or (event == "PLAYER_LOGIN")) then
        initialized = true
        eventFrame:UnregisterEvent("ADDON_LOADED")
        eventFrame:UnregisterEvent("PLAYER_LOGIN")
        onLoaded()
    elseif event == "PLAYER_ENTERING_WORLD" then
        buildActionAvailability()
        onPlayerEnteringWorld()
        updateBits("PLAYER_ENTERING_WORLD")
    elseif event == "PLAYER_TARGET_CHANGED" then
        Faceroll.targetChanged = true
        updateBits("PLAYER_TARGET_CHANGED")
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        updateBits("UNIT_SPELLCAST_SUCCEEDED")
    elseif event == "UNIT_POWER_UPDATE" then
        updateBits("UNIT_POWER_UPDATE")
    elseif event == "UNIT_PET" then
        updateBits("UNIT_PET")
    elseif event == "PLAYER_REGEN_DISABLED" then
        updateBits("PLAYER_REGEN_DISABLED")
    elseif event == "BAG_UPDATE" then
        updateBits("BAG_UPDATE")
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        updateBits("UNIT_SPELLCAST_CHANNEL_STOP")
    elseif event == "ACTIONBAR_UPDATE_STATE" then
        updateBits("ACTIONBAR_UPDATE_STATE")
    elseif event == "CHARACTER_POINTS_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        buildActionAvailability()
        enabledFrameUpdate()
        updateBits(event)
    elseif event == "PLAYER_REGEN_ENABLED" then
        Faceroll.leftCombat = GetTime()
        updateBits("PLAYER_REGEN_ENABLED")
    elseif event == "PLAYER_STARTED_MOVING" then
        Faceroll.moving = true
        updateBits("PLAYER_STARTED_MOVING")
    elseif event == "PLAYER_STOPPED_MOVING" then
        Faceroll.moving = false
        Faceroll.movingStopped = GetTime()
        C_Timer.After(0.6, function()
            updateBits("PLAYER_STOPPED_MOVING")
        end)
        updateBits("PLAYER_STOPPED_MOVING")
    elseif event == "UNIT_AURA" then
        updateBits("UNIT_AURA")
    elseif event == "SPELLS_CHANGED" then
        if spellsChangedTimer then
            spellsChangedTimer:Cancel()
        end
        spellsChangedTimer = C_Timer.NewTimer(2, function()
            spellsChangedTimer = nil
            if syncMacros(true) or syncActionBars(true) then
                SlashCmdList["FRSETUP"]()
            end
        end)
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if Faceroll.classic or Faceroll.ascension then
            -- Classic seems to get fewer other events, just blast here
            updateBits("COMBAT_LOG_EVENT_UNFILTERED")

            -- function unfuck(v)
            --     if v == nil then
            --         return "nil"
            --     end
            --     return v
            -- end

            -- local subEvent = arg2
            -- print("subEvent: " .. subEvent);
            -- if subEvent == "SPELL_DAMAGE" then
            --     local sourceName = select(2, ...)
            --     local destName = select(5, ...)
            --     local spellName = select(8, ...)
            --     local damageAmount = select(10, ...)
            --     local overkill = select(11, ...)
            --     damageAmount = tonumber(damageAmount) - tonumber(overkill)
            --     if  subEvent == "SPELL_DAMAGE"
            --     and sourceName == "Demonza"
            --     and destName == "Elder Mottled Boar"
            --     then
            --         print("HIT BOAR: " .. damageAmount .. " (" .. overkill .. ")")

            --         -- local o = "COMBAT_LOG_EVENT_UNFILTERED: " .. unfuck(subEvent)
            --         -- for i = 1,20 do
            --         --     local q = unfuck(select(i, ...))
            --         --     o = o .. " " .. i .. " " .. q
            --         -- end
            --         -- print(o)
            --     end
            -- end
        end
    end
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("UNIT_PET")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_STARTED_MOVING")
eventFrame:RegisterEvent("PLAYER_STOPPED_MOVING")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:SetScript("OnEvent", onEvent)
if Faceroll.classic or Faceroll.ascension then
    eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
    eventFrame:RegisterEvent("BAG_UPDATE")
    eventFrame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    eventFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
    eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
end

DEFAULT_CHAT_FRAME.editBox:HookScript("OnShow", function()
    -- If this fires, someone is trying to type in chat!
    if Faceroll.active then
        -- Keep track of when this fires, and if a PLAYER_ENTERING_WORLD fires
        -- shortly afterwards, this was probably spurious and we can restore the
        -- active state.
        lastTimeChatDisabledFaceroll = GetTime()
    end
    facerollDeactivate()
end)

hooksecurefunc("ChatEdit_ActivateChat", function(frame)
    if frame:IsShown() then
        facerollDeactivate()
    end
end)

-----------------------------------------------------------------------------------------
-- Slash command registration

SLASH_FR1 = '/fr'
SlashCmdList["FR"] = function(text)
    activeFrameSet(text)
    updateBits("/fr")
end

SLASH_FRA1 = '/fra'
SlashCmdList["FRA"] = facerollActivateToggle

SLASH_FRSTOP1 = '/frstop'
SlashCmdList["FRSTOP"] = facerollStop

SLASH_FRTICK1 = '/frtick'
SlashCmdList["FRTICK"] = tickReset

SLASH_FRR1 = '/frr'
SlashCmdList["FRR"] = toggleRadioOption

SLASH_FRO1 = '/fro'
SlashCmdList["FRO"] = toggleOption

SLASH_FRT1 = '/frt'
SlashCmdList["FRT"] = setOptionTrue

SLASH_FRF1 = '/frf'
SlashCmdList["FRF"] = setOptionFalse

SLASH_FRS1 = '/frs'
SlashCmdList["FRS"] = setOptionString

SLASH_FRD1 = '/frd'
SlashCmdList["FRD"] = toggleDebug

SLASH_FRDEBUG1 = '/frdebug'
SlashCmdList["FRDEBUG"] = toggleDebug

SLASH_FRK1 = '/frk'
SlashCmdList["FRK"] = dumpKeybinds

SLASH_FRUR1 = '/frur'
SlashCmdList["FRUR"] = upgradeRanks

SLASH_FRM1 = '/frm'
SlashCmdList["FRM"] = function()
    syncMacros(false)
end

-----------------------------------------------------------------------------------------
-- Action Bar Placement (/frb)

SLASH_FRB1 = '/frb'
SlashCmdList["FRB"] = function()
    syncActionBars(false)
end

SLASH_FRBC1 = '/frbc'
SlashCmdList["FRBC"] = function()
    local tag = Faceroll.textColor("[frbc] ", "333333")
    local cleared = 0

    for i = 1, #Faceroll.keys do
        local key = Faceroll.keys[i]
        if key then
            local blizzKey = facerollKeyToBlizzKey(key)
            local binding = GetBindingAction(blizzKey)
            if binding and binding ~= "" then
                local slot = bindingToSlot(binding)
                if slot then
                    PickupAction(slot)
                    ClearCursor()
                    cleared = cleared + 1
                    print(tag .. "slot " .. slot .. " (key " .. i .. ") " .. Faceroll.textColor("cleared", "ffffaa"))
                end
            end
        end
    end

    print(tag .. "Cleared " .. cleared .. " slot(s).")
end

-----------------------------------------------------------------------------------------
-- Setup: /frm + /frb + /frk refresh with confirmation (/frs etup)

local function placeGlobalMacro(keyName, macroName)
    local tag = Faceroll.textColor("[frsetup] ", "333333")
    local key = Faceroll.keys[keyName]
    if not key then return end
    local macroIndex = GetMacroIndexByName(macroName)
    if not macroIndex or macroIndex == 0 then return end
    local blizzKey = facerollKeyToBlizzKey(key)
    local binding = GetBindingAction(blizzKey)
    if not binding or binding == "" then return end
    local slot = bindingToSlot(binding)
    if not slot then return end
    if HasAction(slot) then return end
    PickupMacro(macroIndex)
    PlaceAction(slot)
    ClearCursor()
    print(tag .. Faceroll.textColor(macroName, "aaffff") .. " -> slot " .. slot .. " " .. Faceroll.textColor("OK", "aaffaa"))
end

local function setupPlaceGlobalMacros()
    placeGlobalMacro("toggle1", "FRA")
    placeGlobalMacro("signal_st", "FR_ST")
    placeGlobalMacro("signal_aoe", "FR_AE")
end

StaticPopupDialogs["FACEROLL_SETUP"] = {
    text = "Faceroll: Create macros and populate action bars for the active spec?",
    button1 = "Update",
    button2 = "Cancel",
    button3 = "Clear + Update",
    OnAccept = function()
        SlashCmdList["FRM"]()
        SlashCmdList["FRB"]()
        setupPlaceGlobalMacros()
        dumpKeybinds("refresh")
    end,
    OnAlt = function()
        SlashCmdList["FRBC"]()
        SlashCmdList["FRM"]()
        SlashCmdList["FRB"]()
        setupPlaceGlobalMacros()
        dumpKeybinds("refresh")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

SLASH_FRSETUP1 = '/frsetup'
SlashCmdList["FRSETUP"] = function()
    local spec = Faceroll.activeSpec()
    if spec == nil then
        print(Faceroll.textColor("[frsetup] ", "ff5555") .. "No active spec.")
        return
    end
    StaticPopup_Show("FACEROLL_SETUP")
end

-----------------------------------------------------------------------------------------
