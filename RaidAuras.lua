-- Manages raid frame auras: hides extra debuffs and highlights healer buffs

local trackedHealerSpellIds = {
    [194384]  = true, -- Atonement          (Discipline Priest)
    [156910]  = true, -- Beacon of Faith    (Holy Paladin)
    [1244893] = true, -- Beacon of Savior   (Holy Paladin)
    [53563]   = true, -- Beacon of Light    (Holy Paladin)
    [115175]  = true, -- Soothing Mist      (Mistweaver Monk)
    [33763]   = true, -- Lifebloom          (Restoration Druid)
}

local glowFrameCache    = {}
local pendingGlowFrames = {}
local visitedBuffFrames = {}

-- type() returns "number" for secret values, so pcall guards the table access itself
local function IsTrackedHealerAura(spellId)
    if type(spellId) ~= "number" then return false end
    local ok, result = pcall(function() return trackedHealerSpellIds[spellId] == true end)
    return ok and result
end

-- Returns a cached glow frame or creates one from the Blizzard spell alert template
local function GetOrCreateGlowFrame(buffFrame)
    if glowFrameCache[buffFrame] then return glowFrameCache[buffFrame] end

    C_AddOns.LoadAddOn("Blizzard_ActionBar")

    local glow = CreateFrame("Frame", nil, buffFrame, "ActionButtonSpellAlertTemplate")
    glow:SetSize(buffFrame:GetWidth() * 1.4, buffFrame:GetHeight() * 1.4)
    glow:SetPoint("TOPLEFT",     buffFrame, "TOPLEFT",     -4,  4)
    glow:SetPoint("BOTTOMRIGHT", buffFrame, "BOTTOMRIGHT",  4, -4)
    glow.ProcStartFlipbook:Hide() -- prevents golden grid artifact
    glow:Hide()

    glowFrameCache[buffFrame] = glow
    return glow
end

-- Skips the intro flash and plays only the steady loop
local function ShowHealerGlow(buffFrame)
    local glow = GetOrCreateGlowFrame(buffFrame)
    if glow.ProcStartAnim:IsPlaying() then glow.ProcStartAnim:Stop() end
    glow:Show()
    if not glow.ProcLoop:IsPlaying() then glow.ProcLoop:Play() end
end

local function HideHealerGlow(buffFrame)
    local glow = glowFrameCache[buffFrame]
    if not glow then return end
    glow.ProcLoop:Stop()
    glow.ProcStartAnim:Stop()
    glow:Hide()
end

-- Marks visited frames and which of those should glow; does not touch glow state directly
local function EvaluateHealerGlow(buffFrame, aura)
    if not buffFrame then return end
    visitedBuffFrames[buffFrame] = true
    local spellId = aura and type(aura.spellId) == "number" and aura.spellId
    if spellId and IsTrackedHealerAura(spellId) then
        pendingGlowFrames[buffFrame] = true
    end
end

-- Resolves glow state after all UtilSetBuff calls for this pass are done:
--   visited frames        → apply pending state (show or hide)
--   unvisited + hidden    → clear stale glow (empty slot)
--   unvisited + shown     → aura unchanged, leave glow alone
local function OnUpdateAuras(frame)
    if not frame then return end
    if frame.buffFrames then
        for i = 1, #frame.buffFrames do
            local f = frame.buffFrames[i]
            if f then
                if visitedBuffFrames[f] then
                    if pendingGlowFrames[f] then ShowHealerGlow(f) else HideHealerGlow(f) end
                elseif not f:IsShown() then
                    HideHealerGlow(f)
                end
            end
        end
    end
    for f in pairs(pendingGlowFrames) do pendingGlowFrames[f] = nil end
    for f in pairs(visitedBuffFrames) do visitedBuffFrames[f] = nil end
    if frame.debuffFrames then
        for i = 2, #frame.debuffFrames do
            local f = frame.debuffFrames[i]
            if f then f:Hide() end
        end
    end
end

hooksecurefunc("CompactUnitFrame_UpdateAuras", OnUpdateAuras)
hooksecurefunc("CompactUnitFrame_UtilSetBuff", EvaluateHealerGlow)
