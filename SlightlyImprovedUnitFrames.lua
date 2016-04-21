-- SlightlyImprovedUnitFrames 0.3.0beta
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
    return unitFrame and (not unitFrame.hasBeenSlightlyImproved) and IsUnitOnline(unitFrame.unitTag) and (GetGroupSize() <= 4)
end

local function Siuf_ShouldUpdateUnitFrame(unitFrame)
    return unitFrame.hasBeenSlightlyImproved
end

--
--
--

local function OnPowerUpdate(event, unitTag, powerPoolIndex, powerType, powerPool, powerPoolMax)
    if ZO_Group_IsGroupUnitTag(unitTag) then
        d("Power update", unitTag)
        local unitFrame = ZO_UnitFrames_GetUnitFrame(unitTag)
        if Siuf_ShouldUpdateUnitFrame(unitFrame) then
            local healthPool, maxHealthPool = GetUnitPower(unitTag, POWERTYPE_HEALTH)
            Siuf_UpdateGroupBarText(unitFrame.siufHealthBarText, healthPool, maxHealthPool)
        end
    end
end

local function OnLevelUpdate(event, unitTag)
    if ZO_Group_IsGroupUnitTag(unitTag) then
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
end

local function OnVeteranRankUpdate(event, unitTag)
    if ZO_Group_IsGroupUnitTag(unitTag) then
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
end

local function OnUnitCreated(event, unitTag)
    if ZO_Group_IsGroupUnitTag(unitTag) then
        d("Unit created", unitTag)

        local pollCount = 0
        local pollLimit = 20
        local pollInterval = 100
        local pollGroupUnitFrame

        pollGroupUnitFrame = function()
            local unitFrame = ZO_UnitFrames_GetUnitFrame(unitTag)
            if unitFrame then
                if Siuf_ShouldImproveUnitFrame(unitFrame) then
                    Siuf_ImproveGroupUnitFrame(unitFrame)
                end
            else
                if (pollCount < pollLimit) then
                    zo_callLater(pollGroupUnitFrame, pollInterval)
                    pollCount = pollCount + 1
                else
                    d("Group unit frame was not ready in due time")
                end
            end
        end

        pollGroupUnitFrame()
    end
end

local function OnPlayerActivated()
    if IsUnitGrouped("player") and (GetGroupSize() <= 4) then
        local pollCount = 0
        local pollLimit = 10
        local pollInterval = 500
        local pollGroupUnitFrames

        pollGroupUnitFrames = function()
            if (UNIT_FRAMES.groupSize > 0) then
                for unitTag, unitFrame in pairs(UNIT_FRAMES.groupFrames) do
                    if (Siuf_ShouldImproveUnitFrame(unitFrame)) then
                        Siuf_ImproveGroupUnitFrame(unitFrame)
                    end
                end
            else
                if (pollCount < pollLimit) then
                    zo_callLater(pollGroupUnitFrames, pollInterval)
                    pollCount = pollCount + 1
                else
                    d("Group unit frames were not ready in due time")
                end
            end
        end

        pollGroupUnitFrames()
    end
end

local function OnGroupMemberConnectedStatus(event, unitTag)
    if IsUnitOnline(unitTag) then
        local unitFrame = ZO_UnitFrames_GetUnitFrame(unitTag)
        if Siuf_ShouldImproveUnitFrame(unitFrame) then
            Siuf_ImproveGroupUnitFrame(unitFrame)
        end
    end
end

local function OnAddOnLoaded(event, addOnName)
    if (addOnName == SIUF) then
        EVENT_MANAGER:UnregisterForEvent(SIUF, EVENT_ADD_ON_LOADED)

        -- local events =
        -- {
        --     [EVENT_GROUP_INVITE_ACCEPT_RESPONSE_TIMEOUT] = "GROUP_INVITE_ACCEPT_RESPONSE_TIMEOUT",
        --     [EVENT_GROUP_INVITE_RECEIVED] = "GROUP_INVITE_RECEIVED",
        --     [EVENT_GROUP_INVITE_REMOVED] = "GROUP_INVITE_REMOVED",
        --     [EVENT_GROUP_INVITE_RESPONSE] = "GROUP_INVITE_RESPONSE",
        --     [EVENT_GROUP_MEMBER_CONNECTED_STATUS] = "GROUP_MEMBER_CONNECTED_STATUS",
        --     [EVENT_GROUP_MEMBER_IN_REMOTE_REGION] = "GROUP_MEMBER_IN_REMOTE_REGION",
        --     [EVENT_GROUP_MEMBER_JOINED] = "GROUP_MEMBER_JOINED",
        --     [EVENT_GROUP_MEMBER_LEFT] = "GROUP_MEMBER_LEFT",
        --     [EVENT_GROUP_MEMBER_ROLES_CHANGED] = "GROUP_MEMBER_ROLES_CHANGED",
        --     [EVENT_GROUP_NOTIFICATION_MESSAGE] = "GROUP_NOTIFICATION_MESSAGE",
        --     [EVENT_GROUP_SUPPORT_RANGE_UPDATE] = "GROUP_SUPPORT_RANGE_UPDATE",
        --     [EVENT_GROUP_TYPE_CHANGED] = "GROUP_TYPE_CHANGED",
        --     [EVENT_GROUP_UPDATE] = "GROUP_UPDATE",
        --     [EVENT_LEADER_UPDATE] = "LEADER_UPDATE",
        --     [EVENT_PLAYER_ACTIVATED] = "PLAYER_ACTIVATED",
        --     [EVENT_UNIT_FRAME_UPDATE] = "UNIT_FRAME_UPDATE",
        --     [EVENT_UNIT_CREATED] = "UNIT_CREATED",
        -- }

        -- SIUF_EVENT_LOG = {}
        --
        -- for e, name in pairs(events) do
        --     EVENT_MANAGER:RegisterForEvent(SIUF, e, function(event, ...)
        --         local t = {..., ["GetGameTimeMilliseconds"] = GetGameTimeMilliseconds(), ["event"] = name, ["IsPlayerGrouped"] = IsUnitGrouped("player"), ["GetGroupSize"] = GetGroupSize(), ["UNIT_FRAMES.groupFrames"] = #UNIT_FRAMES.groupFrames}
        --         table.insert(SIUF_EVENT_LOG, t)
        --
        --         if (event == EVENT_UNIT_CREATED) then
        --             OnUnitCreated(event, ...)
        --         end
        --
        --         if (event == EVENT_GROUP_MEMBER_CONNECTED_STATUS) then
        --             OnGroupMemberConnectedStatus(event, ...)
        --         end
        --
        --         if (event == EVENT_PLAYER_ACTIVATED) then
        --             OnPlayerActivated(event, ...)
        --         end
        --     end)
        -- end

        EVENT_MANAGER:RegisterForEvent(SIUF, EVENT_UNIT_CREATED, OnUnitCreated)
        EVENT_MANAGER:RegisterForEvent(SIUF, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
        EVENT_MANAGER:RegisterForEvent(SIUF, EVENT_GROUP_MEMBER_CONNECTED_STATUS, OnGroupMemberConnectedStatus)

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
