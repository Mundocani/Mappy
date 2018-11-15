local _
_, Mappy = ...

local gAddonName = select(1, ...)

gMappy_Settings = nil

Mappy.enableBlips = true

Mappy.StackingInfo = {}

Mappy.BlizzardButtonNames = {
	"GameTimeFrame",
	"MiniMapMailFrame",
	"MiniMapTracking",
	"MiniMapWorldMapButton",
	"MiniMapBattlefieldFrame",
	"MiniMapMeetingStoneFrame",
	"MiniMapVoiceChatFrame",
	"MinimapZoomIn",
	"MinimapZoomOut",
	"FeedbackUIButton",
	"MiniMapInstanceDifficulty",
	"MiniMapLFGFrame",
	"GuildInstanceDifficulty",
	"GarrisonLandingPageMinimapButton"
}

Mappy.MinimapAttachedFrames = {
	"VehicleSeatIndicator",
	"WorldStateCaptureBar1",
	"WorldStateCaptureBar2",
	"WorldStateCaptureBar3",
	"WorldStateCaptureBar4",
	--"Boss1TargetFrame",
	--"Boss2TargetFrame",
	--"Boss3TargetFrame",
	--"Boss4TargetFrame",
	"DurabilityFrame",
	"ArenaEnemyFrames",
	"ObjectiveTrackerFrame",
}

Mappy.OtherAddonButtonNames = {
	"CT_RASets_Button",
}

Mappy.IgnoreFrames = {
	Minimap = true,
	MinimapBackdrop = true,
	MiniMapPing = true,
	MinimapToggleButton = true,
	MinimapZoneTextButton = true,
	
	CT_RASetsFrame = true,
}

Mappy.StartingCorner = "TOPRIGHT"

Mappy.CornerInfo = {
	TOPRIGHT = {
		NextCorner = "BOTTOMRIGHT",
		AnchorPoint = "TOP",
		RelativePoint = "BOTTOM",
		ButtonGap = 1,
		HorizGap = 0,
		VertGap = -1,
		HorizInsetDir = -1,
		VertInsetDir = -1,
		IsVert = true,
	},
	
	BOTTOMRIGHT = {
		NextCorner = "BOTTOMLEFT",
		AnchorPoint = "RIGHT",
		RelativePoint = "LEFT",
		ButtonGap = 1,
		HorizGap = -1,
		VertGap = 0,
		HorizInsetDir = -1,
		VertInsetDir = 1,
		IsVert = false,
	},
	
	BOTTOMLEFT = {
		NextCorner = "TOPLEFT",
		AnchorPoint = "BOTTOM",
		RelativePoint = "TOP",
		ButtonGap = 1,
		HorizGap = 0,
		VertGap = 1,
		HorizInsetDir = 1,
		VertInsetDir = 1,
		IsVert = true,
	},
	
	TOPLEFT = {
		NextCorner = "TOPRIGHT",
		AnchorPoint = "LEFT",
		RelativePoint = "RIGHT",
		ButtonGap = 1,
		HorizGap = 1,
		VertGap = 0,
		HorizInsetDir = 1,
		VertInsetDir = -1,
		IsVert = false,
	},
}

Mappy.CornerInfoCCW = {
	TOPRIGHT = {
		NextCorner = "TOPLEFT",
		AnchorPoint = "RIGHT",
		RelativePoint = "LEFT",
		ButtonGap = 1,
		HorizGap = -1,
		VertGap = 0,
		HorizInsetDir = -1,
		VertInsetDir = -1,
		IsVert = false,
	},
	
	BOTTOMRIGHT = {
		NextCorner = "TOPRIGHT",
		AnchorPoint = "BOTTOM",
		RelativePoint = "TOP",
		ButtonGap = 1,
		HorizGap = 0,
		VertGap = 1,
		HorizInsetDir = -1,
		VertInsetDir = 1,
		IsVert = true,
	},
	
	BOTTOMLEFT = {
		NextCorner = "BOTTOMRIGHT",
		AnchorPoint = "LEFT",
		RelativePoint = "RIGHT",
		ButtonGap = 1,
		HorizGap = 1,
		VertGap = 0,
		HorizInsetDir = 1,
		VertInsetDir = 1,
		IsVert = false,
	},
	
	TOPLEFT = {
		NextCorner = "BOTTOMLEFT",
		AnchorPoint = "TOP",
		RelativePoint = "BOTTOM",
		ButtonGap = 1,
		HorizGap = 0,
		VertGap = -1,
		HorizInsetDir = 1,
		VertInsetDir = -1,
		IsVert = true,
	},
}

Mappy.ProfileNameMap = {
	DEFAULT = "Normal",
	gather = "Gather",
	NONE = "Don't change"
}

Mappy.ObjectIconsNormalSmallPath = "Interface\\MINIMAP\\ObjectIconsAtlas"
Mappy.ObjectIconsHighlightSmallPath = "Interface\\Addons\\Mappy\\Textures\\ObjectIconsAtlas_On"

Mappy.ObjectIconsNormalLargePath = "Interface\\Addons\\Mappy\\Textures\\ObjectIconsAtlas_Large"
Mappy.ObjectIconsHighlightLargePath = "Interface\\Addons\\Mappy\\Textures\\ObjectIconsAtlas_On_Large"

Mappy.ObjectIconsNormalPath = ""
Mappy.ObjectIconsHighlightPath = ""

Mappy.LandmarkArrows = {}

function Mappy:AddonLoaded(pEventID, pAddonName)
	if pAddonName ~= gAddonName then
		return
	end
	
	if not gMappy_Settings then
		self:InitializeSettings()
	end
	
	--
	
	self.CurrentProfile = gMappy_Settings.Profiles[gMappy_Settings.CurrentProfileName]
	
	if not self.CurrentProfile then
		self.CurrentProfile = gMappy_Settings.Profiles.DEFAULT
	end
	
	-- Hook Minimap_UpdateRotationSetting to enforce the visibility of the 'N' arrow
	
	hooksecurefunc("Minimap_UpdateRotationSetting", function (...) Mappy:Minimap_UpdateRotationSetting(...) end)
	
	self.SchedulerLib:ScheduleUniqueTask(0.5, self.InitializeMinimap, self)
	
	self.OptionsPanel = self:New(self._OptionsPanel, UIParent)
	self.ButtonOptionsPanel = self:New(self._ButtonOptionsPanel, UIParent)
	self.ProfilesPanel = self:New(self._ProfilesPanel, UIParent)
	
	-- Commands
	
	SlashCmdList.MAPPY = function (...) Mappy:ExecuteCommand(...) end
	SLASH_MAPPY1 = "/mappy"
end

function Mappy:HookMinimapClusterGetBottom()
	MinimapCluster.Mappy_OriginalGetBottom = MinimapCluster.GetBottom
	MinimapCluster.GetBottom = MinimapCluster.GetTop
end

function Mappy:UnhookMinimapClusterGetBottom()
	MinimapCluster.GetBottom = MinimapCluster.Mappy_OriginalGetBottom
	MinimapCluster.Mappy_OriginalGetBottom = nil
end

function Mappy:InitializeSettings()
	gMappy_Settings =
	{
		Profiles =
		{
			DEFAULT =
			{
				MinimapSize = 140,
				MinimapAlpha = 1,
				MinimapCombatAlpha = 0.2,
				MinimapMovingAlpha = 0.2,

				Point = "TOPRIGHT",
				RelativePoint = "TOPRIGHT",
				OffsetX = -32,
				OffsetY = -32,
				
				HideTimeOfDay = false,
				HideZoom = false,
				HideWorldMap = false,
				HideZoneName = false,
				GhostMinimap = false,
				AutoArrangeButtons = true,
				StackToScreen = false,
				RotateMinimap = GetCVar("rotateMinimap") == "1",
				HideNorthLabel = false,
				HideBorder = false,
				HideTracking = false,
				HideTimeManagerClock = false,
				FlashGatherNodes = false,
				UseNormalIcons = false, -- use large icons
				DetachManagedFrames = false
			},
			gather =
			{
				MinimapSize = 1000,
				MinimapAlpha = 0,
				MinimapCombatAlpha = 0,
				MinimapMovingAlpha = 0,

				Point = "CENTER",
				RelativePoint = "CENTER",
				OffsetX = 0,
				OffsetY = 0,
				
				HideTimeOfDay = false,
				HideZoom = false,
				HideWorldMap = false,
				HideZoneName = false,
				GhostMinimap = true,
				AutoArrangeButtons = true,
				StackToScreen = true,
				RotateMinimap = true,
				HideNorthLabel = false,
				HideBorder = true,
				HideTracking = false,
				HideTimeManagerClock = false,
				FlashGatherNodes = true,
				UseNormalIcons = false, -- use large icons
				DetachManagedFrames = true,
				AttachmentPosition = {
					Point = "TOPRIGHT",
					RelativeTo = UIParent,
					RelativePoint = "TOPRIGHT",
					OffsetX = -80,
					OffsetY = -50
				},
				LockManagedFrames = true,
			},
		},
	}
end

function Mappy:InitializeMinimap()
	-- Locate the addon buttons around the minimap
	self:FindMinimapButtons()
	
	self:InitializeDragging()
	self:InitializeSquareShape()
	
	-- Get rid of the hide/show button
	if MinimapToggleButton then -- Not in patch 3.3
		MinimapToggleButton:Hide()
	end
	
	MinimapBorderTop:Hide()
	
	-- Add scroll wheel support
	Minimap:SetScript("OnMouseWheel", function (pMinimap, pDirection) self:MinimapMouseWheel(pDirection) end)
	Minimap:EnableMouseWheel(true)
	
	-- Add the coordinates display
	self.CoordString = Minimap:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	self.CoordString:SetHeight(12)
	self.CoordString:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 15, 15)
	
	self.SchedulerLib:ScheduleRepeatingTask(0.2, self.Update, self)
	
	-- Adjust the objective tracker so it lines up nicely with the map
	ObjectiveTrackerFrame:SetPoint("TOPRIGHT", MinimapCluster, "BOTTOMRIGHT", 10, -30)

	self:InitializeAttachedFrames()
	
	-- Register for events
	self.EventLib:RegisterEvent("ZONE_CHANGED", self.ZoneChanged, self)
	self.EventLib:RegisterEvent("ZONE_CHANGED_INDOORS", self.ZoneChanged, self)
	
	self.EventLib:RegisterEvent("PLAYER_ENTERING_WORLD", self.RegenEnabled, self)
	self.EventLib:RegisterEvent("PLAYER_REGEN_ENABLED", self.RegenEnabled, self)
	self.EventLib:RegisterEvent("PLAYER_REGEN_DISABLED", self.RegenDisabled, self)
	self.EventLib:RegisterEvent("PLAYER_STARTED_MOVING", self.StartedMoving, self)
	self.EventLib:RegisterEvent("PLAYER_STOPPED_MOVING", self.StoppedMoving, self)
	
	self:RegenEnabled()
	
	-- Schedule the configuration
	self.SchedulerLib:ScheduleUniqueTask(0.5, self.ConfigureMinimap, self)
	
	-- Monitor the mounted state so we can determine which opacity setting to use
	self.SchedulerLib:ScheduleUniqueRepeatingTask(0.5, self.UpdateMountedState, self)
end

function Mappy:InitializeAttachedFrames()
	local attachmenFrame = CreateFrame("Frame", "MappyAttachmentFrame", UIParent, "SecureFrameTemplate")
	self.AttachmentFrame = attachmenFrame

	-- Give it an initial position
	self.AttachmentFrame:SetPoint("BOTTOMRIGHT", MinimapCluster, "BOTTOMRIGHT", 0, 0)
	
	self.AttachmentFrame:SetWidth(16)
	self.AttachmentFrame:SetHeight(8)
	self.AttachmentFrame:SetFrameStrata("DIALOG")
	
	self.AttachmentFrame.Texture = self.AttachmentFrame:CreateTexture(nil, "OVERLAY")
	self.AttachmentFrame.Texture:SetAllPoints()
	self.AttachmentFrame.Texture:SetTexture(1, 1, 0)
	
	self:ActivateAttachmentFrame()
end

function Mappy:DeactivateAttachmentFrame()
	self.AttachmentFrame:RegisterForDrag()
	self.AttachmentFrame:EnableMouse(false)
	self.AttachmentFrame:SetMovable(false)
	
	self.AttachmentFrame:SetScript("OnDragStart", nil)
	self.AttachmentFrame:SetScript("OnDragStop", nil)
end

function Mappy:ActivateAttachmentFrame()
	self.AttachmentFrame:RegisterForDrag("LeftButton")
	self.AttachmentFrame:EnableMouse(true)
	self.AttachmentFrame:SetMovable(true)

	self.AttachmentFrame:SetScript("OnDragStart", function (frame)
		frame:StartMoving()
	end)
	
	self.AttachmentFrame:SetScript("OnDragStop", function (frame)
		frame:StopMovingOrSizing()
		self.CurrentProfile.AttachmentPosition = self:GetFramePosition(frame)
	end)
end

