local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceConsole-3.0, AceEvent-3.0
local WardrobeModule = addOn:GetModule("GMM_WardrobeModule")

function WardrobeModule:OnEnable()
  self:RegisterEvent("ADDON_LOADED")
end

function WardrobeModule:ADDON_LOADED(event, name)
  if name ~= "Blizzard_Transmog" then return end

  self:InitMenagerieFrame()

  self:UnregisterEvent("ADDON_LOADED")
end

function WardrobeModule:InitMenagerieFrame()
  local container = TransmogFrame
      and TransmogFrame.WardrobeCollection
      and TransmogFrame.WardrobeCollection.TabContent

  self.WardrobeCollection = TransmogFrame.WardrobeCollection

  self.MenagerieFrame = CreateFrame("Frame", nil, container, "GMM_MenagerieFrame")
  self.MenagerieFrame:ClearAllPoints()
  self.MenagerieFrame:SetAllPoints(container)
  self.MenagerieFrame:SetFrameStrata(container:GetFrameStrata())
  self.MenagerieFrame:SetFrameLevel(container:GetFrameLevel() + 1)
  self.MenagerieTabID = self.WardrobeCollection:AddNamedTab("Menagerie", self.MenagerieFrame)
  self.MenagerieFrame:Init({
    wardrobeCollection = TransmogFrame.WardrobeCollection,
    tabId = self.MenagerieTabID,
    getSlotsInfo = function() return self:GetMenagerieSlotInfo() end,
  })
end

--------------------------------------------------------------------------------
--- Menagerie Wardrobe Mixin
--------------------------------------------------------------------------------
GMM_MenagerieWardrobeMixin = {
  EVENTS_TO_REGISTER = {},
  COLLECTION_TEMPLATES = {
    ["COLLECTION_ITEM"] = {
      template = "GMM_MenagerieElementModelTemplate",
      initFunc = GMM_MenagerieElementModelMixin.Init
    }
  }

}
function GMM_MenagerieWardrobeMixin:Init(context)
  self.wardrobeCollection = context.wardrobeCollection
  self.menagerieTabID = context.tabId
  self.GetSlotsInfo = context.getSlotsInfo

  self:InitTopSlots()
  self:Refresh()
end

function GMM_MenagerieWardrobeMixin:InitTopSlots()
  local charFrame = TransmogFrame.CharacterPreview
  local topSlots = CreateFrame("Frame", nil, charFrame, "GMM_MenagerieTopSlots")
  topSlots:SetFrameStrata(charFrame:GetFrameStrata())
  topSlots:SetFrameLevel(charFrame:GetFrameLevel() + 1)
  topSlots:ClearAllPoints()
  topSlots:SetPoint("TOP", 0, -64)

  self.TopSlots = topSlots
  charFrame.TopSlots = topSlots

  for _index, slotInfo in ipairs(self.GetSlotsInfo()) do
    self:SetupSlot({ index = _index, info = slotInfo })
  end

  self.TopSlots:Show()
  self.TopSlots:Layout()
end

function GMM_MenagerieWardrobeMixin:SetupSlot(context)
  local btn = CreateFrame("Button", nil, self.TopSlots, "GMM_TransmogSlotButtonTemplate")
  local slotInfo = context.info
  btn.layoutIndex = context.index
  btn:Init({
    location = slotInfo.slot,
    title = slotInfo.slotName,
    icon = slotInfo.icon,
    menagerieFrame = self,
    wardrobeCollection = TransmogFrame.WardrobeCollection
  })
  btn:Show()
end

function GMM_MenagerieWardrobeMixin:OnLoad()
  self:Reset()
  self.PagedContent:SetElementTemplateData(self.COLLECTION_TEMPLATES)
end

function GMM_MenagerieWardrobeMixin:OnShow()
  -- self:Refresh()
end

function GMM_MenagerieWardrobeMixin:OnHide()
end

function GMM_MenagerieWardrobeMixin:Reset()
  self.selectedSlotData = nil
end

function GMM_MenagerieWardrobeMixin:Refresh()
  self:RefreshActiveSlotTitle()
  self:RefreshFilterButtons()
  self:RefreshCollectionEntries();

  -- self:RefreshWeaponDropdown();
  -- self:RefreshDisplayTypeButtons();
  -- self:RefreshSecondaryAppearanceToggle();
  -- TODO: Refresh everything else, Filter, CopyTo Button, and PagedContent.
  -- This will all be different, start with Compansions, already done that
  -- Mounts might require different element template, maybe, I don't know.
end

function GMM_MenagerieWardrobeMixin:SetMenagerieSlot(slotFrame, forceRefresh)
  local slotData = slotFrame and slotFrame.slotData or nil
  self.selectedSlotData = slotData;
  if not slotData then
    return
  end

  local changed = true
  local selectedSlotData = self:GetSelectedMenagerieSlotData()

  if selectedSlotData and slotData and
      selectedSlotData.title == slotData.title then
    changed = false
  end

  if changed or forceRefresh then
    self:Refresh()
  end
