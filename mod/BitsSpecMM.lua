-----------------------------------------------------------------------------------------
-- Marksmanship Hunter

local _, Faceroll = ...

local streamlineDeadzone = Faceroll.deadzoneCreate("Aimed Shot", 0.3, 0.5)

Faceroll.trackBuffs({
    ["trickshots"] = { ["name"]="Trick Shots" },
    ["streamline"] = { ["name"]="Streamline" },
    ["preciseshots"] = { ["name"]="Precise Shots" },
    ["spottersmark"] = { ["name"]="Spotter's Mark" },
    ["movingtarget"] = { ["name"]="Moving Target" },
})

local function calcBits()
    local bits = 0
    if Faceroll.isBuffActive("trickshots") then
        bits = bits + 0x1
    end
    if Faceroll.isBuffActive("streamline") then
        bits = bits + 0x2
        Faceroll.deadzoneUpdate(streamlineDeadzone)
    end
    if Faceroll.isBuffActive("preciseshots") then
        bits = bits + 0x4
    end
    if Faceroll.isBuffActive("spottersmark") then
        bits = bits + 0x8
    end
    if Faceroll.isBuffActive("movingtarget") then
        bits = bits + 0x10
    end
    if Faceroll.isSpellAvailable("Aimed Shot") then
        bits = bits + 0x20
    end
    if Faceroll.isSpellAvailable("Rapid Fire") then
        bits = bits + 0x40
    end
    if Faceroll.isSpellAvailable("Explosive Shot") then
        bits = bits + 0x80
    end
    if Faceroll.isSpellAvailable("Kill Shot") then
        bits = bits + 0x100
    end
    if UnitPower("player") < 30 then
        bits = bits + 0x200
    end

    if Faceroll.deadzoneActive(streamlineDeadzone) then
        bits = bits + 0x400
    end

    if Faceroll.debug then
        local o = ""
        local dztext = "F"
        if Faceroll.deadzoneActive(streamlineDeadzone) then
            dztext = "T"
        end
        o = o .. "Aimed Deadzone   :\n"
        o = o .. "active           : " .. dztext .. "\n"
        o = o .. "spellName        : " .. streamlineDeadzone.spellName .. "\n"
        o = o .. "castTimeRemaining: " .. streamlineDeadzone.castTimeRemaining .. "\n"
        o = o .. "duration         : " .. streamlineDeadzone.duration .. "\n"
        o = o .. "endTime          : " .. streamlineDeadzone.endTime .. "\n"
        Faceroll.setDebugText(o)
    end

    return bits
end

Faceroll.registerSpec("HUNTER-2", calcBits)