function Mappy:RecordSetPointData(frame)
	-- Wipe the anchor memory on ClearAllPoints
	hooksecurefunc(frame, "ClearAllPoints", function (frame)
		frame.Mappy_Anchors = nil
	end)

	-- Record the anchor points
	hooksecurefunc(frame, "SetPoint", function (frame, anchorPoint, relativeTo, relativePoint, offsetX, offsetY)
		local anchors = frame.Mappy_Anchors
		if not anchors then
			anchors = {}
			frame.Mappy_Anchors = anchors
		end
		
		local anchor = anchors[anchorPoint]
		if not anchor then
			anchor = {}
			anchors[anchorPoint] = anchor
		end

		assert(relativeTo ~= self.AttachmentFrame)

		anchor.relativeTo = relativeTo
		anchor.relativePoint = relativePoint
		anchor.offsetX = offsetX
		anchor.offsetY = offsetY

		-- Call the original SetPoint if not in combat lockdown
		if not InCombatLockdown() then
			local relativeTo = relativeTo
			if self.CurrentProfile.DetachManagedFrames and (relativeTo == "MinimapCluster" or relativeTo == MinimapCluster) then
				relativeTo = self.AttachmentFrame
			end
			frame:Mappy_SetPoint(anchorPoint, relativeTo, relativePoint, offsetX, offsetY)
		end
	end)
end

function Mappy:HookAttachedFrames()
	if not self.AttachmentFrame
	or not self.CurrentProfile.DetachManagedFrames then
		return
	end
	
	for _, frameName in pairs(self.MinimapAttachedFrames) do
		local frame = _G[frameName]
		
		if frame and frame.SetPoint and not frame.Mappy_DidHook then
			frame.Mappy_DidHook = true

			-- Save the existing SetPoint function 
			frame.Mappy_SetPoint = frame.SetPoint

			-- Point the original SetPoint at IsVisible instead. IsVisible is a secure function
			-- which takes no parameters and affects no state, making it a good choice for this purpose
			frame.SetPoint = frame.IsVisible

			-- Hook the existing SetPoint so the parameters can be recorded
			self:RecordSetPointData(frame)

			-- Save the hooked SetPoint for re-use later
			frame.Mappy_HookedSetPoint = frame.SetPoint
		end

		if frame then
			-- Capture the existing anchors
			local numPoints = frame:GetNumPoints()
			frame.Mappy_Anchors = {}
			for pointIndex = 1, numPoints do
				local point, relativeTo, relativePoint, offsetX, offsetY = frame:GetPoint(pointIndex)
				if relativeTo == self.AttachmentFrame then
					relativeTo = MinimapCluster
				end
				frame.Mappy_Anchors[point] = {
					relativeTo = relativeTo,
					relativePoint = relativePoint,
					offsetX = offsetX,
					offsetY = offsetY
				}
			end

			-- Use the hooked SetPoint
			frame.SetPoint = frame.Mappy_HookedSetPoint
		end
	end

	-- Refresh the anchors
	self:ReanchorDetachedFrames()
end

function Mappy:UnhookAttachedFrames()
	assert(not self.CurrentProfile.DetachManagedFrames, "unhooking but detach is still set")

	-- Refresh the anchors
	self:ReanchorDetachedFrames()
	
	-- Restore each frame to use the original SetPoint function
	for _, frameName in pairs(self.MinimapAttachedFrames) do
		local frame = _G[frameName]
		if frame then
			frame.SetPoint = frame.Mappy_SetPoint
		end
	end
end

function Mappy:ReanchorDetachedFrames()
	-- Don't allow in combat
	if InCombatLockdown() then
		Mappy:TestMessage("ReanchorDetachedFrames: In lockdown")
		return
	end
	
	--
	local detachManagedFrames = self.CurrentProfile.DetachManagedFrames
	for _, frameName in pairs(self.MinimapAttachedFrames) do
		local frame = _G[frameName]
		if frame and frame.Mappy_Anchors then
			for anchorPoint, anchor in pairs(frame.Mappy_Anchors) do
				local relativeTo = anchor.relativeTo
				local relativeToName = tostring(relativeTo)

				if type(relativeTo) == "table" and relativeTo.GetName then
					relativeToName = relativeTo:GetName()
				end

				assert(relativeTo ~= self.AttachmentFrame)

				if detachManagedFrames and (relativeTo == "MinimapCluster" or relativeTo == MinimapCluster) then
					relativeTo = self.AttachmentFrame
					relativeToName = "AttachmentFrame"
				end
				
				-- Call the real SetPoint
				frame:Mappy_SetPoint(anchorPoint, relativeTo, anchor.relativePoint, anchor.offsetX, anchor.offsetY)
			end
		end
	end
end

function Mappy:UpdateAttachmentFrame()
	if InCombatLockdown() then
		self:ErrorMessage("InCombatLockdown during UpdateAttachmentFrame")
		return
	end

	self.AttachmentFrame:ClearAllPoints()
	
	if self.CurrentProfile.DetachManagedFrames then
		if self.CurrentProfile.AttachmentPosition then
			self:SetFramePosition(self.AttachmentFrame, self.CurrentProfile.AttachmentPosition)
		else
			self.AttachmentFrame:SetPoint("BOTTOMRIGHT", MinimapCluster, "BOTTOMRIGHT", 0, 0)
		end
		
		if self.CurrentProfile.LockManagedFrames then
			self.AttachmentFrame:Hide()
		else
			self.AttachmentFrame:Show()
		end
		
		self:HookAttachedFrames()
	else
		self.AttachmentFrame:Hide()
		self:UnhookAttachedFrames()
	end
end

function Mappy:ReparentLandmarks()
	for vFrameIndex, vFrame in ipairs({Minimap:GetChildren()}) do
		-- self:DebugMessage("Frame %s: Width: %s Height: %s Type: %s", vFrame:GetName() or "anonymous", vFrame:GetWidth() or "nil", vFrame:GetHeight() or "nil", vFrame:GetObjectType() or "nil")
		
		if vFrame:GetName() ~= "MinimapBackdrop" then -- Don't reparent the backdrop since we want it to fade with the map
			vFrame:SetParent(MinimapCluster)
		end
	end
end

function Mappy:FindMinimapButtons()
	self.MinimapButtons = {}
	self.MinimapButtonsByFrame = {}
	
	for _, vButtonName in ipairs(self.BlizzardButtonNames) do
		self.IgnoreFrames[vButtonName] = true
	
		local	vButton = _G[vButtonName]
		
		if vButton then
			self:RegisterMinimapButton(vButton, true)
		end
	end
	
	for _, vButtonName in ipairs(self.OtherAddonButtonNames) do
		self.IgnoreFrames[vButtonName] = true
	
		local	vButton = _G[vButtonName]
		
		if vButton then
			self:RegisterMinimapButton(vButton)
		end
	end
	
	-- self:ShowFrameTree(Minimap)
	
	self:FindAddonButtons(MinimapCluster)
	self:FindAddonButtons(MinimapBackdrop)
	self:FindAddonButtons(Minimap)
end

function Mappy:RegisterMinimapButton(pButton, pAlwaysStack)
	if self.MinimapButtonsByFrame[pButton] then
		return
	end
	
	table.insert(self.MinimapButtons, pButton)
	self.MinimapButtonsByFrame[pButton] = true
	
	for vName, vFunction in pairs(self._MinimapButton) do
		pButton[vName] = vFunction
	end
	
	pButton.Mappy_AlwaysStack = pAlwaysStack
	
	if pAlwaysStack then
		pButton:Mappy_SetStackingEnabled(true)
	end
end

function Mappy:ConfigureMinimapOptions()
	if self.CurrentProfile.AutoArrangeButtons then
		self:EnableButtonStacking()
	else
		self:DisableButtonStacking()
	end
	
	if self.CurrentProfile.HideTimeOfDay then
		GameTimeFrame:Hide()
	else
		GameTimeFrame:Show()
	end

	if self.CurrentProfile.HideZoom then
		MinimapZoomIn:Hide()
		MinimapZoomOut:Hide()
	else
		MinimapZoomIn:Show()
		MinimapZoomOut:Show()
	end
	
	if self.CurrentProfile.HideWorldMap then
		MiniMapWorldMapButton:Hide()
	else
		MiniMapWorldMapButton:Show()
	end
	
	if self.CurrentProfile.HideZoneName then
		MinimapZoneTextButton:Hide()
	else
		MinimapZoneTextButton:Show()
	end
	
	if self.CurrentProfile.HideTracking then
		MiniMapTracking:Hide()
	else
		MiniMapTracking:Show()
	end
	
	if self.CurrentProfile.HideTimeManagerClock then
		TimeManagerClockButton:Hide()
	else
		TimeManagerClockButton:Show()
	end
	
	if self.CurrentProfile.FlashGatherNodes then
		self:StartGatherFlash()
	else
		self:StopGatherFlash()
	end

	if self.CurrentProfile.GhostMinimap then
		self:GhostMinimap()
	else
		self:UnghostMinimap()
	end
	
	if self.CurrentProfile.NormalGatherNodes then
		self.ObjectIconsNormalPath = self.ObjectIconsNormalSmallPath
		self.ObjectIconsHighlightPath = self.ObjectIconsHighlightSmallPath
	else
		self.ObjectIconsNormalPath = self.ObjectIconsNormalLargePath
		self.ObjectIconsHighlightPath = self.ObjectIconsHighlightLargePath
	end
	
	if Mappy.enableBlips then
		if self.GatherFlashState then
			Minimap:SetBlipTexture(self.ObjectIconsHighlightPath)
		else
			Minimap:SetBlipTexture(self.ObjectIconsNormalPath)
		end
	end

	self:AdjustBackgroundStyle()
end

function Mappy:EnableButtonStacking()
	self.StackingEnabled = true
	
	for _, vButton in ipairs(self.MinimapButtons) do
		vButton:Mappy_SetStackingEnabled(true)
	end
end

function Mappy:DisableButtonStacking()
	self.StackingEnabled = false
	
	for _, vButton in ipairs(self.MinimapButtons) do
		vButton:Mappy_SetStackingEnabled(false)
	end
end

function Mappy:InitializeDragging()
	MinimapCluster:SetMovable(true)
	MinimapCluster:SetUserPlaced(true)
	
	Minimap:RegisterForDrag("LeftButton")
	Minimap:SetScript("OnDragStart", function() Mappy:StartMovingMinimap() end)
	Minimap:SetScript("OnDragStop", function() Mappy:StopMovingMinimap() end)
	
	MinimapCluster.Mappy_SetPoint = MinimapCluster.SetPoint
	MinimapCluster.Mappy_ClearAllPoints = MinimapCluster.ClearAllPoints
	MinimapCluster.SetPoint = function () end
	MinimapCluster.ClearAllPoints = function () end
	
	Minimap.Mappy_SetPoint = Minimap.SetPoint
	Minimap.Mappy_ClearAllPoints = Minimap.ClearAllPoints
	Minimap.SetPoint = function () end
	Minimap.ClearAllPoints = function () end
	
	Minimap:Mappy_ClearAllPoints()
	Minimap:Mappy_SetPoint("TOPLEFT", MinimapCluster, "TOPLEFT", 0, 0)
end

function Mappy:AdjustBackgroundStyle()
	if self.CurrentProfile.HideBorder then
		MinimapBackdrop:SetBackdropBorderColor(0.75, 0.75, 0.75, 0.0)
		MinimapBackdrop:SetBackdropColor(0.15, 0.15, 0.15, 0.0, 0.0)
	else
		MinimapBackdrop:SetBackdropBorderColor(0.75, 0.75, 0.75)
		MinimapBackdrop:SetBackdropColor(0.15, 0.15, 0.15, 0.0)
	end
end

function Mappy:InitializeSquareShape()
	Minimap:SetMaskTexture("Interface\\Addons\\Mappy\\Textures\\MinimapMask")
	MinimapBorder:SetTexture(nil)
	
	MinimapBackdrop:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = {left = 3, right = 3, top = 3, bottom = 3}})

	MinimapBackdrop:SetBackdropBorderColor(0.75, 0.75, 0.75)
	MinimapBackdrop:SetBackdropColor(0.15, 0.15, 0.15, 0.0)
	MinimapBackdrop:SetAlpha(1.0)

	-- Change the backdrop to size with the map
	
	MinimapBackdrop:ClearAllPoints()
	MinimapBackdrop:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -4, 4)
	MinimapBackdrop:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 4, -4)
	
	-- Move the zone text to the top
	
	MinimapZoneTextButton:ClearAllPoints()
	MinimapZoneTextButton:SetPoint("BOTTOM", Minimap, "TOP", 0, 4)
	
end

function Mappy:SetCounterClockwise(pCCW)
	self.CurrentProfile.CCW = pCCW
	self:LoadProfile(self.CurrentProfile)
end

function Mappy:SetDetachManagedFrames(pDetach)
	self.CurrentProfile.DetachManagedFrames = pDetach
	self:LoadProfile(self.CurrentProfile)
end

function Mappy:SetLockManagedFrames(pLock)
	self.CurrentProfile.LockManagedFrames = pLock
	self:LoadProfile(self.CurrentProfile)
end

function Mappy:SetGhost(pGhost)
	if pGhost then
		self:GhostMinimap()
	else
		self:UnghostMinimap()
	end
end

function Mappy:GhostMinimap()
	self.CurrentProfile.GhostMinimap = true
	
	Minimap:RegisterForDrag()
	Minimap:EnableMouse(false)
	
	MinimapCluster:RegisterForDrag()
	MinimapCluster:EnableMouse(false)
	
	Minimap:EnableMouseWheel(false)
end

