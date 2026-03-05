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
    },
    ["Omen of Clarity"] = {
        { rank = 1, level = 20, minTargetLevel = 20, id = 16864 },
    }
}

-- Tracking known ranks
addonTable.KNOWN_RANKS = {}
addonTable.NOTIFIED_UNTRAINED = {}

function addonTable.UpdateKnownRanks()
    local playerLevel = UnitLevel("player")
    -- If playerLevel is 0, we're likely still loading
    if not playerLevel or playerLevel == 0 then return end

    local _, playerClass = UnitClass("player")
    if playerClass ~= "DRUID" then return end

    for spellName, ranks in pairs(addonTable.SPELL_DATA) do
        addonTable.KNOWN_RANKS[spellName] = addonTable.KNOWN_RANKS[spellName] or {}
        for _, data in ipairs(ranks) do
            -- IsSpellKnown is preferred for spells in Classic clients
            local isKnown = C_SpellBook.IsSpellInSpellBook(data.id) or C_SpellBook.IsSpellKnown(data.id)
            if isKnown then
                addonTable.KNOWN_RANKS[spellName][data.rank] = true
            else
                addonTable.KNOWN_RANKS[spellName][data.rank] = false
                -- Notification for untrained ranks (Omen is a talent, no need to notify)
                if spellName ~= "Omen of Clarity" and playerLevel >= data.level and not addonTable.NOTIFIED_UNTRAINED[spellName .. data.rank] then
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
