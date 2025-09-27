if Faceroll == nil then
    _, Faceroll = ...
end

Faceroll.keys = {}

Faceroll.MODE_NONE = 0
Faceroll.MODE_ST = 1
Faceroll.MODE_AOE = 2

local nextSpec = 0
Faceroll.SPEC_OFF = 0
Faceroll.SPEC_LAST = 0
Faceroll.availableSpecs = {}
Faceroll.activeSpecsByIndex = {}
Faceroll.activeSpecsByKey = {}

Faceroll.bitand = function(a, b)
    local result = 0
    local bitval = 1
    while a > 0 and b > 0 do
      if a % 2 == 1 and b % 2 == 1 then -- test the rightmost bits
          result = result + bitval      -- set the current bit
      end
      bitval = bitval * 2 -- shift left
      a = math.floor(a/2) -- shift right
      b = math.floor(b/2)
    end
    return result
end

local function bitsUnpack(self, rawBits)
    local unpacked = {}
    local currBit = 1
    for _, name in pairs(self.names) do
        local v = false
        if Faceroll.bitand(rawBits, currBit) ~= 0 then
            v = true
        end
        unpacked[name] = v
        currBit = currBit * 2
    end
    return unpacked
end

local function bitsPack(self, state)
    local value = 0
    local currBit = 1
    for _, name in pairs(self.names) do
        if state[name] then
            value = value + currBit
        end
        currBit = currBit * 2
    end
    return value
end

Faceroll.isSeparatorName = function(name)
    return (string.find(name, "^[- ]") ~= nil)
end

Faceroll.createBits = function(unfilteredNames)
    local names = {}
    for _,name in ipairs(unfilteredNames) do
        if not Faceroll.isSeparatorName(name) then
            table.insert(names, name)
        end
    end

    local bits = {
        ["names"]=names,
        ["unpack"]=bitsUnpack,
        ["pack"]=bitsPack,
    }
    return bits
end

Faceroll.createSpec = function(name, color, specKey)
    local spec = {
        ["name"]=name,
        ["color"]=color,
        ["key"]=specKey,
        ["calcState"]=nil,
        ["calcAction"]=nil,
        ["buffs"]=nil,
        ["states"]={},
        ["actions"]={},
        ["options"]={},
        ["keys"]={},
        ["index"]=nil,
    }
    table.insert(Faceroll.availableSpecs, spec)
    return spec
end

Faceroll.enableSpec = function(specName)
    for _, spec in ipairs(Faceroll.availableSpecs) do
        if spec.name == specName then
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
            spec.bits = Faceroll.createBits(spec.states)
            local bitCount = #spec.bits.names
            local actionCount = #spec.actions

            print("Enabling Spec: " .. spec.name .. " (" .. Faceroll.SPEC_LAST .. "), ".. bitCount .. "/28 bits, " .. actionCount .. " actions")
            return
        end
    end
    print("Faceroll.enableSpec(): ERROR - Unrecognized spec " .. specName)
end

Faceroll.createState = function(spec)
    local state = spec.bits:unpack(0)
    for _,name in ipairs(spec.options) do
        if Faceroll.options[name] ~= nil then
            state[name] = true
        end
    end
    return state
end

Faceroll.activateKeybinds = function()
    for _, spec in ipairs(Faceroll.activeSpecsByIndex) do
        if spec.actions ~= nil then
            for index, action in ipairs(spec.actions) do
                local key = Faceroll.keys[action]
                if key == nil then
                    key = Faceroll.keys[index]
                end
                if key ~= nil then
                    print("["..spec.name.."] " .. action .. " -> " .. key)
                    spec.keys[action] = key
                else
                    print("["..spec.name.."] " .. action .. " -> UNMAPPED")
                end
            end
        end
    end
end

Faceroll.activeSpec = function()
    local _, playerClass = UnitClass("player")
    local specIndex = "CLASSIC"
    if not Faceroll.classic then
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
Faceroll.enableSpec("OFF")
