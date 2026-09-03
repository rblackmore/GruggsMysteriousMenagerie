local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceEvent-3.0
local wardrobeModule = addOn:GetModule("WardrobeModule")
---@class AceAddon: GMM_Companion
local companionModule = addOn:GetModule("CompanionModule")

local Enums = addonTable.Enums
local Models = addonTable.Models
local CompanionList = Models.CompanionList

----------------------------------------------------------------------------------------------------
--- Menagerie Model Base Mixin
----------------------------------------------------------------------------------------------------

-- Used Simply as a base for getting data for the TemplateModel.
-- Element Data will differ between pet, mount so this servers as a bridge to that data.
-- It may even server as a home for callbacks to Database APIs for adding/removing,
-- making decisions on which API to call depending on elementData type.
GMM_MenagerieModelBaseMixin = {}

function GMM_MenagerieModelBaseMixin:GetDisplayID()
  if self.elementData and self.elementData.type == Enums.TransmogMenagerieSlotType.Companion and self.elementData.speciesID then
    return C_PetJournal.GetDisplayIDByIndex(self.elementData.speciesID, 1) or 16259
  end
end

function GMM_MenagerieModelBaseMixin:IsFavorite()
  if self.elementData and self.elementData.type == Enums.TransmogMenagerieSlotType.Companion and self.elementData.petID then
    return C_PetJournal.PetIsFavorite(self.elementData.petID)
  end
end

function GMM_MenagerieModelBaseMixin:IsOwned()
  if self.elementData and self.elementData.type == Enums.TransmogMenagerieSlotType.Companion and self.elementData.isOwned then
    return self.elementData.isOwned
  end
end

function GMM_MenagerieModelBaseMixin:IsInCurrentOutfitList()
  local outfitId = C_TransmogOutfitInfo.GetCurrentlyViewedOutfitID()
  local list = companionModule.Database:GetListForScope(Enums.SCOPES.outfit, outfitId)
  return CompanionList.hasPet(list, self.elementData.petID)
end

function GMM_MenagerieModelBaseMixin:AddOrRemoveItemToList()
  local outfitId = C_TransmogOutfitInfo.GetCurrentlyViewedOutfitID()
  local list = companionModule.Database:GetListForScope(Enums.SCOPES.outfit, outfitId)

  if CompanionList.hasPet(list, self.elementData.petID) then
    companionModule.Database:AddPetToOutfit(self.elementData.petID, outfitId)
  else
    companionModule.Database:RemovePetFromOutfit(self.elementData.petID, outfitId)
  end
end

----------------------------------------------------------------------------------------------------
--- Menagerie Model Mixin
----------------------------------------------------------------------------------------------------

GMM_MenagerieModelMixin = CreateFromMixins(GMM_MenagerieModelBaseMixin)


function GMM_MenagerieModelMixin:OnLoad()
  self:SetRotation(math.pi * -0.15)
  self:SetPortraitZoom(0.5)
  self:RefreshCamera()
end

function GMM_MenagerieModelMixin:Init(elementData)
  self.elementData = elementData

  if not self.elementData then
    return
  end

  self:Refresh()
end

function GMM_MenagerieModelMixin:Reset()

end

function GMM_MenagerieModelMixin:Refresh()
  self:RefreshFavoriteIcon()
  self:RefreshBorders()
  self:RefreshModel()
end

function GMM_MenagerieModelMixin:RefreshFavoriteIcon()
  self.FavoriteIcon:SetShown(self:IsFavorite())
end

function GMM_MenagerieModelMixin:RefreshBorders()
  self.Border:SetShown(self:IsOwned())
  self.UnownedOverlay:SetShown(not self:IsOwned())
  self.UnownedBorder:SetShown(not self:IsOwned())
  self.SelectedBorder:SetShown(self:IsInCurrentOutfitList())
end

function GMM_MenagerieModelMixin:RefreshModel()
  self:SetDisplayInfo(self:GetDisplayID())
end

function GMM_MenagerieModelMixin:OnEnter()
  self.BorderHighlight:Show()
end

function GMM_MenagerieModelMixin:OnLeave()
  self.BorderHighlight:Hide()
end

function GMM_MenagerieModelMixin:OnMouseUp(button, isInside)
  if button ~= "LeftButton" or not isInside or not self:IsOwned() then
    return
  end

  self:AddOrRemoveItemToList()
end

function GMM_MenagerieModelMixin:OnMouseDown() end

----------------------------------------------------------------------------------------------------
--- Slot Icon Mixin
----------------------------------------------------------------------------------------------------

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
