local addonName, addonTable = ...

-- Configuration: Level requirements for TBC Spells
-- minTargetLevel is max(1, level - 10) based on Classic/TBC rules
addonTable.SPELL_DATA = {
    ["Mark of the Wild"] = {
        { rank = 8, level = 70, minTargetLevel = 60, id = 26990 },
        { rank = 7, level = 60, minTargetLevel = 50, id = 9885 },
        { rank = 6, level = 50, minTargetLevel = 40, id = 9884 },
        { rank = 5, level = 40, minTargetLevel = 30, id = 8907 },
        { rank = 4, level = 30, minTargetLevel = 20, id = 5234 },
        { rank = 3, level = 20, minTargetLevel = 10, id = 6756 },
        { rank = 2, level = 10, minTargetLevel = 1,  id = 5232 },
        { rank = 1, level = 1,  minTargetLevel = 1,  id = 1126 },
    },
    ["Thorns"] = {
        { rank = 7, level = 64, minTargetLevel = 54, id = 26992 },
        { rank = 6, level = 54, minTargetLevel = 44, id = 9910 },
        { rank = 5, level = 44, minTargetLevel = 34, id = 9756 },
        { rank = 4, level = 34, minTargetLevel = 24, id = 8914 },
        { rank = 3, level = 24, minTargetLevel = 14, id = 1075 },
        { rank = 2, level = 14, minTargetLevel = 4,  id = 782 },
        { rank = 1, level = 6,  minTargetLevel = 1,  id = 467 },
    }
}

-- Tracking known ranks
addonTable.KNOWN_RANKS = {}
addonTable.NOTIFIED_UNTRAINED = {}

function addonTable.IsSecretValue(val)
    return issecretvalue and issecretvalue(val) or false
end

function addonTable.IsSpellKnown(spellId)
    if C_Spell and C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(spellId) then
        return false
    end
    if C_SpellBook then
        if C_SpellBook.IsSpellInSpellBook and C_SpellBook.IsSpellInSpellBook(spellId) then
            return true
        end
        if C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(spellId) then
            return true
        end
        if C_SpellBook.IsSpellKnownOrInSpellBook and C_SpellBook.IsSpellKnownOrInSpellBook(spellId) then
            return true
        end
    end
    if IsPlayerSpell and IsPlayerSpell(spellId) then
        return true
    end
    if IsSpellKnown and IsSpellKnown(spellId) then
        return true
    end
    return false
end

function addonTable.GetSpellCooldown(spell)
    if C_Spell and C_Spell.GetSpellCooldown then
        local ok, info = pcall(C_Spell.GetSpellCooldown, spell)
        if ok and info and not addonTable.IsSecretValue(info) then
            local start = info.startTime
            local duration = info.duration
            local enabled = info.isEnabled
            if addonTable.IsSecretValue(start) or addonTable.IsSecretValue(duration) or addonTable.IsSecretValue(enabled) then
                return 0, 0, 0
            end
            return start or 0, duration or 0, (enabled and 1 or 0)
        end
        return 0, 0, 0
    elseif GetSpellCooldown then
        local start, duration, enabled = GetSpellCooldown(spell)
        if addonTable.IsSecretValue(start) or addonTable.IsSecretValue(duration) or addonTable.IsSecretValue(enabled) then
            return 0, 0, 0
        end
        return start or 0, duration or 0, (enabled == true and 1 or enabled or 0)
    end
    return 0, 0, 0
end

function addonTable.IsSpellInRange(spellName, unit)
    if unit == "player" then return true end
    if C_Spell and C_Spell.IsSpellInRange then
        local ok, inRange = pcall(C_Spell.IsSpellInRange, spellName, unit)
        if ok and not addonTable.IsSecretValue(inRange) and inRange ~= nil then
            return inRange == true or inRange == 1
        end
    elseif IsSpellInRange then
        local inRange = IsSpellInRange(spellName, unit)
        if not addonTable.IsSecretValue(inRange) and inRange ~= nil then
            return inRange == 1 or inRange == true
        end
    end
    if UnitInRange then
        local inRange = UnitInRange(unit)
        if not addonTable.IsSecretValue(inRange) then
            return inRange == true or inRange == 1
        end
    end
    return false
