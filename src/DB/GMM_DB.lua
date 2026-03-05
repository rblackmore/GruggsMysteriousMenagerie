local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)


-------------------------------------------------------------------------------
--- Module API

function addOn:InitializeDatabase()
  self.db = LibStub("AceDB-3.0"):New("GMM_DB", { profile = {}, char = {}, global = {} }, true)

  self.dbCompanions = self.db:RegisterNamespace("Companions", {
    profile = {

      global = { pets = {}, order = {}, weights = {}, total = 0 },
      continents = {},
      zones = {},
      owned = {},
      cities = {},
      meta = { schemaVersion = 1, createdAt = time(), lastUpdated = time() },
    },
    char = {
      outfits = {}
    }
  })

  self.dbMounts = self.db:RegisterNamespace("Mounts", {
    profile = {

      global = { mounts = {}, order = {}, total = 0 },
      continents = {},
      zones = {},
      cities = {},
      categories = {}, -- eg. { ground = {set+order}, flying = {...}}
      meta = { schemaVersion = 1, createdAt = time(), lastUpdated = time() },
    },
    char = {
      outfits = {}
    }
  })

  self.dbSettings = self.db:RegisterNamespace("Settings", {
    profile = {
      companions = {
        MessageFormat = "Help me %s you're my only hope!!!",
        Channel = "SAY",
        UseCustomName = true,
        Automation = {
          delay = 5,
          forcesummon = false,
          GLOBAL = true,
          SCENARIO = true,
          RAID = true,
          DUNGEON = true,
          ARENA = true,
          BATTLEGROUND = true,
          RESTING = true,
        },
        mounts = {},
        ui = {
          showMinimapButton = true,
        },
        meta = { schemaVersion = 1, createdAt = time(), lastUpdated = time() },
      },
      global = {
        debut = false,
      },
      char = {}
    }
  })

  self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileEvent")
  self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileEvent")
  self.db.RegisterCallback(self, "OnProfileReset", "OnProfileEvent")
end

function addOn:RefreshProfilePointers()
  self.dbp = self.db.profile
  self.dbc = self.db.char
end

function addOn:OnProfileEvent(...)
  self:RefreshProfilePointers()
end

-- function addOn:GetGlobalSettings()
--   return self.db["Settings"]
-- end

-- function addOn:GetCompanionsDB()
--   return self.db["Companions"]
-- end

-- function addOn:GetMountsDB()
--   return self.db["Mounts"]
-- end

-- function addOn:GetProfileDB()
--   return self.db["profile"]
-- end

-- function addOn:LoadProfile()
--   -- Callback for Profile Change Events
-- end


-- local defaults = {
--   ["profile"] = {
--     ["Settings"] = {},
--     ["Mounts"] = {
--       ["Settings"] = {}
--     },
--     ["Companions"] = {
--       ["Settings"] = {
--         ["MessageFormat"] = "Help me %s you're my only hope!!!",
--         ["Channel"] = "SAY",
--         ["UseCustomName"] = true,
--         ["Automation"] = {
--           ["delay"] = 5,
--           ["forcesummon"] = false,
--           ["GLOBAL"] = true,
--           ["SCENARIO"] = true,
--           ["RAID"] = true,
--           ["DUNGEON"] = true,
--           ["ARENA"] = true,
--           ["BATTLEGROUND"] = true,
--           ["RESTING"] = true,
--           ["PetOfTheDay"] =
--           {
--             Enabled = false,
--             Date = {
--               ["year"] = 2004,
--               ["month"] = 11,
--               ["day"] = 23,
--             },
--             Pet = nil,
--           },
--         }
--       },
--       ["FavoritePets"] = {},
--       ["Locations"] = {
--         ["ZoneName"] = {
--           Total = 0,
--           CompanionIds = {}
--         }
--       },
--       ["Specializations"] = {
--         ["Class|Spec"] = {
--           Total = 0,
--           CompanionIds = {}
--         }
--       }
--     }
--   }
-- }
