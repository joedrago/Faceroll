-----------------------------------------------------------------------------------------
-- Ret Paladin

local function press(button, name)
    -- print("Think: " .. name)
    return button
end

local function nextAction(action, bits)
    local holypower3 = bitand(bits, 0x1)
    local holypower5 = bitand(bits, 0x2)
    local allinbuff = bitand(bits, 0x4)
    local empyreanpowerbuff = bitand(bits, 0x8)
    local lightsdeliverancebuff = bitand(bits, 0x10)
    local expurgationdot = bitand(bits, 0x20)
    local divinehammeravailable = bitand(bits, 0x40)
    local executionsentenceavailable = bitand(bits, 0x80)
    local wakeofashesavailable = bitand(bits, 0x100)
    local divinetollavailable = bitand(bits, 0x200)
    local judgmentavailable = bitand(bits, 0x400)
    local bladeofjusticeavailable = bitand(bits, 0x800)
    local hammerofwrathavailable = bitand(bits, 0x1000)
    local hammeroflightavailable = bitand(bits, 0x2000)

    if action == ACTION_ST then
        -- Single Target

        if divinehammeravailable > 0 and holypower3 > 0 then
            return press("7", "Divine Hammer (with enough Holy Power to extend it)")

        elseif executionsentenceavailable > 0 then
            return press("8", "Execution Sentence")

        elseif hammeroflightavailable > 0 and holypower5 > 0 then
            return press("9", "Hammer of Light (regular cast)")

        elseif allinbuff > 0 and holypower3 > 0 then
            return press("0", "Final Verdict (with an All in! proc)")

        -- elseif hammeroflightavailable > 0 and holypower5 > 0 and lightsdeliverancebuff > 0 then
        --     return press("9", "Hammer of Light (with a Light's Deliverance proc)")

        elseif holypower5 > 0 then
            return press("0", "Final Verdict (with 5 Holy Power)")

        elseif bladeofjusticeavailable > 0 and expurgationdot == 0 then
            return press("=", "Blade of Justice (if Expurgation isn't active)")

        elseif wakeofashesavailable > 0 then
            return press("9", "Wake of Ashes")

        elseif divinetollavailable > 0 then
            return press("pad7", "Divine Toll")

        elseif empyreanpowerbuff > 0 then
            return press("-", "Divine Storm (with an Empyrean Power proc)")

        elseif hammeroflightavailable == 0 and holypower3 > 0 then
            return press("0", "Final Verdict")

        elseif judgmentavailable > 0 then
            return press("pad8", "Judgment")

        elseif bladeofjusticeavailable > 0 then
            return press("=", "Blade of Justice")

        elseif hammerofwrathavailable > 0 then
            return press("f7", "Hammer of Wrath")

        else
            return press(nil, "NOTHING")
        end

    elseif action == ACTION_AOE then
        -- AOE

        if divinehammeravailable > 0 and holypower3 > 0 then
            return press("7", "Divine Hammer (with enough Holy Power to extend it)")

        elseif executionsentenceavailable > 0 then
            return press("8", "Execution Sentence")

        elseif hammeroflightavailable > 0 and holypower5 > 0 then
            return press("9", "Hammer of Light (regular cast)")

        elseif (holypower3 > 0 and allinbuff > 0) or empyreanpowerbuff > 0 then
            return press("-", "Divine Storm (with an All in! or Empyrean Power proc)")

        -- elseif hammeroflightavailable > 0 and lightsdeliverancebuff > 0 then
        --     return press("9", "Hammer of Light (with a Light's Deliverance proc)")

        elseif holypower5 > 0 then
            return press("-", "Divine Storm (with 5 Holy Power)")

        elseif wakeofashesavailable > 0 then
            return press("9", "Wake of Ashes")

        elseif divinetollavailable > 0 then
            return press("pad7", "Divine Toll")

        elseif hammeroflightavailable == 0 and holypower3 > 0 then
            return press("-", "Divine Storm")

        elseif judgmentavailable > 0 then
            return press("pad8", "Judgment")

        elseif bladeofjusticeavailable > 0 then
            return press("=", "Blade of Justice")

        elseif hammerofwrathavailable > 0 then
            return press("f7", "Hammer of Wrath")

        else
            return press(nil, "NOTHING")
        end
    end

    return nil
end

return nextAction