function Mappy:UnghostMinimap()
	self.CurrentProfile.GhostMinimap = false
	
	Minimap:RegisterForDrag("LeftButton")
	Minimap:EnableMouse(true)

	Minimap:SetScript("OnMouseWheel", function (self, direction) Mappy:MinimapMouseWheel(direction) end)
	Minimap:EnableMouseWheel(true)
end

function Mappy:SaveProfile(pName)
	if not pName or pName == "" then
		Mappy:ErrorMessage("You must specify a name for the profile")
		return
	end
	
	local vName = string.lower(pName)
	
	-- Clone the current profile
	
	local vProfile = {}
	
	for vKey, vValue in pairs(self.CurrentProfile) do
		vProfile[vKey] = vValue
	end
	
	gMappy_Settings.Profiles[vName] = vProfile
	gMappy_Settings.CurrentProfileName = vName
	
	self.CurrentProfile = vProfile
end

function Mappy:LoadProfileName(pName)
	if not pName or pName == "" then
		self:ErrorMessage("You must specify a name for the profile")
		return
	end
	
	local vName = pName:lower()
	
	if not gMappy_Settings.Profiles[vName] then
		self:ErrorMessage("Couldn't find a saved profile with the name %s", pName)
		return
	end
	
	gMappy_Settings.CurrentProfileName = vName
	self:LoadProfile(gMappy_Settings.Profiles[vName])
end

function Mappy:LoadDefaultProfile()
	gMappy_Settings.CurrentProfileName = "DEFAULT"
	self:LoadProfile(gMappy_Settings.Profiles.DEFAULT)
end

function Mappy:LoadProfile(pProfile)
	local vProfileChanged = self.CurrentProfile ~= pProfile
	
	self.CurrentProfile = pProfile
	
	if vProfileChanged then
		if self.OptionsPanel:IsVisible() then
			self.OptionsPanel:OnShow()
		end
		
		if self.ButtonOptionsPanel:IsVisible() then
			self.ButtonOptionsPanel:OnShow()
		end
		
		if self.ProfilesPanel:IsVisible() then
			self.ProfilesPanel:OnShow()
		end
	end
	
	self.SchedulerLib:ScheduleUniqueTask(0, self.ConfigureMinimap, self)
end

function Mappy:ExecuteCommand(pCommand)
	local	vStartIndex, vEndIndex, vCommand, vParameter = string.find(pCommand, "(%w+) ?(.*)")
	
	if not vCommand then
		self:help()
		return
	end
	
	vCommand = vCommand:lower()
	
	if self[vCommand] then
		self[vCommand](self, vParameter)
	
	-- See if there's a profile with the name and load it if there is
		
	elseif gMappy_Settings.Profiles[vCommand] then
		gMappy_Settings.CurrentProfileName = vCommand
		self:LoadProfile(gMappy_Settings.Profiles[vCommand])
	else
		self:ErrorMessage("Expected command")
	end
end

function Mappy:help()
	self:NoteMessage(HIGHLIGHT_FONT_COLOR_CODE.."/mappy help"..NORMAL_FONT_COLOR_CODE..": Shows this list")
	self:NoteMessage(HIGHLIGHT_FONT_COLOR_CODE.."/mappy default"..NORMAL_FONT_COLOR_CODE..": Loads the default profile")
	self:NoteMessage(HIGHLIGHT_FONT_COLOR_CODE.."/mappy normal"..NORMAL_FONT_COLOR_CODE..": Alias for /mappy default")
	self:NoteMessage(HIGHLIGHT_FONT_COLOR_CODE.."/mappy save settingsname"..NORMAL_FONT_COLOR_CODE..": Saves the settings under the name settingsname")
	self:NoteMessage(HIGHLIGHT_FONT_COLOR_CODE.."/mappy load settingsname"..NORMAL_FONT_COLOR_CODE..": Loads the settings")
	self:NoteMessage(HIGHLIGHT_FONT_COLOR_CODE.."/mappy settingsname"..NORMAL_FONT_COLOR_CODE..": Shorthand version of /mappy load")
	self:NoteMessage(HIGHLIGHT_FONT_COLOR_CODE.."/mappy ghost"..NORMAL_FONT_COLOR_CODE..": Mouse clicks in the minimap will be passed through to the background")
	self:NoteMessage(HIGHLIGHT_FONT_COLOR_CODE.."/mappy unghost"..NORMAL_FONT_COLOR_CODE..": Mouse clicks work as usual")
	self:NoteMessage(HIGHLIGHT_FONT_COLOR_CODE.."/mappy corner TOPLEFT|TOPRIGHT|BOTTOMLEFT|BOTTOMRIGHT"..NORMAL_FONT_COLOR_CODE..": Sets the starting corner for button stacking")
	self:NoteMessage(HIGHLIGHT_FONT_COLOR_CODE.."/mappy reset"..NORMAL_FONT_COLOR_CODE..": Resets all settings and profiles")
end

function Mappy:ghost(pParameter)
	self:GhostMinimap()
end

function Mappy:unghost(pParameter)
	self:UnghostMinimap()
end

function Mappy:save(pParameter)
	self:SaveProfile(pParameter)
end

function Mappy:load(pParameter)
	self:LoadProfileName(pParameter)
end

function Mappy:normal(pParameter)
	self:LoadDefaultProfile()
end

Mappy.default = Mappy.normal -- Alias the 'normal' command as 'default'

function Mappy:corner(pParameter)
	local vCorner = pParameter:upper()
	
	if vCorner == "TOPLEFT"
	or vCorner == "TOPRIGHT"
	or vCorner == "BOTTOMLEFT"
	or vCorner == "BOTTOMRIGHT" then
		self.CurrentProfile.StartingCorner = vCorner
		self:LoadProfile(self.CurrentProfile)
	else
		self:ErrorMessage("Corner must be TOPLEFT, TOPRIGHT, BOTTOMLEFT, or BOTTOMRIGHT")
	end
end

function Mappy:cw(pParameter)
	self:SetCCW(false)
end

function Mappy:ccw(pParameter)
	self:SetCCW(true)
end

function Mappy:reset(pParameter)
	self:InitializeSettings()
	self:LoadProfile(gMappy_Settings.Profiles.DEFAULT)
end

function Mappy:gcompact()
	self:CompactGatherer()
end

function Mappy:BeginStackingButtons()
	if self.CurrentProfile.StackToScreen then
		self.StackingInfo.StackingParent = UIParent
		
		if self.CurrentProfile.HideTimeOfDay then
			self.StackingInfo.StackingInsetX = 18
			self.StackingInfo.StackingInsetY = 18
		else
			self.StackingInfo.StackingInsetX = 24
			self.StackingInfo.StackingInsetY = 24
		end
	else
		self.StackingInfo.StackingParent = Minimap
		self.StackingInfo.StackingInsetX = 0
		self.StackingInfo.StackingInsetY = 0
	end
	
	self.StackingInfo.Corner = self.StartingCorner
	self.StackingInfo.CornerInfo = (self.CurrentProfile.CCW and self.CornerInfoCCW or self.CornerInfo)[self.StackingInfo.Corner]
	self.StackingInfo.PreviousButton = nil
	
	if self.StackingInfo.CornerInfo.IsVert then
		self.StackingInfo.SpaceRemaining = self.StackingInfo.StackingParent:GetHeight() - (2 * self.StackingInfo.StackingInsetY)
	else
		self.StackingInfo.SpaceRemaining = self.StackingInfo.StackingParent:GetWidth() - (2 * self.StackingInfo.StackingInsetX)
	end
	
	self.StackingInfo.ButtonFrameLevel = Minimap:GetFrameLevel() + 5
end

function Mappy:StackButton(pButton, pNextButton)
	-- Calculate the space used by the button
	
	local	vSpaceUsed
	local	vButtonSize = pButton:GetHeight()
	
	if not self.StackingInfo.PreviousButton then
		vSpaceUsed = vButtonSize / 2 -- Corner, so use half the size
	else
		vSpaceUsed = vButtonSize + self.StackingInfo.CornerInfo.ButtonGap
	end
	
	-- See if there's going to be room for the next button
	
	if pNextButton then
		local	vSpaceNeeded = vSpaceUsed + pNextButton:GetHeight() / 2
		
		if self.StackingInfo.Corner:sub(1, 6) == "BOTTOM"
		and not self.StackingInfo.CornerInfo.IsVert
		and self.StackingInfo.StackingParent == Minimap
		and self.StackingInfo.PreviousButton
		and TimeManagerClockButton
		and TimeManagerClockButton:IsVisible() then
			if self.CurrentProfile.CCW then
				if self.StackingInfo.PreviousButton:GetRight() < TimeManagerClockButton:GetRight()
				and self.StackingInfo.PreviousButton:GetRight() + vSpaceUsed > TimeManagerClockButton:GetLeft() then
					local vGapWidth = TimeManagerClockButton:GetLeft() - self.StackingInfo.PreviousButton:GetRight()
					local vClockButtonWidth = TimeManagerClockButton:GetWidth()
					
					self.StackingInfo.PreviousButton = TimeManagerClockButton
					self.StackingInfo.SpaceRemaining = self.StackingInfo.SpaceRemaining - vClockButtonWidth - vGapWidth
				end
			else
				if self.StackingInfo.PreviousButton:GetLeft() > TimeManagerClockButton:GetLeft()
				and self.StackingInfo.PreviousButton:GetLeft() - vSpaceUsed < TimeManagerClockButton:GetRight() then
					local vGapWidth = self.StackingInfo.PreviousButton:GetLeft() - TimeManagerClockButton:GetRight()
					local vClockButtonWidth = TimeManagerClockButton:GetWidth()
					
					self.StackingInfo.PreviousButton = TimeManagerClockButton
					self.StackingInfo.SpaceRemaining = self.StackingInfo.SpaceRemaining - vClockButtonWidth - vGapWidth
				end
			end
		end
		
		if self.StackingInfo.SpaceRemaining < vSpaceNeeded then
			-- Change the stacking direction and corner
			
			self.StackingInfo.Corner = self.StackingInfo.CornerInfo.NextCorner
			self.StackingInfo.CornerInfo = (self.CurrentProfile.CCW and self.CornerInfoCCW or self.CornerInfo)[self.StackingInfo.Corner]
			self.StackingInfo.PreviousButton = nil
			
			if self.StackingInfo.CornerInfo.IsVert then
				self.StackingInfo.SpaceRemaining = self.StackingInfo.StackingParent:GetHeight() - (2 * self.StackingInfo.StackingInsetY)
			else
				self.StackingInfo.SpaceRemaining = self.StackingInfo.StackingParent:GetWidth() - (2 * self.StackingInfo.StackingInsetX)
			end
			
			vSpaceUsed = vButtonSize / 2
		end
	end
	
	-- Stack the button
	
	MinimapCluster:SetAlpha(1)
	
	pButton:SetParent(MinimapCluster)
	pButton:SetAlpha(1)
	Mappy.SetFrameLevel(pButton, self.StackingInfo.ButtonFrameLevel)
	
	if not pButton.Mappy_ClearAllPoints then
		self:DebugMark()
		self:DebugMessage("Mappy_ClearAllPoints is nil.  Name is %s", pButton:GetName() or "nil")
		self:DebugTable("pButton", pButton)
		self:DebugStack()
	end
	
	pButton:Mappy_ClearAllPoints()
	
	if not self.StackingInfo.PreviousButton then
		pButton:Mappy_SetPoint(
				"CENTER",
				self.StackingInfo.StackingParent,
				self.StackingInfo.Corner,
				self.StackingInfo.CornerInfo.HorizInsetDir * self.StackingInfo.StackingInsetX,
				self.StackingInfo.CornerInfo.VertInsetDir * self.StackingInfo.StackingInsetY)
		
		self.StackingInfo.PreviousButton = pButton
	else
		pButton:Mappy_SetPoint(
				self.StackingInfo.CornerInfo.AnchorPoint,
				self.StackingInfo.PreviousButton,
				self.StackingInfo.CornerInfo.RelativePoint,
				self.StackingInfo.CornerInfo.HorizGap, self.StackingInfo.CornerInfo.VertGap)
	end
	
	self.StackingInfo.SpaceRemaining = self.StackingInfo.SpaceRemaining - vSpaceUsed
	self.StackingInfo.PreviousButton = pButton
end

function Mappy:SetMinimapAlpha(pAlpha)
	if self.DisableUpdates then
		return
	end
	
	self.CurrentProfile.MinimapAlpha = pAlpha
	self:AdjustAlpha(pAlpha)
end

function Mappy:SetMinimapCombatAlpha(pAlpha)
	if self.DisableUpdates then
		return
	end
	
	self.CurrentProfile.MinimapCombatAlpha = pAlpha
	self:AdjustAlpha(pAlpha)
end

function Mappy:SetMinimapMovingAlpha(pAlpha)
	if self.DisableUpdates then
		return
	end
	
	self.CurrentProfile.MinimapMovingAlpha = pAlpha
	self:AdjustAlpha(pAlpha)
end

function Mappy:SetMinimapSize(pSize)
	if self.DisableUpdates then
		return
	end
	
	self.CurrentProfile.MinimapSize = pSize
	self.SchedulerLib:ScheduleUniqueTask(0, self.ConfigureMinimap, self)
end

