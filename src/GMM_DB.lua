local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)

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
          ["delay"] = 5,
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
            Pet = nil,
          },
        }
      },
      ["FavoritePets"] = {},
    }
  }
}

-------------------------------------------------------------------------------
--- Public API

function addOn:InitializeDatabase()
  self.db = LibStub("AceDB-3.0"):New("GMM_DB", defaults, true)

  self.db.RegisterCallback(self, "OnProfileChanged", "LoadProfile")
  self.db.RegisterCallback(self, "OnProfileCopied", "LoadProfile")
  self.db.RegisterCallback(self, "OnProfileReset", "LoadProfile")
end

function addOn:GetGlobalSettings()
  return self.db["Settings"]
end

function addOn:GetCompanionsDB()
  return self.db["Companions"]
end

function addOn:GetMountsDB()
  return self.db["Mounts"]
end

function addOn:GetProfileDB()
  return self.db["profile"]
end

function addOn:LoadProfile()
  -- Callback for Profile Change Events
end
