local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceConsole-3.0, AceEvent-3.0
local WardrobeModule = addOn:GetModule("GMM_WardrobeModule")

GMM_MenagerieSlot = {
  Companions = 0,
  FlyingMounts = 1,
  GroundMounts = 2
}

function WardrobeModule:OnInitialize()
  self.wardrobeDB = addOn.outfitDb.char
end

function WardrobeModule:GetMenagerieSlotInfo()
  -- Returns an Array of Group slot infor like https://warcraft.wiki.gg/wiki/API_C_TransmogOutfitInfo.GetSlotGroupInfo
  local menagerieSlots = {}
  table.insert(menagerieSlots, {
    slot = GMM_MenagerieSlot.Companions,
    slotName = "Companions",
    icon = "category-icons_pets_active"
  })
  table.insert(menagerieSlots, {
    slot = GMM_MenagerieSlot.FlyingMounts,
    slotName = "Flying Mounts",
    icon = "shop-icon-mount-flying-selected"
  })
  table.insert(menagerieSlots, {
    slot = GMM_MenagerieSlot.GroundMounts,
    slotName = "Ground Mounts",
    icon = "category-icons_mounts_active"
  })
  return menagerieSlots
end

-- Should use C_PetJournal to build a collection of companions with either petID or speciesID
-- MenagerieFrame is responsible to turning these into an element data object for use with a Dataprovider
-- Dataprovider will then be sent to the PagedContent
function WardrobeModule:GetCompanionEntries(filters)
  local outfitId = C_TransmogOutfitInfo.GetCurrentlyViewedOutfitID()
  local companionDB = self:GetCompanionsForOutfitOrNil(outfitId)

  local entries = {}
  for i = 1, C_PetJournal.GetNumPets() do
    local petID, speciesID = C_PetJournal.GetPetInfoByIndex(i)
    local petEntry = {
      index = i,
      petID = petID,
      speciesID = speciesID,
      isSelected = self:OutfitContainsPetId(companionDB, petID)
    }
    if filters.ShowUnused then
      table.insert(entries, petEntry)
    elseif petEntry.isSelected then
      table.insert(entries, petEntry)
    end
  end
  return entries
end

function WardrobeModule:GetMountEntries(filters)
  local entries = {}
  for _index, mountID in ipairs(C_MountJournal.GetMountIDs()) do
    local name, spellID, icon, isActive, isUsable,
    sourceType, isFavorite, isFactionSpecific, faction,
    shouldHideOnChar, isCollected,
    _, isSteadyFlight         = C_MountJournal.GetMountInfoByID(mountID)
    local creatureDisplayInfoID, description, source,
    isSelfMount, mountTypeID, uiModelSceneID, animID, spellVisualKitID,
    disablePlayerMountPreview = C_MountJournal.GetMountInfoExtraByID(mountID)

    local grounded            = mountTypeID == 230 -- Update to Include other TypeIDs that are ground only.
    local canFly              = mountTypeID == 424 or mountTypeID == 247 or mountTypeID == 248
    if isCollected then
      if filters.IncludeGround then
        table.insert(entries, {
          index = _index,
          mountID = mountID
        })
      elseif not grounded and canFly then
        table.insert(entries, {
          index = _index,
          mountID = mountID
        })
      end
    end
  end

  return entries
end

function WardrobeModule:OutfitContainsPetId(outfitDb, petID)
  if not outfitDb then return false, nil end
  if not petID then return false, nil end

  for i, v in ipairs(outfitDb) do
    if v == petID then
      return true, i
    end
  end
  return false, nil
end

function WardrobeModule:GetCompanionsForOutfitOrNil(outfitId)
  local outfitDb = self:GetOutfitTableOrNil(outfitId)
  if not outfitDb then return nil end
  return outfitDb.Companions
end

function WardrobeModule:GetOutfitTableOrNil(outfitId)
  return self.wardrobeDB["Outfits"][outfitId] or nil
end

function WardrobeModule:GetOrCreateOutfitTable(outfitId)
  if self.wardrobeDB["Outfits"][outfitId] then
    return self.wardrobeDB["Outfits"][outfitId]
  end

  local outfitdb = {
    Companions = {
      Total = 0
    },
    Mounts = {
      Flying = {
        Total = 0
      },
      Ground = {
        Total = 0
      },
      Passenger = {
        Total = 0
      },
      Aquatic = {
        Total = 0
      }
    }
  }

  self.wardrobeDB["Outfits"][outfitId] = outfitdb
  return self.wardrobeDB["Outfits"][outfitId]
end
