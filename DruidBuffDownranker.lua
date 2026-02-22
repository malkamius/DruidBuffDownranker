-- Configuration: Level requirements for TBC Spells
-- minTargetLevel is max(1, level - 10) based on Classic/TBC rules
local SPELL_DATA = {
    ["Mark of the Wild"] = {
        {rank = 8, level = 70, minTargetLevel = 60, id = 26990},
        {rank = 7, level = 60, minTargetLevel = 50, id = 9885},
        {rank = 6, level = 50, minTargetLevel = 40, id = 9884},
        {rank = 5, level = 40, minTargetLevel = 30, id = 8907},
        {rank = 4, level = 30, minTargetLevel = 20, id = 5234},
        {rank = 3, level = 20, minTargetLevel = 10, id = 6756},
        {rank = 2, level = 10, minTargetLevel = 1,  id = 5232},
        {rank = 1, level = 1,  minTargetLevel = 1,  id = 1126},
    },
    ["Thorns"] = {
        {rank = 7, level = 64, minTargetLevel = 54, id = 26992},
        {rank = 6, level = 54, minTargetLevel = 44, id = 9910},
        {rank = 5, level = 44, minTargetLevel = 34, id = 9756},
        {rank = 4, level = 34, minTargetLevel = 24, id = 8914},
        {rank = 3, level = 24, minTargetLevel = 14, id = 1075},
        {rank = 2, level = 14, minTargetLevel = 4,  id = 782},
        {rank = 1, level = 6,  minTargetLevel = 1,  id = 467},
    }
}

-- Tracking known ranks
local KNOWN_RANKS = {}
local NOTIFIED_UNTRAINED = {}

local function UpdateKnownRanks()
    local playerLevel = UnitLevel("player")
    -- If playerLevel is 0, we're likely still loading
    if not playerLevel or playerLevel == 0 then return end
    
    for spellName, ranks in pairs(SPELL_DATA) do
        KNOWN_RANKS[spellName] = KNOWN_RANKS[spellName] or {}
        for _, data in ipairs(ranks) do
            -- IsSpellKnown is preferred for spells in Classic clients
            local isKnown = IsSpellKnown(data.id) or IsPlayerSpell(data.id)
            if isKnown then
                KNOWN_RANKS[spellName][data.rank] = true
            else
                KNOWN_RANKS[spellName][data.rank] = false
                -- Notification for untrained ranks
                if playerLevel >= data.level and not NOTIFIED_UNTRAINED[spellName .. data.rank] then
                    print("|cFFFFFF00[DruidBuff]|r You can train |cFF00FF00" .. spellName .. " (Rank " .. data.rank .. ")|r at your level!")
                    NOTIFIED_UNTRAINED[spellName .. data.rank] = true
                end
            end
        end
    end
end

-- Settings State
local DruidBuffSettings = {
    ["Mark of the Wild"] = { mouseover = true },
    ["Thorns"] = { mouseover = true }
}

-- --- KEYBINDING LOCALIZATION ---
_G["BINDING_HEADER_DRUIDBUFFDR_HEADER"] = "Druid Buff Downranker"
_G["BINDING_NAME_CLICK SmartMotW:LeftButton"] = "Cast Smart MotW"
_G["BINDING_NAME_CLICK SmartThorns:LeftButton"] = "Cast Smart Thorns"

-- Create the Container Frame
local bar = CreateFrame("Frame", "DruidBuffBar", UIParent)
bar:SetSize(90, 45)
bar:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
bar:SetMovable(true)
bar:EnableMouse(true)
bar:SetClampedToScreen(true)
bar:RegisterForDrag("LeftButton")

bar.bg = bar:CreateTexture(nil, "BACKGROUND")
bar.bg:SetAllPoints()
bar.bg:SetColorTexture(0, 0, 0, 0.3)

bar:SetScript("OnDragStart", function(self) 
    if IsShiftKeyDown() then self:StartMoving() end 
end)
bar:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

-- --- OPTIONS PANEL HIERARCHY SETUP (Modern Settings API) ---

-- 1. Create the Main Parent Category (Druid)
local druidCategoryFrame = CreateFrame("Frame", "DruidBuffDownranker_DruidParent", UIParent)
druidCategoryFrame.name = "Druid"

local parentTitle = druidCategoryFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
parentTitle:SetPoint("TOPLEFT", 16, -16)
parentTitle:SetText("Druid Addon Collection")

local druidCategory = Settings.RegisterCanvasLayoutCategory(druidCategoryFrame, "Druid")
Settings.RegisterAddOnCategory(druidCategory)