end

function GMM_MenagerieWardrobeMixin:GetSelectedMenagerieSlotData()
  return self.selectedSlotData
end

function GMM_MenagerieWardrobeMixin:RefreshActiveSlotTitle()
  local title = ""
  local selectedSlotData = self:GetSelectedMenagerieSlotData()
  if selectedSlotData and selectedSlotData.title then
    title = selectedSlotData.title
  end
  if self.ActiveSlotTitle then
    self.ActiveSlotTitle:SetText(title)
  end
end

function GMM_MenagerieWardrobeMixin:RefreshFilterButtons()
  local selectedSlotData = self:GetSelectedMenagerieSlotData()

  if not selectedSlotData then
    self.CompanionFilterButton:Hide()
    self.MountFilterButton:Hide()
    return
  end
  if selectedSlotData.location == GMM_MenagerieSlot.Companions then
    self.CompanionFilterButton:Show()
    self.MountFilterButton:Hide()
  elseif selectedSlotData.location == GMM_MenagerieSlot.FlyingMounts or selectedSlotData.location == GMM_MenagerieSlot.GroundMounts then
    self.CompanionFilterButton:Hide()
    self.MountFilterButton:Show()
  end
end

function GMM_MenagerieWardrobeMixin:RefreshCollectionEntries()
  self.itemEntries = nil
  local selectedSlotData = self:GetSelectedMenagerieSlotData()
  if selectedSlotData and selectedSlotData.location == GMM_MenagerieSlot.Companions then
    WardrobeModule:Print("Getting Companion Entries")
    self.itemEntries = WardrobeModule:GetCompanionEntries({ ShowUnused = true })
  elseif selectedSlotData and selectedSlotData.location == GMM_MenagerieSlot.FlyingMounts then
    WardrobeModule:Print("Getting Mount Entries")
    self.itemEntries = WardrobeModule:GetMountEntries({ IncludeGround = false }) -- Not Implemented yet.
  elseif selectedSlotData and selectedSlotData.location == GMM_MenagerieElementModelMixin.GroundMounts then
    WardrobeModule:Print("Getting Ground Mount Entries")
    self.itemEntries = WardrobeModule:GetMountEntries({ IncludeGround = true }) -- Not Implemented yet.
  end

  if not self.itemEntries then
    return
  end

  local retrainCurrentPage = true
  self:SetCollectionEntries(self.itemEntries, retrainCurrentPage)
end

function GMM_MenagerieWardrobeMixin:SetCollectionEntries(entries, retrainCurrentPage)
  local collectionElements = {}
  for _index, itemEntry in ipairs(entries) do
    -- element is the data object provided to each element on the pagedcontent.
    local element = {
      templateKey = "COLLECTION_ITEM", -- Add Property to indicate Pet or Mount
      itemInfo = itemEntry,
      collectionFrame = self
    }
    table.insert(collectionElements, element)
  end

  WardrobeModule:Print("Element Count: ", #collectionElements)
  local collectionData = { { elements = collectionElements } }
  local dataProvider = CreateDataProvider(collectionData)
  self.PagedContent:SetDataProvider(dataProvider, retrainCurrentPage)
end

function GMM_MenagerieWardrobeMixin:InitCompanionFilterButton() end

function GMM_MenagerieWardrobeMixin:InitMountFilterButton() end

--------------------------------------------------------------------------------
--- Slot Button Mixin
--------------------------------------------------------------------------------
GMM_TransmogSlotButtonMixin = {}
-- {
-- location = slotInfo.slot,
-- title = slotInfo.name,
-- icon = slotInfo.icon,
-- menagerieFrame = self,
-- wardrobeCollection = TransmogFrame.WardrobeCollection
--   }
function GMM_TransmogSlotButtonMixin:OnLoad()
  self:Update()
end

function GMM_TransmogSlotButtonMixin:OnShow()
  self:Update()
end

function GMM_TransmogSlotButtonMixin:Init(slotData)
  self.slotData = slotData
  self:Update()
end

function GMM_TransmogSlotButtonMixin:Update()
  if self.slotData then
    self.Icon:SetAtlas(self.slotData.icon)
  end
end

function GMM_TransmogSlotButtonMixin:OnClick(buttonName)
  if buttonName == "LeftButton" then
    PlaySound(SOUNDKIT.UI_TRANSMOG_GEAR_SLOT_CLICK);
    self:OnSelect()
  end
end

function GMM_TransmogSlotButtonMixin:OnSelect()
  self.slotData.menagerieFrame:SetMenagerieSlot(self, true)
  self.slotData.wardrobeCollection:SetTab(self.slotData.menagerieFrame.menagerieTabID, true)
end
