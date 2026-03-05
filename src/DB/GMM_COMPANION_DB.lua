local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")

--------------------------------------------------------------------------------
--- Local Helper Functions
--------------------------------------------------------------------------------
local function GetContinentIDForMap(mapID)
  local info = mapID and C_Map.GetMapInfo(mapID)
  while info do
    if info.mapType == Enum.UIMapType.Continent then
      return info.mapID
    end
    if not info.parentMapID then break end
    info = C_Map.GetMapInfo(info.parentMapID)
  end
  return nil
end

local function FilterExistingPetGUIDs(petsSet)
  if not petsSet then return nil end
  local filtered = {}
  for guid in pairs(petsSet) do
    local speciesID = C_PetJournal.GetPetInfoByPetID(guid)
    if speciesID ~= nil then
      filtered[guid] = true
    end
  end
  return filtered
end

--------------------------------------------------------------------------------
--- Database Module API
--------------------------------------------------------------------------------
function mod:InitializeDatabasePointers()
  self.CompanionsNS = addOn.dbCompanions
  self.SettingsNS = addOn.dbSettings

  self:RefreshProfilePointers()

  self.CompanionsNS.RegisterCallback(self, "OnProfileChanged", "OnProfileEvent")
  self.CompanionsNS.RegisterCallback(self, "OnProfileCopied", "OnProfileEvent")
  self.CompanionsNS.RegisterCallback(self, "OnProfileReset", "OnProfileEvent")

  self:EnsureGlobal()
  self:EnsureOwned()
end

function mod:RefreshProfilePointers()
  if not self.CompanionsNS then return end

  self.dbp = self.CompanionsNS.profile
  self.dbc = self.CompanionsNS.char
  self.settingsProfile = self.SettingsNS and self.SettingsNS.profile or nil
end

function mod:OnProfileEvent(...)
  self:RefreshProfilePointers()
  -- self:RefreshUI() if UI References Data
end

function mod:EnsureGlobal()
  self.dbp.global = self.dbp.global or { pets = {}, order = {}, total = 0 }

  self.dbp.global.pets = self.dbp.global.pets or {}
  self.dbp.global.order = self.dbp.global.order or {}
  self.dbp.global.total = self.dbp.global.total or 0

  return self.dbp.global
end

function mod:EnsureContinent(continentID)
  self.dbp.continents = self.dbp.continents or {}
  local c = self.dbp.continents[continentID]
  if not c then
    c = { pets = {}, order = {}, total = 0 }
    self.dbp.continents[continentID] = c
  end
  return c
end

function mod:EnsureZone(continentID, zoneID)
  self.dbp.zones = self.dbp.zones or {}
  self.dbp.zones[continentID] = self.dbp.zones[continentID] or {}
  local z = self.dbp.zones[continentID][zoneID]
  if not z then
    z = { pets = {}, order = {}, total = 0 }
    self.dbp.zones[continentID][zoneID] = z
  end
  return z
end

function mod:EnsureOutfit(outfitID)
  self.dbc.outfits = self.dbc.outfits or {}
  local o = self.dbc.outfits[outfitID]
  if not o then
    o = { pets = {}, order = {}, total = 0 }
    self.dbc.outfits[outfitID] = o
  end
  return o
end

function mod:EnsureOwned()
  local o = self:RefreshOwnedList()
  self.dbp.owned = o
  return o
end

function mod:RemoveGlobal()
  self.dbp.global = { pets = {}, order = {}, total = 0 }
end

function mod:RemoveContinent(continentID)
  if self.dbp.continents then
    self.dbp.continents[continentID] = nil
    return true
  end
  return false
end

function mod:RemoveZone(continentID, zoneID)
  if self.dbp.zones[continentID] and self.dbp.zones[continentID][zoneID] then
    self.dbp.zones[continentID][zoneID] = nil
    return true
  end

  return false
end

function mod:RemoveOutfit(outfitID)
  if self.dbc.outfits and self.dbc.outfits[outfitID] then
    self.dbc.outfits[outfitID] = nil
    return true
  end
  return false
end

function mod:RefreshEffectivePetList()
  self.EffectivePetList = self:GetEffectivePetList()
  return self.EffectivePetList
end

function mod:RefreshOwnedList()
  local list = { pets = {}, order = {}, total = 0 }
  local numPets = C_PetJournal.GetNumPets()
  for i = 1, numPets do
    local petGUID = C_PetJournal.GetPetInfoByIndex(i)
    if petGUID then
      self:AddPet(list, petGUID)
    end
  end
  return list
end

function mod:AddPet(list, petGUID)
  list.pets = list.pets or {}
  list.order = list.order or {}
  list.total = list.total or 0

  if not list.pets[petGUID] then
    list.pets[petGUID] = true
    table.insert(list.order, petGUID)
    list.total = (list.total or 0) + 1
    return true
  end
  return false
end

function mod:RemovePet(list, petGUID)
  if list and list.pets and list.pets[petGUID] then
    list.pets[petGUID] = nil
    for i, id in ipairs(list.order) do
      if id == petGUID then
        table.remove(list.order, i)
        break
      end
    end
    list.total = math.max((list.total or 1) - 1, 0)
    return true
  end
  return false
end

function mod:GetCurrentPetList(mapID, outfitID, continentID)
  -- 1) Outfit
  if outfitID and self.dbc.outfits and self.dbc.outfits[outfitID] then
    return self.dbc.outfits[outfitID]
  end

  -- 2) Zone
  if continentID and mapID and self.dbp.zones and self.dbp.zones[continentID] then
    local zl = self.dbp.zones[continentID][mapID]
    if zl then return zl end
  end

  -- 3) Continent
  if continentID and self.dbp.continents and self.dbp.continents[continentID] then
    return self.dbp.continents[continentID]
  end

  -- 4 ) Global Default
  local global = self:EnsureGlobal()
  if global and global.order and #global.order > 0 then
    return global
  end

  -- 5) Default to Owned Pets if Global is Empty
  return self:EnsureOwned()
end

function mod:GetEffectivePetList()
  local outfitID = C_TransmogOutfitInfo.GetActiveOutfitID()
  local mapID = C_Map.GetBestMapForUnit("player")
  local continentID = GetContinentIDForMap(mapID)

  return self:GetCurrentPetList(mapID, outfitID, continentID)
end
