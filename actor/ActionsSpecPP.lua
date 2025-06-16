-----------------------------------------------------------------------------------------
-- Prot Paladin

local function press(button, name)
    -- print("Think: " .. name)
    return button
end

local function nextAction(action, bits)
    local holavailable = bitand(bits, 0x1)
    local holypower1 = bitand(bits, 0x2)
    local holypower3 = bitand(bits, 0x4)
    local needsheal = bitand(bits, 0x8)
    local shaketheheavensbuff = bitand(bits, 0x10)
    local blessingofdawnbuff = bitand(bits, 0x20)
    local consecrationbuff = bitand(bits, 0x40)
    local blessedhammer = bitand(bits, 0x80)
    local eyeoftyr = bitand(bits, 0x100)
    local divinetoll = bitand(bits, 0x200)
    local judgment = bitand(bits, 0x400)
    local avengersshield = bitand(bits, 0x800)
    local hammerofwrath = bitand(bits, 0x1000)
    local consecration = bitand(bits, 0x2000)
    local holding = bitand(bits, 0x4000)

    if action == ACTION_Q then
        -- Single Target

        if needsheal > 0 then
            return press("f11", "Word of Glory")

        elseif holypower3 == 0 and eyeoftyr > 0 then
            return press("0", "Eye of Tyr")

        elseif holavailable > 0 and holypower3 > 0 and blessingofdawnbuff > 0 then
            return press("0", "Hammer of Light")

        elseif consecration > 0 and consecrationbuff == 0 then
            return press("f9", "Consecration")

        elseif holypower3 > 0 then
            return press("f7", "Shield of the Righteous")

        elseif holypower3 == 0 and divinetoll > 0 then
            return press("f10", "Divine Toll")

        elseif hammerofwrath > 0 then
            return press("9", "Hammer of Wrath")

        elseif judgment > 0 then
            return press("8", "Judgment")

        elseif holding == 0 and avengersshield > 0 then
            return press("f8", "Avenger's Shield")

        elseif blessedhammer > 0 then
            return press("7", "Blessed Hammer")

        elseif consecration > 0 then
            return press("f9", "Consecration")

        end

    elseif action == ACTION_E then
        -- AOE

        if needsheal > 0 then
            return press("f11", "Word of Glory")

        elseif holypower3 == 0 and eyeoftyr > 0 then
            return press("0", "Eye of Tyr")

        elseif holavailable > 0 and holypower3 > 0 and blessingofdawnbuff > 0 then
            return press("0", "Hammer of Light")

        elseif consecration > 0 and consecrationbuff == 0 then
            return press("f9", "Consecration")

        elseif holypower3 > 0 then
            return press("f7", "Shield of the Righteous")

        elseif holding == 0 and avengersshield > 0 then
            return press("f8", "Avenger's Shield")

        elseif hammerofwrath > 0 then
            return press("9", "Hammer of Wrath")

        elseif judgment > 0 then
            return press("8", "Judgment")

        elseif holypower1 == 0 and divinetoll > 0 then
            return press("f10", "Divine Toll")

        elseif blessedhammer > 0 then
            return press("7", "Blessed Hammer")

        elseif consecration > 0 then
            return press("f9", "Consecration")

        end

    end

    return nil
end

return nextAction
