local addonName, addonTable = ...
local addOn = addonTable.addOn
local module = addOn:GetModule("CompanionModule")

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

function module:RefreshFavorites()
  self.CompanionDB["FavoritePets"] = {}
  for petID, _, owned, customName, _, isFav, _, name in addOn.PetJournal:CompanionIterator() do
    if isFav then
      self:AddCompanionToZone("FavoritePets", petID, addOn.PetJournal:GetSimplePetTable(petID))
    end
  end
end

function module:RefreshOwnedPetData()
  self.OwnedPetData = {}
  for petID, _, owned, customName, _, isFav, _, name in addOn.PetJournal:CompanionIterator() do
    if owned then
      self.OwnedPetData[petID] = addOn.PetJournal:GetSimplePetTable(petID)
    end
  end
end

function module:InitializeCompanionDB()
  self.CompanionDB = addOn.db["profile"]["Companions"]
  self.Settings = self.CompanionDB["Settings"]

  self:RefreshFavorites()
  self:RefreshOwnedPetData()
end

function module:GetCurrentZoneCompanionList()
  local location = GetZoneText()

  if isNilOrEmpty(self.CompanionDB, location) then
    return shallowCopy(self.CompanionDB[location])
  end

  location = addOn.GetCurrentZoneType()

  if isNilOrEmpty(self.CompanionDB, location) then
    return shallowCopy(self.CompanionDB[location])
  end

  return shallowCopy(self.CompanionDB["FavoritePets"])
end

function module:AddCompanionToZone(zone, petID, petTable)
  if not self.CompanionDB[zone] then
    self.CompanionDB[zone] = {} -- Create New Table for Zone if Not exist.
  end
  self.CompanionDB[zone][petID] = petTable
end

function module:RemoveCompanionFromZone(zone, petID)
  if not self.CompanionDB[zone] then
    return
  end
  self.CompanionDB[zone][petID] = nil
end

function module:Zone_Contains(zone, petID)
  return self.CompanionDB[zone][petID] ~= nil
end
