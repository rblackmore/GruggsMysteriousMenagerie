local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceEvent-3.0
local wardrobeModule = addOn:GetModule("WardrobeModule")

GMM_WardrobeMixin = {
  COLLECTION_TEMPLATES = {
    ["COLLECTION_ITEM"] = {
      template = "GMM_TransmogItemTemplate",
      initFunc = GMM_WardrobeItemMixin.Init,
      resetFunc = GMM_WardrobeItemMixin.Reset
    }
  }
}

function GMM_WardrobeMixin:OnLoad()
  self:InitFilterButton()
  self.PagedContent:SetElementTemplateData(self.COLLECTION_TEMPLATES)
end

function GMM_WardrobeMixin:OnShow() end

function GMM_WardrobeMixin:OnHide() end

function GMM_WardrobeMixin:OnEvent() end

function GMM_WardrobeMixin:OnKeyDown() end

function GMM_WardrobeMixin:InitFilterButton()
  self.FilterButton:SetText(SOURCES)
end

function GMM_WardrobeMixin:GetActiveSlotCallback()
  return wardrobeModule:GetSelectedSlotData()
end

function GMM_WardrobeMixin:UpdateSlot(slotData)
  self:Refresh()
end

function GMM_WardrobeMixin:Refresh()
  self:RefreshActiveSlotTitle()
  self:RefreshCollectionEntries()
end

function GMM_WardrobeMixin:RefreshActiveSlotTitle()
  local activeSlotData = self:GetActiveSlotCallback()
  if not activeSlotData or not activeSlotData.slotName then
    self.ActiveSlotTitle:SetText("")
    return
  end

  self.ActiveSlotTitle:SetText(activeSlotData.slotName)
end

function GMM_WardrobeMixin:RefreshCollectionEntries()
end