function Mappy:ConfigureMinimap()
	-- Bail out if the minimap is in a protected state
	if MinimapCluster:IsProtected() and not MinimapCluster:CanChangeProtectedState() then
		return
	end
	
	if InCombatLockdown() then
		return
	end

	self.StartingCorner = self.CurrentProfile.StartingCorner or "TOPRIGHT"
	
	self:ConfigureMinimapOptions()
	
	self:SetFramePosition(MinimapCluster, self.CurrentProfile)
	
	self:UpdateAttachmentFrame()
	
	Minimap:SetWidth(self.CurrentProfile.MinimapSize)
	Minimap:SetHeight(self.CurrentProfile.MinimapSize)
	
	MinimapCluster:SetWidth(self.CurrentProfile.MinimapSize)
	MinimapCluster:SetHeight(self.CurrentProfile.MinimapSize)
	
	for vMapArrow, _ in pairs(self.LandmarkArrows) do
		vMapArrow.Mappy.SetWidth(vMapArrow, self.CurrentProfile.MinimapSize * 1.1)
		vMapArrow.Mappy.SetHeight(vMapArrow, self.CurrentProfile.MinimapSize * 1.1)
	end
	
	Minimap:SetScale(1.001) -- Poke the scaling to force a refresh of the minimap size
	Minimap:SetScale(1)
	
	if TimeManagerClockButton then
		TimeManagerClockButton:ClearAllPoints()
		TimeManagerClockButton:SetPoint("CENTER", Minimap, "BOTTOM", 0, -2)
--		TimeManagerClockButton:SetFrameLevel(10)
	end
	
	-- Stack all the known buttons
	
	self:BeginStackingButtons()

	local	vButton
	
	for _, vNextButton in pairs(self.MinimapButtons) do
		if vNextButton.Mappy_SetPoint then
			if vButton and vButton:IsVisible() then
				self:StackButton(vButton, vNextButton)
			end
			
			vButton = vNextButton
		end
	end
	
	if vButton and vButton:IsVisible() then
		self:StackButton(vButton, nil)
	end
	
	self:AdjustAlpha()
	
	-- Update the rotation
	if self.CurrentProfile.RotateMinimap ~= nil then
		if self.CurrentProfile.RotateMinimap then
			SetCVar("rotateMinimap", "1")
		else
			SetCVar("rotateMinimap", "0")
		end
		
		Minimap_UpdateRotationSetting()
	end

	-- Update the cluster position hack
	Mappy:UpdateMinimapClusterBottomHook()
end

function Mappy:UpdateMinimapClusterBottomHook()
	-- Blizzard modified MultiActionBars to calculate a scaling value based on the
	-- MinimapCluster's bottom position. This causes problems if the bottom is too
	-- low on the screen (gather mode or positioning map in a bottom corner, for
	-- example), so I'm hooking GetBottom() to return a high number to avoid the problem.
	local minimapClusterBottomIsHooked = MinimapCluster.Mappy_OriginalGetBottom ~= nil

	-- Get the actual bottom of the minimap
	local minimapClusterBottom
	if minimapClusterBottomIsHooked then
		minimapClusterBottom = MinimapCluster.Mappy_OriginalGetBottom(MinimapCluster)
	else
		minimapClusterBottom = MinimapCluster:GetBottom()
	end

	-- Determine if the hook should be applied
	local minimapClusterBottomMin = UIParent:GetTop() * 0.75
	local minimapClusterBottomNeedsHooked = minimapClusterBottom < minimapClusterBottomMin

	-- Leave if the hook state is already good
	if minimapClusterBottomNeedsHooked == minimapClusterBottomIsHooked then
		return
	end

	-- Hook/unhook
	if minimapClusterBottomNeedsHooked then
		Mappy:HookMinimapClusterGetBottom()
	else
		Mappy:UnhookMinimapClusterGetBottom()
	end
end

function Mappy:GetUIObjectDescription(pUIObject)
	local	vDimensions = math.floor(pUIObject:GetWidth() + 0.5).."x"..math.floor(pUIObject:GetHeight() + 0.5)
	local	vIsShown, vIsVisible
	
	if pUIObject:IsShown() then
		vIsShown = "shown"
	else
		vIsShown = "hidden"
	end
	
	if pUIObject:IsVisible() then
		vIsVisible = "visible"
	else
		vIsVisible = "invisible"
	end
	
	return string.format("%s %s %s %s", vDimensions, pUIObject:GetObjectType(), vIsShown, vIsVisible)
end

function Mappy:ShowFrameTree(pFrame, pFrameLabel, pIndentString)
	local	vNumRegions = pFrame:GetNumRegions()
	local	vNumChildren = pFrame:GetNumChildren()
	
	if not pIndentString then
		pIndentString = ""
	end
	
	if not pFrameLabel then
		Mappy.AnonFrames = {}
		pFrameLabel = pFrame:GetName() or "anonymous"
	end
	
	Mappy:DebugMessage(string.format("%s%s: %s", pIndentString, pFrameLabel, self:GetUIObjectDescription(pFrame)))
	
	local	vIndentString = pIndentString.."    "
	
	if vNumRegions > 0 then
		Mappy:DebugMessage(string.format("%sRegions (%d)", pIndentString, vNumRegions))
		
		for vRegionIndex, vRegion in pairs({pFrame:GetRegions()}) do
			local	vRegionLabel = vRegion:GetName() or ("["..vRegionIndex.."]")
			
			Mappy:DebugMessage(string.format("%s%s: %s", vIndentString, vRegionLabel, self:GetUIObjectDescription(vRegion)))
		end
	end
	
	if vNumChildren > 0 then
		Mappy:DebugMessage(string.format("%sChildren (%d)", pIndentString, vNumChildren))
		
		for vFrameIndex, vFrame in pairs({pFrame:GetChildren()}) do
			local	vFrameName = vFrame:GetName()
			local	vFrameLabel = vFrameName or ("["..vFrameIndex.."]")
			
			if not vFrameName then
				table.insert(Mappy.AnonFrames, vFrame)
			end
			
			self:ShowFrameTree(vFrame, vFrameLabel, vIndentString)
		end
	end
end

function Mappy:IsAnchoredToFrame(pFrame, pAnchoredTo)
	local	vNumPoints = pFrame:GetNumPoints()

	for vPointIndex = 1, vNumPoints do
		local vPoint, vRelativeTo, vRelativePoint, vXOffset, vYOffset = pFrame:GetPoint(vPointIndex)
		
		if vRelativeTo == pAnchoredTo then
			return true
		end
	end
	
	return false
end

function Mappy:IsButtonFrame(pFrame, pAnchoredTo)
	if pFrame:IsForbidden() then
		return false
	end
	local	vFrameName = pFrame:GetName() or "Anonymous"
	local	vFrameType = pFrame.GetObjectType and pFrame:GetObjectType() or pFrame:GetFrameType()
	local	vFrameWidth = pFrame:GetWidth()
	local	vFrameHeight = pFrame:GetHeight()

	if self.IgnoreFrames[vFrameName]
	or self.MinimapButtonsByFrame[pFrame]
	or vFrameType == "Model"
	or vFrameWidth < 24 or vFrameWidth > 48
	or math.abs(vFrameHeight - vFrameWidth) > 1e-3 then
		return false
	end
	
	if pAnchoredTo and not self:IsAnchoredToFrame(pFrame, pAnchoredTo) then
		return false
	end
	
	-- DEFAULT_CHAT_FRAME:AddMessage("Found minimap button "..vFrameName)
	return true
end

function Mappy:FindAddonButtons(pFrame, pAnchoredTo)
	for _, vFrame in pairs({pFrame:GetChildren()}) do
		if self:IsButtonFrame(vFrame, pAnchoredTo) then
			self:RegisterMinimapButton(vFrame)
		end
	end
	
	if not pAnchoredTo then
		self:FindAddonButtons(UIParent, pFrame)
	end
end

function Mappy:IsDruidTravelForm()
	local _, vClassID = UnitClass("player")
	
	if vClassID ~= "DRUID" then
		return false
	end
	
	local vIndex = 1
	
	while true do
		local vName, vRank, vIcon, vCount, vDebuffType,
			  vDuration, vExpirationTime, vUnitCaster,
			  vIsStealable, vShouldConsolidate, vSpellID = UnitAura("player", vIndex, "HELPFUL")
		
		if not vName then
			return false
		end
		
		if vSpellID == 33943
		or vSpellID == 40120
		or vSpellID == 783 then
			return true
		end
		
		vIndex = vIndex + 1
	end
end

function Mappy:ShouldForceMapToOpaque()
	return IsIndoors()
end

function Mappy:GetInstanceType()
	local _, instanceType, _, _, _, _, _, instanceMapID = GetInstanceInfo()
	
	-- Remap the Garrison instance to an outdoor type
	if instanceMapID == 1159 then
		instanceType = nil
	end

	-- Done
	return instanceType
end

function Mappy:SelectAutoProfile()
	-- Leave if in combat lockdown
	if InCombatLockdown() then
		return
	end

	-- Use the instance type to figure out which profile to select
	local profileName

	local instanceType = self:GetInstanceType()
	if instanceType == "party"
	or instanceType == "raid" then
		profileName = gMappy_Settings.DungeonProfile
	elseif instanceType == "pvp" then
		profileName = gMappy_Settings.BattlegroundProfile
	elseif IsMounted() or IsFlying() or self:IsDruidTravelForm() or UnitInVehicle("player") then
		profileName = gMappy_Settings.MountedProfile
	else
		profileName = gMappy_Settings.DefaultProfile
	end
	
	-- Do nothing if no profile was selected
	if not profileName then
		return
	end
	
	-- Fetch the profile
	local profile = gMappy_Settings.Profiles[profileName]
	if not profile then
		return
	end
	
	-- Load the profile if it's changing
	if profile ~= self.CurrentProfile then
		self:LoadProfile(profile)
	end
end

function Mappy:Update()
	self:SelectAutoProfile()
	
	-- Update the alpha
	
	local	vIndoors = IsIndoors()
	
	if self.wasIndoors ~= vIndoors then
		self.wasIndoors = vIndoors
		self:AdjustAlpha()
	end

	local	vResting = IsResting()
	
	if self.wasResting ~= vResting then
		self.wasResting = vResting
		self:AdjustAlpha()
	end
	
	-- Update the coords
	if not self.CurrentProfile.HideCoordinates then
		self:UpdateCoords()
	end
end

function Mappy:UpdateCoords()
	if false then
		local	vX, vY = GetPlayerMapPosition("player")
		if not vX or not vY or (vX == 0 and vY == 0) then
			self.CoordString:SetText("")
		else
			self.CoordString:SetText(string.format("%.1f, %.1f", vX * 100, vY * 100))
		end
	end
end

function Mappy:AdjustAlpha(pForceAlpha)
	if pForceAlpha then
		Minimap:SetAlpha(pForceAlpha)
		if self.MappyPlayerArrow then
			self.MappyPlayerArrow:SetAlpha(1 - pForceAlpha)
		end
	else
		local vAlpha
		
		if self.InCombat and not self.IsMounted then
			vAlpha = self.CurrentProfile.MinimapCombatAlpha or 0.2
		elseif self.IsMoving then
			vAlpha = self.CurrentProfile.MinimapMovingAlpha or 0.2
		else
			vAlpha = self.CurrentProfile.MinimapAlpha or 1
		end
		
		-- Force the alpha to 1 if we're indoors.  The minimap doesn't work
		-- properly if the alpha isn't 1 (it'll just show solid black) while
		-- indoors (in this case, indoors means any major city, inside any building, any dungeon)
		-- Detection of 'indoors' is imperfect however, so there are still times that the minimap
		-- will go black when you don't want it to
		
		local forceToOpaque = self:ShouldForceMapToOpaque()
		if vAlpha > 0 and forceToOpaque then
			vAlpha = 1
		end

		if Minimap:GetAlpha() ~= vAlpha then
			Minimap:SetAlpha(vAlpha)

			if self.MappyPlayerArrow then
				self.MappyPlayerArrow:SetAlpha(1 - vAlpha)
			end

			-- Fudge the zoom to force the minimap to re-paint
			local minimapZoom = Minimap:GetZoom()
			if minimapZoom > 0 then
				Minimap:SetZoom(minimapZoom - 1)
			else
				Minimap:SetZoom(minimapZoom + 1)
			end
			Minimap:SetZoom(minimapZoom)
		end
	end
end

function Mappy:ZoneChanged()
	self:AdjustAlpha()
end

function Mappy:RegenEnabled()
	self.InCombat = false

	-- Refresh all the attached frames
	self:ReanchorDetachedFrames()

	-- Do a reconfiguration after a short delay
	self.SchedulerLib:ScheduleUniqueTask(0.25, self.ConfigureMinimap, self)
end

function Mappy:RegenDisabled()
	self.InCombat = true

	-- Hide the attachment frame during combat
	self.AttachmentFrame:Hide()
	
	-- Adjust the alpha for combat
	self:AdjustAlpha()
end

function Mappy:StartedMoving()
	self.IsMoving = true
	self:AdjustAlpha()
end

function Mappy:StoppedMoving()
	self.IsMoving = false
	self:AdjustAlpha()
end

function Mappy:UpdateMountedState()
	local	isMounted = IsMounted()
	
	if self.IsMounted == isMounted then
		return
	end
	
	self.IsMounted = isMounted
	self:AdjustAlpha()
end

