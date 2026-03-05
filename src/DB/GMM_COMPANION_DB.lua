local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")

--------------------------------------------------------------------------------
--- Database Schema
--------------------------------------------------------------------------------

local default =
{
  meta = {
    schemaVersion = 1,
    createdAt = time(),
    lastUpdated = time(),
  },
  ["profile"] = {

    global = {
      pets = { -- to set: [petGUID] = true

      },
      order = {},
      total = 0
    },
    continents = {
      -- keyed using UiMapID
      -- [12] = { pets = {}, order = {}, total = 0} (Kalimdor)

    },
    zones = {
      -- zones[continentID][zoneUiMapID] = { pets = {}}
      --[[
      [101] = { -- Outland
      [107] = { -- Nagrand
      pets = { }
      },
      [104] = { -- Shadowmoon Valley (Outland)
      pets = { }
      }
      }
      ]] --
    },
    owned = {},
    cities = {
      --[[
      Cities are zones, but we can check if the player is resting?
      Check if the mapID matches a city id?
      I may need to create a custom list of known city id's?
      ]]
    }
  },
  ["char"] = {
    outfits = {
      -- [outfitID] = { pets = {}, order = {}, total = 0}
    }
  }
}

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

--------------------------------------------------------------------------------
--- Module API
--------------------------------------------------------------------------------

function mod:InitializeCompanionDatabase()
  self.CompanionDB = LibStub("AceDB-3.0"):New("GMM_COMPANIONS_DB", default, true)
  self:RefreshProfilePointers()

  self.CompanionDB.RegisterCallback(self, "OnProfileChanged", "OnAceDBProfileEvent")
  self.CompanionDB.RegisterCallback(self, "OnProfileCopied", "OnAceDBProfileEvent")
  self.CompanionDB.RegisterCallback(self, "OnProfileReset", "OnAceDBProfileEvent")
  self:EnsureGlobal()
  self:EnsureOwned()
end

function mod:RefreshProfilePointers()
  self.dbp = self.CompanionDB.profile
  self.dbc = self.CompanionDB.char
end

function mod:RefreshEffectivePetList()
  self.EffectivePetList = self:GetEffectivePetList()
end

function mod:OnAceDBProfileEvent(...)
  self:RefreshProfilePointers()
  -- self:RefreshUI() if UI References Data
end

function mod:EnsureGlobal()
  local g = self.dbp.global or { pets = {}, order = {}, total = 0 }

  g.pets = g.pets or {}
  g.order = g.order or {}
  g.total = g.total or 0

  self.dbp.global = g
  return g
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

function mod:FilterExistingPetGUIDs(petsSet)
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
