local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceEvent-3.0
local wardrobeModule = addOn:GetModule("WardrobeModule")

GMM_WardrobeMixin = {
  COLLECTION_TEMPLATES = {
    -- It's possible, I may create different Templates here depending on which menagerie is loaded (Pets, Mounts, etc) and use a different Frame.
    ["COLLECTION_ITEM"] = {
      template = "GMM_MenagerieModelTemplate",
      initFunc = GMM_MenagerieModelMixin.Init,
      resetFunc = GMM_MenagerieModelMixin.Reset
    }
  }
}

function GMM_WardrobeMixin:OnLoad()
  self:InitFilterButton()
  self.PagedContent:SetElementTemplateData(self.COLLECTION_TEMPLATES)
end

function GMM_WardrobeMixin:OnShow()
  self:Refresh()
end

function GMM_WardrobeMixin:OnHide()
  -- self:Reset()
end

function GMM_WardrobeMixin:OnEvent() end

function GMM_WardrobeMixin:OnKeyDown() end

function GMM_WardrobeMixin:InitFilterButton()
  self.FilterButton:SetText(SOURCES)
end

function GMM_WardrobeMixin:GetSelectedSlotData()
  return wardrobeModule:GetSelectedSlotData()
end

-- function GMM_WardrobeMixin:UpdateSlot()
--   self:Refresh()
-- end
function GMM_WardrobeMixin:Reset()
  self.ActiveSlotTitle:SetText("")
  self.PagedContent:SetDataProvider(CreateDataProvider())
end

function GMM_WardrobeMixin:Refresh()
  self:RefreshActiveSlotTitle()
  self:RefreshCollectionEntries()
end

function GMM_WardrobeMixin:RefreshActiveSlotTitle()
  local activeSlotData = self:GetSelectedSlotData()
  if not activeSlotData or not activeSlotData.slotName then
    self.ActiveSlotTitle:SetText("")
    return
  end

  self.ActiveSlotTitle:SetText(activeSlotData.slotName)
end

function GMM_WardrobeMixin:RefreshCollectionEntries()
  -- Make sure Slot data exist, not responsible for refreshing slotData
  -- Fetch Collection Entries see (Pets,Mounts,Hearthstones): C_TransmogCollection.GetCategoryAppearances()
  -- SetCollectionEntries(entries, retainCurrentPage)
  local entries = wardrobeModule:GetCollectionEntries(self:GetSelectedSlotData())

  if not entries then
    self.PagedContent:SetDataProvider(CreateDataProvider(), false)
    return
  end

  local retainCurrentPage = true
  self:SetCollectionEntries(entries, retainCurrentPage)
end

function GMM_WardrobeMixin:SetCollectionEntries(entries, retainCurrentPage)
  local collectionData = { { elements = entries } }
  self.PagedContent:SetDataProvider(CreateDataProvider(collectionData), retainCurrentPage)
end