function Mappy:SetFlashGatherNodes(pFlash)
	if pFlash then
		self.CurrentProfile.FlashGatherNodes = true
		self:StartGatherFlash()
	else
		self.CurrentProfile.FlashGatherNodes = nil
		self:StopGatherFlash()
	end
end

function Mappy:SetLargeGatherNodes(pLarge)
	self.CurrentProfile.NormalGatherNodes = not pLarge
	self:ConfigureMinimapOptions()
end

function Mappy:SetHideTracking(pHide)
	if pHide then
		self.CurrentProfile.HideTracking = true
		MiniMapTracking:Hide()
	else
		self.CurrentProfile.HideTracking = nil
		MiniMapTracking:Show()
	end
end

function Mappy:SetHideTimeManagerClock(pHide)
	if pHide then
		self.CurrentProfile.HideTimeManagerClock = true
		TimeManagerClockButton:Hide()
	else
		self.CurrentProfile.HideTimeManagerClock = nil
		TimeManagerClockButton:Show()
	end
end

function Mappy:SetHideTimeOfDay(pHide)
	if pHide then
		self.CurrentProfile.HideTimeOfDay = true
		GameTimeFrame:Hide()
	else
		self.CurrentProfile.HideTimeOfDay = nil
		GameTimeFrame:Show()
	end
end

function Mappy:SetHideZoom(pHide)
	if pHide then
		self.CurrentProfile.HideZoom = true
		MinimapZoomIn:Hide()
		MinimapZoomOut:Hide()
	else
		self.CurrentProfile.HideZoom = nil
		MinimapZoomIn:Show()
		MinimapZoomOut:Show()
	end
end

function Mappy:SetHideWorldMap(pHide)
	if pHide then
		self.CurrentProfile.HideWorldMap = true
		MiniMapWorldMapButton:Hide()
	else
		self.CurrentProfile.HideWorldMap = nil
		MiniMapWorldMapButton:Show()
	end
end

function Mappy:SetHideCoordinates(pHide)
	if pHide then
		self.CurrentProfile.HideCoordinates = true
		self.CoordString:SetText("")
	else
		self.CurrentProfile.HideCoordinates = nil
	end
end

function Mappy:SetHideZoneName(pHide)
	if pHide then
		self.CurrentProfile.HideZoneName = true
		MinimapZoneTextButton:Hide()
	else
		self.CurrentProfile.HideZoneName = nil
		MinimapZoneTextButton:Show()
	end
end

function Mappy:SetLockPosition(pLock)
	if pLock then
		self.CurrentProfile.LockPosition = true
	else
		self.CurrentProfile.LockPosition = nil
	end
end

function Mappy:SetHideNorthLabel(pHide)
	if pHide then
		self.CurrentProfile.HideNorthLabel = true
		MinimapNorthTag:Hide()
	else
		self.CurrentProfile.HideNorthLabel = nil
		if GetCVar("rotateMinimap") ~= "1" then
			MinimapNorthTag:Show()
		end
	end
end

function Mappy:SetHideBorder(pHide)
	self.CurrentProfile.HideBorder = pHide and true or nil
	self:AdjustBackgroundStyle()
end

function Mappy:SetAutoArrangeButtons(pEnable)
	if pEnable then
		self.CurrentProfile.AutoArrangeButtons = true
		self:EnableButtonStacking()
	else
		self.CurrentProfile.AutoArrangeButtons = nil
		self:DisableButtonStacking()
	end
	
	self.SchedulerLib:ScheduleUniqueTask(0, self.ConfigureMinimap, self)
end

function Mappy:SetStackToScreen(pStackToScreen)
	if pStackToScreen then
		self.CurrentProfile.StackToScreen = true
	else
		self.CurrentProfile.StackToScreen = nil
	end
	
	self.SchedulerLib:ScheduleUniqueTask(0, self.ConfigureMinimap, self)
end

function Mappy.Button_OnHide(self, ...)
	local	vResult
	
	if self.Mappy_OnHide then
		vResult = self:Mappy_OnHide(...)
	end
	
	Mappy.SchedulerLib:ScheduleUniqueTask(0, Mappy.ConfigureMinimap, Mappy)
	
	return vResult
end

function Mappy.Button_OnShow(self, ...)
	local	vResult
	
	if self.Mappy_OnShow then
		vResult = self:Mappy_OnShow(...)
	end
	
	Mappy.SchedulerLib:ScheduleUniqueTask(0, Mappy.ConfigureMinimap, Mappy)
	
	return vResult
end

----------------------------------------
Mappy._MinimapButton = {}
----------------------------------------

function Mappy._MinimapButton:Mappy_SetStackingEnabled(pEnable)
	if pEnable then
		if not self.Mappy_SetPoint then
			self:Mappy_SaveAnchors()
			
			self.Mappy_SetPoint = self.SetPoint
			self.Mappy_ClearAllPoints = self.ClearAllPoints
			self.Mappy_OnHide = self:GetScript("OnHide")
			self.Mappy_OnShow = self:GetScript("OnShow")
			
			self.SetPoint = self.Mappy_SaveSetPoint
			self.ClearAllPoints = self.Mappy_SaveClearAllPoints
			self:SetScript("OnHide", Mappy.Button_OnHide)
			self:SetScript("OnShow", Mappy.Button_OnShow)
		end
	else
		if self.Mappy_SetPoint and not self.Mappy_AlwaysStack then
			self.SetPoint = self.Mappy_SetPoint
			self.ClearAllPoints = self.Mappy_ClearAllPoints
			self:SetScript("OnHide", self.Mappy_OnHide)
			self:SetScript("OnShow", self.Mappy_OnShow)
			
			self.Mappy_SetPoint = nil
			self.Mappy_ClearAllPoints = nil
			self.Mappy_OnHide = nil
			self.Mappy_OnShow = nil
			
			self:Mappy_RestoreAnchors()
		end
	end
end

function Mappy._MinimapButton:Mappy_SaveAnchors()
	if self.Mappy_SavedAnchors then
		return
	end
	
	self.Mappy_SavedAnchors = {}
	
	for vIndex = 1, self:GetNumPoints() do
		local vPoint, vRelativeTo, vRelativePoint, vOffsetX, vOffsetY = self:GetPoint(vIndex)
		
		self.Mappy_SavedAnchors[vPoint] = {RelativeTo = vRelativeTo, RelativePoint = vRelativePoint, OffsetX = vOffsetX, OffsetY = vOffsetY}
	end
end

function Mappy._MinimapButton:Mappy_RestoreAnchors()
	if not self.Mappy_SavedAnchors then
		return
	end
	
	self:ClearAllPoints()

	for vPoint, vAnchorInfo in pairs(self.Mappy_SavedAnchors) do
		self:SetPoint(vPoint, vAnchorInfo.RelativeTo, vAnchorInfo.RelativePoint, vAnchorInfo.OffsetX, vAnchorInfo.OffsetY)
	end
	
	self.Mappy_SavedAnchors = nil
end

function Mappy._MinimapButton:Mappy_SaveSetPoint(pPoint, pRelativeTo, pRelativePoint, pOffsetX, pOffsetY)
	if not self.Mappy_SavedAnchors then
		return
	end
	
	self.Mappy_SavedAnchors[pPoint] = {RelativeTo = pRelativeTo, RelativePoint = pRelativePoint, OffsetX = pOffsetX, OffsetY = pOffsetY}
end

function Mappy._MinimapButton:Mappy_SaveClearAllPoints()
	if not self.Mappy_SavedAnchors then
		return
	end
	
	for vKey, _ in pairs(self.Mappy_SavedAnchors) do
		self.Mappy_SavedAnchors[vKey] = nil
	end
end

function Mappy:MinimapMouseWheel(pWheelDirection)
	local	vZoom = Minimap:GetZoom()
	
	if pWheelDirection > 0 then
		if vZoom < (Minimap:GetZoomLevels() - 1) then
			Minimap:SetZoom(vZoom + 1)
		end
		
		MinimapZoomOut:Enable()
		
		if Minimap:GetZoom() == (Minimap:GetZoomLevels() - 1) then
			MinimapZoomIn:Disable()
		end
	else
		if vZoom > 0 then
			Minimap:SetZoom(vZoom - 1)
		end

		MinimapZoomIn:Enable()
		
		if Minimap:GetZoom() == 0 then
			MinimapZoomOut:Disable()
		end
	end
end

function Mappy:StartMovingMinimap()
	if self.CurrentProfile.LockPosition then
		return
	end
	
	-- Enable moving
	
	MinimapCluster.SetPoint = MinimapCluster.Mappy_SetPoint
	MinimapCluster.ClearAllPoints = MinimapCluster.Mappy_ClearAllPoints
	
	-- Start moving
	
	MinimapCluster:StartMoving()
end

function Mappy:StopMovingMinimap()
	if self.CurrentProfile.LockPosition then
		return
	end
	
	-- Stop moving
	
	MinimapCluster:StopMovingOrSizing()
	
	-- Disable moving
	
	MinimapCluster.SetPoint = function () end
	MinimapCluster.ClearAllPoints = function () end
	
	-- Save the new position
	
	MinimapCluster:SetUserPlaced(true) -- Must leave this true or UIParent will screw up laying out windows
	
	self:PositionChanged()
end

function Mappy:StartGatherFlash()
	self.EnableFlashingNodes = true
	
	if not self.ObjectIconsNormalCache then
		self.ObjectIconsNormalCache = MinimapCluster:CreateTexture(nil, "BACKGROUND")
		self.ObjectIconsNormalCache:SetPoint("TOPLEFT", MinimapCluster, "TOPLEFT", 0, 0)
		self.ObjectIconsNormalCache:SetWidth(1)
		self.ObjectIconsNormalCache:SetHeight(1)
		self.ObjectIconsNormalCache:SetAlpha(0.01)

		self.ObjectIconsHighlightCache = MinimapCluster:CreateTexture(nil, "BACKGROUND")
		self.ObjectIconsHighlightCache:SetPoint("TOPLEFT", MinimapCluster, "TOPLEFT", 0, 0)
		self.ObjectIconsHighlightCache:SetWidth(1)
		self.ObjectIconsHighlightCache:SetHeight(1)
		self.ObjectIconsHighlightCache:SetAlpha(0.01)
	end
	
	if self.ObjectIconsNormalCache then
		self.ObjectIconsNormalCache:SetTexture(self.ObjectIconsNormalPath)
		self.ObjectIconsHighlightCache:SetTexture(self.ObjectIconsHighlightPath)
	end
	
	self.SchedulerLib:ScheduleUniqueRepeatingTask(0.5, self.UpdateGatherFlash, self)
end

function Mappy:StopGatherFlash()
	self.EnableFlashingNodes = false
	
	if self.ObjectIconsNormalCache then
		self.ObjectIconsNormalCache:SetTexture("")
		self.ObjectIconsHighlightCache:SetTexture("")
	end
end

function Mappy:UpdateGatherFlash()
	if not Mappy.enableBlips then
		return
	end

	if not self.EnableFlashingNodes then
		self.SchedulerLib:UnscheduleTask(self.UpdateGatherFlash, self)
		Minimap:SetBlipTexture(self.ObjectIconsNormalPath)
		return
	end

	self.GatherFlashState = not self.GatherFlashState

	if self.GatherFlashState then
		-- Re-set the texture caches because the Mac client doesn't seem to work right the first try
		-- self.ObjectIconsHighlightCache:SetTexture(self.ObjectIconsHighlightPath)

		-- Set the minimap texture
		Minimap:SetBlipTexture(self.ObjectIconsHighlightPath)
	else
		-- Re-set the texture caches because the Mac client doesn't seem to work right the first try
		-- self.ObjectIconsNormalCache:SetTexture(self.ObjectIconsNormalPath)

		-- Set the minimap texture
		Minimap:SetBlipTexture(self.ObjectIconsNormalPath)
	end
end

function Mappy:GetFramePosition(pFrame)
	local vUIScale = UIParent:GetEffectiveScale()
	
	local vUILeft = UIParent:GetLeft() * vUIScale
	local vUIRight = UIParent:GetRight() * vUIScale
	local vUICenter = 0.5 * (vUILeft + vUIRight)
	
	local vUITop = UIParent:GetTop() * vUIScale
	local vUIBottom = UIParent:GetBottom() * vUIScale
	local vUIMiddle = 0.5 * (vUITop + vUIBottom)
	
	--
	
	local vFrameScale = pFrame:GetEffectiveScale()
	
	local vFrameLeft = pFrame:GetLeft() * vFrameScale
	local vFrameRight = pFrame:GetRight() * vFrameScale
	local vFrameCenter = 0.5 * (vFrameLeft + vFrameRight)
	
	local vFrameTop = pFrame:GetTop() * vFrameScale
	local vFrameBottom = pFrame:GetBottom() * vFrameScale
	local vFrameMiddle = 0.5 * (vFrameTop + vFrameBottom)
	
	--
	
	local vTopDistance = math.abs(vFrameTop - vUITop)
	local vMiddleDistance = math.abs(vFrameMiddle - vUIMiddle)
	local vBottomDistance = math.abs(vFrameBottom - vUIBottom)
	
	local vLeftDistance = math.abs(vFrameLeft - vUILeft)
	local vCenterDistance = math.abs(vFrameCenter - vUICenter)
	local vRightDistance = math.abs(vFrameRight - vUIRight)
	
	--
	
	local vVertAnchor, vOffsetY
	
	if vTopDistance < vMiddleDistance and vTopDistance < vBottomDistance then
		vVertAnchor = "TOP"
		vOffsetY = (vFrameTop - vUITop) / vUIScale
	
	elseif vMiddleDistance < vBottomDistance then
		vVertAnchor = ""
		vOffsetY = (vFrameMiddle - vUIMiddle) / vUIScale
	
	else
		vVertAnchor = "BOTTOM"
		vOffsetY = (vFrameBottom - vUIBottom) / vUIScale
	end
	
	--
	
	local vHorizAnchor, vOffsetX
	
	if vLeftDistance < vCenterDistance and vLeftDistance < vRightDistance then
		vHorizAnchor = "LEFT"
		vOffsetX = (vFrameLeft - vUILeft) / vUIScale
	
	elseif vCenterDistance < vRightDistance then
		vHorizAnchor = ""
		vOffsetX = (vFrameCenter - vUICenter) / vUIScale
	
	else
		vHorizAnchor = "RIGHT"
		vOffsetX = (vFrameRight - vUIRight) / vUIScale
	end
	
	--
	
	local vAnchor = vVertAnchor..vHorizAnchor
	
	if vAnchor == "" then
		vAnchor = "CENTER"
	end
	
	return 	{Point = vAnchor, RelativePoint = vAnchor, OffsetX = vOffsetX, OffsetY = vOffsetY}
