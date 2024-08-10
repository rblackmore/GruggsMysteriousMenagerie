local addonName, addonTable = ...
local addOn = addonTable.addOn
local companionModule = addOn:GetModule("CompanionModule")

local defaults = {
  ["profile"] = {
    ["Settings"] = {
      ["MessageFormat"] = "Help me %s you're my only hope!!!",
      ["Channel"] = "SAY",
      ["UseCustomName"] = true,
      ["Automation"] = {
        ["delay"] = 2,
        ["GLOBAL"] = true,
        ["SCENARIO"] = true,
        ["RAID"] = true,
        ["DUNGEON"] = true,
        ["ARENA"] = true,
        ["BATTLEGROUND"] = true,
        ["RESTING"] = true,
        ["PetOfTheDay"] =
        {
          Enabled = false,
          Date = {
            ["year"] = 2004,
            ["month"] = 11,
            ["day"] = 23,
          },
          PetId = nil,
        },
      }
    },
    ["Companions"] = {
      ["FavoritePets"] = {},
    }
  }
}

function companionModule:GetDefaultDBValues()
  return defaults
end

function companionModule:LoadDatabase()
  self.db = LibStub("AceDB-3.0"):New("GMM_CompanionDB", self:GetDefaultDBValues(), true)
end

local function isNilOrEmpty(db, location)
  if db["profile"]["Companions"][location] ~= nil and #db["profile"]["Companions"][location] > 0 then
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
function companionModule:GetCurrentZoneCompanionList()
  local location = GetZoneText()
  if isNilOrEmpty(self.db, location) then
    return shallowCopy(self.db["profile"]["Companions"][location])
  end

  location = addOn.GetCurrentZoneType()

  if isNilOrEmpty(self.db, location) then
    return shallowCopy(self.db["profile"]["Companions"][location])
  end

  return shallowCopy(self.db["profile"]["Companions"]["FavoritePets"])
end

function companionModule:AddCompanionToZone(zone, petID, petTable)
  if not self.db["profile"]["Companions"][zone] then
    self.db["profile"]["Companions"][zone] = {} -- Create New Table for Zone if Not exist.
  end
  self.db["profile"]["Companions"][zone][petID] = petTable
end

function companionModule:RemoveCompanionFromZone(zone, petID)
  if not self.db["profile"]["Companions"][zone] then
    return
  end
  self.db["profile"]["Companions"][zone][petID] = nil
end

function companionModule:Zone_Contains(zone, petID)
  return self.db["profile"]["Companions"][zone][petID] ~= nil
end

function companionModule:GetDatabaseSettings()
  return self.db["profile"].Settings
end
