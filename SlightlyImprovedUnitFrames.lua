-- SlightlyImprovedUnitFrames 0.2.0beta
-- Licensed under CC-BY-NC-SA-4.0

local SIUF = "SlightlyImprovedUnitFrames"

-- Uncomment to disable debug messages
local function d() end

--
--
--

local function Siuf_CreateControl(suffix, parent, template)
    return CreateControlFromVirtual(parent:GetName()..suffix, parent, template)
end

local function Siuf_UpdateGroupBarText(control, healthPool, maxHealthPool)
    -- local healthPool, maxHealthPool = GetUnitPower(unitTag, POWERTYPE_HEALTH)
    local percentage = (healthPool > 0) and zo_round(healthPool * 100 / maxHealthPool) or 0
    control:SetText(string.format("%d / %d (%d%%)", healthPool, maxHealthPool, percentage))
end

local function Siuf_UpdateGroupTagText(control, unitTag)
    control:SetText(unitTag)
end

local function Siuf_UpdateGroupClassIcon(control, classId, gender, level, veteranRank)
    local texture = GetClassIcon(classId)

    control.tooltipText = zo_strformat(SI_CLASS_NAME, GetClassName(gender, classId))

    if (veteranRank > 0) then
        local icon = zo_iconFormat("esoui/art/lfg/lfg_veterandungeon_up.dds", 28, 28)
        control.tooltipText = control.tooltipText..icon..veteranRank
        else
        local icon = zo_iconFormat("esoui/art/lfg/lfg_normaldungeon_up.dds", 28, 28)
        control.tooltipText = control.tooltipText..icon..level
    end

    control:SetTexture(GetClassIcon(classId))
end

--
--
--

local function Siuf_ImproveGroupUnitFrame(unitFrame)
    local unitTag = unitFrame.unitTag
    unitFrame.hasBeenSlightlyImproved = true

    -- Display health bar text
    local healthBarControl = unitFrame.healthBar.barControls[1]
    unitFrame.siufHealthBarText = Siuf_CreateControl("SiufBarText", healthBarControl, "SiufGroupBarText")

    local healthPool, maxHealthPool = GetUnitPower(unitTag, POWERTYPE_HEALTH)
    Siuf_UpdateGroupBarText(unitFrame.siufHealthBarText, healthPool, maxHealthPool)

    -- Display character class icon
    unitFrame.siufClassIcon = Siuf_CreateControl("SiufClassIcon", unitFrame.frame, "SiufGroupClassIcon")
    table.insert(unitFrame.fadeComponents, unitFrame.siufClassIcon)

    local classId = GetUnitClassId(unitTag)
    local gender = GetUnitGender(unitTag)
    local level = GetUnitLevel(unitTag)
    local veteranRank = GetUnitVeteranRank(unitTag)
    Siuf_UpdateGroupClassIcon(unitFrame.siufClassIcon, classId, gender, level, veteranRank)

    -- DEBUG: Display unit tag
    -- unitFrame.siufTagText = Siuf_CreateControl("SiufTagText", unitFrame.frame, "SiufGroupTagText")
    -- Siuf_UpdateGroupTagText(unitFrame.siufTagText, unitTag)

    unitFrame:RefreshControls()
end

local function Siuf_ShouldImproveUnitFrame(unitFrame)
    return (unitFrame and not unitFrame.hasBeenSlightlyImproved and string.find(unitFrame.unitTag, "group", 1, true) == 1 and IsUnitOnline(unitFrame.unitTag))
end

local function Siuf_ShouldUpdateUnitFrame(unitFrame)
    return (unitFrame and unitFrame.hasBeenSlightlyImproved and string.find(unitFrame.unitTag, "group", 1, true) == 1 and IsUnitOnline(unitFrame.unitTag))
end

--
--
--

local function OnUnitCreated(event, unitTag)
    d("Unit created", unitTag)
    local unitFrame = ZO_UnitFrames_GetUnitFrame(unitTag)
    if Siuf_ShouldImproveUnitFrame(unitFrame) then
        Siuf_ImproveGroupUnitFrame(unitFrame)
    end
end

local function OnPowerUpdate(event, unitTag, powerPoolIndex, powerType, powerPool, powerPoolMax)
    d("Power update", unitTag)
    local unitFrame = ZO_UnitFrames_GetUnitFrame(unitTag)
    if Siuf_ShouldUpdateUnitFrame(unitFrame) then
        local healthPool, maxHealthPool = GetUnitPower(unitTag, POWERTYPE_HEALTH)
        Siuf_UpdateGroupBarText(unitFrame.siufHealthBarText, healthPool, maxHealthPool)
    end
end

local function OnLevelUpdate(event, unitTag)
    d("Level update", unitTag)
    local unitFrame = ZO_UnitFrames_GetUnitFrame(unitTag)
    if Siuf_ShouldUpdateUnitFrame(unitFrame) then
        local classId = GetUnitClassId(unitTag)
        local gender = GetUnitGender(unitTag)
        local level = GetUnitLevel(unitTag)
        local veteranRank = GetUnitVeteranRank(unitTag)
        Siuf_UpdateGroupClassIcon(unitFrame.siufClassIcon, classId, gender, level, veteranRank)
    end
end

local function OnVeteranRankUpdate(event, unitTag)
    d("VR update", unitTag)
    local unitFrame = ZO_UnitFrames_GetUnitFrame(unitTag)
    if Siuf_ShouldUpdateUnitFrame(unitFrame) then
        local classId = GetUnitClassId(unitTag)
        local gender = GetUnitGender(unitTag)
        local level = GetUnitLevel(unitTag)
        local veteranRank = GetUnitVeteranRank(unitTag)
        Siuf_UpdateGroupClassIcon(unitFrame.siufClassIcon, classId, gender, level, veteranRank)
    end
end

local function OnPlayerActivated(event, ...)
    for unitTag, unitFrame in pairs(UNIT_FRAMES.groupFrames) do
        d(unitTag, Siuf_ShouldImproveUnitFrame(unitFrame))

        if Siuf_ShouldImproveUnitFrame(unitFrame) then
            Siuf_ImproveGroupUnitFrame(unitFrame)
        end
    end
end

local function OnAddOnLoaded(event, addOnName)
    if (addOnName == SIUF) then
        EVENT_MANAGER:UnregisterForEvent(SIUF, EVENT_ADD_ON_LOADED)

        EVENT_MANAGER:RegisterForEvent(SIUF, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
        EVENT_MANAGER:RegisterForEvent(SIUF, EVENT_UNIT_CREATED, OnUnitCreated)
        EVENT_MANAGER:RegisterForEvent(SIUF, EVENT_POWER_UPDATE, OnPowerUpdate)
        EVENT_MANAGER:RegisterForEvent(SIUF, EVENT_LEVEL_UPDATE, OnLevelUpdate)
        EVENT_MANAGER:RegisterForEvent(SIUF, EVENT_VETERAN_RANK_UPDATE, OnVeteranRankUpdate)

        local filters =
        {
            REGISTER_FILTER_UNIT_TAG_PREFIX, "group",
            REGISTER_FILTER_POWER_TYPE, POWERTYPE_HEALTH,
        }
        EVENT_MANAGER:AddFilterForEvent(SIUF, EVENT_POWER_UPDATE, unpack(filters))
    end
end

EVENT_MANAGER:RegisterForEvent(SIUF, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
