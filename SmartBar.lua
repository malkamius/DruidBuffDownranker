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
smartBtn:RegisterForClicks("LeftButtonDown", "AnyDown")
smartBtn:SetAttribute("type", "macro")

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
    local i = 1
    while true do
        local name = UnitBuff(unit, i)
        if not name then break end
        if name == buffName then return true end
        if buffName == "Mark of the Wild" and name == "Gift of the Wild" then return true end
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
        table.insert(units, "target")
    end
    
    table.insert(units, "player")
    -- Classic/TBC compatible checks
    local numRaid = IsInRaid and IsInRaid() and GetNumGroupMembers() or (GetNumRaidMembers and GetNumRaidMembers() or 0)
    local numParty = IsInGroup and IsInGroup() and GetNumSubgroupMembers() or (GetNumPartyMembers and GetNumPartyMembers() or 0)

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

local function FindMissingBuff()
    if not DruidBuffSettings then return nil, nil, nil, nil end
    local units = GetGroupUnits()

    if DruidBuffSettings["Mark of the Wild"] and DruidBuffSettings["Mark of the Wild"].show then
        for _, unit in ipairs(units) do
            if IsValidBuffTarget(unit) and not HasBuff(unit, "Mark of the Wild") then
                local rank = GetAppropriateRank("Mark of the Wild", unit)
                if rank then
                    return "Mark of the Wild", rank, unit, "Interface\\Icons\\Spell_Nature_Regeneration"
                end
            end
        end
    end

    if DruidBuffSettings["Thorns"] and DruidBuffSettings["Thorns"].show then
        for _, unit in ipairs(units) do
            if IsValidBuffTarget(unit) and not HasBuff(unit, "Thorns") then
                local rank = GetAppropriateRank("Thorns", unit)
                if rank then
                    return "Thorns", rank, unit, "Interface\\Icons\\Spell_Nature_Thorns"
                end
            end
        end
    end
    
    if DruidBuffSettings["Omen of Clarity"] and DruidBuffSettings["Omen of Clarity"].show then
        if IsValidBuffTarget("player") and not HasBuff("player", "Omen of Clarity") then
            if addonTable.KNOWN_RANKS["Omen of Clarity"] and addonTable.KNOWN_RANKS["Omen of Clarity"][1] then
                 return "Omen of Clarity", nil, "player", "Interface\\Icons\\Spell_Nature_CrystalBall"
            end
        end
    end

    return nil, nil, nil, nil
end

local function UpdateSmartBuffButton()
    if InCombatLockdown() then return end

    local spell, rank, unit, icon = FindMissingBuff()
    if spell and unit then
        local rankText = rank and ("(Rank " .. rank .. ")") or ""
        local macroText = "/cast [@" .. unit .. "] " .. spell .. rankText
        smartBtn:SetAttribute("macrotext", macroText)
        smartBtn:SetAttribute("macrotext1", macroText)
        smartBtn.tex:SetTexture(icon)
        smartBtn.tex:SetDesaturated(false)
        smartBtn:SetAlpha(1.0)
    else
        smartBtn:SetAttribute("macrotext", "")
        smartBtn:SetAttribute("macrotext1", "")
        smartBtn.tex:SetTexture("Interface\\Icons\\Spell_Nature_Regeneration")
        smartBtn.tex:SetDesaturated(true)
        smartBtn:SetAlpha(0.5)
    end
end

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
