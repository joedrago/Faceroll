-----------------------------------------------------------------------------------------
-- Outlaw Rogue

local function nextAction(bits)
    local shouldkeepitrolling = bitand(bits, 0x1)
    local shouldrollthebones = bitand(bits, 0x2)
    local adrenalinerushbuff = bitand(bits, 0x4)
    local bladeflurry = bitand(bits, 0x8)
    local ruthlessprecision = bitand(bits, 0x10)
    local subterfuge = bitand(bits, 0x20)
    local stealth = bitand(bits, 0x40)
    local opportunity = bitand(bits, 0x80)
    local audacity = bitand(bits, 0x100)
    local keepitrollingcd = bitand(bits, 0x200)
    local adrenalinerushcd = bitand(bits, 0x400)
    local betweentheeyescd = bitand(bits, 0x800)
    local vanishcd = bitand(bits, 0x1000)
    local rollthebonescd = bitand(bits, 0x2000)
    local cp5 = bitand(bits, 0x4000)
    local cp6 = bitand(bits, 0x8000)

    if facerollAction == ACTION_Q then
        -- Single Target

        if shouldkeepitrolling > 0 and keepitrollingcd > 0 then
            -- Keep It Rolling if you have any 4 active Roll the Bones buffs.
            return "f7" -- keep it rolling

        elseif shouldrollthebones > 0 and rollthebonescd > 0 then
            -- Roll the Bones if you have 2 or fewer buffs if neither consist of
            -- Broadside, Ruthless Precision or True Bearing. Cast ONCE
            -- immediately after using Keep It Rolling.
            return "pad8" -- roll the bones

        elseif adrenalinerushcd > 0 and cp5 == 0 then
            -- Adrenaline Rush on cooldown at 2 or fewer combo points.
            return "pad7" -- adrenaline rush

        elseif stealth == 0 and subterfuge == 0 and vanishcd > 0 and cp6 > 0 and adrenalinerushbuff > 0 then
            -- Vanish followed by Between the Eyes at 6 or more combo points
            -- while Adrenaline Rush is active AND ANY 1 of the following
            -- conditions is met. Adrenaline Rush has 3 or less seconds
            -- remaining. Vanish has 15 seconds remaining on overcapping.
            -- Between the Eyes is on cooldown AND  Ruthless Precision is
            -- active.
            return "=" -- vanish

        elseif betweentheeyescd > 0 and (cp6 > 0 or (cp5 > 0 and subterfuge > 0)) then
            -- Between the Eyes if buff duration is 4 or less seconds, or you
            -- have Ruthless Precision buff active at 6 or more combo points.
            -- During Subterfuge finish at 5 or more as your only finisher.
            return "-" -- between the eyes

        elseif cp6 > 0 then
            -- Dispatch if at 6 or more combo points.
            return "8" -- dispatch

        elseif cp5 == 0 and (audacity > 0 or subterfuge > 0) then
            -- Ambush if you have Audacity, or are in Subterfuge at 4 or less
            -- combo points.
            return "9" -- ambush

        elseif opportunity > 0 and cp5 == 0 then
            --  Pistol Shot if you have Opportunity at 3 or less combo points.
            --  With Broadside active, only cast at 1 or less combo points.
            return "0" -- pistol shot

        elseif cp6 == 0 then
            -- Sinister Strike at 5 or less combo points.
            return "7" -- sinister strike

        end

    elseif facerollAction == ACTION_E then
        -- AOE

        if bladeflurry > 0 then
            -- Blade Flurry if there are 2 or more targets in range, and is not
            -- already active.
            return "f8" -- blade flurry

        elseif shouldkeepitrolling > 0 and keepitrollingcd > 0 then
            -- Keep It Rolling if you have any 4 active Roll the Bones buffs.
            return "f7" -- keep it rolling

        elseif shouldrollthebones > 0 and rollthebonescd > 0 then
            -- Roll the Bones if you have 2 or fewer buffs if neither consist of
            -- Broadside, Ruthless Precision or True Bearing. Cast ONCE
            -- immediately after using Keep It Rolling.
            return "pad8" -- roll the bones

        elseif adrenalinerushcd > 0 and cp5 == 0 then
            -- Adrenaline Rush on cooldown at 2 or fewer combo points.
            return "pad7" -- adrenaline rush

        elseif stealth == 0 and subterfuge == 0 and vanishcd > 0 and cp6 > 0 and adrenalinerushbuff > 0 then
            -- Vanish followed by Between the Eyes at 6 or more combo points
            -- while Adrenaline Rush is active AND ANY 1 of the following
            -- conditions is met. Adrenaline Rush has 3 or less seconds
            -- remaining. Vanish has 15 seconds remaining on overcapping.
            -- Between the Eyes is on cooldown AND  Ruthless Precision is
            -- active.
            return "=" -- vanish

        elseif betweentheeyescd > 0 and (cp6 > 0 or (cp5 > 0 and subterfuge > 0)) then
            -- Between the Eyes if buff duration is 4 or less seconds, or you
            -- have Ruthless Precision buff active at 6 or more combo points.
            -- During Subterfuge finish at 5 or more as your only finisher.
            return "-" -- between the eyes

        elseif cp6 > 0 then
            -- Dispatch if at 6 or more combo points.
            return "8" -- dispatch

        elseif cp5 == 0 and (audacity > 0 or subterfuge > 0) then
            -- Ambush if you have Audacity, or are in Subterfuge at 4 or less
            -- combo points.
            return "9" -- ambush

        elseif opportunity > 0 and cp5 == 0 then
            --  Pistol Shot if you have Opportunity at 3 or less combo points.
            --  With Broadside active, only cast at 1 or less combo points.
            return "0" -- pistol shot

        elseif cp6 == 0 then
            -- Sinister Strike at 5 or less combo points.
            return "7" -- sinister strike
        end
    end
    return nil
end

return nextAction
