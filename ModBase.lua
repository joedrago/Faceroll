if Faceroll == nil then
    _, Faceroll = ...
end

Faceroll.hold = false

-----------------------------------------------------------------------------------------
-- Debug Overlay Shenanigans

Faceroll.debug = false
Faceroll.debugOverlay = nil

Faceroll.setDebugText = function(text)
    if Faceroll.debug and Faceroll.debugOverlay ~= nil then
        Faceroll.debugOverlay:setText(text)
    end
end

Faceroll.debugInit = function()
    if Faceroll.debug then
        Faceroll.debugOverlay = Faceroll.createFrame(300, 300,                  -- size
                                                     "TOPLEFT", 0, 0,           -- position
                                                     "TOOLTIP", 0.9,            -- strata/alpha
                                                     "TOPLEFT", "firamono", 13) -- text
    end
end

-----------------------------------------------------------------------------------------
-- Helpers

Faceroll.textColor = function(text, color)
    return "\124cff" .. color .. text .. "\124r"
end

-----------------------------------------------------------------------------------------
-- Buff Tracking

local buffs = {}

Faceroll.trackBuffs = function(newBuffs)
    for _, name in ipairs(newBuffs) do
        buffs[name] = { ["name"]=name }
        buffs[name].id = 0
        buffs[name].remain = false
        buffs[name].cto = false
        buffs[name].expirationTime = 0
        buffs[name].stacks = 0
    end
end

Faceroll.resetBuffs = function()
    print("Faceroll: Reset Buffs")
    for _, buff in pairs(buffs) do
        buff.id = 0
        buff.remain = false
        buff.cto = false
        buff.expirationTime = 0
        buff.stacks = 0
    end
end

Faceroll.getBuff = function(buffName)
    return buffs[buffName]
end

Faceroll.isBuffActive = function(buffName)
    if buffs[buffName].id ~= 0 then
        return true
    end
    return false
end

Faceroll.getBuffStacks = function(buffName)
    if buffs[buffName].id ~= 0 then
        return buffs[buffName].stacks
    end
    return 0
end

Faceroll.getBuffRemaining = function(buffName)
    if buffs[buffName].id ~= 0 then
        local remaining = math.max(buffs[buffName].expirationTime - GetTime(), 0)
        return remaining
    end
    return 0
end

Faceroll.spellCharges = function(spellName)
    local chargeInfo = C_Spell.GetSpellCharges(spellName)
    if chargeInfo == nil then
        return 0
    end
    return chargeInfo.currentCharges
end

Faceroll.spellCooldown = function(spellName)
    local cd = C_Spell.GetSpellCooldown(spellName)
    if cd == nil then
        return 0
    end
    local duration = cd.duration
    if duration > 0 then
        local since = GetTime() - cd.startTime
        return duration - since
    end
    return 0
end

Faceroll.spellChargesSoon = function(spellName, count, seconds)
    local chargeInfo = C_Spell.GetSpellCharges(spellName)
    if chargeInfo == nil then
        return false
    end
    if chargeInfo.currentCharges < count - 1 then
        return false
    end
    if Faceroll.spellCooldown(spellName) > seconds then
        return false
    end
    return true
end

Faceroll.isSpellAvailable = function(spellName)
    if not C_Spell.IsSpellUsable(spellName) then
        return false
    end
    if C_Spell.GetSpellCooldown(spellName).duration > 1.5 then
        return false
    end
    return true
end

Faceroll.isDotActive = function(spellName)
    local name, _, _, _, fullDuration, expirationTime = AuraUtil.FindAuraByName(spellName, "target", "HARMFUL|PLAYER")
    if name ~= nil and fullDuration > 0 then
        local remainingDuration = expirationTime - GetTime()
        local normalizedDuration = remainingDuration / fullDuration
        if normalizedDuration < 0 then
            normalizedDuration = 0
        end
        return normalizedDuration
    end
    return -1
end

Faceroll.dotStacks = function(spellName)
    local name, _, stacks, _, fullDuration, expirationTime = AuraUtil.FindAuraByName(spellName, "target", "HARMFUL|PLAYER")
    if name ~= nil and fullDuration > 0 then
        return stacks
    end
    return 0
end

Faceroll.isHotActive = function(spellName, target)
    local name, _, _, _, fullDuration, expirationTime = AuraUtil.FindAuraByName(spellName, target, "HELPFUL")
    if name ~= nil and fullDuration > 0 then
        local remainingDuration = expirationTime - GetTime()
        local normalizedDuration = remainingDuration / fullDuration
        if normalizedDuration < 0 then
            normalizedDuration = 0
        end
        return normalizedDuration
    end
    return -1
end

-- Spellcasting "dead zones", aka windows of time where we should consider this spell unavailable/dead
-- This is useful for when we don't want to cast a spell *twice* but we don't know we shouldn't
-- press it until some dot appears or travel time finishes, etc.
-- WARNING: be sure to use /frkick in the macro for the spell you're trying to put in a deadzone!
Faceroll.deadzoneCreate = function(spellName, normalizedCastTimeRemaining, deadzoneDuration)
    return {
        ["spellName"]=spellName,
        ["castTimeRemaining"]=normalizedCastTimeRemaining,
        ["duration"]=deadzoneDuration,
        ["endTime"]=0,
    }
end

-- Safe to call any time
Faceroll.deadzoneActive = function(deadzone)
    return (deadzone.endTime > GetTime())
end

