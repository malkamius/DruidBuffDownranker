local addonName, addonTable = ...

-- Create the Container Frame
local bar = CreateFrame("Frame", "DruidBuffBar", UIParent)
bar:SetSize(110, 60)
bar:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
bar:SetMovable(true)
bar:EnableMouse(true)
bar:SetClampedToScreen(true)
bar:RegisterForDrag("LeftButton")

bar.bg = bar:CreateTexture(nil, "BACKGROUND")
bar.bg:SetAllPoints()
bar.bg:SetColorTexture(0, 0, 0, 0.5)

bar:SetScript("OnDragStart", function(self) 
    if IsShiftKeyDown() then self:StartMoving() end 
end)
bar:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

-- --- BUTTON LOGIC ---
local function UpdateButtonRank(btn)
    if InCombatLockdown() or not DruidBuffSettings then return end

    local spellName = btn.baseSpell
    local unit = "player"
    
    if DruidBuffSettings[spellName].mouseover and UnitExists("mouseover") then
        unit = "mouseover"
    elseif UnitExists("target") then
        unit = "target"
    end
    
    local targetLevel = UnitLevel(unit)
    local rankText = ""

    local ranks = addonTable.SPELL_DATA[spellName]
    if spellName ~= "Omen of Clarity" and targetLevel and targetLevel > 0 then
        for _, data in ipairs(ranks) do
            -- Selection logic:
            -- 1. We must know the rank (trained)
            -- 2. Target must meet the minimum level requirement for that rank
            if addonTable.KNOWN_RANKS[spellName] and addonTable.KNOWN_RANKS[spellName][data.rank] then
                if targetLevel >= data.minTargetLevel then
                    rankText = "(Rank " .. data.rank .. ")"
                    break
                end
            end
        end
    elseif spellName == "Omen of Clarity" then
        rankText = "" -- Omen has no rank text in its spell name
        unit = "player" -- Omen is always self
    end

    local macroText = "/cast [@" .. unit .. ",exists][@player] " .. spellName .. rankText
    btn:SetAttribute("macrotext", macroText)
    btn:SetAttribute("macrotext1", macroText)
    btn._lastDesc = spellName .. rankText .. " on " .. (UnitName(unit) or "Self")
end

local function CreateBuffButton(name, spellName, icon, parent, xOffset)
    local btn = CreateFrame("Button", name, parent, "SecureActionButtonTemplate")
    btn:SetSize(40, 40)
    btn:SetPoint("LEFT", parent, "LEFT", xOffset, 0)
    btn.baseSpell = spellName

    btn.tex = btn:CreateTexture(nil, "BACKGROUND")
    btn.tex:SetAllPoints()
    btn.tex:SetTexture(icon)
    btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")

    btn:RegisterForClicks("LeftButtonDown", "AnyDown")
    btn:SetAttribute("type", "macro")

    btn.cd = CreateFrame("Cooldown", name.."Cooldown", btn, "CooldownFrameTemplate")
    btn.cd:SetHideCountdownNumbers(false)
    btn.cd:SetAllPoints()

    local function UpdateButtonCooldown()
        local start, duration, enabled = GetSpellCooldown(btn.baseSpell)
        if start and duration and duration > 0 and enabled == 1 then
            btn.cd:SetCooldown(start, duration)
            btn.tex:SetDesaturated(true)
            btn.tex:SetVertexColor(0.5, 0.5, 0.5)
        else
            btn.cd:SetCooldown(0, 0)
            btn.tex:SetDesaturated(false)
            btn.tex:SetVertexColor(1, 1, 1)
        end
    end

    btn:SetScript("OnUpdate", function(self, elapsed)
        -- We throttle the visual update to avoid heavy processing every frame
        self._cdTimer = (self._cdTimer or 0) + elapsed
        if self._cdTimer > 0.1 then
            self._cdTimer = 0
            UpdateButtonCooldown()
        end
    end)

    btn:SetScript("OnEvent", function(self, event) 
        UpdateButtonRank(self) 
    end)
    btn:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    btn:RegisterEvent("PLAYER_TARGET_CHANGED")
    btn:RegisterEvent("PLAYER_REGEN_ENABLED")
    btn:RegisterEvent("UNIT_TARGET")

    btn:SetScript("PreClick", function(self)
        UpdateButtonRank(self)
        if RaidWarningFrame and self._lastDesc then
            RaidNotice_AddMessage(RaidWarningFrame, "[DruidBuff] " .. self._lastDesc, ChatTypeInfo["RAID_WARNING"])
        end
    end)

    -- Update is handled when things load, but we can call it here too safely out of combat
    if not InCombatLockdown() then
        UpdateButtonRank(btn)
        UpdateButtonCooldown()
    end
    return btn
end

local motwBtn = CreateBuffButton("SmartMotW", "Mark of the Wild", "Interface\\Icons\\Spell_Nature_Regeneration", bar, 0)
local thornsBtn = CreateBuffButton("SmartThorns", "Thorns", "Interface\\Icons\\Spell_Nature_Thorns", bar, 0)
local omenBtn = CreateBuffButton("SmartOmen", "Omen of Clarity", "Interface\\Icons\\Spell_Nature_CrystalBall", bar, 0)

-- Global layout function so options can trigger it
function addonTable.UpdateActionBarLayout()
    if not DruidBuffSettings then return end

    local _, playerClass = UnitClass("player")
    if playerClass ~= "DRUID" then
        if bar then bar:Hide() end
        return
    end

    local xOffset = 10
    local visibleButtons = 0
    
    local function LayoutButton(btn)
        local spellName = btn.baseSpell
        local hasKnownRank = false
        if addonTable.KNOWN_RANKS[spellName] then
            for _, known in pairs(addonTable.KNOWN_RANKS[spellName]) do
                if known then hasKnownRank = true break end
            end
        end

        if DruidBuffSettings[spellName] and DruidBuffSettings[spellName].show and hasKnownRank then
            btn:Show()
            btn:SetPoint("LEFT", bar, "LEFT", xOffset, 0)
            xOffset = xOffset + 45
            visibleButtons = visibleButtons + 1
        else
            btn:Hide()
        end
    end
    
    LayoutButton(motwBtn)
    LayoutButton(omenBtn)
    LayoutButton(thornsBtn)
    
    if visibleButtons > 0 then
        bar:SetSize((visibleButtons * 45) + 20, 60)
        if DruidBuffSettings.showActionBar then
            bar:Show()
        else
            bar:Hide()
        end
    else
        bar:Hide()
    end
end
