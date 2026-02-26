-- [apply gradient depth overlay and clean arena frame accessories]

local GRADIENT_ALPHA = 0.25
local TOP_COLOR = CreateColor(0, 0, 0, GRADIENT_ALPHA)
local BOTTOM_COLOR = CreateColor(0, 0, 0, 0)

local function ApplyHealthBarGradient(frame)
    if not frame or not frame.healthBar then return end
    local healthBar = frame.healthBar
    if healthBar.cleanGradient then return end
    local gradient = healthBar:CreateTexture(nil, "ARTWORK", nil, 7)
    gradient:SetAllPoints(healthBar)
    gradient:SetColorTexture(1, 1, 1, 1)
    gradient:SetGradient("VERTICAL", BOTTOM_COLOR, TOP_COLOR)
    healthBar.cleanGradient = gradient
end

hooksecurefunc("DefaultCompactUnitFrameSetup", ApplyHealthBarGradient)
hooksecurefunc("DefaultCompactMiniFrameSetup", ApplyHealthBarGradient)

-- [reposition arena accessories and hide casting bar after each layout update]

local ACCESSORY_SIZE = 40

local function AdjustArenaMember(memberFrame)
    if not memberFrame then return end

    local castingBar = memberFrame.CastingBarFrame
    if castingBar then
        castingBar:SetAlpha(0)
    end

    local ccRemover = memberFrame.CcRemoverFrame
    if ccRemover then
        ccRemover:SetSize(ACCESSORY_SIZE, ACCESSORY_SIZE)
        ccRemover:ClearAllPoints()
        ccRemover:SetPoint("TOPLEFT", memberFrame, "TOPRIGHT", 2, 0)
    end

    local debuffFrame = memberFrame.DebuffFrame
    if debuffFrame then
        debuffFrame:SetSize(ACCESSORY_SIZE, ACCESSORY_SIZE)
        debuffFrame:ClearAllPoints()
        debuffFrame:SetPoint("TOPRIGHT", memberFrame, "TOPLEFT", -2, 0)
    end

    local tray = memberFrame.SpellDiminishStatusTray
    if tray then
        tray:ClearAllPoints()
        tray:SetPoint("BOTTOMRIGHT", memberFrame, "BOTTOMLEFT", -2, 0)
    end
end

-- [hook the actual frame instance because Mixin copies the original method before addon hooks apply]

local function SetupArenaHook()
    if not CompactArenaFrame or CompactArenaFrame.cleanArenaHooked then return end
    CompactArenaFrame.cleanArenaHooked = true
    hooksecurefunc(CompactArenaFrame, "UpdateLayout", function(self)
        for _, memberFrame in ipairs(self.memberUnitFrames) do
            AdjustArenaMember(memberFrame)
        end
    end)
end

SetupArenaHook()

if CompactArenaFrame_Generate then
    hooksecurefunc("CompactArenaFrame_Generate", SetupArenaHook)
end