-- 2. Create the Sub-Category (BuffDownranker)
local optionsFrame = CreateFrame("Frame", "DruidBuffDownrankerOptions", UIParent)
optionsFrame.name = "BuffDownranker"

local title = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Druid Buff Downranker Settings")

local function CreateToggle(spellName, yOffset)
    local cb = CreateFrame("CheckButton", "DruidBuffCheck_"..spellName:gsub("%s+", ""), optionsFrame, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 16, yOffset)
    local cbText = _G[cb:GetName().."Text"]
    if cbText then cbText:SetText("Enable Mouseover for "..spellName) end
    cb:SetChecked(DruidBuffSettings[spellName].mouseover)
    cb:SetScript("OnClick", function(self)
        DruidBuffSettings[spellName].mouseover = self:GetChecked()
    end)
    return cb
end

CreateToggle("Mark of the Wild", -50)
CreateToggle("Thorns", -80)

-- Using RegisterCanvasLayoutSubcategory is the correct way to handle nesting in modern WoW/TBC Classic
local subCategory = Settings.RegisterCanvasLayoutSubcategory(druidCategory, optionsFrame, "BuffDownranker")

-- --- BUTTON LOGIC ---
local function UpdateButtonRank(btn)
    if InCombatLockdown() then return end

    local spellName = btn.baseSpell
    local unit = "player"
    
    if DruidBuffSettings[spellName].mouseover and UnitExists("mouseover") then
        unit = "mouseover"
    elseif UnitExists("target") then
        unit = "target"
    end
    
    local targetLevel = UnitLevel(unit)
    local rankText = ""

    if targetLevel and targetLevel > 0 then
        local ranks = SPELL_DATA[spellName]
        for _, data in ipairs(ranks) do
            -- Selection logic:
            -- 1. We must know the rank (trained)
            -- 2. Target must meet the minimum level requirement for that rank
            if KNOWN_RANKS[spellName] and KNOWN_RANKS[spellName][data.rank] then
                if targetLevel >= data.minTargetLevel then
                    rankText = "(Rank " .. data.rank .. ")"
                    break
                end
            end
        end
    end

    local macroText = "/cast [@" .. unit .. ",exists][@player] " .. spellName .. rankText
    btn:SetAttribute("macrotext", macroText)
    btn:SetAttribute("macrotext1", macroText)
    btn._lastDesc = spellName .. rankText .. " on " .. (UnitName(unit) or "Self")
end

local function CreateBuffButton(name, spellName, icon, parent, xOffset)
    local btn = CreateFrame("Button", name, parent, "SecureActionButtonTemplate")
    btn:SetSize(40, 40)
    btn:SetPoint("LEFT", parent, "LEFT", xOffset + 2, 0)
    btn.baseSpell = spellName

    btn.tex = btn:CreateTexture(nil, "BACKGROUND")
    btn.tex:SetAllPoints()
    btn.tex:SetTexture(icon)
    btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")

    btn:RegisterForClicks("LeftButtonDown", "AnyDown")
    btn:SetAttribute("type", "macro")

    btn:SetScript("OnEvent", function(self, event) 
        if event == "SPELLS_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
            UpdateKnownRanks()
        end
        UpdateButtonRank(self) 
    end)
    btn:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    btn:RegisterEvent("PLAYER_TARGET_CHANGED")
    btn:RegisterEvent("PLAYER_REGEN_ENABLED")
    btn:RegisterEvent("UNIT_TARGET")
    btn:RegisterEvent("SPELLS_CHANGED")
    btn:RegisterEvent("PLAYER_ENTERING_WORLD")

    btn:SetScript("PreClick", function(self)
        UpdateButtonRank(self)
        if RaidWarningFrame then
            RaidNotice_AddMessage(RaidWarningFrame, "[DruidBuff] " .. self._lastDesc, ChatTypeInfo["RAID_WARNING"])
        end
    end)

    UpdateButtonRank(btn)
    return btn
end

-- Initial call to populate known ranks
UpdateKnownRanks()

local motwBtn = CreateBuffButton("SmartMotW", "Mark of the Wild", "Interface\\Icons\\Spell_Nature_Regeneration", bar, 0)
local thornsBtn = CreateBuffButton("SmartThorns", "Thorns", "Interface\\Icons\\Spell_Nature_Thorns", bar, 45)

print("|cFF00FF00DruidBuffDownranker Loaded!|r Settings: Options > Addons > Druid > BuffDownranker")