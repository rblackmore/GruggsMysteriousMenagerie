local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceConsole-3.0, AceEvent-3.0
local WardrobeModule = addOn:GetModule("GMM_WardrobeModule")

GMM_MenagerieElementModelMixin = {}

function GMM_MenagerieElementModelMixin:Init(elementData)
  self.elementData = elementData

  if not self.elementData then
    return
  end


  local itemInfo = self.elementData.itemInfo -- Contains Data about the Pet or Mount
  if itemInfo.petID then                     -- Owned Pet, petID is nil if pet is not owned.
    local speciesID, customName, level, xp, maxXp,
    displayID, isFavorite, name, icon, petType,
    creatureID, sourceText, description, isWild, canBattle,
    isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByPetID(itemInfo.petID)
    self.displayID = displayID
    self.Name = name or customName
    self.isFavorite = isFavorite
    self.Owned = true
  elseif itemInfo.speciesID then -- Unowned Pet
    local speciesName, speciesIcon, petType, companionID, tooltipSource,
    tooltipDescription, isWild, canBattle, isTradeable, isUnique,
    obtainable, creatureDisplayID = C_PetJournal.GetPetInfoBySpeciesID(itemInfo.speciesID)
    self.displayID = creatureDisplayID
    self.Name = speciesName
    self.isFavorite = false
    self.Owned = false
  elseif itemInfo.mountID then -- Mount, mountID should exist regardless of ownership
    -- bulid element as mount
    local name, spellID, icon, isActive, isUsable,
    sourceType, isFavorite, isFactionSpecific, faction,
    shouldHideOnChar, isCollected,
    _, isSteadyFlight         = C_MountJournal.GetMountInfoByID(itemInfo.mountID)
    local creatureDisplayInfoID, description, source,
    isSelfMount, mountTypeID, uiModelSceneID, animID, spellVisualKitID,
    disablePlayerMountPreview = C_MountJournal.GetMountInfoExtraByID(itemInfo.mountID)
    self.displayID            = creatureDisplayInfoID
    self.Name                 = name
    self.isFavorite           = isFavorite
    self.Owned                = isCollected
  end

  self:SetDisplayInfo(self.displayID)
  self:Refresh()
  --[[
    Perhaps 'elementData' should have a flag to indicate if we're dealing with a companion or mount.
    then we can take the logic from there, where iteminfo will contain appropriate data.
    eg. Companions can have custom names, mounts cannot.
    much of the data will be the same, eg displayID (I think).
    the GUID of each item may differ:
      COmpanions are unique, ie player could have more than 1 of the same species.
    MOunts are not unique in this way, so not sure if the GUIDs are unique per mount, or we just look at each one as a 'species'
    I need to investigate the C_MountJournal API.
  ]] --
end

function GMM_MenagerieElementModelMixin:OnEnter()
  self.BorderHighlight:Show()
end

function GMM_MenagerieElementModelMixin:OnLeave()
  self.BorderHighlight:Hide()
end

function GMM_MenagerieElementModelMixin:OnMouseUp(button, isInside)
  -- Add Item to Database
  -- Should Element Data come with a callback to do this?
end

function GMM_MenagerieElementModelMixin:OnMouseDown(button)

end

function GMM_MenagerieElementModelMixin:Refresh()
  self.FavoriteIcon:SetShown(self.isFavorite)
  self:RefreshModel()
  self:UpdateElementBorder()
end

function GMM_MenagerieElementModelMixin:RefreshModel()
  self:SetDisplayInfo(self.displayID)
  self:SetRotation(math.pi * -0.15)
  self:SetPortraitZoom(0.5)
  self:RefreshCamera()
end

function GMM_MenagerieElementModelMixin:RefreshGameTooltip()
  if not self.elementData then
    return
  end
  GameTooltip:SetOwned(self, "ANCHOR_RIGHT")
  GameTooltip:SetText(self.Name)
  GameTooltip:Show()
end

function GMM_MenagerieElementModelMixin:UpdateElementBorder()
  self.Border:SetShown(self.Owned and not self.elementData.isSelected)
  self.SelectedBorder:SetShown(self.elementData.isSelected)
  self.UnownedOverlay:SetShown(not self.Owned)
  self.UnownedBorder:SetShown(not self.Owned)
end
