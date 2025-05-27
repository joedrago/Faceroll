-----------------------------------------------------------------------------------------
-- Unholy DK

local function press(button, name)
    -- print("Press: " .. name)
    return button
end

local function nextAction(action, bits)
    local needspet = bitand(bits, 0x1)
    local raiseabomination = bitand(bits, 0x2)
    local abominationlimb = bitand(bits, 0x4)
    local darktransformation = bitand(bits, 0x8)
    local unholyassault = bitand(bits, 0x10)
    local apocalypse = bitand(bits, 0x20)
    local soulreaper = bitand(bits, 0x40)
    local deathcoil80sd = bitand(bits, 0x80)
    local outbreak = bitand(bits, 0x100)
    local festeringstrike = bitand(bits, 0x200)
    local scourgestrikepb = bitand(bits, 0x400)
    local deathcoilrot = bitand(bits, 0x800)
    local scourgestrike3 = bitand(bits, 0x1000)
    local epidemicsd = bitand(bits, 0x2000)
    local epidemicrc = bitand(bits, 0x4000)
    local deathanddecaybuff = bitand(bits, 0x8000)
    local outbreakvpndt = bitand(bits, 0x10000)
    local festeringscythe = bitand(bits, 0x20000)
    local haswounds = bitand(bits, 0x40000)
    local outbreakvp = bitand(bits, 0x80000)

    if action == ACTION_Q then
        -- Single Target

        if needspet > 0 then
            return press("7", "raise dead")

        elseif raiseabomination > 0 then
            return press("8", "raise abomination")

        elseif abominationlimb > 0 then
            return press("9", "abomination limb")

        elseif darktransformation > 0 then
            return press("0", "dark transformation")

        elseif unholyassault > 0 then
            return press("-", "unholy assault")

        elseif apocalypse > 0 then
            return press("=", "apocalypse")

        elseif soulreaper > 0 then
            return press("pad7", "soul reaper")

        elseif deathcoil80sd > 0 then
            return press("pad8", "death coil")

        elseif outbreak > 0 then
            return press("f7", "outbreak")

        elseif festeringstrike > 0 then
            return press("f8", "festering strike")

        elseif scourgestrikepb > 0 then
            return press("f9", "scourge strike1")

        elseif deathcoilrot > 0 then
            return press("pad8", "death coil")

        elseif scourgestrike3 > 0 then
            return press("f9", "scourge strike2")

        else
            return press("pad8", "death coil")

        end

    elseif action == ACTION_E then
        -- AOE

        if deathanddecaybuff > 0 then
            -- burst phase

            if scourgestrikepb > 0 then
                return press("f9", "scourge strike3")

            elseif outbreakvp > 0 then
                return press("f7", "outbreak")

            elseif festeringscythe > 0 then
                return press("f8", "festering strike")

            elseif epidemicsd > 0 then
                return press("f10", "epidemic1")

            elseif haswounds > 0 then
                return press("f9", "scourge strike4")

            else
                return press("f10", "epidemic2")
            end
        else
            -- build phase
            if needspet > 0 then
                return press("7", "raise dead")

            elseif scourgestrikepb > 0 then
                return press("f9", "scourge strike5")

            elseif raiseabomination > 0 then
                return press("8", "raise abomination")

            elseif abominationlimb > 0 then
                return press("9", "abomination limb")

            elseif apocalypse > 0 then
                return press("=", "apocalypse")

            elseif darktransformation > 0 then
                return press("0", "dark transformation")

            elseif epidemicsd > 0 then
                return press("f10", "epidemic3")

            elseif unholyassault > 0 then
                return press("-", "unholy assault")

            elseif outbreakvp > 0 then
                return press("f7", "outbreak")

            elseif epidemicrc > 0 then
                return press("f10", "epidemic4")

            elseif deathanddecaybuff == 0 then
                return press("f11", "defile")

            end
        end

    end

    return nil
end

return nextAction
