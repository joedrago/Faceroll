if Faceroll == nil then
    _, Faceroll = ...
end

Faceroll.keys = {}

local nextSpec = 0
Faceroll.SPEC_OFF = 0
Faceroll.SPEC_LAST = 0
Faceroll.availableSpecs = {}
Faceroll.activeSpecsByIndex = {}
Faceroll.activeSpecsByKey = {}

Faceroll.isSeparatorName = function(name)
    return (string.find(name, "^[- ]") ~= nil)
end

Faceroll.createSpec = function(name, color, specKey)
    local spec = {
        ["name"]=name,
        ["color"]=color,
        ["key"]=specKey,
        ["calcState"]=nil,
        ["calcAction"]=nil,
        ["buffs"]=nil,
        ["overlay"]={},
        ["actions"]={},
        ["options"]={},
        ["keys"]={},
        ["index"]=nil,
    }
    table.insert(Faceroll.availableSpecs, spec)
    return spec
end

Faceroll.createState = function(spec)
    local state = {}
    for _,name in ipairs(spec.options) do
        if Faceroll.options[name] ~= nil then
            state[name] = true
        end
    end
    return state
end

Faceroll.initSpecs = function()
    for _, spec in ipairs(Faceroll.availableSpecs) do
        Faceroll.activeSpecsByIndex[nextSpec] = spec
        nextSpec = nextSpec + 1
        spec.index = #Faceroll.activeSpecsByIndex
        Faceroll.SPEC_LAST = #Faceroll.activeSpecsByIndex
        if spec.buffs ~= nil then
            Faceroll.trackBuffs(spec.buffs)
        end
        if Faceroll.activeSpecsByKey[spec.key] ~= nil then
            print("WARNING: Multiple specs for the same key active! Overriding preexisting spec key: " .. spec.key)
        end
        Faceroll.activeSpecsByKey[spec.key] = spec
        -- print("Enabling Spec: " .. spec.name .. " (" .. Faceroll.SPEC_LAST .. "), ".. bitCount .. "/28 bits, " .. actionCount .. " actions")
    end

    for _, spec in ipairs(Faceroll.activeSpecsByIndex) do
        if spec.actions ~= nil then
            for index, action in ipairs(spec.actions) do
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

    print("Faceroll.activateSpecs(): " .. #Faceroll.activeSpecsByIndex .. " available specs.")
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
    elseif not Faceroll.classic then
        if GetSpecialization ~= nil then
            specIndex = GetSpecialization()
        end
    end
    if playerClass == nil or specIndex == nil then
        return nil
    end
    local specKey = playerClass .. "-" .. specIndex
    local spec = Faceroll.activeSpecsByKey[specKey]
    return spec
end

Faceroll.createSpec("OFF", "333333", "OFF")
