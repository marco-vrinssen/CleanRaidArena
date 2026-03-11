-- Manage raid frame auras to hide extra debuffs and highlight healer buffs

-- Healer buff spell IDs to track on raid frames
local trackedHealerSpellIds = {
    [194384]  = true, -- Atonement (Discipline Priest)
    [156910]  = true, -- Beacon of Faith (Holy Paladin)
    [1244893] = true, -- Beacon of the Savior (Holy Paladin)
    [53563]   = true, -- Beacon of Light (Holy Paladin)
    [115175]  = true, -- Soothing Mist (Mistweaver Monk)
    [33763]   = true, -- Lifebloom (Restoration Druid)
}

-- Check whether an aura spell ID matches any tracked healer spell
local function IsTrackedHealerAura(spellId)
    if not spellId then return false end
    return trackedHealerSpellIds[spellId] == true
end

-- Hide all debuff frames beyond the first to reduce visual clutter
local function HideExtraDebuffs(frame)
    if not frame or not frame.debuffFrames then return end
    for debuffIndex = 2, #frame.debuffFrames do
        local debuffFrame = frame.debuffFrames[debuffIndex]
        if debuffFrame then
            debuffFrame:Hide()
        end
    end
end

hooksecurefunc("CompactUnitFrame_UpdateAuras", HideExtraDebuffs)

-- Cache glow frames per buff frame to avoid recreating them on every update
local glowFrameCache = {}

-- Retrieve or create a native glow frame attached to the given buff frame
local function GetOrCreateGlowFrame(buffFrame)
    if glowFrameCache[buffFrame] then
        return glowFrameCache[buffFrame]
    end

    -- Ensure Blizzard_ActionBar is loaded so the template is available
    C_AddOns.LoadAddOn("Blizzard_ActionBar")

    local glow = CreateFrame("Frame", nil, buffFrame, "ActionButtonSpellAlertTemplate")
    glow:SetSize(buffFrame:GetWidth() * 1.4, buffFrame:GetHeight() * 1.4)
    glow:SetPoint("TOPLEFT", buffFrame, "TOPLEFT", -4, 4)
    glow:SetPoint("BOTTOMRIGHT", buffFrame, "BOTTOMRIGHT", 4, -4)

    -- Permanently hide the start flipbook to prevent the golden grid artifact
    glow.ProcStartFlipbook:Hide()

    glow:Hide()

    glowFrameCache[buffFrame] = glow
    return glow
end

-- Start the steady glow immediately, skipping the intro flash animation
local function ShowHealerGlow(buffFrame)
    local glow = GetOrCreateGlowFrame(buffFrame)
    if glow.ProcStartAnim:IsPlaying() then
        glow.ProcStartAnim:Stop()
    end
    glow:Show()
    if not glow.ProcLoop:IsPlaying() then
        glow.ProcLoop:Play()
    end
end

-- Stop the loop animation and hide the glow
local function HideHealerGlow(buffFrame)
    local glow = glowFrameCache[buffFrame]
    if glow then
        glow.ProcLoop:Stop()
        glow.ProcStartAnim:Stop()
        glow:Hide()
    end
end

-- Show or hide the healer glow based on whether the aura spell ID is tracked
local function EvaluateHealerGlow(buffFrame, aura)
    if not buffFrame then return end

    if not aura or not IsTrackedHealerAura(aura.spellId) then
        HideHealerGlow(buffFrame)
        return
    end

    ShowHealerGlow(buffFrame)
end

hooksecurefunc("CompactUnitFrame_UtilSetBuff", EvaluateHealerGlow)
