local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)

GMM_TransmogCompanionModelMixin = {}

--------------------------------------------------------------------------------
--- CompanionModelMixin For Companion Element
--------------------------------------------------------------------------------

function GMM_TransmogCompanionModelMixin:OnLoad()

end

function GMM_TransmogCompanionModelMixin:Init(elementData)
  self.elementData = elementData
  if not self.elementData then
    return
  end

  if self.elementData.petID then
    -- Owned Pet use getInfo by PetId
    local speciesID, customName, level, xp, maxXp,
    displayID, isFavorite, name, icon, petType,
    creatureID, sourceText, description, isWild, canBattle,
    isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByPetID(self.elementData.petID)


    self.displayID = displayID
    self.Name = name or customName
    self.isFavorite = isFavorite
    self.Owned = true
  else
    -- Unowned Pet use GetInfo By Species
    local speciesName, speciesIcon, petType, companionID, tooltipSource,
    tooltipDescription, isWild, canBattle, isTradeable, isUnique,
    obtainable, creatureDisplayID = C_PetJournal.GetPetInfoBySpeciesID(self.elementData.speciesID)
    self.displayID = creatureDisplayID
    self.Name = speciesName
    self.isFavorite = false
    self.Owned = false
  end

  self:SetDisplayInfo(self.displayID)

  self:Refresh()
end

function GMM_TransmogCompanionModelMixin:OnEnter()
  self.BorderHighlight:Show()
  self:RefreshGameTooltip()
end

function GMM_TransmogCompanionModelMixin:OnLeave()
  self.BorderHighlight:Hide()
  GameTooltip:Hide()
end

function GMM_TransmogCompanionModelMixin:OnMouseUp(button, isInside)
  if button ~= "LeftButton" then
    return
  end
  if not isInside then
    return
  end

  if not self.Owned then
    return
  end

  local viewedOutfitId = C_TransmogOutfitInfo.GetCurrentlyViewedOutfitID()
  local petId = self.elementData.petID

  self.elementData.isSelected = self.elementData.collectionFrame:AddOrRemovePetToOutfit(viewedOutfitId, petId)
  self:Refresh()
end

function GMM_TransmogCompanionModelMixin:OnMouseDown(button)
end

function GMM_TransmogCompanionModelMixin:Reset()
end

function GMM_TransmogCompanionModelMixin:Refresh()
  self.FavoriteIcon:SetShown(self.isFavorite)
  self:RefreshModel()
  self:UpdateElementBorder()
end

function GMM_TransmogCompanionModelMixin:RefreshModel()
  self:SetDisplayInfo(self.displayID)
  self:SetRotation(math.pi * -0.15)
  self:SetPortraitZoom(0.5)
  self:RefreshCamera();
end

function GMM_TransmogCompanionModelMixin:RefreshGameTooltip()
  if not self.elementData then
    return
  end
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

  GameTooltip:SetText(self.Name)
  GameTooltip:Show()
end

function GMM_TransmogCompanionModelMixin:UpdateElementBorder()
  self.Border:SetShown(self.Owned and not self.elementData.isSelected)
  self.SelectedBorder:SetShown(self.elementData.isSelected)
  self.UnownedOverlay:SetShown(not self.Owned)
  self.UnownedBorder:SetShown(not self.Owned)
end
