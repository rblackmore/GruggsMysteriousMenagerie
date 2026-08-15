local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")

local Data = addOn.Data
local API = mod.API
local Utilities = addOn.Utilities

--------------------------------------------------------------------------------
--- Local
--------------------------------------------------------------------------------

local function addPetToList(list, petGUID, weight)
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

local function removePetFromList(list, petGUID)
  if not (list and list.pets and list.pets[petGUID]) then
    return false
  end

  list.pets[petGUID] = nil
  if list.weights then
    list.weights[petGUID] = nil
  end

  for i, id in ipairs(list.order or {}) do
    if id == petGUID then
      table.remove(list.order, i)
      break
    end
  end
  list.total = math.max((list.total or 1) - 1, 0)
  return true
end

local function createEmptyList()
  return { pets = {}, order = {}, weights = {}, total = 0 }
end

local function ensureGlobal()
  local dbp = Data.Companions.profile
  dbp.global = dbp.global or createEmptyList()
  return dbp
end

local function ensureContinent(continentID)
  local dbp = Data.Companions.profile
  dbp.continents = dbp.continents or {}
  local c = dbp.continents[continentID]
  if not c then
    c = createEmptyList()
    dbp.continents[continentID] = c
  end
  return c
end

local function ensureZone(continentID, zoneID)
  local dbp = Data.Companions.profile
  dbp.zones = dbp.zones or {}
  dbp.zones[continentID] = dbp.zones[continentID] or {}

  local z = dbp.zones[continentID][zoneID]
  if not z then
    z = createEmptyList()
    dbp.zones[continentID][zoneID] = z
  end
  return z
end

local function ensureOutfit(outfitID)
  local dbc = Data.Companions.char
  dbc.outfits = dbc.outfits or {}
  local o = dbc.outfits[outfitID]
  if not o then
    o = createEmptyList()
    dbc.outfits[outfitID] = o
  end
  return o
end

local function listHasPets(list)
  if not list then
    return false
  end
  if type(list.total) == "number" and list.total > 0 then
    return true
  end

  return list.order and #list.order > 0
end

local function getListFor(outfitID, mapID, continentID)
  local dbp = Data.Companions.profile
  local dbc = Data.Companions.char

  -- 1) Outfit
  if outfitID and dbc.outfits then
    local outfit = dbc.outfits[outfitID]
    if listHasPets(outfit) then
      return outfit
    end
  end

  -- 2) Zone
  if continentID and mapID and dbp.zones then
    local continent = dbp.zones[continentID]
    if continent then
      local zone = continent[mapID]
      if listHasPets(zone) then
        return zone
      end
    end
  end

  -- 3) Continent
  if continentID and dbp.continents then
    local continent = dbp.continents[continentID]
    if listHasPets(continent) then
      return continent
    end
  end

  -- 4 ) Global
  if dbp.global and listHasPets(dbp.global) then
    return dbp.global
  end

  -- 5) Fallback should be handled by Cache to avoid rebuilding each time on DB side
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

function API:AddPetToGlobal(petGUID, weight)
  if not petGUID then
    return false, "Missing petGUID"
  end

  local speciesID = C_PetJournal.GetPetInfoByPetID(petGUID)
  if not speciesID then
    return false, "Invalid petGUID"
  end
  local global = ensureGlobal()
  local added = addPetToList(global, petGUID, weight)
  return true, added and "Added" or "Updated"
end

function API:AddPetToContinent(petGUID, continentID, weight)
  if not petGUID then
    return false, "Missing petGUID"
  end

  if not continentID then
    return false, "Missing continentID"
  end

  local speciesID = C_PetJournal.GetPetInfoByPetID(petGUID)
  if not speciesID then
    return false, "Invalid petGUID"
  end

  local continent = ensureContinent(continentID)
  local added = addPetToList(continent, petGUID, weight)
  return true, added and "Added" or "Updated"
end

