if Faceroll == nil then
    _, Faceroll = ...
end

-----------------------------------------------------------------------------------------
-- Bridge Constants

Faceroll.MODE_NONE = 0
Faceroll.MODE_ST = 1
Faceroll.MODE_AOE = 2

Faceroll.BRIDGE_FLAG_ACTIVE = 0x1

Faceroll.BRIDGE_KEY_NONE = ""

-----------------------------------------------------------------------------------------
-- Helpers

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

-----------------------------------------------------------------------------------------
-- Bridge Key Transport

-- In order for a ST/AOE key choice to be sent across the bridge,
-- its name must be in this list.
Faceroll.bridgeKeyTable = {
    "7",
    "8",
    "9",
    "0",
    "-",
    "=",
    "f7",
    "f8",
    "f9",
    "f10",
    "f11",
    "f12",
    "pad1",
    "pad2",
    "pad3",
    "pad4",
    "pad5",
    "pad6",
    "pad7",
    "pad8",
    "pad9",
}

Faceroll.bridgeKeyMap = {}
for keyIndex,key in ipairs(Faceroll.bridgeKeyTable) do
    Faceroll.bridgeKeyMap[key] = keyIndex
end

Faceroll.bridgeKeyName = function(keyIndex)
    if keyIndex == 0 then
        return Faceroll.BRIDGE_KEY_NONE
    end
    return Faceroll.bridgeKeyTable[keyIndex]
end

Faceroll.bridgeKeyIndex = function(keyName)
    if keyName == Faceroll.BRIDGE_KEY_NONE then
        return 0
    end
    return Faceroll.bridgeKeyMap[keyName]
end

-----------------------------------------------------------------------------------------
-- Bridge Signals Transport

-- "listen" are keys the Action system are listening for; the keys the user presses.
-- "pulse" are keys regularly pulsed back to the game when actively sending that mode's actions.

Faceroll.bridgeSignals = {}
Faceroll.bridgeSignals.listen0 = nil
Faceroll.bridgeSignals.listen1 = nil
Faceroll.bridgeSignals.pulse0 = nil
Faceroll.bridgeSignals.pulse1 = nil

Faceroll.bridgeSignalKeys = function(listen0, listen1, pulse0, pulse1)
    Faceroll.bridgeSignals.listen0 = listen0
    Faceroll.bridgeSignals.listen1 = listen1
    Faceroll.bridgeSignals.pulse0 = pulse0
    Faceroll.bridgeSignals.pulse1 = pulse1
end

-----------------------------------------------------------------------------------------
-- Bridge State

Faceroll.bridgeStatePack = function(bridgeState)
    local mode0 = Faceroll.bridgeKeyIndex(bridgeState.key0)
    if mode0 == nil then
        print("Faceroll: Unknown key " .. bridgeState.key0)
        return 0
    end

    local mode1 = Faceroll.bridgeKeyIndex(bridgeState.key1)
    if mode1 == nil then
        print("Faceroll: Unknown key " .. bridgeState.key1)
        return 0
    end

    local flags = 0
    if bridgeState.active then
        flags = flags + Faceroll.BRIDGE_FLAG_ACTIVE
    end

    local bits = (mode0 * 0x01000000) + (mode1 * 0x00010000) + flags
    return bits
end

Faceroll.bridgeStateUnpack = function(bits)
    local bridgeState = {}

    bridgeState._mode0 = math.floor(Faceroll.bitand(bits, 0xff000000) / 0x01000000)
    bridgeState._mode1 = math.floor(Faceroll.bitand(bits, 0x00ff0000) / 0x00010000)
    bridgeState._flags = math.floor(Faceroll.bitand(bits, 0x0000ffff))

    bridgeState.key0 = Faceroll.bridgeKeyName(bridgeState._mode0)
    bridgeState.key1 = Faceroll.bridgeKeyName(bridgeState._mode1)
    if bridgeState.key0 == nil then
        print("ERROR[bridgeStateUnpack]: Unknown mode0 index " .. bridgeState._mode0)
        return nil
    end
    if bridgeState.key1 == nil then
        print("ERROR[bridgeStateUnpack: Unknown mode1 index " .. bridgeState._mode1)
        return nil
    end

    bridgeState.active = (Faceroll.bitand(bridgeState._flags, Faceroll.BRIDGE_FLAG_ACTIVE) ~= 0)
    return bridgeState
end

Faceroll.bridgeStateDump = function(bridgeState)
    if bridgeState == nil then
        print("Faceroll[bridgeStateDump]: nil")
        return
    end

    local active = "F"
    if bridgeState.active then
        active = "T"
    end

    print("Faceroll[bridgeStateDump]: key0 " .. bridgeState.key0 .. " key1 " .. bridgeState.key1 .. " active " .. active)
end
