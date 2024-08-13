local addonName, addonTable = ...
local addOn = addonTable.addOn

local defaults = {
  ["profile"] = {
    ["Settings"] = {},
    ["Mounts"] = {
      ["Settings"] = {}
    },
    ["Companions"] = {
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
      ["FavoritePets"] = {},
    }
  }
}

function addOn:InitializeDatabase()
  self:Print("Initializing Core DB")
  self.db = LibStub("AceDB-3.0"):New("GMM_DB", defaults, true)
  addOn.Settings = addOn.db["Settings"]
  self:Print("Core DB Initialized")
end
