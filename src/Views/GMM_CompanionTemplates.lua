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

  self:SetDisplayInfo(self.elementData.petInfo.displayID)
  self.FavoriteIcon:SetShown(self.elementData.petInfo.isFavorite)

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

  local viewedOutfitId = C_TransmogOutfitInfo.GetCurrentlyViewedOutfitID()
  local petId = self.elementData.petInfo.petId

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
  local itemQuality = C_Item.GetItemQualityByID(self.elementData.petInfo.petId)

  GameTooltip:SetText(self.elementData.petInfo.name)
  GameTooltip:Show()
end

function GMM_CompanionModelMixin:UpdateElementBorder()
  self.SelectedBorder:SetShown(self.elementData.isSelected)
end
