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
  self:RefreshModel()
  self.Name:SetText(self.elementData.petInfo.name)
end

function GMM_CompanionModelMixin:OnEnter()
  self.BorderHighlight:Show()
end

function GMM_CompanionModelMixin:OnLeave()
  if not self:IsMouseOver() then
    self.BorderHighlight:Hide()
  end
end

function GMM_CompanionModelMixin:OnMouseUp(button, isInside)
  if not button == "LeftButton" or not isInside then
    return
  end

  local viewedOutfitId = C_TransmogOutfitInfo.GetCurrentlyViewedOutfitID()
  local petId = self.elementData.petInfo.petId

  self.elementData.collectionFrame:AddPetToOutfit(viewedOutfitId, petId)
end

function GMM_CompanionModelMixin:OnMouseDown(button)
  print("OnMouseDown", self.elementData.petInfo.name)
end

function GMM_CompanionModelMixin:Reset()
end

function GMM_CompanionModelMixin:RefreshModel()
  self:SetRotation(math.pi * -0.15)
  self:SetPortraitZoom(0.5)
  self:RefreshCamera();
end
