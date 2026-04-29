local addonName, addonTable = ...

-- --- SMART BUFF BAR MULTI-TARGET ASSIST ---

local smartBar = CreateFrame("Frame", "DruidSmartBuffBar", UIParent)
smartBar:SetSize(60, 60)
smartBar:SetPoint("CENTER", UIParent, "CENTER", 100, -100)
smartBar:SetMovable(true)
smartBar:EnableMouse(true)
smartBar:SetClampedToScreen(true)
smartBar:RegisterForDrag("LeftButton")

smartBar.bg = smartBar:CreateTexture(nil, "BACKGROUND")
smartBar.bg:SetAllPoints()
smartBar.bg:SetColorTexture(0, 0, 0, 0.5)

smartBar:SetScript("OnDragStart", function(self)
    if IsShiftKeyDown() then self:StartMoving() end
end)
smartBar:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

local smartBtn = CreateFrame("Button", "SmartBuffAutoBtn", smartBar, "SecureActionButtonTemplate")
smartBtn:SetSize(40, 40)
smartBtn:SetPoint("CENTER", smartBar, "CENTER", 0, 0)
smartBtn.tex = smartBtn:CreateTexture(nil, "BACKGROUND")
smartBtn.tex:SetAllPoints()
smartBtn.tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
smartBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
smartBtn:RegisterForClicks("AnyDown")
smartBtn:SetAttribute("type1", "macro")

-- --- Thorns Tank Only Popup Menu ---
local popupMenu = CreateFrame("Frame", "SmartBuffPopupMenu", UIParent,
    BackdropTemplateMixin and "BackdropTemplate" or nil)
popupMenu:SetSize(170, 40)
popupMenu:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
popupMenu:Hide()
popupMenu:SetFrameStrata("DIALOG")
popupMenu:SetFrameLevel(100)

local popupCancelFrame = CreateFrame("Button", "SmartBuffPopupMenuCancel", UIParent)
popupCancelFrame:SetAllPoints()
popupCancelFrame:SetFrameStrata("DIALOG")
popupCancelFrame:SetFrameLevel(1)
popupCancelFrame:EnableMouse(true)
popupCancelFrame:RegisterForClicks("LeftButtonDown", "RightButtonDown")
popupCancelFrame:Hide()
popupCancelFrame:SetScript("OnClick", function()
    popupMenu:Hide()
end)

popupMenu:SetScript("OnShow", function()
    popupCancelFrame:Show()
end)
popupMenu:SetScript("OnHide", function()
    popupCancelFrame:Hide()
end)

local popupCheck = CreateFrame("CheckButton", "SmartBuffPopupMenuCheck", popupMenu, "InterfaceOptionsCheckButtonTemplate")
popupCheck:SetPoint("LEFT", 10, 0)
_G[popupCheck:GetName() .. "Text"]:SetText("Thorns: Tanks Only")
popupCheck:SetScript("OnClick", function(self)
    if DruidBuffSettings and DruidBuffSettings["Thorns"] then
        DruidBuffSettings["Thorns"].tanksOnly = self:GetChecked()
        local cb = _G["DruidBuffCheck_Tanks_Thorns"]
        if cb then cb:SetChecked(self:GetChecked()) end
    end
end)

popupMenu:SetScript("OnUpdate", function(self, elapsed)
    if not self:IsMouseOver() and not smartBtn:IsMouseOver() then
        self.hoverTimer = (self.hoverTimer or 0) + elapsed
        if self.hoverTimer > 2.0 then
            self:Hide()
            self.hoverTimer = 0
        end
    else
        self.hoverTimer = 0
    end
end)

smartBtn:SetScript("PostClick", function(self, button)
    if button == "RightButton" then
        if popupMenu:IsShown() then
            popupMenu:Hide()
        else
            popupCheck:SetChecked(DruidBuffSettings and DruidBuffSettings["Thorns"] and
                DruidBuffSettings["Thorns"].tanksOnly or false)
            popupMenu:ClearAllPoints()

            local cx, cy = self:GetCenter()
            local screenWidth = GetScreenWidth()
            local screenHeight = GetScreenHeight()

            local point, relPoint = "BOTTOMLEFT", "TOPRIGHT"

            if cx > (screenWidth / 2) then
                if cy > (screenHeight / 2) then
                    point, relPoint = "TOPRIGHT", "BOTTOMLEFT"
                else
                    point, relPoint = "BOTTOMRIGHT", "TOPLEFT"
                end
            else
                if cy > (screenHeight / 2) then
                    point, relPoint = "TOPLEFT", "BOTTOMRIGHT"
                else
                    point, relPoint = "BOTTOMLEFT", "TOPRIGHT"
                end
            end

            popupMenu:SetPoint(point, self, relPoint, 0, 0)
            popupMenu:Show()
        end
    end
end)

