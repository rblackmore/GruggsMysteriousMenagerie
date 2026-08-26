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

GMM_TransmogSlotMixin = {}

function GMM_TransmogSlotMixin:Init(slotData)
  self.slotData = slotData
end

function GMM_TransmogSlotMixin:OnLoad()
  self:Update();
end

function GMM_TransmogSlotMixin:OnClick(buttonName)
  if not self.slotData then
    return
  end

  if buttonName == "LeftButton" then
    PlaySound(SOUNDKIT.UI_TRANSMOG_GEAR_SLOT_CLICK)
    self:OnSelect()
  end
end

function GMM_TransmogSlotMixin:OnSelect()
  wardrobeModule:SelectSlot(self.slotData)
end

function GMM_TransmogSlotMixin:OnEnter() end

function GMM_TransmogSlotMixin:OnLeave() end

function GMM_TransmogSlotMixin:OnShow()
  self:Update();
end

function GMM_TransmogSlotMixin:Update()
  if not self.slotData or not self:IsShown() then
    return
  end

  self.Icon:SetAtlas(self.slotData.iconTexture) -- Alternate
  -- self.Icon:SetTexture(self.slotData.iconTexture)
  self.Icon:SetSize(45, 45)
end

function GMM_TransmogSlotMixin:Release()
  self:SetSelected(false)
  self:SetParent(nil)
end

function GMM_TransmogSlotMixin:SetSelected(selected)
  if not self.slotData then
    return
  end
  self.SelectedFrame:SetShown(selected)
end
