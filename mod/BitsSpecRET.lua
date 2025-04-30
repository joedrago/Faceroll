-----------------------------------------------------------------------------------------
-- Ret Paladin

local _, Faceroll = ...

Faceroll.trackBuffs({
    ["allin"] = { ["name"]="All In!" },
    ["empyreanpower"] = { ["name"]="Empyrean Power" },
    ["lightsdeliverance"] = { ["name"]="Light's Deliverance" },
})

local function calcBits()
    local bits = 0

    local holypower = UnitPower("player", Enum.PowerType.HolyPower)
    local holAvailable = false
    if GetTime() < Faceroll.holExpirationTime then
        holAvailable = true
    end

    if holypower >= 3 then
        bits = bits + 0x1
    end
    if holypower >= 5 then
        bits = bits + 0x2
    end

    if Faceroll.isBuffActive("allin") then
        bits = bits + 0x4
    end
    if Faceroll.isBuffActive("empyreanpower") then
        bits = bits + 0x8
    end
    if Faceroll.isBuffActive("lightsdeliverance") then
        bits = bits + 0x10
    end

    if Faceroll.isDotActive("Expurgation") then
        bits = bits + 0x20
    end

    if Faceroll.isSpellAvailable("Divine Hammer") then
        bits = bits + 0x40
    end
    if Faceroll.isSpellAvailable("Execution Sentence") then
        bits = bits + 0x80
    end
    if Faceroll.isSpellAvailable("Wake of Ashes") then
        bits = bits + 0x100
    end
    if Faceroll.isSpellAvailable("Divine Toll") then
        bits = bits + 0x200
    end
    if Faceroll.isSpellAvailable("Judgment") then
        bits = bits + 0x400
    end
    if Faceroll.isSpellAvailable("Blade of Justice") then
        bits = bits + 0x800
    end
    if Faceroll.isSpellAvailable("Hammer of Wrath") then
        bits = bits + 0x1000
    end

    if holAvailable then
        bits = bits + 0x2000
    end

    if Faceroll.debug then
        local o = ""
        local hol = "N"
        if holAvailable then
            hol = "Y"
        end
        o = o .. "Hammer of Light: " .. hol .. "\n"
        Faceroll.setDebugText(o)
    end

    return bits
end

Faceroll.registerSpec("PALADIN-3", calcBits)