local smartBtnCD = CreateFrame("Cooldown", "SmartBuffAutoBtnCooldown", smartBtn, "CooldownFrameTemplate")
smartBtnCD:SetHideCountdownNumbers(false)
smartBtnCD:SetAllPoints()

local function GetUnitTargetLevel(unit)
    local targetLevel = UnitLevel(unit)
    if not targetLevel or targetLevel <= 0 then
        targetLevel = 1
    end
    return targetLevel
end

local function IsValidBuffTarget(unit)
    return UnitExists(unit) and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit)
end

local function HasBuff(unit, buffName)
    local thresholdPct = (DruidBuffSettings and DruidBuffSettings.rebuffThreshold) or 0
    local i = 1
    while true do
        local name, icon, count, debuffType, duration, expirationTime = UnitBuff(unit, i)
        if not name then break end

        local isMatch = (name == buffName) or (buffName == "Mark of the Wild" and name == "Gift of the Wild")

        if isMatch then
            -- If the buff has an expiration time and duration > 0, check against the percentage threshold
            if expirationTime and expirationTime > 0 and duration and duration > 0 then
                local timeLeft = expirationTime - GetTime()
                if timeLeft < 0 then
                    timeLeft = duration
                end
                local thresholdSeconds = (duration * thresholdPct) / 100
                if timeLeft <= thresholdSeconds then
                    return false -- Treat as not having the buff (needs rebuff)
                end
            end
            return true
        end
        i = i + 1
    end
    return false
end

local function GetAppropriateRank(spellName, unit)
    local targetLevel = GetUnitTargetLevel(unit)
    local ranks = addonTable.SPELL_DATA[spellName]
    if ranks then
        for _, data in ipairs(ranks) do
            if addonTable.KNOWN_RANKS[spellName] and addonTable.KNOWN_RANKS[spellName][data.rank] then
                if targetLevel >= data.minTargetLevel then
                    return data.rank
                end
            end
        end
    end
    return nil
end

local function GetGroupUnits()
    local units = {}

    if UnitExists("target") and UnitIsFriend("player", "target") and UnitIsPlayer("target") then
        if not UnitIsUnit("target", "player") then
            table.insert(units, "target")
        end
    end

    table.insert(units, "player")
    local numRaid = IsInRaid and IsInRaid() and GetNumGroupMembers() or 0
    local numParty = IsInGroup and IsInGroup() and GetNumSubgroupMembers() or 0

    if numRaid > 0 then
        for i = 1, numRaid do
            table.insert(units, "raid" .. i)
        end
    elseif numParty > 0 then
        for i = 1, numParty do
            table.insert(units, "party" .. i)
        end
    end
    return units
end

local function InRange(spellName, unit)
    if unit == "player" then return true end
    local inRange = IsSpellInRange(spellName, unit)
    return inRange == 1
end

local function IsTank(unit)
    if UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit) == "TANK" then
        return true
    end
    if GetPartyAssignment and GetPartyAssignment("MAINTANK", unit) then
        return true
    end
    return false
end

local function IsGroupMember(unit)
    if unit == "player" then return true end
    if string.match(unit, "^party%d+$") then return true end
    if string.match(unit, "^raid%d+$") then return true end
    return false
end

