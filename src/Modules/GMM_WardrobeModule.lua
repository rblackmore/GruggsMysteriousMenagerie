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

function WardrobeModule:GetCompanionEntries(filters)
  -- Should use C_PetJournal to build a collection of companions with either petID or speciesID
  -- MenagerieFrame is responsible to turning these into an element data object for use with a Dataprovider
  -- Dataprovider will then be sent to the PagedContent
  local outfitId = C_TransmogOutfitInfo.GetCurrentlyViewedOutfitID()
  local companionDB = self:GetCompanionsForOutfitOrNil(outfitId)

  local entries = {}
  for i = 1, C_PetJournal.GetNumPets() do
    local petID, speciesID = C_PetJournal.GetPetInfoByIndex(i)
    local element = {
      index = i,
      petID = petID,
      speciesID = speciesID,
      isSelected = self:OutfitContainsPetId(companionDB, petID)
    }
    if filters.ShowUnused then
      table.insert(entries, element)
    elseif element.isSelected then
      table.insert(entries, element)
    end
  end
  return entries
end

function WardrobeModule:GetMountEntries()
  -- Same as Companion Entries
  -- Should I have a parem that sets filters to include types?
  -- ie: All, Ground Only, Flying Only, Passenger or Aquatic?
  local entries = {}
  table.insert(entries, {
    index = 1,
    mountID = "Mount-ID-123456789",
    isSelected = true,
  })
  table.insert(entries, {
    index = 2,
    mountID = "Mount-ID-123456789",
    isSelected = false,
  })
  table.insert(entries, {
    index = 2,
    mountID = "Mount-ID-123456789",
    isSelected = true,
  })
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
