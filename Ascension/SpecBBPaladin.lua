-----------------------------------------------------------------------------------------
-- Ascension WoW Bronzebeard Paladin

if Faceroll == nil then
    _, Faceroll = ...
end

local spec = Faceroll.createSpec("PAL", "975774", "PALADIN-ASCENSION")

spec.melee = "Crusader Strike"

local availableBuffs = {}
availableBuffs.m = {["name"]="Blessing of Might",  ["key"]="might"}
availableBuffs.w = {["name"]="Blessing of Wisdom", ["key"]="wisdom"}
availableBuffs.k = {["name"]="Blessing of Kings", ["key"]="kings"}

local partyBuffsRequested = nil
local partyBuffSeen = {}
local function partyBuffSeenCount()
    local count = 0
    for k,v in pairs(partyBuffSeen) do
        count = count + 1
    end
    return count
end

local function everyoneBuffed()
    if partyBuffsRequested == nil then
        -- no buffs configured
        return true
    end

    local countSeen = partyBuffSeenCount()
    if countSeen > 0 and ((countSeen+1) == GetNumGroupMembers()) then
        return true
    end
    return false
end

local function targetIsPartyMember()
    for i = 1,4 do
        if UnitIsUnit("target", "party" .. i) == 1 then
            return true
        end
    end
    return false
end

local function requestedBuff(unitIndex)
    if partyBuffsRequested == nil then
        return nil
    end

    local reqCount = #partyBuffsRequested
    if unitIndex < 1 or unitIndex > reqCount then
        return nil
    end

    local buff = availableBuffs[partyBuffsRequested[unitIndex]]
    if buff == nil then
        return nil
    end
    return buff
end

spec.setOption = function(raw)
    partyBuffSeen = {}
    if strlenutf8(raw) == 0 then
        partyBuffsRequested = nil
        print("Disabling party buffs.")
        return
    end

    partyBuffsRequested = { strsplit(" ", raw) }
    for i, v in ipairs(partyBuffsRequested) do
        local unitName = UnitName("party" .. i)
        if unitName ~= nil then
            local buff = availableBuffs[v]
            local buffName = "(Ignore)"
            if buff ~= nil then
                buffName = buff.name
            end
            print(" * " .. Faceroll.textColor(unitName, "ffffaa") .. " -> " .. Faceroll.textColor(buffName, "aaffaa"))
        end
    end
end

-----------------------------------------------------------------------------------------
-- States

spec.overlay = Faceroll.createOverlay({
    "- Resources -",
    "selfheal",
    "group",
    "allbuffed",

    "- Buffs -",
    "sealcommand",
    "sealrighteousness",
    "blessing",

    "- Spells -",
    "crusaderstrike",
    "judgement",
    "hand",
    "consecration",
})

local healDeadzone = Faceroll.deadzoneCreate("Holy Light", 1.5, 0.5)

spec.calcState = function(state)
    if Faceroll.combatJustEnded then
        partyBuffSeen = {}
    end
    state.allbuffed = everyoneBuffed()

    -- Resources --
    Faceroll.deadzoneUpdate(healDeadzone)
    local curHP = UnitHealth("player")
    local maxHP = UnitHealthMax("player")
    local norHP = curHP / maxHP
    if Faceroll.hasManaForSpell("Holy Light") and not Faceroll.deadzoneActive(healDeadzone) then
        state.selfheal = true
    end
    state.normHP = norHP
    if IsInGroup() then
        state.group = true
    end

    -- Buffs --

    if Faceroll.isBuffActive("Seal of Command") then
        state.sealcommand = true
    end
    if Faceroll.isBuffActive("Seal of Righteousness") then
        state.sealrighteousness = true
    end
    if Faceroll.isBuffActive("Blessing of Wisdom") then
        state.blessing = true
    end

    -- if Faceroll.isBuffActive("Arcane Intellect") or Faceroll.isBuffActive("Arcane Brilliance") then
    --     state.arcaneintellect = true
    -- end
    -- if Faceroll.isBuffActive("Drink") then
    --     state.drink = true
    -- end
    -- if Faceroll.getBuffRemaining("Drink") < 4 then
    --     state.drinkending = true
    -- end
    -- if Faceroll.isBuffActive("Ice Barrier") then
    --     state.icebarrier = true
    -- end

    -- Spells --

    if Faceroll.isSpellAvailable("Crusader Strike") then
        state.crusaderstrike = true
    end
    if Faceroll.isSpellAvailable("Judgement of Light") then
        state.judgement = true
    end
    if Faceroll.isSpellAvailable("Hand of Reckoning") then
        state.hand = true
    end
    if Faceroll.isSpellAvailable("Consecration") then
        state.consecration = true
    end

    return state
end

-----------------------------------------------------------------------------------------
-- Actions

spec.actions = {
    "might",
    "wisdom",
    "kings",
    "sealcommand",
    "sealrighteousness",
    "crusaderstrike",
    "judgement",
    "hand",
    "consecration",
    "targetparty",
    "heal",
}

spec.calcAction = function(mode, state)
    -- local st = (mode == Faceroll.MODE_ST)
    local aoe = (mode == Faceroll.MODE_AOE)

    -- ((state.combat and (state.normHP <= 0.5)) or
    if state.selfheal and (not state.combat and (state.normHP <= 0.7)) then
        return "heal"

    elseif not state.sealcommand then
        return "sealcommand"
    -- elseif not state.sealrighteousness then
    --     return "sealrighteousness"

    elseif not state.blessing then
        return "wisdom"

    elseif state.targetingenemy then
            if not state.combat and not state.group and state.hand then
                return "hand"

            elseif aoe and state.consecration then
                return "consecration"

            elseif state.judgement then
                return "judgement"

            else
                return "crusaderstrike"
            end
        -- end

    elseif not state.combat and state.group and everyoneBuffed() and targetIsPartyMember() then
        return nil

    elseif not state.combat and state.group and not everyoneBuffed() then
        -- buff teammates
        local unitIndex = 0
        for i = 1,4 do
            if (unitIndex == 0) and (UnitIsUnit("target", "party" .. i) == 1) then
                unitIndex = i
            end
        end
        if unitIndex > 0 then
            local unit = "party" .. unitIndex
            local reqBuff = requestedBuff(unitIndex)
            if reqBuff == nil then
                print("Unit " .. unit .. " does not want a buff.")
                partyBuffSeen[unit] = true
                if everyoneBuffed() then
                    print("I've buffed everyone.")
                    return nil
                end
            else
                local aura = Faceroll.ascensionFindAura(unit, reqBuff.name, "HELPFUL")
                if aura == nil then
                    -- print("Unit " .. unit .. " NEEDS " .. reqBuff.name .. " (" .. reqBuff.key .. ")")
                    return reqBuff.key
                else
                    -- print("Unit " .. unit .. " already has " .. reqBuff.name .. " (" .. reqBuff.key .. ")")
                    partyBuffSeen[unit] = true

                    if everyoneBuffed() then
                        print("I've buffed everyone.")
                        return nil
                    end
                    return "targetparty"
                end
            end
        else
            return "targetparty"
        end
    end

    return nil
end