end

function addonTable.GetUnitBuffInfo(unit, index)
    if C_Secrets and C_Secrets.ShouldUnitAuraIndexBeSecret and C_Secrets.ShouldUnitAuraIndexBeSecret(unit, index, "HELPFUL") then
        return nil, nil, nil, true
    end
    if C_UnitAuras and (C_UnitAuras.GetBuffDataByIndex or C_UnitAuras.GetAuraDataByIndex) then
        local aura
        if C_UnitAuras.GetBuffDataByIndex then
            aura = C_UnitAuras.GetBuffDataByIndex(unit, index)
        else
            aura = C_UnitAuras.GetAuraDataByIndex(unit, index, "HELPFUL")
        end
        if not aura then
            return nil, nil, nil, false
        end
        if addonTable.IsSecretValue(aura) or addonTable.IsSecretValue(aura.name) then
            return nil, nil, nil, true
        end
        local duration = not addonTable.IsSecretValue(aura.duration) and aura.duration or 0
        local expirationTime = not addonTable.IsSecretValue(aura.expirationTime) and aura.expirationTime or 0
        return aura.name, duration, expirationTime, false
    elseif UnitBuff then
        local name, _, _, _, duration, expirationTime = UnitBuff(unit, index)
        if not name then
            return nil, nil, nil, false
        end
        if addonTable.IsSecretValue(name) then
            return nil, nil, nil, true
        end
        return name, duration, expirationTime, false
    elseif UnitAura then
        local name, _, _, _, duration, expirationTime = UnitAura(unit, index, "HELPFUL")
        if not name then
            return nil, nil, nil, false
        end
        if addonTable.IsSecretValue(name) then
            return nil, nil, nil, true
        end
        return name, duration, expirationTime, false
    end
    return nil, nil, nil, false
end

function addonTable.UpdateKnownRanks()
    local playerLevel = UnitLevel("player")
    -- If playerLevel is 0, we're likely still loading
    if not playerLevel or addonTable.IsSecretValue(playerLevel) or playerLevel == 0 then return end

    local _, playerClass = UnitClass("player")
    if playerClass ~= "DRUID" then return end

    for spellName, ranks in pairs(addonTable.SPELL_DATA) do
        addonTable.KNOWN_RANKS[spellName] = addonTable.KNOWN_RANKS[spellName] or {}
        for _, data in ipairs(ranks) do
            -- IsSpellKnown is preferred for spells in Classic clients
            local isKnown = addonTable.IsSpellKnown(data.id)
            if isKnown then
                addonTable.KNOWN_RANKS[spellName][data.rank] = true
            else
                addonTable.KNOWN_RANKS[spellName][data.rank] = false
                -- Notification for untrained ranks
                if playerLevel >= data.level and not addonTable.NOTIFIED_UNTRAINED[spellName .. data.rank] then
                    local nameDisplay = spellName .. " (Rank " .. data.rank .. ")"
                    print("|cFFFFFF00[DruidBuff]|r You can train |cFF00FF00" .. nameDisplay .. "|r at your level!")
                    addonTable.NOTIFIED_UNTRAINED[spellName .. data.rank] = true
                end
            end
        end
    end
end

-- Setup global event monitor for the core data
local coreFrame = CreateFrame("Frame")
coreFrame:RegisterEvent("SPELLS_CHANGED")
coreFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
coreFrame:SetScript("OnEvent", function(self, event)
    addonTable.UpdateKnownRanks()
    if addonTable.UpdateActionBarLayout then addonTable.UpdateActionBarLayout() end
end)

-- Initial call
addonTable.UpdateKnownRanks()
