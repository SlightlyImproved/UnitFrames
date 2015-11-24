-- SlightlyImprovedUnitFrames 0.1.0beta
-- Licensed under CC-BY-NC-SA-4.0

local SIUF = "SlightlyImprovedUnitFrames"

-- Disable debug messages
local function d() end

--
--
--

local function Siuf_CreateGroupBarText(parent)
    return CreateControlFromVirtual(parent:GetName().."SiufBarText", parent, "SiufGroupBarText")
end

local function Siuf_CreateGroupLevelText(parent)
    return CreateControlFromVirtual(parent:GetName().."SiufLevelText", parent, "SiufGroupLevelText")
end

local function Siuf_CreateGroupTagText(parent)
    return CreateControlFromVirtual(parent:GetName().."SiufTagText", parent, "SiufGroupTagText")
end

local function Siuf_CreateGroupClassIcon(parent)
    return CreateControlFromVirtual(parent:GetName().."SiufClassIcon", parent, "SiufGroupClassIcon")
end

local function Siuf_UpdateGroupBarText(control, unitTag)
    local healthPool, maxHealthPool = GetUnitPower(unitTag, POWERTYPE_HEALTH)
    local percentage = (healthPool > 0) and zo_round(healthPool * 100 / maxHealthPool) or 0
    control:SetText(string.format("%d / %d (%d%%)", healthPool, maxHealthPool, percentage))
end

local function Siuf_UpdateGroupLevelText(control, unitTag)
    local level = GetUnitLevel(unitTag)
    local veteranRank = GetUnitVeteranRank(unitTag)

    if (veteranRank > 0) then
        control:SetText(GetVeteranIconMarkupString(28)..veteranRank)
    else
        control:SetText(zo_iconFormat("EsoUI/Art/Campaign/campaignbrowser_guild.dds", 24, 24)..level)
    end
end

local function Siuf_UpdateGroupLevelText(control, unitTag)
    local level = GetUnitLevel(unitTag)
    local veteranRank = GetUnitVeteranRank(unitTag)

    if (veteranRank > 0) then
        control:SetText(GetVeteranIconMarkupString(28)..veteranRank)
    else
        control:SetText(zo_iconFormat("EsoUI/Art/Campaign/campaignbrowser_guild.dds", 24, 24)..level)
    end
end

local function Siuf_UpdateGroupTagText(control, unitTag)
    control:SetText(unitTag)
end

local function Siuf_UpdateGroupClassIcon(control, unitTag)
    local classId = GetUnitClassId(unitTag)
    local texture = GetClassIcon(classId)
    local gender = GetUnitGender(unitTag)

    control.tooltipText = zo_strformat(SI_CLASS_NAME, GetClassName(gender, classId))

    local level = GetUnitLevel(unitTag)
    local veteranRank = GetUnitVeteranRank(unitTag)

    if (veteranRank > 0) then
        control.tooltipText = control.tooltipText..GetVeteranIconMarkupString(28)..veteranRank
    else
        control.tooltipText = control.tooltipText.." Lvl. "..level
    end

    control:SetTexture(GetClassIcon(classId))
end

local function DebugUnitFrame(unitFrame)
    local str = unitFrame.unitTag.." "
    if (not unitFrame.siufHealthBarText) then str=str.."HealthBarText," end
    if (not unitFrame.siufClassIcon) then str=str.."ClassIcon," end
    if (not unitFrame.siufTagText) then str=str.."TagText," end
    -- if (not unitFrame.siufLevelText) then str=str.."LevelText," end
    d(str)
end


local function Siuf_ImproveGroupUnitFrame(unitFrame)

    DebugUnitFrame(unitFrame)

    -- Display health bar text
    if (unitFrame.siufHealthBarText) then
    else
        local healthBarControl = unitFrame.healthBar.barControls[1]
        unitFrame.siufHealthBarText = Siuf_CreateGroupBarText(healthBarControl)
    end
    Siuf_UpdateGroupBarText(unitFrame.siufHealthBarText, unitFrame.unitTag)

    -- Display player class icon
    if (unitFrame.siufClassIcon) then
    else
        unitFrame.siufClassIcon = Siuf_CreateGroupClassIcon(unitFrame.frame)
        table.insert(unitFrame.fadeComponents, unitFrame.siufClassIcon)
    end
    Siuf_UpdateGroupClassIcon(unitFrame.siufClassIcon, unitFrame.unitTag)

    -- Display player level or veterank rank
    -- if (unitFrame.siufLevelText) then
    -- else
    --     unitFrame.siufLevelText = Siuf_CreateGroupLevelText(unitFrame.frame)
    --     table.insert(unitFrame.fadeComponents, unitFrame.siufLevelText)
    -- end
    -- Siuf_UpdateGroupLevelText(unitFrame.siufLevelText, unitFrame.unitTag)

    -- DEBUG: Display unit tag
    if (unitFrame.siufTagText) then
    else
        unitFrame.siufTagText = Siuf_CreateGroupTagText(unitFrame.frame)
    end
    Siuf_UpdateGroupTagText(unitFrame.siufTagText, unitFrame.unitTag)

    unitFrame:RefreshControls()
end

local function Siuf_ImproveGroupUnitFrames()
    if (UNIT_FRAMES.groupSize > 0 and UNIT_FRAMES.groupSize <= 4) then
        for unitTag, unitFrame in pairs(UNIT_FRAMES.groupFrames) do
            d(string.format("Improving unit frame for %s", unitTag))
            Siuf_ImproveGroupUnitFrame(unitFrame)
        end
    end
end

--
--
--

local function OnPowerUpdate(event, unitTag, powerPoolIndex, powerType, powerPool, powerPoolMax)
    -- d("Power update", unitTag)
    DebugUnitFrame(UNIT_FRAMES.groupFrames[unitTag])
    Siuf_ImproveGroupUnitFrame(UNIT_FRAMES.groupFrames[unitTag])
end

local function OnGroupMemberJoined(...)
    d("Group member joined", {...})
    Siuf_ImproveGroupUnitFrames()
end

local function OnGroupUpdate(...)
    d("Group update", {...})
    Siuf_ImproveGroupUnitFrames()
end

local function OnUnitFrameUpdate(...)
    d("Unit frame update", {...})
end

local function OnAddOnLoaded(event, addOnName)
    if (addOnName == SIUF) then

        -- Player might reconnect/reload while still on a party
        Siuf_ImproveGroupUnitFrames()

        EVENT_MANAGER:RegisterForEvent(SIUF, EVENT_GROUP_MEMBER_JOINED, OnGroupMemberJoined)
        EVENT_MANAGER:RegisterForEvent(SIUF, EVENT_GROUP_UPDATE, OnGroupUpdate)
        EVENT_MANAGER:RegisterForEvent(SIUF, EVENT_UNIT_FRAME_UPDATE, OnUnitFrameUpdate)

        EVENT_MANAGER:RegisterForEvent(SIUF, EVENT_POWER_UPDATE, OnPowerUpdate)
        EVENT_MANAGER:AddFilterForEvent(SIUF, EVENT_POWER_UPDATE, REGISTER_FILTER_UNIT_TAG_PREFIX, "group", REGISTER_FILTER_POWER_TYPE, POWERTYPE_HEALTH)

        EVENT_MANAGER:UnregisterForEvent(SIUF, EVENT_ADD_ON_LOADED)
    end
end

EVENT_MANAGER:RegisterForEvent(SIUF, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
