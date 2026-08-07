local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")

mod.DB = mod.DB or {}
local DB = mod.DB
local Enums = addonTable.Enums
local Maps = addonTable.Maps

--------------------------------------------------------------------------------
--- Local Helper Functions
--------------------------------------------------------------------------------
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

local function ListHasPets(list)
  if not list then
    return false
  end
  if type(list.total) == "number" and list.total > 0 then
    return true
  end
  if list.order and #list.order > 0 then
    return true
  end
  return false
end

--------------------------------------------------------------------------------
--- Database Module API
--------------------------------------------------------------------------------
function DB:Init()
  self.CompanionsNS = addOn.DB.CompanionNS
  self.SettingsNS = addOn.DB.SettingsNS

  self:RefreshProfilePointers()

  self.CompanionsNS.RegisterCallback(self, "OnProfileChanged", "OnProfileEvent")
  self.CompanionsNS.RegisterCallback(self, "OnProfileCopied", "OnProfileEvent")
  self.CompanionsNS.RegisterCallback(self, "OnProfileReset", "OnProfileEvent")
end

function DB:RefreshProfilePointers()
  if not self.CompanionsNS then return end

  self.dbp = self.CompanionsNS.profile
  self.dbc = self.CompanionsNS.char
  self.settingsProfile = self.SettingsNS and self.SettingsNS.profile
end

function DB:OnProfileEvent(...)
  self:RefreshProfilePointers()
  -- self:RefreshUI() if UI References Data
end

function DB:EnsureGlobal()
  self.dbp.global = self.dbp.global or { pets = {}, order = {}, weights = {}, total = 0 }

  self.dbp.global.pets = self.dbp.global.pets or {}
  self.dbp.global.order = self.dbp.global.order or {}
  self.dbp.global.weights = self.dbp.global.weights or {}
  self.dbp.global.total = self.dbp.global.total or 0

  return self.dbp.global
end

function DB:EnsureContinent(continentID)
  self.dbp.continents = self.dbp.continents or {}
  local c = self.dbp.continents[continentID]
  if not c then
    c = { pets = {}, order = {}, total = 0 }
    self.dbp.continents[continentID] = c
  end
  return c
end

function DB:EnsureZone(continentID, zoneID)
  self.dbp.zones = self.dbp.zones or {}
  self.dbp.zones[continentID] = self.dbp.zones[continentID] or {}
  local z = self.dbp.zones[continentID][zoneID]
  if not z then
    z = { pets = {}, order = {}, total = 0 }
    self.dbp.zones[continentID][zoneID] = z
  end
  return z
end

function DB:EnsureOutfit(outfitID)
  self.dbc.outfits = self.dbc.outfits or {}
  local o = self.dbc.outfits[outfitID]
  if not o then
    o = { pets = {}, order = {}, total = 0 }
    self.dbc.outfits[outfitID] = o
  end
  return o
end

function DB:RemoveGlobal()
  self.dbp.global = { pets = {}, order = {}, weights = {}, total = 0 }
end

function DB:RemoveContinent(continentID)
  if self.dbp.continents then
    self.dbp.continents[continentID] = nil
    return true
  end
  return false
end

function DB:RemoveZone(continentID, zoneID)
  if self.dbp.zones[continentID] and self.dbp.zones[continentID][zoneID] then
    self.dbp.zones[continentID][zoneID] = nil
    return true
  end

  return false
end

function DB:RemoveOutfit(outfitID)
  if self.dbc.outfits and self.dbc.outfits[outfitID] then
    self.dbc.outfits[outfitID] = nil
    return true
  end
  return false
end

function DB:AddPet(list, petGUID, weight)
  list.pets = list.pets or {}
  list.order = list.order or {}
  list.weights = list.weights or {}
  list.total = list.total or 0

  if not list.pets[petGUID] then -- Add New Pet
    list.pets[petGUID] = true
    table.insert(list.order, petGUID)
    list.weights[petGUID] = tonumber(weight) or 1.0
    list.total = (list.total or 0) + 1
    return true
  else
    if weight ~= nil then -- Update existing pet Weight
      list.weights[petGUID] = tonumber(weight) or 1.0
    end
  end
  return false
end

