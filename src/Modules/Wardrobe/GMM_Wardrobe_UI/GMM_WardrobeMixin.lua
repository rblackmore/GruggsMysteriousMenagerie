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
