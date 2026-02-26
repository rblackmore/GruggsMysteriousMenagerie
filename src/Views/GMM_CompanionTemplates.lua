local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)

GMM_CompanionModelMixin = {}

--------------------------------------------------------------------------------
--- CompanionModelMixin For Companion Element
--------------------------------------------------------------------------------

function GMM_CompanionModelMixin:OnLoad()

end

function GMM_CompanionModelMixin:Init(elementData)
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
    self:SetDisplayInfo(displayID)
    self.FavoriteIcon:SetShown(C_PetJournal.PetIsFavorite(self.elementData.petID))

    self.Name = name or customName
    self.Owned = true
  else
    -- Unowned Pet use GetInfo By Species
    local speciesName, speciesIcon, petType, companionID, tooltipSource,
    tooltipDescription, isWild, canBattle, isTradeable, isUnique,
    obtainable, creatureDisplayID = C_PetJournal.GetPetInfoBySpeciesID(self.elementData.speciesID)
    self:SetDisplayInfo(creatureDisplayID)

    self.Name = speciesName
    self.Owned = false
  end


  self:Refresh()
end

function GMM_CompanionModelMixin:OnEnter()
  self.BorderHighlight:Show()
  self:RefreshGameTooltip()
end

function GMM_CompanionModelMixin:OnLeave()
  self.BorderHighlight:Hide()
  GameTooltip:Hide()
end

function GMM_CompanionModelMixin:OnMouseUp(button, isInside)
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

function GMM_CompanionModelMixin:OnMouseDown(button)
end

function GMM_CompanionModelMixin:Reset()
end

function GMM_CompanionModelMixin:Refresh()
  self:RefreshModel()
  self:UpdateElementBorder()
end

function GMM_CompanionModelMixin:RefreshModel()
  self:SetRotation(math.pi * -0.15)
  self:SetPortraitZoom(0.5)
  self:RefreshCamera();
end

function GMM_CompanionModelMixin:RefreshGameTooltip()
  if not self.elementData then
    return
  end
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

  GameTooltip:SetText(self.Name)
  GameTooltip:Show()
end

function GMM_CompanionModelMixin:UpdateElementBorder()
  self.SelectedBorder:SetShown(self.elementData.isSelected)
  self.UnownedOverlay:SetShown(not self.Owned)
  self.UnownedBorder:SetShown(not self.Owned)

  self.Border:SetShown(self.Owned and not self.elementData.isSelected)
end