end

function Mappy:SetFramePosition(pFrame, pPosition)
	if not pPosition or not pFrame or (pFrame:IsProtected() and not pFrame:CanChangeProtectedState()) then
		return
	end
	
	if pFrame.Mappy_ClearAllPoints then
		pFrame:Mappy_ClearAllPoints()
		pFrame:Mappy_SetPoint(
				pPosition.Point or "TOPRIGHT",
				UIParent,
				pPosition.RelativePoint or "TOPRIGHT",
				pPosition.OffsetX or -32,
				pPosition.OffsetY or -32)
	else
		pFrame:ClearAllPoints()
		pFrame:SetPoint(
				pPosition.Point or "TOPRIGHT",
				UIParent,
				pPosition.RelativePoint or "TOPRIGHT",
				pPosition.OffsetX or -32,
				pPosition.OffsetY or -32)
	end
end

function Mappy:PositionChanged()
	local vPosition = self:GetFramePosition(MinimapCluster)
	
	self.CurrentProfile.Point = vPosition.Point
	self.CurrentProfile.RelativePoint = vPosition.RelativePoint
	self.CurrentProfile.OffsetX = vPosition.OffsetX
	self.CurrentProfile.OffsetY = vPosition.OffsetY
	
	self:SetFramePosition(MinimapCluster, self.CurrentProfile)
end

function Mappy.SetFrameLevel(pFrame, pLevel)
	local vOldLevel = pFrame:GetFrameLevel()
	local vLevelOffset = pLevel - vOldLevel
	
	pFrame:SetFrameLevel(pLevel)
	
	local	vChildren = {pFrame:GetChildren()}
	
	for _, vChildFrame in pairs(vChildren) do
		local vNewChildLevel = vChildFrame:GetFrameLevel() + vLevelOffset
		if vNewChildLevel < 1 then vNewChildLevel = 1 end
		Mappy.SetFrameLevel(vChildFrame, vNewChildLevel)
	end
end

function Mappy:Minimap_UpdateRotationSetting()
	self.CurrentProfile.RotateMinimap = GetCVar("rotateMinimap") == "1"
	
	if self.CurrentProfile.HideNorthLabel then
		MinimapNorthTag:Hide()
	end
end

----------------------------------------
Mappy.RotatingMinimapArrow = {}
----------------------------------------

function Mappy.RotatingMinimapArrow:Construct(pArrow)
	-- Do nothing if we've already hooked this one
	
	if Mappy.LandmarkArrows[pArrow] then
		return
	end
	
	-- Save the current values
	
	pArrow.Mappy =
	{
		SetPosition = pArrow.SetPosition,
		GetPosition = pArrow.GetPosition,
		SetWidth = pArrow.SetWidth,
		GetWidth = pArrow.GetWidth,
		SetHeight = pArrow.SetHeight,
		GetHeight = pArrow.GetHeight,
		
		Width = pArrow:GetWidth(),
		Height = pArrow:GetHeight(),
	}
	
	pArrow.Mappy.x, pArrow.Mappy.y, pArrow.Mappy.z = pArrow:GetPosition()
	
	-- Hook the model
	
	for vName, vFunction in pairs(self) do
		pArrow[vName] = vFunction
	end
	
	-- Recalculate the current position
	
	pArrow.Mappy.SetWidth(pArrow, Mappy.CurrentProfile.MinimapSize)
	pArrow.Mappy.SetHeight(pArrow, Mappy.CurrentProfile.MinimapSize)
	
	pArrow:SetPosition(pArrow.Mappy.x, pArrow.Mappy.y, pArrow.Mappy.z)
	
	--
	
	Mappy.LandmarkArrows[pArrow] = true
end

function Mappy.RotatingMinimapArrow:SetPosition(pX, pY, pZ)
	self.Mappy.x, self.Mappy.y, self.Mappy.z = pX, pY, pZ
	
	-- Remap the position
	
	local vOrigRight, vOrigTop = self:GetOrigTopRightCoord()
	local vNewRight, vNewTop = self:GetTopRightCoord()
	
	local vX = pX * vNewRight / vOrigRight
	local vY = pY * vNewTop / vOrigTop
	
	-- Mappy:TestMessage("SetPosition: %s, %s, %s from %s, %s to %s, %s resulting in %s, %s, %s", pX, pY, pZ, vOrigRight, vOrigTop, vNewRight, vNewTop, vX, vY, pZ)
	
	self.Mappy.SetPosition(self, vX, vY, pZ)
end

function Mappy.RotatingMinimapArrow:GetPosition()
	return self.Mappy.x, self.Mappy.y, self.Mappy.z
end

function Mappy.RotatingMinimapArrow:SetWidth(pWidth)
	self.Mappy.Width = pWidth
end

function Mappy.RotatingMinimapArrow:GetWidth()
	return self.Mappy.Width
end

function Mappy.RotatingMinimapArrow:SetHeight(pHeight)
	self.Mappy.Height = pHeight
end

function Mappy.RotatingMinimapArrow:GetHeight()
	return self.Mappy.Height
end

function Mappy.RotatingMinimapArrow:GetTopRightCoord()
	local vScale = self:GetEffectiveScale()
	local vHyp = ((GetScreenWidth() * vScale) ^ 2 + (GetScreenHeight() * vScale) ^ 2) ^ 0.5
	
	return (self.Mappy.GetWidth(self)) / vHyp, (self.Mappy.GetHeight(self)) / vHyp
end

function Mappy.RotatingMinimapArrow:GetOrigTopRightCoord()
	local vScale = self:GetEffectiveScale()
	local vHyp = ((GetScreenWidth() * vScale) ^ 2 + (GetScreenHeight() * vScale) ^ 2) ^ 0.5
	
	return (self.Mappy.Width or 140.8) / vHyp, (self.Mappy.Height or 140.8) / vHyp
end

function Mappy:GetModelTopRight(pModel)
	local vScale = pModel:GetEffectiveScale()
	local vHyp = ((GetScreenWidth() * vScale) ^ 2 + (GetScreenHeight() * vScale) ^ 2) ^ 0.5
	
	return (pModel:GetWidth()) / vHyp, (pModel:GetHeight()) / vHyp
end

----------------------------------------
-- Hook QuestHelper if present
----------------------------------------

function Mappy:HookQuestHelper()
	--[[
	if not QuestHelper
	or not DongleStub then
		Mappy:DebugMessage("QuestHelper not found")
		return
	end
	
	local AstrolabeMapMonitor = DongleStub("AstrolabeMapMonitor")
	
	if not AstrolabeMapMonitor then
		Mappy:DebugMessage("AstrolabeMapMonitor not found")
		return
	end
	
	for vAstrolabe, vVersion in pairs(AstrolabeMapMonitor.AstrolabeLibrarys) do
		if vAstrolabe.processingFrame then
			Mappy:DebugMessage("Found an Astrolabe with processingFrame, re-parenting")
			
			vAstrolabe.processingFrame:SetParent(UIParent)
		else
			Mappy:DebugTable("Astrolabe"..tostring(vAstrolabe), vAstrolabe, 1)
		end
	end
	
	QuestHelper.Mappy_CreateMipmapDodad = QuestHelper.CreateMipmapDodad
	
	function QuestHelper:CreateMipmapDodad()
		local vIcon = self:Mappy_CreateMipmapDodad()
		
		vIcon:SetParent(MinimapCluster)
		vIcon:SetFrameLevel(MinimapCluster:GetFrameLevel() + 5)
		
		return vIcon
	end
	]]
end

Mappy:HookQuestHelper()

----------------------------------------
-- Gatherer support
----------------------------------------

if Gatherer
and Gatherer.MiniNotes
and Gatherer.MiniNotes.UpdateMinimapNotes then
	Gatherer.MiniNotes.Mappy_UpdateMinimapNotes = Gatherer.MiniNotes.UpdateMinimapNotes
	
	function Gatherer.MiniNotes.UpdateMinimapNotes(...)
		local vResult = {Gatherer.MiniNotes.Mappy_UpdateMinimapNotes(...)}
		
		for _, vGatherNote in ipairs(Gatherer.MiniNotes.Notes) do
			vGatherNote:SetParent(MinimapCluster)
			vGatherNote:SetFrameLevel(MinimapCluster:GetFrameLevel() + 5)
		end
		
		return unpack(vResult)
	end
end

----------------------------------------
-- GatherMate support
----------------------------------------

if GatherMate or GatherMate2 then
	local vGatherMate = GatherMate or GatherMate2
	
	-- Hook the pin function to place icons on the MinimapCluster instead of the Minimap
	
	local vDisplay = vGatherMate:GetModule("Display")
	local vOrigGetMiniPin = vDisplay.getMiniPin
	vDisplay.getMiniPin = function (...)
		local vPin = vOrigGetMiniPin(...)
		
		vPin:SetParent(MinimapCluster)
		
		return vPin
	end
end

----------------------------------------
-- Minimap addon support
----------------------------------------

function GetMinimapShape()
	return "SQUARE"
end

----------------------------------------
-- Compact the gatherer database (collapses nodes)
----------------------------------------

local POS_X = 1
local POS_Y = 2
local COUNT = 3
local HARVESTED = 4
local INSPECTED = 5
local SOURCE = 6

function Mappy:CompactGatherer()
	-- Gatherer node data indices
	
	local vGatherData = Gatherer.Storage.GetRawDataTable()
	
	for vContinentIndex, vContinentData in ipairs(vGatherData) do
		for vZoneID, vZoneData in pairs(vContinentData) do
			local vNodeBin = self:BuildGathererNodeBin(vZoneData)
			
			self:CollapseNearbyGathererNodes(vNodeBin)
			self:AdjustCollapsedNodePositions(vNodeBin)
			self:SaveGathererData(vNodeBin, vZoneData)
		end -- for vZoneID
	end -- for vContinentIndex
end

function Mappy:BuildGathererNodeBin(pZoneData)
	local vNodeBin = {}
	
	for vNodeID, vNodeList in pairs(pZoneData) do
		local vNodeTypeBin = vNodeBin[vNodeList.gtype]
		
		if not vNodeTypeBin then
			vNodeTypeBin = {}
			vNodeBin[vNodeList.gtype]= vNodeTypeBin
		end
		
		for vNodeIndex, vNodeData in ipairs(vNodeList) do
			local vColumn2 = math.floor(vNodeData[POS_X] * 1000 + 0.5)
			local vRow2 = math.floor(vNodeData[POS_Y] * 1000 + 0.5)
			
			local vNodeTypeRow = vNodeTypeBin[vRow2]
			
			if not vNodeTypeRow then
				vNodeTypeRow = {}
				vNodeTypeBin[vRow2] = vNodeTypeRow
			end
			
			local vExistingNode = vNodeTypeRow[vColumn2]
			
			if vExistingNode then
				vExistingNode[POS_X] = vExistingNode[POS_X] + vNodeData[POS_X]
				vExistingNode[POS_Y] = vExistingNode[POS_Y] + vNodeData[POS_Y]
				vExistingNode[COUNT] = vExistingNode[COUNT] + vNodeData[COUNT]
				vExistingNode.CollapseCount = vExistingNode.CollapseCount + 1
			else
				local vNewNodeData = {}
				
				for vKey, vValue in pairs(vNodeData) do
					vNewNodeData[vKey] = vValue
				end
				
				vNewNodeData.CollapseCount = 1
				vNewNodeData.NodeID = vNodeID
				vNodeTypeRow[vColumn2] = vNewNodeData
			end -- if vExistingNode
		end -- while vNodeIndex
	end -- for vNodeType
	
	return vNodeBin
end

