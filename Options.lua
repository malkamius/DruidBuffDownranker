local addonName, addonTable = ...

-- Settings State Initialization
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, arg1)
    if arg1 == addonName then
        DruidBuffSettings = DruidBuffSettings or {
            ["Mark of the Wild"] = { mouseover = true, show = true },
            ["Thorns"] = { mouseover = true, show = true },
            ["Omen of Clarity"] = { show = true },
            showActionBar = true,
            showSmartActionBar = true
        }
        self:UnregisterEvent("ADDON_LOADED")
        -- Trigger initial layout renders if they are loaded
        if addonTable.UpdateActionBarLayout then addonTable.UpdateActionBarLayout() end
        if addonTable.UpdateSmartBarVisibility then addonTable.UpdateSmartBarVisibility() end
    end
end)

-- --- KEYBINDING LOCALIZATION ---
_G["BINDING_HEADER_DRUIDBUFFDR_HEADER"] = "Druid Buff Downranker"
_G["BINDING_NAME_CLICK SmartMotW:LeftButton"] = "Cast Smart MotW"
_G["BINDING_NAME_CLICK SmartThorns:LeftButton"] = "Cast Smart Thorns"
_G["BINDING_NAME_CLICK SmartOmen:LeftButton"] = "Cast Smart Omen"
_G["BINDING_NAME_CLICK SmartBuffAutoBtn:LeftButton"] = "Cast Smart Auto Buff"

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

local function CreateToggle(spellName, yOffset, hasMouseover)
    local cbShow = CreateFrame("CheckButton", "DruidBuffCheck_Show_"..spellName:gsub("%s+", ""), optionsFrame, "InterfaceOptionsCheckButtonTemplate")
    cbShow:SetPoint("TOPLEFT", 16, yOffset)
    _G[cbShow:GetName().."Text"]:SetText("Show "..spellName)
    
    cbShow:SetScript("OnShow", function(self)
        self:SetChecked(DruidBuffSettings and DruidBuffSettings[spellName].show or false)
    end)
    
    cbShow:SetScript("OnClick", function(self)
        if DruidBuffSettings then
            DruidBuffSettings[spellName].show = self:GetChecked()
            if addonTable.UpdateActionBarLayout then addonTable.UpdateActionBarLayout() end
        end
    end)
    
    if hasMouseover then
        local cbMouse = CreateFrame("CheckButton", "DruidBuffCheck_Mouse_"..spellName:gsub("%s+", ""), optionsFrame, "InterfaceOptionsCheckButtonTemplate")
        cbMouse:SetPoint("TOPLEFT", 180, yOffset)
        _G[cbMouse:GetName().."Text"]:SetText("Enable Mouseover")
        
        cbMouse:SetScript("OnShow", function(self)
            self:SetChecked(DruidBuffSettings and DruidBuffSettings[spellName].mouseover or false)
        end)
        
        cbMouse:SetScript("OnClick", function(self)
            if DruidBuffSettings then
                DruidBuffSettings[spellName].mouseover = self:GetChecked()
            end
        end)
    end
end

CreateToggle("Mark of the Wild", -50, true)
CreateToggle("Thorns", -80, true)
CreateToggle("Omen of Clarity", -110, false)

local showBarToggle = CreateFrame("CheckButton", "DruidBuffCheck_ShowActionBar", optionsFrame, "InterfaceOptionsCheckButtonTemplate")
showBarToggle:SetPoint("TOPLEFT", 16, -150)
_G[showBarToggle:GetName().."Text"]:SetText("Show Action Bar")
showBarToggle:SetScript("OnShow", function(self)
    self:SetChecked(DruidBuffSettings and DruidBuffSettings.showActionBar or false)
end)
showBarToggle:SetScript("OnClick", function(self)
    if DruidBuffSettings then
        DruidBuffSettings.showActionBar = self:GetChecked()
        if self:GetChecked() then
            if DruidBuffBar then DruidBuffBar:Show() end
        else
            if DruidBuffBar then DruidBuffBar:Hide() end
        end
    end
end)

local showSmartBarToggle = CreateFrame("CheckButton", "DruidBuffCheck_ShowSmartActionBar", optionsFrame, "InterfaceOptionsCheckButtonTemplate")
showSmartBarToggle:SetPoint("TOPLEFT", 16, -180)
_G[showSmartBarToggle:GetName().."Text"]:SetText("Show Smart Buff Bar")
showSmartBarToggle:SetScript("OnShow", function(self)
    self:SetChecked(DruidBuffSettings and DruidBuffSettings.showSmartActionBar or false)
end)
showSmartBarToggle:SetScript("OnClick", function(self)
    if DruidBuffSettings then
        DruidBuffSettings.showSmartActionBar = self:GetChecked()
        if addonTable.UpdateSmartBarVisibility then addonTable.UpdateSmartBarVisibility() end
    end
end)

-- Using RegisterCanvasLayoutSubcategory is the correct way to handle nesting in modern WoW/TBC Classic
local subCategory = Settings.RegisterCanvasLayoutSubcategory(druidCategory, optionsFrame, "BuffDownranker")
