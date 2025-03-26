-----------------------------------------------------------------------------------------
-- Elemental Shaman

local function nextAction(bits)
    local tempest = bitand(bits, 0x1)
    local enough_maelstrom = bitand(bits, 0x2)
    local flameshock_on_target = bitand(bits, 0x4)
    local stormkeeper = bitand(bits, 0x8)

    if facerollAction == ACTION_Q then
        -- Single Target

        if stormkeeper > 0 then
            return "=" -- stormkeeper

        elseif flameshock_on_target == 0 then
            return "-" -- flame shock

        elseif enough_maelstrom > 0 then
            return "0" -- earth shock

        else
            return "7" -- lightning bolt
        end

    elseif facerollAction == ACTION_E then
        -- AOE

        if stormkeeper > 0 then
            return "=" -- stormkeeper

        elseif tempest > 0 then
            return "7" -- "tempest" (its actually just lightning bolt)

        elseif enough_maelstrom > 0 then
            return "9" -- earthquake

        else
            return "8" -- chain lightning
        end
    end
    return nil
end

return nextAction