function Mappy:CollapseNearbyGathererNodes(pNodeBin)
	for vNodeType, vNodeTypeBin in pairs(pNodeBin) do
		for vRow, vRowData in pairs(vNodeTypeBin) do
			for vColumn, vNodeData in pairs(vRowData) do
				for vRowOffset = -4, 4 do
					for vColOffset = -4, 4 do
						if vRowOffset ~= 0 or vColOffset ~= 0 then
							local vRow2 = vRow + vRowOffset
							local vColumn2 = vColumn + vColOffset
							
							local vRowData2 = vNodeTypeBin[vRow2]
							local vNodeData2 = vRowData2 and vRowData2[vColumn2]
							
							if vNodeData2 then
								vNodeData2[POS_X] = vNodeData[POS_X] + vNodeData2[POS_X]
								vNodeData2[POS_Y] = vNodeData[POS_Y] + vNodeData2[POS_Y]
								vNodeData2[COUNT] = vNodeData[COUNT] + vNodeData2[COUNT]
								
								vNodeData2.CollapseCount = vNodeData.CollapseCount + vNodeData2.CollapseCount
								
								vRowData[vColumn] = nil
								
								Mappy:NoteMessage("Collapsing nearby %s node", vNodeType)
							end
						end -- if vRowOffset
					end -- for vColOffset
				end -- for vRowOffset
			end -- for vColumn
		end -- for vRow
	end -- for vNodeType
end

function Mappy:AdjustCollapsedNodePositions(pNodeBin)				
	for vNodeType, vNodeTypeBin in pairs(pNodeBin) do
		for vRow, vRowData in pairs(vNodeTypeBin) do
			for vColumn, vNodeData in pairs(vRowData) do
				if vNodeData.CollapseCount > 1 then
					vNodeData[POS_X] = vNodeData[POS_X] / vNodeData.CollapseCount
					vNodeData[POS_Y] = vNodeData[POS_Y] / vNodeData.CollapseCount
				end
			end -- for vColumn
		end -- for vRow
	end -- for vNodeType
end

function Mappy:SaveGathererData(pNodeBin, pZoneData)
	for vKey, _ in pairs(pZoneData) do
		pZoneData[vKey] = nil
	end
	
	for vNodeType, vNodeTypeBin in pairs(pNodeBin) do
		for vRow, vRowBin in pairs(vNodeTypeBin) do
			for vColumn, vNodeData in pairs(vRowBin) do
				local vNodeList = pZoneData[vNodeData.NodeID]
				
				if not vNodeList then
					vNodeList =
					{
						gtype = vNodeType
					}
					pZoneData[vNodeData.NodeID] = vNodeList
				end
				
				table.insert(vNodeList, vNodeData)
			end
		end
	end
	
	Gatherer.Report.NeedsUpdate()
end

----------------------------------------
Mappy._OptionsPanel = {}
----------------------------------------

function Mappy._OptionsPanel:New(pParent)
	return CreateFrame("Frame", nil, pParent)
end

function Mappy._OptionsPanel:Construct(pParent)
	self:Hide()
	
	self.name = "Mappy"
	InterfaceOptions_AddCategory(self)
	
	self.Title = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	self.Title:SetPoint("TOPLEFT", self, "TOPLEFT", 15, -15)
	self.Title:SetText("Mappy Main Settings")
	
	-- Size slider
	
	self.SizeSlider = CreateFrame("Slider", "MappySizeSlider", self, "OptionsSliderTemplate")
	self.SizeSlider:SetWidth(380)
	self.SizeSlider:SetPoint("TOPLEFT", self.Title, "BOTTOMLEFT", 0, -15)
	self.SizeSlider:SetMinMaxValues(80, 1000)
	self.SizeSlider:SetScript("OnValueChanged", function (self) Mappy:SetMinimapSize(self:GetValue()) end)
	MappySizeSliderText:SetText("Size")
	MappySizeSliderLow:SetText("Small")
	MappySizeSliderHigh:SetText("Large")
	
	-- Alpha slider
	
	self.AlphaSlider = CreateFrame("Slider", "MappyAlphaSlider", self, "OptionsSliderTemplate")
	self.AlphaSlider:SetWidth(180)
	self.AlphaSlider:SetPoint("TOPLEFT", self.SizeSlider, "BOTTOMLEFT", 0, -30)
	self.AlphaSlider:SetScript("OnValueChanged", function (self) Mappy:SetMinimapAlpha(self:GetValue()) end)
	MappyAlphaSliderText:SetText("Alpha")
	self.AlphaSlider:SetMinMaxValues(0, 1)
	
	-- Combat alpha slider
	
	self.CombatAlphaSlider = CreateFrame("Slider", "MappyCombatAlphaSlider", self, "OptionsSliderTemplate")
	self.CombatAlphaSlider:SetWidth(180)
	self.CombatAlphaSlider:SetPoint("TOPLEFT", self.AlphaSlider, "TOPRIGHT", 20, 0)
	self.CombatAlphaSlider:SetScript("OnValueChanged", function (self) Mappy:SetMinimapCombatAlpha(self:GetValue()) end)
	MappyCombatAlphaSliderText:SetText("Combat Alpha")
	self.CombatAlphaSlider:SetMinMaxValues(0, 1)
	
	-- Movement alpha slider
	
	self.MovingAlphaSlider = CreateFrame("Slider", "MappyMovingAlphaSlider", self, "OptionsSliderTemplate")
	self.MovingAlphaSlider:SetWidth(180)
	self.MovingAlphaSlider:SetPoint("TOPLEFT", self.CombatAlphaSlider, "TOPRIGHT", 20, 0)
	self.MovingAlphaSlider:SetScript("OnValueChanged", function (self) Mappy:SetMinimapMovingAlpha(self:GetValue()) end)
	MappyMovingAlphaSliderText:SetText("Movement Alpha")
	self.MovingAlphaSlider:SetMinMaxValues(0, 1)
	
	-- Hide coordinates

	self.HideCoordinatesCheckbutton = CreateFrame("Checkbutton", "MappyHideCoordinatesCheckbutton", self, "OptionsCheckButtonTemplate")
	self.HideCoordinatesCheckbutton:SetPoint("TOPLEFT", self.AlphaSlider, "TOPLEFT", -5, -45)
	self.HideCoordinatesCheckbutton:SetScript("OnClick", function (self) Mappy:SetHideCoordinates(self:GetChecked()) end)
	MappyHideCoordinatesCheckbuttonText:SetText("Hide coordinates")

	-- Hide zone name

	self.HideZoneNameCheckbutton = CreateFrame("Checkbutton", "MappyHideZoneNameCheckbutton", self, "OptionsCheckButtonTemplate")
	self.HideZoneNameCheckbutton:SetPoint("TOPLEFT", self.HideCoordinatesCheckbutton, "TOPLEFT", 0, -25)
	self.HideZoneNameCheckbutton:SetScript("OnClick", function (self) Mappy:SetHideZoneName(self:GetChecked()) end)
	MappyHideZoneNameCheckbuttonText:SetText("Hide zone name")

	-- Hide North arrow

	self.HideNorthLabelCheckbutton = CreateFrame("Checkbutton", "MappyHideNorthLabelCheckbutton", self, "OptionsCheckButtonTemplate")
	self.HideNorthLabelCheckbutton:SetPoint("TOPLEFT", self.HideZoneNameCheckbutton, "TOPLEFT", 0, -25)
	self.HideNorthLabelCheckbutton:SetScript("OnClick", function (self) Mappy:SetHideNorthLabel(self:GetChecked()) end)
	MappyHideNorthLabelCheckbuttonText:SetText("Hide North label")
	
	-- Hide background

	self.HideBorderCheckbutton = CreateFrame("Checkbutton", "MappyHideBorderCheckbutton", self, "OptionsCheckButtonTemplate")
	self.HideBorderCheckbutton:SetPoint("TOPLEFT", self.HideNorthLabelCheckbutton, "TOPLEFT", 0, -25)
	self.HideBorderCheckbutton:SetScript("OnClick", function (self) Mappy:SetHideBorder(self:GetChecked()) end)
	MappyHideBorderCheckbuttonText:SetText("Hide border")
	
	-- Flash gathering nodes
	
	self.FlashGatherNodesCheckbutton = CreateFrame("Checkbutton", "MappyFlashGatherNodesCheckbutton", self, "OptionsCheckButtonTemplate")
	self.FlashGatherNodesCheckbutton:SetPoint("TOPLEFT", self.HideBorderCheckbutton, "TOPLEFT", 0, -40)
	self.FlashGatherNodesCheckbutton:SetScript("OnClick", function (self) Mappy:SetFlashGatherNodes(self:GetChecked()) end)
	MappyFlashGatherNodesCheckbuttonText:SetText("Flash gathering nodes")

	-- Large gathering nodes
	
	self.LargeGatherNodesCheckbutton = CreateFrame("Checkbutton", "MappyLargeGatherNodesCheckbutton", self, "OptionsCheckButtonTemplate")
	self.LargeGatherNodesCheckbutton:SetPoint("TOPLEFT", self.FlashGatherNodesCheckbutton, "TOPLEFT", 0, -25)
	self.LargeGatherNodesCheckbutton:SetScript("OnClick", function (self) Mappy:SetLargeGatherNodes(self:GetChecked()) end)
	MappyLargeGatherNodesCheckbuttonText:SetText("Large gathering nodes")

	-- Lock position
	self.LockPositionCheckbutton = CreateFrame("Checkbutton", "MappyLockPositionCheckbutton", self, "OptionsCheckButtonTemplate")
	self.LockPositionCheckbutton:SetPoint("TOPLEFT", self.LargeGatherNodesCheckbutton, "TOPLEFT", 0, -40)
	self.LockPositionCheckbutton:SetScript("OnClick", function (self) Mappy:SetLockPosition(self:GetChecked()) end)
	MappyLockPositionCheckbuttonText:SetText("Lock position")

	-- Ghost
	
	self.GhostCheckbutton = CreateFrame("Checkbutton", "MappyGhostCheckbutton", self, "OptionsCheckButtonTemplate")
	self.GhostCheckbutton:SetPoint("TOPLEFT", self.LockPositionCheckbutton, "TOPLEFT", 0, -25)
	self.GhostCheckbutton:SetScript("OnClick", function (self) Mappy:SetGhost(self:GetChecked()) end)
	MappyGhostCheckbuttonText:SetText("Pass clicks through")

	-- Attached frames
	
	self.DetachManagedFramesCheckbutton = CreateFrame("Checkbutton", "MappyDetachManagedFramesCheckbutton", self, "OptionsCheckButtonTemplate")
	self.DetachManagedFramesCheckbutton:SetPoint("TOPLEFT", self.GhostCheckbutton, "TOPLEFT", 0, -40)
	self.DetachManagedFramesCheckbutton:SetScript("OnClick", function (button) Mappy:SetDetachManagedFrames(button:GetChecked()) self:OnShow() end)
	MappyDetachManagedFramesCheckbuttonText:SetText("Detach UI frames (quest watch, durability, etc.)")

	self.LockManagedFramesCheckbutton = CreateFrame("Checkbutton", "MappyLockManagedFramesCheckbutton", self, "OptionsCheckButtonTemplate")
	self.LockManagedFramesCheckbutton:SetPoint("TOPLEFT", self.DetachManagedFramesCheckbutton, "TOPLEFT", 0, -25)
	self.LockManagedFramesCheckbutton:SetScript("OnClick", function (button) Mappy:SetLockManagedFrames(button:GetChecked()) end)
	MappyLockManagedFramesCheckbuttonText:SetText("Lock UI frames position")

	self:SetScript("OnShow", self.OnShow)
	self:SetScript("OnHide", self.OnHide)
end

function Mappy._OptionsPanel:OnShow()
	Mappy.DisableUpdates = true
	
	self.SizeSlider:SetValue(Mappy.CurrentProfile.MinimapSize or 140)
	self.AlphaSlider:SetValue(Mappy.CurrentProfile.MinimapAlpha or 1)
	self.CombatAlphaSlider:SetValue(Mappy.CurrentProfile.MinimapCombatAlpha or 0.2)
	self.MovingAlphaSlider:SetValue(Mappy.CurrentProfile.MinimapMovingAlpha or 0.2)
	self.HideCoordinatesCheckbutton:SetChecked(Mappy.CurrentProfile.HideCoordinates)
	self.HideZoneNameCheckbutton:SetChecked(Mappy.CurrentProfile.HideZoneName)
	self.HideNorthLabelCheckbutton:SetChecked(Mappy.CurrentProfile.HideNorthLabel)
	self.HideBorderCheckbutton:SetChecked(Mappy.CurrentProfile.HideBorder)
	self.FlashGatherNodesCheckbutton:SetChecked(Mappy.CurrentProfile.FlashGatherNodes)
	self.LargeGatherNodesCheckbutton:SetChecked(not Mappy.CurrentProfile.NormalGatherNodes)
	self.LockPositionCheckbutton:SetChecked(Mappy.CurrentProfile.LockPosition)
	self.GhostCheckbutton:SetChecked(Mappy.CurrentProfile.GhostMinimap)
	
	self.DetachManagedFramesCheckbutton:SetChecked(Mappy.CurrentProfile.DetachManagedFrames)
	self.LockManagedFramesCheckbutton:SetChecked(Mappy.CurrentProfile.LockManagedFrames)
	
	if Mappy.CurrentProfile.DetachManagedFrames then
		self.LockManagedFramesCheckbutton:Enable()
	else
		self.LockManagedFramesCheckbutton:Disable()
	end
	
	Mappy.DisableUpdates = false
end

function Mappy._OptionsPanel:OnHide()
end

----------------------------------------
Mappy._ButtonOptionsPanel = {}
----------------------------------------

function Mappy._ButtonOptionsPanel:New(pParent)
	return CreateFrame("Frame", nil, pParent)
end