function API:AddPetToZone(petGUID, continentID, zoneID, weight)
  if not petGUID then
    return false, "Missing petGUID"
  end

  if not continentID or not zoneID then
    return false, "Missing continentID or zoneID"
  end

  local speciesID = C_PetJournal.GetPetInfoByPetID(petGUID)
  if not speciesID then
    return false, "Invalid petGUID"
  end

  local zone = ensureZone(continentID, zoneID)
  local added = addPetToList(zone, petGUID, weight)
  return true, added and "Added" or "Updated"
end

function API:AddPetToOutfit(petGUID, outfitID, weight)
  if not petGUID then
    return false, "Missing petGUID"
  end

  if not outfitID then
    return false, "Missing outfitID"
  end

  local speciesID = C_PetJournal.GetPetInfoByPetID(petGUID)
  if not speciesID then
    return false, "Invalid petGUID"
  end

  local outfit = ensureOutfit(outfitID)
  local added = addPetToList(outfit, petGUID, weight)
  return true, added and "Added" or "Updated"
end

function API:RemovePetFromGlobal(petGUID)
  if not petGUID then
    return false, "Missing petGUID"
  end

  local speciesID = C_PetJournal.GetPetInfoByPetID(petGUID)
  if not speciesID then
    return false, "Invalid petGUID"
  end

  local global = ensureGlobal()
  local removed = removePetFromList(global, petGUID)
  return removed, removed and "Pet removed from Global List" or "Pet not found in global list"
end

function API:RemovePetFromContinent(petGUID, continentID)
  if not petGUID then
    return false, "Missing petGUID"
  end

  if not continentID then
    return false, 'Missing continentID'
  end

  local speciesID = C_PetJournal.GetPetInfoByPetID(petGUID)
  if not speciesID then
    return false, "Invalid petGUID"
  end

  local continent = ensureContinent(continentID)
  local removed = removePetFromList(continent, petGUID)
  return removed, removed and "Pet removed from continent List" or "Pet not found in continent list"
end

function API:RemovePetFromZone(petGUID, continentID, zoneID)
  if not petGUID then
    return false, "Missing petGUID"
  end

  if not continentID or not zoneID then
    return false, 'Missing continentID or zoneID'
  end

  local speciesID = C_PetJournal.GetPetInfoByPetID(petGUID)
  if not speciesID then
    return false, "Invalid petGUID"
  end

  local zone = ensureZone(continentID, zoneID)
  local removed = removePetFromList(zone, petGUID)
  return removed, removed and "Pet removed from zone List" or "Pet not found in zone list"
end

function API:RemovePetFromOutfit(petGUID, outfitID)
  if not petGUID then
    return false, "Missing petGUID"
  end

  if not outfitID then
    return false, 'Missing outfitID'
  end

  local speciesID = C_PetJournal.GetPetInfoByPetID(petGUID)
  if not speciesID then
    return false, "Invalid petGUID"
  end

  local outfit = ensureOutfit(outfitID)
  local removed = removePetFromList(outfit, petGUID)
  return removed, removed and "Pet removed from outfit List" or "Pet not found in outfit list"
end

function API:GetCurrentContextPetList()
  local outfitID = C_TransmogOutfitInfo.GetActiveOutfitID()
  local mapID = C_Map.GetBestMapForUnit("player")
  local _, continentID = Utilities:GetContinentIDForMap(mapID)

  local list = getListFor(outfitID, mapID, continentID)
  if not list then
    list = API:BuildFallbackList()
  end
  return list
end

function API:BuildFallbackList()
  local dbp = Data.Settings.profile
  local useFavorites = dbp.companions.UseFavoritesFallback

  local list = createEmptyList()
  local petGUIDs = C_PetJournal.GetOwnedPetIDs()

  for i = 1, #petGUIDs do
    local speciesID, _, _, _, _, _, isFavorite = C_PetJournal.GetPetInfoByPetID(petGUIDs[i])
    if speciesID then
      if not useFavorites or isFavorite then
        addPetToList(list, petGUIDs[i])
      end
    end
  end

  return list
end

function API:SetPetOfTheDay(petId)
  local podSettings = self.settingsProfile.companions["Automation"]["petoftheday"]
  podSettings.PetId = petId
  podSettings.Date = date("*t")
end
