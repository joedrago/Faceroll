if Faceroll == nil then
    _, Faceroll = ...
end

Faceroll.keys = {}

Faceroll.ACTION_NONE = 0
Faceroll.ACTION_ST = 1
Faceroll.ACTION_AOE = 2

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

Faceroll.createSpec = function(name, color, specKey)
    local spec = {
        ["name"]=name,
        ["color"]=color,
        ["key"]=specKey,
        ["calcBits"]=nil,
        ["nextAction"]=nil,
        ["buffs"]=nil,
        ["abilities"]={},
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

            print("Enabling Spec: " .. spec.name .. " (" .. Faceroll.SPEC_LAST .. ")")
            return
        end
    end
    print("Faceroll.enableSpec(): ERROR - Unrecognized spec " .. specName)
end

Faceroll.activateKeybinds = function()
    for _, spec in ipairs(Faceroll.activeSpecsByIndex) do
        if spec.abilities ~= nil then
            for index, ability in ipairs(spec.abilities) do
                local key = Faceroll.keys[ability]
                if key == nil then
                    key = Faceroll.keys[index]
                end
                if key ~= nil then
                    print("["..spec.name.."] " .. ability .. " -> " .. key)
                    spec.keys[ability] = key
                else
                    print("["..spec.name.."] " .. ability .. " -> UNMAPPED")
                end
            end
        end
    end
end

Faceroll.createSpec("OFF", "333333", "OFF")
Faceroll.enableSpec("OFF")

local function bitsEnable(self, name)
    local bitValue = self.lookup[name]
    if bitValue ~= nil then
        if Faceroll.bitand(self.value, bitValue) == 0 then
            self.value = self.value + bitValue
        end
    end
end

local function bitsReset(self)
    self.value = 0
end

local function bitsIsEnabled(self, name)
    local bitValue = self.lookup[name]
    if bitValue ~= nil then
        if Faceroll.bitand(self.value, bitValue) ~= 0 then
            return true
        end
    end
    return false
end

local function bitsParse(self, rawBits)
    local parsed = {}
    local currBit = 1
    for _, name in pairs(self.names) do
        local v = false
        if Faceroll.bitand(rawBits, currBit) ~= 0 then
            v = true
        end
        parsed[name] = v
        currBit = currBit * 2
    end
    return parsed
end

local function bitsValue(self)
    return self.value
end

Faceroll.createBits = function(names)
    local lookup = {}
    local currBit = 1
    for _, name in pairs(names) do
        lookup[name] = currBit
        currBit = currBit * 2
    end

    local bits = {
        ["value"]=0,
        ["names"]=names,
        ["lookup"]=lookup,
        ["enable"]=bitsEnable,
        ["isEnabled"]=bitsIsEnabled,
        ["parse"]=bitsParse,
        ["reset"]=bitsReset,
    }
    return bits
end