function DB:AddPetToScope(scope, key1, key2, petGUID, weight)
  local list = nil
  if scope == Enums.ListScope.Outfit then
    list = self:EnsureOutfit(key1)     -- key1 = outfitID
  elseif scope == Enums.ListScope.Zone then
    list = self:EnsureZone(key1, key2) -- key1 = continentId, key2 = zoneID
  elseif scope == Enums.ListScope.Continent then
    list = self:EnsureContinent(key1)  -- key1 = continentID
  elseif scope == Enums.ListScope.Global then
    list = self:EnsureGlobal()
  else
    return false, "Invalid Scope"
  end
  if not petGUID then
    return false, "Missing PetGUID"
  end

  local speciesID = C_PetJournal.GetPetInfoByPetID(petGUID)
  if not speciesID then return false, "Invalid PetGUID" end
  local added = self:AddPet(list, petGUID, weight)
  return true, added and "Added" or "Updated"
end

function DB:AddPetsToScope(scope, key1, key2, petGUIDs, weight)
  for _, v in ipairs(petGUIDs) do
    self:AddPetToScope(scope, key1, key2, v, weight);
  end
end

function DB:AddPetToGlobal(petGUID, weight)
  self:AddPetToScope(Enums.ListScope.Global, nil, nil, petGUID, weight);
end

function DB:AddPetToContinent(petGUID, continentID, weight)
  self:AddPetToScope(Enums.ListScope.Continent, continentID, nil, petGUID, weight);
end

function DB:AddPetToZone(petGUID, continentID, zoneID, weight)
  self:AddPetToScope(Enums.ListScope.Zone, continentID, zoneID, petGUID, weight);
end

function DB:AddPetToOutfit(petGUID, outfitID, weight)
  self:AddPetToScope(Enums.ListScope.Outfit, outfitID, nil, petGUID, weight);
end

function DB:RemovePet(list, petGUID)
  if list and list.pets and list.pets[petGUID] then
    list.pets[petGUID] = nil
    if list.weights then list.weights[petGUID] = nil end
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

function DB:GetEffectivePetList()
  local outfitID = C_TransmogOutfitInfo.GetActiveOutfitID()
  local mapID = C_Map.GetBestMapForUnit("player")
  local continentID = Maps:GetContinentIDForMap(mapID)

  return self:GetListFor(outfitID, mapID, continentID)
end

function DB:GetListFor(outfitID, mapID, continentID)
  -- 1) Outfit
  if outfitID and self.dbc.outfits and ListHasPets(self.dbc.outfits[outfitID]) then
    return self.dbc.outfits[outfitID]
  end

  -- 2) Zone
  if continentID and mapID and self.dbp.zones and self.dbp.zones[continentID] then
    local zl = self.dbp.zones[continentID][mapID]
    if ListHasPets(zl) then
      return zl
    end
  end

  -- 3) Continent
  if continentID and self.dbp.continents and ListHasPets(self.dbp.continents[continentID]) then
    return self.dbp.continents[continentID]
  end

  -- 4 ) Global
  if self.dbp.global and ListHasPets(self.dbp.global) then
    return self.dbp.global
  end

  -- 5) Fallback should be handled by Cache to avoid rebuilding each time on DB side
  return nil
end

function DB:GetFallbackList()
  local settings = self:GetCompanionSettings()
  local useFavorites = settings["UseFavoritesFallback"]

  local list = { pets = {}, order = {}, total = 0 }
  local petGUIDs = C_PetJournal.GetOwnedPetIDs()

  for i = 1, #petGUIDs do
    local speciesID, _, _, _, _, _, isFavorite = C_PetJournal.GetPetInfoByPetID(petGUIDs[i])
    if speciesID then
      if not useFavorites or isFavorite then
        self:AddPet(list, petGUIDs[i])
      end
    end
  end

  return list
end

function DB:SetPetOfTheDay(petId)
  local podSettings = self.settingsProfile.companions["Automation"]["petoftheday"]
  podSettings.PetId = petId
  podSettings.Date = date("*t")
end

function DB:GetCompanionSettings()
  if not self.settingsProfile or not self.settingsProfile.companions then
    return {}
  end
  return self.settingsProfile.companions
end

function DB:GetCompanionNamespace()
  if not self.CompanionsNS then
    return {}
  end
  return self.CompanionsNS
end
