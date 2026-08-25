local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceEvent-3.0
local wardrobeModule = addOn:GetModule("WardrobeModule")



GMM_WardrobeItemMixin = {}

function GMM_WardrobeItemMixin:Init() end

function GMM_WardrobeItemMixin:Reset() end

function GMM_WardrobeItemMixin:OnEnter() end

function GMM_WardrobeItemMixin:OnLeave() end

function GMM_WardrobeItemMixin:OnMouseUp() end

function GMM_WardrobeItemMixin:OnMouseDown() end



GMM_TransmogSlotButtonMixin = {}

function GMM_TransmogSlotButtonMixin:Init(slotData)
  self.slotData = slotData
end

function GMM_TransmogSlotButtonMixin:OnLoad() end

function GMM_TransmogSlotButtonMixin:OnClick() end

function GMM_TransmogSlotButtonMixin:OnEnter() end

function GMM_TransmogSlotButtonMixin:OnLeave() end

function GMM_TransmogSlotButtonMixin:OnShow() end
