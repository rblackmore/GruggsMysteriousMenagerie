local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")
---@class AceAddon: AceConsole-3.0, AceEvent-3.0,
local PetJournal = addOn:GetModule("GMM_PetJournal")
---@class AceAddon: AceConsole-3.0, AceEvent-3.0
local MapInfo = addOn:GetModule("GMM_MapInfo")

local function isNotNilOrEmpty(db, location)
  if db[location] ~= nil and #db[location] > 0 then
    return true
  end
  return false
end

local function shallowCopy(t)
  local t2 = {}
  for k, v in pairs(t) do
    t2[k] = v
  end
  return t2
end

function mod:RefreshFavorites()
  self.CompanionDB["FavoritePets"] = {}
  for petID, _, owned, customName, _, isFav, _, name in PetJournal:CompanionIterator() do
    if isFav then
      self:AddCompanionToZone("FavoritePets", petID, PetJournal:GetSimplePetTable(petID))
    end
  end
end

function mod:RefreshOwnedPetData()
  self.OwnedPetData = {}
  for petID, _, owned, customName, _, isFav, _, name in PetJournal:CompanionIterator() do
    if owned then
      self.OwnedPetData[petID] = PetJournal:GetSimplePetTable(petID)
    end
  end
end

function mod:InitializeCompanionDB()
  self.CompanionDB = addOn.db["profile"]["Companions"]
  self.Settings = self.CompanionDB["Settings"]

  self:ScheduleTimer(function()
    self:RefreshFavorites()
    self:RefreshOwnedPetData()
  end, 1)
end

function mod:GetCurrentZoneCompanionList()
  local location = GetZoneText()

  if isNotNilOrEmpty(self.CompanionDB, location) then
    return shallowCopy(self.CompanionDB[location])
  end

  location = MapInfo.GetCurrentZoneType()

  if isNotNilOrEmpty(self.CompanionDB, location) then
    return shallowCopy(self.CompanionDB[location])
  end

  return shallowCopy(self.CompanionDB["FavoritePets"])
end

function mod:AddCompanionToZone(zone, petID, petTable)
  if not self.CompanionDB[zone] then
    self.CompanionDB[zone] = {} -- Create New Table for Zone if Not exist.
  end
  self.CompanionDB[zone][petID] = petTable
end

function mod:RemoveCompanionFromZone(zone, petID)
  if not self.CompanionDB[zone] then
    return
  end
  self.CompanionDB[zone][petID] = nil
end

function mod:AddCompanionToLocation(location, petID)
  local locations = self.CompanionDB["Locations"]

  if not locations[location] then
    locations[location] = { Total = 0, CompanionIds = {} }
  end
  locations[location]["Total"] = locations[location]["Total"] + 1
  locations[location]["CompanionIds"][locations[location]["Total"]] = petID

  return locations[location]["Total"]
end

function mod:RemoveCompanionFromLocation(location, petID)
  local locations = self.CompanionDB["Locations"]
  if not locations[location] then
    -- No Saved Data for this Loation
    return
  end

  local petIdTable = locations[location]["CompanionIds"]

  for i = 1, #petIdTable do
    if petIdTable[i] == petID then
      table.remove(petIdTable, i)
    end
  end
end

function mod:Zone_Contains(zone, petID)
  return self.CompanionDB[zone][petID] ~= nil
end
