local addonName, addonTable = ...

-- Settings State Initialization
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, arg1)
    if arg1 == addonName then
        DruidBuffSettings = DruidBuffSettings or {
            ["Mark of the Wild"] = { mouseover = true, show = true, smartCast = true },
            ["Thorns"] = { mouseover = true, show = true, smartCast = true },
            ["Omen of Clarity"] = { show = true, smartCast = true },
            showActionBar = true,
            showSmartActionBar = true,
            rebuffThreshold = 10
        }
        -- Ensure backwards compatibility
        if DruidBuffSettings then
            if DruidBuffSettings.rebuffThreshold == nil then
                DruidBuffSettings.rebuffThreshold = 10
            end
            for _, spell in ipairs({ "Mark of the Wild", "Thorns", "Omen of Clarity" }) do
                if DruidBuffSettings[spell] and DruidBuffSettings[spell].smartCast == nil then
                    DruidBuffSettings[spell].smartCast = true
                end
            end
            if DruidBuffSettings["Thorns"] and DruidBuffSettings["Thorns"].tanksOnly == nil then
                DruidBuffSettings["Thorns"].tanksOnly = false
            end
        end
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

local function CreateToggle(spellName, yOffset, hasMouseover, hasTanksOnly)
    local cbShow = CreateFrame("CheckButton", "DruidBuffCheck_Show_" .. spellName:gsub("%s+", ""), optionsFrame,
        "InterfaceOptionsCheckButtonTemplate")
    cbShow:SetPoint("TOPLEFT", 16, yOffset)
    _G[cbShow:GetName() .. "Text"]:SetText("Show " .. spellName)

    cbShow:SetScript("OnShow", function(self)
        self:SetChecked(DruidBuffSettings and DruidBuffSettings[spellName].show or false)
    end)

    cbShow:SetScript("OnClick", function(self)
        if DruidBuffSettings then
            DruidBuffSettings[spellName].show = self:GetChecked()
            if addonTable.UpdateActionBarLayout then addonTable.UpdateActionBarLayout() end
        end
    end)

    local cbSmart = CreateFrame("CheckButton", "DruidBuffCheck_Smart_" .. spellName:gsub("%s+", ""), optionsFrame,
        "InterfaceOptionsCheckButtonTemplate")
    cbSmart:SetPoint("TOPLEFT", 180, yOffset)
    _G[cbSmart:GetName() .. "Text"]:SetText("Smart Cast")

    cbSmart:SetScript("OnShow", function(self)
        local val = DruidBuffSettings and DruidBuffSettings[spellName].smartCast
        if val == nil then val = true end
        self:SetChecked(val)
    end)

    cbSmart:SetScript("OnClick", function(self)
        if DruidBuffSettings then
            DruidBuffSettings[spellName].smartCast = self:GetChecked()
            if addonTable.UpdateSmartBarVisibility then addonTable.UpdateSmartBarVisibility() end
        end
    end)

    if hasMouseover then
        local cbMouse = CreateFrame("CheckButton", "DruidBuffCheck_Mouse_" .. spellName:gsub("%s+", ""), optionsFrame,
            "InterfaceOptionsCheckButtonTemplate")
        cbMouse:SetPoint("TOPLEFT", 300, yOffset)
        _G[cbMouse:GetName() .. "Text"]:SetText("Enable Mouseover")

        cbMouse:SetScript("OnShow", function(self)
            self:SetChecked(DruidBuffSettings and DruidBuffSettings[spellName].mouseover or false)
        end)

        cbMouse:SetScript("OnClick", function(self)
            if DruidBuffSettings then
                DruidBuffSettings[spellName].mouseover = self:GetChecked()
            end
        end)
    end

    if hasTanksOnly then
        local cbTanks = CreateFrame("CheckButton", "DruidBuffCheck_Tanks_" .. spellName:gsub("%s+", ""), optionsFrame,
            "InterfaceOptionsCheckButtonTemplate")
        cbTanks:SetPoint("TOPLEFT", 450, yOffset)
        _G[cbTanks:GetName() .. "Text"]:SetText("Tanks Only")

        cbTanks:SetScript("OnShow", function(self)
            self:SetChecked(DruidBuffSettings and DruidBuffSettings[spellName].tanksOnly or false)
        end)

        cbTanks:SetScript("OnClick", function(self)
            if DruidBuffSettings then
                DruidBuffSettings[spellName].tanksOnly = self:GetChecked()
            end
        end)
    end
