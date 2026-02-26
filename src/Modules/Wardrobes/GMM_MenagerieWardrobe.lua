local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceConsole-3.0, AceEvent-3.0
local WardrobeModule = addOn:GetModule("GMM_WardrobeModule")

function WardrobeModule:OnEnable()
  self:RegisterEvent("ADDON_LOADED")
end

function WardrobeModule:ADDON_LOADED(event, name)
  if name ~= "Blizzard_Transmog" then
    return
  end

  local container = TransmogFrame
      and TransmogFrame.WardrobeCollection
      and TransmogFrame.WardrobeCollection.TabContent

  self.WardrobeCollection = TransmogFrame.WardrobeCollection

  self.MenagerieFrame = CreateFrame("Frame", nil, container, "GMM_MenagerieFrame")
  self.MenagerieFrame:SetFrameStrata(container:GetFrameStrata())
  self.MenagerieFrame:SetFrameLevel(container:GetFrameLevel() + 1)
  self.MenagerieFrame:ClearAllPoints()
  self.MenagerieFrame:SetAllPoints(container)
  self.MenagerieFrame.wardrobeCollection = TransmogFrame.WardrobeCollection

  self.MenagerieTabID = self.WardrobeCollection:AddNamedTab("Menagerie", self.MenagerieFrame)

  TransmogFrame.WardrobeCollection.gmmMenagerieTabID = self.MenagerieTabID

  local charFrame = TransmogFrame.CharacterPreview
  local topSlots = CreateFrame("Frame", nil, charFrame, "GMM_MenagerieTopSlots")
  self.TopSlots = topSlots
  charFrame.TopSlots = topSlots

  topSlots:ClearAllPoints()
  topSlots:SetPoint("TOP", 0, -64)

  -- Gather Slot Data.... This should be simple, just set Companion as a title
  -- maybe need an enum to indicate Companion/Flying/Ground?
  local slotButton = CreateFrame("Button", nil, topSlots, "GMM_TransmogSlotButtonTemplate")

  local slotData = {
    menagerieLocation = "Companions",
    menagerieTabID = self.MenagerieTabID,
    menagerieFrame = self.MenagerieFrame,
    wardrobeCollection = TransmogFrame.WardrobeCollection,
  }

  slotButton:Init(slotData)
  slotButton.layoutIndex = 1

  slotButton:Show()
  topSlots:Show()
  topSlots:Layout()
  self:UnregisterEvent("ADDON_LOADED")
end

--------------------------------------------------------------------------------
--- Menagerie Wardrobe Mixin
--------------------------------------------------------------------------------
GMM_MenagerieWardrobeMixin = {

}

function GMM_MenagerieWardrobeMixin:OnLoad()
  self.selectedMenagerieSlotData = nil
end

function GMM_MenagerieWardrobeMixin:OnShow()
  self:Refresh()
end

function GMM_MenagerieWardrobeMixin:Reset()
  self.selectedMenagerieSlotData = nil
  self:Refresh()
end

function GMM_MenagerieWardrobeMixin:Refresh()
  self:RefreshActiveSlotTitle()
  -- TODO: Refresh everything else, Filter, CopyTo Button, and PagedContent.
  -- This will all be different, start with Compansions, already done that
  -- Mounts might require different element template, maybe, I don't know.
end

function GMM_MenagerieWardrobeMixin:SetMenagerieSlot(slotFrame, forceRefresh)
  local slotData = slotFrame and slotFrame.slotData or nil
  self.selectedMenagerieSlotData = slotData;

  local changed = true
  WardrobeModule:Print("Slot Data: ", slotData)
  WardrobeModule:Print("Slot Data (Location): ", slotData.menagerieLocation)


  if self.selectedMenagerieSlotData and slotData and
      self.selectedMenagerieSlotData.menagerieLocation == slotData.menagerieLocation then
    changed = false
  end
  self.selectedMenagerieSlotData = slotData
  if changed or forceRefresh then
    self:Refresh()
  end
end

function GMM_MenagerieWardrobeMixin:GetSelectedMenagerieSlotData()
  return self.selectedMenagerieSlotData
end

function GMM_MenagerieWardrobeMixin:RefreshActiveSlotTitle()
  local title = ""
  if self.selectedMenagerieSlotData and self.selectedMenagerieSlotData.menagerieLocation then
    title = self.selectedMenagerieSlotData.menagerieLocation
  end
  WardrobeModule:Print("Title is: ", title)
  if self.ActiveSlotTitle then
    self.ActiveSlotTitle:SetText(title)
  end
end

--------------------------------------------------------------------------------
--- Slot Button Mixin
--------------------------------------------------------------------------------
GMM_TransmogSlotButtonMixin = {}

function GMM_TransmogSlotButtonMixin:OnLoad()
  WardrobeModule:Print("Loading Slot Button")
  self:Update()
end

function GMM_TransmogSlotButtonMixin:OnShow()
  WardrobeModule:Print("Showing Slot Button")
  self:Update()
end

function GMM_TransmogSlotButtonMixin:Init(slotData)
  WardrobeModule:Print("Initializing Slot Button")
  self.slotData = slotData
end

function GMM_TransmogSlotButtonMixin:Update()
  WardrobeModule:Print("Updating Slot Button")
  self.Icon:SetAtlas("category-icons_pets_active")
end

function GMM_TransmogSlotButtonMixin:OnClick(buttonName)
  WardrobeModule:Print("Clicked " .. self.slotData.menagerieLocation .. " Button")
  if buttonName == "LeftButton" then
    PlaySound(SOUNDKIT.UI_TRANSMOG_GEAR_SLOT_CLICK);
    self:OnSelect()
  end
end

function GMM_TransmogSlotButtonMixin:OnSelect()
  self.slotData.menagerieFrame:SetMenagerieSlot(self, true)
  self.slotData.wardrobeCollection:SetTab(self.slotData.menagerieTabID, true)
end