local function FindMissingBuff()
    if not DruidBuffSettings then return nil, nil, nil, nil, false end
    local units = GetGroupUnits()

    local function checkSpells(requireRange)
        if DruidBuffSettings["Mark of the Wild"] and DruidBuffSettings["Mark of the Wild"].smartCast ~= false then
            for _, unit in ipairs(units) do
                if IsValidBuffTarget(unit) and not HasBuff(unit, "Mark of the Wild") then
                    if not requireRange or InRange("Mark of the Wild", unit) then
                        local rank = GetAppropriateRank("Mark of the Wild", unit)
                        if rank then
                            return "Mark of the Wild", rank, unit, "Interface\\Icons\\Spell_Nature_Regeneration"
                        end
                    end
                end
            end
        end

        if DruidBuffSettings["Omen of Clarity"] and DruidBuffSettings["Omen of Clarity"].smartCast ~= false then
            if IsValidBuffTarget("player") and not HasBuff("player", "Omen of Clarity") then
                if addonTable.KNOWN_RANKS["Omen of Clarity"] and addonTable.KNOWN_RANKS["Omen of Clarity"][1] then
                    return "Omen of Clarity", nil, "player", "Interface\\Icons\\Spell_Nature_CrystalBall"
                end
            end
        end

        if DruidBuffSettings["Thorns"] and DruidBuffSettings["Thorns"].smartCast ~= false then
            local tanksOnly = DruidBuffSettings["Thorns"].tanksOnly
            local inGroup = IsInGroup and IsInGroup()
            for _, unit in ipairs(units) do
                if IsValidBuffTarget(unit) and not HasBuff(unit, "Thorns") then
                    if not tanksOnly or not inGroup or not IsGroupMember(unit) or IsTank(unit) then
                        if not requireRange or InRange("Thorns", unit) then
                            local rank = GetAppropriateRank("Thorns", unit)
                            if rank then
                                return "Thorns", rank, unit, "Interface\\Icons\\Spell_Nature_Thorns"
                            end
                        end
                    end
                end
            end
        end
        return nil, nil, nil, nil
    end

    local spell, rank, targetUnit, icon = checkSpells(true)
    if spell then return spell, rank, targetUnit, icon, true end

    local s, r, tu, i = checkSpells(false)
    if s then return s, r, tu, i, false end

    return nil, nil, nil, nil, false
end

local function UpdateSmartBuffButton()
    if InCombatLockdown() then return end

    local spell, rank, unit, icon, inRange = FindMissingBuff()
    if spell and unit then
        local rankText = rank and ("(Rank " .. rank .. ")") or ""

        if inRange == false then
            smartBtn:SetAttribute("macrotext", "")
            smartBtn:SetAttribute("macrotext1", "")
            smartBtn.tex:SetTexture(icon)
            smartBtn.tex:SetDesaturated(true)
            smartBtn.tex:SetVertexColor(1, 0.5, 0.5)
            smartBtnCD:SetCooldown(0, 0)
            smartBtn:SetAlpha(0.7)
        else
            local macroText = "/cast [@" .. unit .. "] " .. spell .. rankText
            smartBtn:SetAttribute("macrotext", macroText)
            smartBtn:SetAttribute("macrotext1", macroText)
            smartBtn.tex:SetTexture(icon)

            local start, duration, enabled = GetSpellCooldown(spell)
            if start and duration and duration > 0 and enabled == 1 then
                smartBtnCD:SetCooldown(start, duration)
                smartBtn.tex:SetDesaturated(true)
                smartBtn.tex:SetVertexColor(0.5, 0.5, 0.5)
            else
                smartBtnCD:SetCooldown(0, 0)
                smartBtn.tex:SetDesaturated(false)
                smartBtn.tex:SetVertexColor(1, 1, 1)
            end

            smartBtn:SetAlpha(1.0)
        end
    else
        smartBtn:SetAttribute("macrotext", "")
        smartBtn:SetAttribute("macrotext1", "")
        smartBtn.tex:SetTexture("Interface\\Icons\\Spell_Nature_Regeneration")
        smartBtn.tex:SetDesaturated(true)
        smartBtn.tex:SetVertexColor(1, 1, 1)
        smartBtn:SetAlpha(0.5)
        smartBtnCD:SetCooldown(0, 0)
    end
end

smartBtn:SetScript("OnUpdate", function(self, elapsed)
    if InCombatLockdown() then return end
    self._cdTimer = (self._cdTimer or 0) + elapsed
    if self._cdTimer > 0.1 then
        self._cdTimer = 0
        UpdateSmartBuffButton()
    end
end)

function addonTable.UpdateSmartBarVisibility()
    if not DruidBuffSettings then return end

    local _, playerClass = UnitClass("player")
    if playerClass ~= "DRUID" or not DruidBuffSettings.showSmartActionBar then
        if smartBar then smartBar:Hide() end
    else
        if smartBar then smartBar:Show() end
        if not InCombatLockdown() then
            UpdateSmartBuffButton()
        end
    end
end

local scannerFrame = CreateFrame("Frame")
scannerFrame:RegisterEvent("UNIT_AURA")
scannerFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
scannerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
scannerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
scannerFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
scannerFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
scannerFrame:SetScript("OnEvent", function(self, event, ...)
    if not InCombatLockdown() then
        UpdateSmartBuffButton()
        -- Also try to layout if entering world to ensure visibility applies
        if event == "PLAYER_ENTERING_WORLD" and addonTable.UpdateSmartBarVisibility then
            addonTable.UpdateSmartBarVisibility()
        end
    end
end)

print("|cFF00FF00DruidBuffDownranker Loaded!|r Settings: Options > Addons > Druid > BuffDownranker")
