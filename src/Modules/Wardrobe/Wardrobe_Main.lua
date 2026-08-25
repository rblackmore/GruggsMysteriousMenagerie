local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceEvent-3.0
local wardrobeModule = addOn:NewModule("WardrobeModule");

local Enums = addonTable.Enums

function wardrobeModule:OnInitialize()
  self:RegisterEvent("ADDON_LOADED", "OnAddonLoaded")
  self.MenagerieSlotFramePool = CreateFramePool("BUTTON", nil, "GMM_TransmogSlotButtonTemplate")
end

function wardrobeModule:OnAddonLoaded(event, addon)
  if addon == "Blizzard_Transmog" then
    self:SetupFrame()
  end
end

function wardrobeModule:SetupFrame()
  local tabOwner = TransmogFrame.WardrobeCollection
  local gmm_wardrobeFrame = CreateFrame("Frame", nil, tabOwner.TabContent, "GMM_WardrobeFrame")
  gmm_wardrobeFrame:ClearAllPoints()
  gmm_wardrobeFrame:SetAllPoints(tabOwner.TabContent)
  gmm_wardrobeFrame:SetFrameStrata(tabOwner.TabContent:GetFrameStrata())
  gmm_wardrobeFrame:SetFrameLevel(tabOwner.TabContent:GetFrameLevel() + 1)
  gmm_wardrobeFrame.transmogFrame = TransmogFrame
  gmm_wardrobeFrame.tabOwner = tabOwner
  gmm_wardrobeFrame.tabID = tabOwner:AddNamedTab("Menagerie", gmm_wardrobeFrame)
  self:SetupSlots()
  self:UnregisterEvent("ADDON_LOADED")
  self.wardrobeFrame = gmm_wardrobeFrame
end

function wardrobeModule:GetAllMenagerieSlotInfo()
  local slots = {
    { slot = Enums.TransmogMenagerieSlot.Companion,    type = Enums.TransmogMenagerieSlotType.Companion, slotName = "Companions" },
    { slot = Enums.TransmogMenagerieSlot.GroundMounts, type = Enums.TransmogMenagerieSlotType.Mount,     slotName = "Ground Mounts" },
    { slot = Enums.TransmogMenagerieSlot.FlyingMounts, type = Enums.TransmogMenagerieSlotType.Mount,     slotName = "Flying Mounts" }
  }
  return slots
end

function wardrobeModule:SetupSlots()
  local parent = TransmogFrame and TransmogFrame.CharacterPreview and TransmogFrame.CharacterPreview.RightSlots

  if not parent then
    return
  end
  local menagerieSlots = CreateFrame("Frame", nil, parent, "VerticalLayoutFrame")
  menagerieSlots.spacing = 5
  menagerieSlots:ClearAllPoints()
  menagerieSlots:SetPoint("TOP", parent, "BOTTOM", 0, -50)
  menagerieSlots:SetFrameStrata(parent:GetFrameStrata())
  menagerieSlots:SetFrameLevel(parent:GetFrameLevel())

  self.MenagerieSlotFramePool:ReleaseAll()

  local slotInfo = self:GetAllMenagerieSlotInfo()

  if not slotInfo then
    return
  end

  for index, info in ipairs(slotInfo) do
    local slotFrame = self.MenagerieSlotFramePool:Acquire()

    local slotData = {
      module = self,
      transmogFrame = TransmogFrame,
      data = info
    }

    slotFrame.layoutIndex = index

    slotFrame:Init(slotData)
    slotFrame:SetParent(menagerieSlots)
    slotFrame:Show()
  end
end

function wardrobeModule:SelectSlot(slotData)
  self.wardrobeFrame:UpdateSlot(slotData)
end

-- function TransmogFrameMixin:SelectSlot(slotFrame, forceRefresh)
-- 	-- Visually update selected slot
-- 	self.CharacterPreview:UpdateSlot(slotFrame.slotData, forceRefresh);

-- 	-- It is possible that when updating the character preview slot, we noticed slotFrame is no longer valid (is now disabled etc.) and have selected a new slot in that flow.
-- 	-- Do not update the wardrobe collection with the now stale data in such case.
-- 	local selectedSlotData = self.CharacterPreview:GetSelectedSlotData();
-- 	if selectedSlotData ~= slotFrame.slotData then
-- 		return;
-- 	end

-- 	-- Navigate to correct items in collection.
-- 	self.WardrobeCollection:UpdateSlot(slotFrame.slotData, forceRefresh);
-- end
