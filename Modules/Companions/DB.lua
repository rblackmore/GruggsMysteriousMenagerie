local addonName, addonTable = ...
local addOn = addonTable.addOn
local module = addOn:GetModule("CompanionModule")
local DB = addOn.db
local CompanionsDB = DB["profile"]["Companions"]

local function isNilOrEmpty(db, location)
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

function module:InitializeCompanionDB()
  module.Settings = self.CompanionDB["Settings"]
  if self.CompanionDB.OwnedPetData == nil then
    self.CompanionDB.OwnedPetData = {}
  end

  for petID, _, owned, customName, _, isFav, _, name in addOn.PetJournal:CompanionIterator() do
    if isFav then
      self:AddCompanionToZone("FavoritePets", petID, addOn.PetJournal:GetSimplePetTable(petID))
    end
    if owned then
      self.CompanionDB.OwnedPetData[petID] = addOn.PetJournal:GetSimplePetTable(petID)
    end
  end
end

function module:GetCurrentZoneCompanionList()
  local location = GetZoneText()

  if isNilOrEmpty(DB, location) then
    return shallowCopy(CompanionsDB[location])
  end

  location = addOn.GetCurrentZoneType()

  if isNilOrEmpty(DB, location) then
    return shallowCopy(CompanionsDB[location])
  end

  return shallowCopy(CompanionsDB["FavoritePets"])
end

function module:AddCompanionToZone(zone, petID, petTable)
  if not CompanionsDB[zone] then
    CompanionsDB[zone] = {} -- Create New Table for Zone if Not exist.
  end
  CompanionsDB[zone][petID] = petTable
end

function module:RemoveCompanionFromZone(zone, petID)
  if not CompanionsDB[zone] then
    return
  end
  CompanionsDB[zone][petID] = nil
end

function module:Zone_Contains(zone, petID)
  return CompanionsDB[zone][petID] ~= nil
end