end

CreateToggle("Mark of the Wild", -50, true, false)
CreateToggle("Thorns", -80, true, true)
CreateToggle("Omen of Clarity", -110, false, false)

local showBarToggle = CreateFrame("CheckButton", "DruidBuffCheck_ShowActionBar", optionsFrame,
    "InterfaceOptionsCheckButtonTemplate")
showBarToggle:SetPoint("TOPLEFT", 16, -150)
_G[showBarToggle:GetName() .. "Text"]:SetText("Show Action Bar")
showBarToggle:SetScript("OnShow", function(self)
    self:SetChecked(DruidBuffSettings and DruidBuffSettings.showActionBar or false)
end)
showBarToggle:SetScript("OnClick", function(self)
    if DruidBuffSettings then
        DruidBuffSettings.showActionBar = self:GetChecked()

        ---@type Frame
        ---@diagnostic disable-next-line: undefined-global
        local bar = DruidBuffBar
        if self:GetChecked() then
            if bar then bar:Show() end
        else
            if bar then bar:Hide() end
        end
    end
end)

local showSmartBarToggle = CreateFrame("CheckButton", "DruidBuffCheck_ShowSmartActionBar", optionsFrame,
    "InterfaceOptionsCheckButtonTemplate")
showSmartBarToggle:SetPoint("TOPLEFT", 16, -180)
_G[showSmartBarToggle:GetName() .. "Text"]:SetText("Show Smart Buff Bar")
showSmartBarToggle:SetScript("OnShow", function(self)
    self:SetChecked(DruidBuffSettings and DruidBuffSettings.showSmartActionBar or false)
end)
showSmartBarToggle:SetScript("OnClick", function(self)
    if DruidBuffSettings then
        DruidBuffSettings.showSmartActionBar = self:GetChecked()
        if addonTable.UpdateSmartBarVisibility then addonTable.UpdateSmartBarVisibility() end
    end
end)

local slider = CreateFrame("Slider", "DruidBuffRebuffSlider", optionsFrame, "OptionsSliderTemplate")
slider:SetPoint("TOPLEFT", 24, -230)
slider:SetWidth(180)
slider:SetMinMaxValues(0, 100) -- 0% to 100%
slider:SetValueStep(5)
slider:SetObeyStepOnDrag(true)

-- Add a fill texture for visual feedback
local sliderFill = slider:CreateTexture(nil, "ARTWORK")
sliderFill:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
sliderFill:SetVertexColor(0, 1, 0, 0.5) -- Semi-transparent green
sliderFill:SetPoint("TOPLEFT", slider, "TOPLEFT", 4, -4)
sliderFill:SetPoint("BOTTOMLEFT", slider, "BOTTOMLEFT", 4, 4)

_G[slider:GetName() .. "Low"]:SetText("0%")
_G[slider:GetName() .. "High"]:SetText("100%")

local function UpdateSliderText(value)
    _G[slider:GetName() .. "Text"]:SetText(string.format("Rebuff Threshold: %d%%", value))

    local min, max = slider:GetMinMaxValues()
    local percentage = value / (max - min)
    if percentage > 0 then
        -- The slider background width minus some padding (approx 8 pixels)
        sliderFill:SetWidth((slider:GetWidth() - 8) * percentage)
        sliderFill:Show()
    else
        sliderFill:Hide()
    end
end

slider:SetScript("OnShow", function(self)
    local val = DruidBuffSettings and DruidBuffSettings.rebuffThreshold or 10
    self:SetValue(val)
    UpdateSliderText(val)
end)

slider:SetScript("OnValueChanged", function(self, value)
    if not self:IsVisible() then return end
    if DruidBuffSettings then
        DruidBuffSettings.rebuffThreshold = value
        UpdateSliderText(value)
    end
end)

-- Using RegisterCanvasLayoutSubcategory is the correct way to handle nesting in modern WoW/TBC Classic
local subCategory = Settings.RegisterCanvasLayoutSubcategory(druidCategory, optionsFrame, "BuffDownranker")