-- Only call this when all other state means you're interested in *starting* the deadzone,
-- e.g. you're trying to only cast Wrath twice to proc Eclipse and the wrath count has 1 left
Faceroll.deadzoneUpdate = function(deadzone)
    local castingSpell, _, _, _, castingSpellEndTime = UnitCastingInfo("player")
    local castingSpellDone = 0
    if castingSpell then
        castingSpellDone = castingSpellEndTime / 1000 - GetTime()
        -- print("castingSpell " .. castingSpell .. " castingSpellDone " .. castingSpellDone)
    end
    if castingSpell == deadzone.spellName and castingSpellDone < deadzone.castTimeRemaining then
        deadzone.endTime = GetTime() + deadzone.duration
    end
    return Faceroll.deadzoneActive(deadzone)
end

-----------------------------------------------------------------------------------------
-- Buff Events

-- HACK: Roll The Bones tracking -- I haven't figured out if/how I want to move
-- this tracking to FacerollSpecOUT.lua yet, but for now, we'll just have it here.
-- It is harmless to track for other specs.
Faceroll.rtbStart = 0
Faceroll.rtbEnd = 0
Faceroll.rtbDelay = 0.1
Faceroll.rtbNeedsAPressAfterKIR = false

Faceroll.onPlayerAura = function(info)
    if info.addedAuras then
        for _, aura in pairs(info.addedAuras) do
            for _, buff in pairs(buffs) do
                if aura.name == buff.name then
                    -- print("Detected: " .. buff.name)
                    if buff.harmful then
                        if aura.isHarmful then
                            buff.id = aura.auraInstanceID
                        end
                    else
                        buff.id = aura.auraInstanceID
                        buff.expirationTime = aura.expirationTime
                        buff.stacks = aura.applications

                        local auraRemaining = aura.expirationTime - GetTime()
                        local rtbRemaining = math.max(Faceroll.rtbEnd - GetTime(), 0)
                        buff.remain = auraRemaining > rtbRemaining + Faceroll.rtbDelay
                        buff.cto = rtbRemaining > auraRemaining + Faceroll.rtbDelay
                    end
                end
            end
        end
    end

    if info.updatedAuraInstanceIDs then
		for _, v in pairs(info.updatedAuraInstanceIDs) do
			local aura = C_UnitAuras.GetAuraDataByAuraInstanceID("player", v)
            if aura ~= nil then
                for _, buff in pairs(buffs) do
                    if aura.name == buff.name then
                        buff.id = aura.auraInstanceID
                        buff.expirationTime = aura.expirationTime
                        buff.stacks = aura.applications

                        local auraRemaining = aura.expirationTime - GetTime()
                        local rtbRemaining = math.max(Faceroll.rtbEnd - GetTime(), 0)
                        buff.remain = auraRemaining > rtbRemaining + Faceroll.rtbDelay
                        buff.cto = rtbRemaining > auraRemaining + Faceroll.rtbDelay
                    end
                end
            end
        end
	end

	if info.removedAuraInstanceIDs then
		for _, id in pairs(info.removedAuraInstanceIDs) do
            for _, buff in pairs(buffs) do
                if buff.id == id then
                    -- print("Lost: " .. buff.name)
                    buff.id = 0
                    buff.expirationTime = 0
                    buff.stacks = 0
                    buff.remain = false
                    buff.cto = false
                end
            end
        end
	end
end

-- HACK: Hammer of Light tracking. I really should move this and RtB to their
-- proper places. This is ugly.
Faceroll.holExpirationTime = 0

Faceroll.onPlayerSpellEvent = function(spellEvent, spellID)
    if spellEvent == "SPELL_AURA_REMOVED" and spellID == 433674 then
        -- free cast from Light's Deliverance
        Faceroll.holExpirationTime = GetTime() + 20
    elseif spellEvent == "SPELL_CAST_SUCCESS" then
        if spellID == 255937 then
            -- regular cast from wake of the ashes
            Faceroll.holExpirationTime = GetTime() + 20
        elseif spellEvent == "SPELL_CAST_SUCCESS" then
            if spellID == 387174 then
                -- regular cast from wake of the ashes
                Faceroll.holExpirationTime = GetTime() + 20
            elseif spellID == 429826 or spellID == 427453 then
                -- hide on Hammer of Light cast
                Faceroll.holExpirationTime = 0
            end
        end
    end

    if spellID == 381989 then -- keep it rolling
        if spellEvent == "SPELL_CAST_SUCCESS" then
            -- print("Keep it rolling! - " .. spellEvent)
            Faceroll.rtbNeedsAPressAfterKIR = true
        end
    elseif spellID == 315508 then -- roll the bones
        if spellEvent == "SPELL_CAST_SUCCESS" then
            -- print("Roll the bones! - " .. spellEvent)
            Faceroll.rtbNeedsAPressAfterKIR = false
        elseif spellEvent == "SPELL_AURA_APPLIED" then
            Faceroll.rtbStart = GetTime()
            Faceroll.rtbEnd = Faceroll.rtbStart + 30
        elseif spellEvent == "SPELL_AURA_REFRESH" then
            Faceroll.rtbStart = GetTime()
            Faceroll.rtbEnd = 30 + Faceroll.rtbStart + math.min(Faceroll.rtbEnd - Faceroll.rtbStart, 9)
        elseif spellEvent == "SPELL_AURA_REMOVED" then
            Faceroll.rtbStart = 0
            Faceroll.rtbEnd = 0
        end
    end
end
