-- SlightlyImprovedUnitFrames 0.4.0 beta_250816
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

local function Siuf_UpdateGroupClassIcon(control, classId, gender, level, championRank)
	local texture = GetClassIcon(classId)

	control.tooltipText = zo_strformat(SI_CLASS_NAME, GetClassName(gender, classId))

	if (championRank > 0) then
		local icon = zo_iconFormat("esoui/art/lfg/lfg_championdungeon_up.dds", 28, 28)
		control.tooltipText = control.tooltipText..icon..championRank
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
	local championRank = GetUnitChampionPoints(unitTag)
	Siuf_UpdateGroupClassIcon(unitFrame.siufClassIcon, classId, gender, level, championRank)

	-- DEBUG: Display unit tag
	-- unitFrame.siufTagText = Siuf_CreateControl("SiufTagText", unitFrame.frame, "SiufGroupTagText")
	-- Siuf_UpdateGroupTagText(unitFrame.siufTagText, unitTag)

	unitFrame:RefreshControls()
	
	
end

local function Siuf_ShouldImproveUnitFrame(unitFrame)
	return unitFrame and (not unitFrame.hasBeenSlightlyImproved) and IsUnitOnline(unitFrame.unitTag) and (GetGroupSize() <= 4)	
end

local function Siuf_ShouldUpdateUnitFrame(unitFrame)
	return 	unitFrame.hasBeenSlightlyImproved
end

--
--
--

local function OnPowerUpdate(event, unitTag, powerPoolIndex, powerType, powerPool, powerPoolMax)
	if ZO_Group_IsGroupUnitTag(unitTag) then
		d(GetString(SI_SIUF_POWER_UPDATE), unitTag)
		local unitFrame = ZO_UnitFrames_GetUnitFrame(unitTag)
		if Siuf_ShouldUpdateUnitFrame(unitFrame) then
			local healthPool, maxHealthPool = GetUnitPower(unitTag, POWERTYPE_HEALTH)
			Siuf_UpdateGroupBarText(unitFrame.siufHealthBarText, healthPool, maxHealthPool)
			Siuf_handleUnitFrames()
		end
	end
end

local function OnLevelUpdate(event, unitTag)
	if ZO_Group_IsGroupUnitTag(unitTag) then
		d(GetString(SI_SIUF_LEVEL_UPDATE), unitTag)
		local unitFrame = ZO_UnitFrames_GetUnitFrame(unitTag)
		if Siuf_ShouldUpdateUnitFrame(unitFrame) then
			local classId = GetUnitClassId(unitTag)
			local gender = GetUnitGender(unitTag)
			local level = GetUnitLevel(unitTag)
			local championRank = GetUnitChampionPoints(unitTag)
			Siuf_UpdateGroupClassIcon(unitFrame.siufClassIcon, classId, gender, level, championRank)		
			Siuf_handleUnitFrames()
		end
	end
end

local function OnChampionPointUpdate(event, unitTag)
	if ZO_Group_IsGroupUnitTag(unitTag) then
		d(GetString(SI_SIUF_CP_UPDATE), unitTag)
		local unitFrame = ZO_UnitFrames_GetUnitFrame(unitTag)
		if Siuf_ShouldUpdateUnitFrame(unitFrame) then
			local classId = GetUnitClassId(unitTag)
			local gender = GetUnitGender(unitTag)
			local level = GetUnitLevel(unitTag)
			local championRank = GetUnitChampionPoints(unitTag)
			Siuf_UpdateGroupClassIcon(unitFrame.siufClassIcon, classId, gender, level, championRank)
		end
	end
end

local function OnUnitCreated(event, unitTag)
	if ZO_Group_IsGroupUnitTag(unitTag) then
		d(GetString(SI_SIUF_UNIT_CREATED), unitTag)

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
					d(GetString(SI_SIUF_UNITFRAME_NOT_READY))
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
						if nil == unitFrame then return false end
					end
				end
			else
				if (pollCount < pollLimit) then
					zo_callLater(pollGroupUnitFrames, pollInterval)
					pollCount = pollCount + 1
				else
					d(GetString(SI_SIUF_UNITFRAME_NOT_READY))
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

--
--
--

local function tryHideControl(control)
    if nil == control then d("control is nil") return end
    control:SetHidden(true)
	d(control:GetName())
end

function Siuf_handleUnitFrames()

    if not IsUnitGrouped('player') then return end

    tryHideControl(ZO_GroupUnitFramegroup1RoleIcon)
    tryHideControl(ZO_GroupUnitFramegroup2RoleIcon)
	tryHideControl(ZO_GroupUnitFramegroup3RoleIcon)
	tryHideControl(ZO_GroupUnitFramegroup4RoleIcon)

end

--[[
SLASH_COMMANDS["/siuf"] = function()
	Siuf_handleUnitFrames()
end
]]--

local function OnAddOnLoaded(event, addOnName)
    if (addOnName == SIUF) then

		zo_callLater(function() Siuf_handleUnitFrames() end, 1000)

		EVENT_MANAGER:UnregisterForEvent(SIUF, EVENT_ADD_ON_LOADED)

		EVENT_MANAGER:RegisterForEvent(SIUF, EVENT_UNIT_CREATED, OnUnitCreated)
		EVENT_MANAGER:RegisterForEvent(SIUF, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
		EVENT_MANAGER:RegisterForEvent(SIUF, EVENT_GROUP_MEMBER_CONNECTED_STATUS, OnGroupMemberConnectedStatus)

		EVENT_MANAGER:RegisterForEvent(SIUF, EVENT_POWER_UPDATE, OnPowerUpdate)
		EVENT_MANAGER:RegisterForEvent(SIUF, EVENT_LEVEL_UPDATE, OnLevelUpdate)
		EVENT_MANAGER:RegisterForEvent(SIUF, EVENT_CHAMPION_POINT_UPDATE, OnChampionPointUpdate)

		local filters =
		{
			REGISTER_FILTER_UNIT_TAG_PREFIX, GetString(SI_SIUF_UNITFRAME_GROUP),
			REGISTER_FILTER_POWER_TYPE, POWERTYPE_HEALTH,
		}
		EVENT_MANAGER:AddFilterForEvent(SIUF, EVENT_POWER_UPDATE, unpack(filters))
	end
end

EVENT_MANAGER:RegisterForEvent(SIUF, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
