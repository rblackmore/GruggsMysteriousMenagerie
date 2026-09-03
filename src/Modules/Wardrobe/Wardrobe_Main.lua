local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceEvent-3.0
local wardrobeModule = addOn:NewModule("WardrobeModule");

local Enums = addonTable.Enums
local L = addonTable.L

function wardrobeModule:OnInitialize()
  self:RegisterEvent("ADDON_LOADED", "OnAddonLoaded")
  self.MenagerieSlotFramePool = CreateFramePool("BUTTON", nil, "GMM_TransmogSlotTemplate")
end

function wardrobeModule:OnAddonLoaded(event, addon)
  if addon == "Blizzard_Transmog" then
    self:SetupFrame()
    self:UnregisterEvent("ADDON_LOADED")
  end
end

function wardrobeModule:GetAllMenagerieSlotInfo()
  local slots = {
    { slot = Enums.TransmogMenagerieSlot.Companion,    type = Enums.TransmogMenagerieSlotType.Companion, slotName = L["TW Companions Header"],    iconTexture = "category-icons_pets_active" },
    { slot = Enums.TransmogMenagerieSlot.GroundMounts, type = Enums.TransmogMenagerieSlotType.Mount,     slotName = L["TW Ground Mounts Header"], iconTexture = "category-icons_mounts_active" },
    { slot = Enums.TransmogMenagerieSlot.FlyingMounts, type = Enums.TransmogMenagerieSlotType.Mount,     slotName = L["TW Flying Mounts Header"], iconTexture = "shop-icon-mount-flying-selected" }
  }
  return slots
end

function wardrobeModule:SetupFrame()
  self:SetupSlots()
  local tabOwner = TransmogFrame.WardrobeCollection
  local gmm_wardrobeFrame = CreateFrame("Frame", nil, tabOwner.TabContent, "GMM_WardrobeFrame")
  gmm_wardrobeFrame:ClearAllPoints()
  gmm_wardrobeFrame:SetAllPoints(tabOwner.TabContent)
  gmm_wardrobeFrame:SetFrameStrata(tabOwner.TabContent:GetFrameStrata())
  gmm_wardrobeFrame:SetFrameLevel(tabOwner.TabContent:GetFrameLevel() + 1)
  gmm_wardrobeFrame.transmogFrame = TransmogFrame
  gmm_wardrobeFrame.tabOwner = tabOwner
  gmm_wardrobeFrame.tabID = tabOwner:AddNamedTab("Menagerie", gmm_wardrobeFrame)
  self.wardrobeFrame = gmm_wardrobeFrame
  self:RefreshSlot()
end

function wardrobeModule:SetupSlots()
  local layoutParent = TransmogFrame and TransmogFrame.CharacterPreview and TransmogFrame.CharacterPreview.RightSlots

  if not layoutParent then
    return
  end
  local menagerieSlots = CreateFrame("Frame", nil, layoutParent, "VerticalLayoutFrame")
  menagerieSlots.spacing = 2
  menagerieSlots:ClearAllPoints()
  menagerieSlots:SetPoint("TOP", layoutParent, "BOTTOM", 0, -50)
  menagerieSlots:SetFrameStrata(layoutParent:GetFrameStrata())
  menagerieSlots:SetFrameLevel(layoutParent:GetFrameLevel())

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
      slotName = info.slotName,
      iconTexture = info.iconTexture,
      slot = info.slot,
      type = info.type,
    }

    if index == 1 then
      self.selectedSlotData = slotData
    end

    slotFrame.layoutIndex = index

    slotFrame:Init(slotData)
    slotFrame:SetParent(menagerieSlots)
    slotFrame:Show()
  end
end

function wardrobeModule:SelectSlot(slotData)
  self:SetSelectedSlot(slotData)
  self:SetToMenagerieTab()
end

function wardrobeModule:SetSelectedSlot(slotData)
  if self.selectedSlotData and self.selectedSlotData.slotName == slotData.slotName then
    return
  end

  self.selectedSlotData = slotData
  self:RefreshSlot()

  if self.wardrobeFrame then
    self.wardrobeFrame:Refresh()
  end
end

function wardrobeModule:SetToMenagerieTab()
  if self.wardrobeFrame.tabOwner:GetTab() ~= self.wardrobeFrame.tabID then
    self.wardrobeFrame.tabOwner:SetTab(self.wardrobeFrame.tabID)
  end
end

function wardrobeModule:GetSelectedSlotData()
  return self.selectedSlotData
end

function wardrobeModule:RefreshSlot()
  for slotFrame in self.MenagerieSlotFramePool:EnumerateActive() do
    slotFrame:SetSelected(
      slotFrame.slotData and
      self.selectedSlotData and
      slotFrame.slotData.slotName == self.selectedSlotData.slotName)
  end
end

function wardrobeModule:GetCollectionEntries(slotData)
  -- switch statement to build appropriate data Entries depending on slotData.slot
  -- Called from the MenagerieWardrobeFrame to use for populated paged view.

  if not slotData then
    return
  end

  if slotData.type == Enums.TransmogMenagerieSlotType.Companion then
    return self:GetCompanionEntries()
  end
end

function wardrobeModule:GetCompanionEntries()
  local entries = {}

  for i = 1, C_PetJournal.GetNumPets() do
    local petID, speciesID, owned, customName, level, favorite, isRevoked,
    speciesName, icon, petType, companionID, tooltip, description, isWild,
    canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(i)

    local element = {
      templateKey = "COLLECTION_ITEM",
      index = i,
      type = Enums.TransmogMenagerieSlotType.Companion,
      petID = petID,
      isOwned = petID ~= nil,
      speciesID = speciesID,
      name = customName or speciesName,
      collectionFrame = self.wardrobeFrame,
      isSelected = false
    }
    table.insert(entries, element)
  end
  return entries;
end
