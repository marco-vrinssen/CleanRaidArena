-- Manage raid frame auras to hide extra debuffs and highlight healer buffs

local issecretvalue = issecretvalue or function() return false end

local trackedHealerSpellWords = {
    "Atonement",
    "Beacon",
    "Lifebloom",
    "Soothing",
}

local function IsTrackedHealerAura(auraName)
    if not auraName then return false end
    for _, healerWord in ipairs(trackedHealerSpellWords) do
        if auraName:find(healerWord, 1, true) then
            return true
        end
    end
    return false
end

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

local LCG = LibStub("LibCustomGlow-1.0", true)

local HEALER_GLOW_OPTIONS = {
    color      = { 1.0, 0.9, 0.0, 1.0 },
    startAnim  = false,
    frameLevel = 5,
    xOffset    = 2,
    yOffset    = 2,
}

local function EvaluateHealerGlow(buffFrame, aura)
    if not buffFrame then return end
    if not LCG then return end

    if not aura or issecretvalue(aura.spellId) or not IsTrackedHealerAura(aura.name) then
        LCG.ProcGlow_Stop(buffFrame)
        return
    end

    LCG.ProcGlow_Start(buffFrame, HEALER_GLOW_OPTIONS)
end

hooksecurefunc("CompactUnitFrame_UtilSetBuff", EvaluateHealerGlow)