function Mappy._ButtonOptionsPanel:Construct(pParent)
	self:Hide()
	
	self.name = "Buttons"
	self.parent = "Mappy"
	
	InterfaceOptions_AddCategory(self)
	
	self.Title = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	self.Title:SetPoint("TOPLEFT", self, "TOPLEFT", 15, -15)
	self.Title:SetText("Mappy Buttons")
	
	-- Hide time-of-day
	
	self.HideTimeOfDayCheckbutton = CreateFrame("Checkbutton", "MappyHideTimeOfDayCheckbutton", self, "OptionsCheckButtonTemplate")
	self.HideTimeOfDayCheckbutton:SetPoint("TOPLEFT", self.Title, "BOTTOMLEFT", 0, -15)
	self.HideTimeOfDayCheckbutton:SetScript("OnClick", function (self) Mappy:SetHideTimeOfDay(self:GetChecked()) end)
	MappyHideTimeOfDayCheckbuttonText:SetText("Hide calendar button")
	
	-- Hide zoom in/out

	self.HideZoomCheckbutton = CreateFrame("Checkbutton", "MappyHideZoomCheckbutton", self, "OptionsCheckButtonTemplate")
	self.HideZoomCheckbutton:SetPoint("TOPLEFT", self.HideTimeOfDayCheckbutton, "TOPLEFT", 0, -25)
	self.HideZoomCheckbutton:SetScript("OnClick", function (self) Mappy:SetHideZoom(self:GetChecked()) end)
	MappyHideZoomCheckbuttonText:SetText("Hide zoom buttons")

	-- Hide world map button

	self.HideWorldMapCheckbutton = CreateFrame("Checkbutton", "MappyHideWorldMapCheckbutton", self, "OptionsCheckButtonTemplate")
	self.HideWorldMapCheckbutton:SetPoint("TOPLEFT", self.HideZoomCheckbutton, "TOPLEFT", 0, -25)
	self.HideWorldMapCheckbutton:SetScript("OnClick", function (self) Mappy:SetHideWorldMap(self:GetChecked()) end)
	MappyHideWorldMapCheckbuttonText:SetText("Hide world map button")

	-- Hide Tracking Icon
	
	self.HideMiniMapTrackingCheckbutton = CreateFrame("Checkbutton", "MappyHideMiniMapTrackingCheckbutton", self, "OptionsCheckButtonTemplate")
	self.HideMiniMapTrackingCheckbutton:SetPoint("TOPLEFT", self.HideWorldMapCheckbutton, "TOPLEFT", 0, -25)
	self.HideMiniMapTrackingCheckbutton:SetScript("OnClick", function (self) Mappy:SetHideTracking(self:GetChecked()) end)
	MappyHideMiniMapTrackingCheckbuttonText:SetText("Hide Tracking icon")
	
	-- Hide Time Manager Clock
	
	self.HideTimeManagerClockCheckbutton = CreateFrame("Checkbutton", "MappyHideTimeManagerClockCheckbutton", self, "OptionsCheckButtonTemplate")
	self.HideTimeManagerClockCheckbutton:SetPoint("TOPLEFT", self.HideMiniMapTrackingCheckbutton, "TOPLEFT", 0, -25)
	self.HideTimeManagerClockCheckbutton:SetScript("OnClick", function (self) Mappy:SetHideTimeManagerClock(self:GetChecked()) end)
	MappyHideTimeManagerClockCheckbuttonText:SetText("Hide clock")
	
	-- Addon button stacking

	self.AutoStackCheckbutton = CreateFrame("Checkbutton", "MappyAutoStackCheckbutton", self, "OptionsCheckButtonTemplate")
	self.AutoStackCheckbutton:SetPoint("TOPLEFT", self.HideTimeManagerClockCheckbutton, "TOPLEFT", 0, -40)
	self.AutoStackCheckbutton:SetScript("OnClick", function (self) Mappy:SetAutoArrangeButtons(self:GetChecked()) end)
	MappyAutoStackCheckbuttonText:SetText("Auto-arrange addon buttons")
	
	-- Starting corner
	
	self.TopLeftCheckbutton = CreateFrame("Checkbutton", "MappyTopLeftCheckbutton", self, "OptionsCheckButtonTemplate")
	self.TopLeftCheckbutton:SetPoint("TOPLEFT", self.AutoStackCheckbutton, "TOPLEFT", 30, -25)
	self.TopLeftCheckbutton:SetScript("OnClick", function (button) Mappy:corner("TOPLEFT") self:OnShow() end)
	MappyTopLeftCheckbuttonText:SetText("Top-left")
	
	self.TopRightCheckbutton = CreateFrame("Checkbutton", "MappyTopRightCheckbutton", self, "OptionsCheckButtonTemplate")
	self.TopRightCheckbutton:SetPoint("TOPLEFT", self.TopLeftCheckbutton, "TOPLEFT", 120, 0)
	self.TopRightCheckbutton:SetScript("OnClick", function (button) Mappy:corner("TOPRIGHT") self:OnShow() end)
	MappyTopRightCheckbuttonText:SetText("Top-right")
	
	self.BottomLeftCheckbutton = CreateFrame("Checkbutton", "MappyBottomLeftCheckbutton", self, "OptionsCheckButtonTemplate")
	self.BottomLeftCheckbutton:SetPoint("TOPLEFT", self.TopLeftCheckbutton, "TOPLEFT", 0, -25)
	self.BottomLeftCheckbutton:SetScript("OnClick", function (button) Mappy:corner("BOTTOMLEFT") self:OnShow() end)
	MappyBottomLeftCheckbuttonText:SetText("Bottom-left")
	
	self.BottomRightCheckbutton = CreateFrame("Checkbutton", "MappyBottomRightCheckbutton", self, "OptionsCheckButtonTemplate")
	self.BottomRightCheckbutton:SetPoint("TOPLEFT", self.TopRightCheckbutton, "TOPLEFT", 0, -25)
	self.BottomRightCheckbutton:SetScript("OnClick", function (button) Mappy:corner("BOTTOMRIGHT") self:OnShow() end)
	MappyBottomRightCheckbuttonText:SetText("Bottom-right")
	
	-- Direction

	self.CCWCheckbutton = CreateFrame("Checkbutton", "MappyCCWCheckbutton", self, "OptionsCheckButtonTemplate")
	self.CCWCheckbutton:SetPoint("TOPLEFT", self.BottomLeftCheckbutton, "TOPLEFT", 0, -25)
	self.CCWCheckbutton:SetScript("OnClick", function (self) Mappy:SetCounterClockwise(self:GetChecked()) end)
	MappyCCWCheckbuttonText:SetText("Counter-clockwise")
	
	-- Stacking parent

	self.StackToScreenCheckbutton = CreateFrame("Checkbutton", "MappyStackToScreenCheckbutton", self, "OptionsCheckButtonTemplate")
	self.StackToScreenCheckbutton:SetPoint("TOPLEFT", self.CCWCheckbutton, "TOPLEFT", 0, -25)
	self.StackToScreenCheckbutton:SetScript("OnClick", function (self) Mappy:SetStackToScreen(self:GetChecked()) end)
	MappyStackToScreenCheckbuttonText:SetText("Stack around screen")
	
	self:SetScript("OnShow", self.OnShow)
	self:SetScript("OnHide", self.OnHide)
end

function Mappy._ButtonOptionsPanel:OnShow()
	Mappy.DisableUpdates = true
	
	self.HideTimeOfDayCheckbutton:SetChecked(Mappy.CurrentProfile.HideTimeOfDay)
	self.HideZoomCheckbutton:SetChecked(Mappy.CurrentProfile.HideZoom)
	self.HideWorldMapCheckbutton:SetChecked(Mappy.CurrentProfile.HideWorldMap)
	self.HideMiniMapTrackingCheckbutton:SetChecked(Mappy.CurrentProfile.HideTracking)
	self.HideTimeManagerClockCheckbutton:SetChecked(Mappy.CurrentProfile.HideTimeManagerClock)
	self.AutoStackCheckbutton:SetChecked(Mappy.CurrentProfile.AutoArrangeButtons)
	self.TopLeftCheckbutton:SetChecked(Mappy.CurrentProfile.StartingCorner == "TOPLEFT")
	self.TopRightCheckbutton:SetChecked(not Mappy.CurrentProfile.StartingCorner or Mappy.CurrentProfile.StartingCorner == "TOPRIGHT")
	self.BottomLeftCheckbutton:SetChecked(Mappy.CurrentProfile.StartingCorner == "BOTTOMLEFT")
	self.BottomRightCheckbutton:SetChecked(Mappy.CurrentProfile.StartingCorner == "BOTTOMRIGHT")
	self.CCWCheckbutton:SetChecked(Mappy.CurrentProfile.CCW)
	self.StackToScreenCheckbutton:SetChecked(Mappy.CurrentProfile.StackToScreen)
	
	Mappy.DisableUpdates = false
end

function Mappy._ButtonOptionsPanel:OnHide()
end

----------------------------------------
Mappy._ProfilesPanel = {}
----------------------------------------

function Mappy._ProfilesPanel:New(pParent)
	return CreateFrame("Frame", nil, pParent)
end

function Mappy._ProfilesPanel:Construct(pParent)
	self:Hide()
	
	self.name = "Profiles"
	self.parent = "Mappy"
	
	InterfaceOptions_AddCategory(self)
	
	self.Title = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	self.Title:SetPoint("TOPLEFT", self, "TOPLEFT", 15, -15)
	self.Title:SetText("Mappy Profiles")
	
	--
	
	self.DidCreateMenus = false
	
	self:SetScript("OnShow", self.OnShow)
	self:SetScript("OnHide", self.OnHide)
end

function Mappy._ProfilesPanel:OnShow()
	Mappy.DisableUpdates = true
	
	if not self.DidCreateMenus then
		self.DidCreateMenus = true

		self.DungeonMenu = Mappy:New(Mappy.UIElementsLib._TitledDropDownMenuButton, self, function (...) self:ProfileMenuFunc(self.DungeonMenu, "DungeonProfile", ...) end)
		self.DungeonMenu:SetTitle("Dungeon")
		self.DungeonMenu:SetWidth(150)
		self.DungeonMenu:SetPoint("TOPLEFT", self.Title, "BOTTOMLEFT", 80, -15)

		self.BattlegroundMenu = Mappy:New(Mappy.UIElementsLib._TitledDropDownMenuButton, self, function (...) self:ProfileMenuFunc(self.BattlegroundMenu, "BattlegroundProfile", ...) end)
		self.BattlegroundMenu:SetTitle("Battleground")
		self.BattlegroundMenu:SetWidth(150)
		self.BattlegroundMenu:SetPoint("TOPLEFT", self.DungeonMenu, "BOTTOMLEFT", 0, -15)

		self.MountedMenu = Mappy:New(Mappy.UIElementsLib._TitledDropDownMenuButton, self, function (...) self:ProfileMenuFunc(self.MountedMenu, "MountedProfile", ...) end)
		self.MountedMenu:SetTitle("Mounted")
		self.MountedMenu:SetWidth(150)
		self.MountedMenu:SetPoint("TOPLEFT", self.BattlegroundMenu, "BOTTOMLEFT", 0, -15)

		self.DefaultMenu = Mappy:New(Mappy.UIElementsLib._TitledDropDownMenuButton, self, function (...) self:ProfileMenuFunc(self.DefaultMenu, "DefaultProfile", ...) end)
		self.DefaultMenu:SetTitle("All others")
		self.DefaultMenu:SetWidth(150)
		self.DefaultMenu:SetPoint("TOPLEFT", self.MountedMenu, "BOTTOMLEFT", 0, -15)
	end

	self.MountedMenu:SetCurrentValueText(Mappy:GetProfileName(gMappy_Settings.MountedProfile))
	self.DungeonMenu:SetCurrentValueText(Mappy:GetProfileName(gMappy_Settings.DungeonProfile))
	self.BattlegroundMenu:SetCurrentValueText(Mappy:GetProfileName(gMappy_Settings.BattlegroundProfile))
	self.DefaultMenu:SetCurrentValueText(Mappy:GetProfileName(gMappy_Settings.DefaultProfile))
	
	Mappy.DisableUpdates = false
end

function Mappy._ProfilesPanel:OnHide()
end

function Mappy._ProfilesPanel:ProfileMenuFunc(menu, profileIndex, items)
	items:AddToggle("Don't change", function ()
		return not gMappy_Settings[profileIndex]
	end, function (item)
		gMappy_Settings[profileIndex] = nil
		menu:SetCurrentValueText(Mappy:GetProfileName(gMappy_Settings[profileIndex]))
	end)

	for profileID, profile in pairs(gMappy_Settings.Profiles) do
		items:AddToggle(Mappy:GetProfileName(profileID), function ()
			return gMappy_Settings[profileIndex] == profileID
		end, function (item)
			gMappy_Settings[profileIndex] = profileID
			menu:SetCurrentValueText(Mappy:GetProfileName(gMappy_Settings[profileIndex]))
		end)
	end
end

function Mappy:GetProfileName(profileID)
	if not profileID then
		profileID = "NONE"
	end

	local name = Mappy.ProfileNameMap[profileID]
	
	if not name then
		name = profileID
	end

	return name
end

----------------------------------------
----------------------------------------

Mappy.EventLib:RegisterEvent("ADDON_LOADED", Mappy.AddonLoaded, Mappy)
