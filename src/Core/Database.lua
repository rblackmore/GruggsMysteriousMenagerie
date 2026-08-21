local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0, GMM_Addon
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class GMM_Data
---@field AceDatabase AceDBObject-3.0
---@field Companions AceDBObject-3.0
---@field Mounts AceDBObject-3.0
---@field Settings AceDBObject-3.0
---@field profile AceDBObject-3.0
---@field char AceDBObject-3.0

local Data = addOn.Data

--------------------------------------------------------------------------------
--- API
--------------------------------------------------------------------------------
function Data:Init()
  self["AceDatabase"] = LibStub("AceDB-3.0"):New("GMM_DB", { profile = {}, char = {}, global = {} }, true)

  self["Mounts"] = self.AceDatabase:RegisterNamespace("Mounts", {
    profile = {

      world = { mounts = {}, order = {}, total = 0 },
      continents = {},
      zones = {},
      cities = {},
      categories = {}, -- eg. { ground = {set+order}, flying = {...}}
      meta = { schemaVersion = 1, createdAt = time(), lastUpdated = time() },
    },
    char = {
      outfits = {},
      meta = { schemaVersion = 1, createdAt = time(), lastUpdated = time() },
    }
  })

  self["Settings"] = self.AceDatabase:RegisterNamespace("Settings", {
    profile = {
      companions = {
        MessageFormat = "Help me %s you're my only hope!!!",
        Channel = "SAY",
        UseCustomName = true,
        UseFavoritesFallback = true,
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
          petoftheday = {
            Enabled = false,
            Date = {
              ["year"] = 2004,
              ["month"] = 11,
              ["day"] = 23,
            },
            Pet = nil,
          },
        },
        ui = {
          showMinimapButton = true,
        },
        meta = { schemaVersion = 1, createdAt = time(), lastUpdated = time() },
      },
      global = {
        debut = false,
      },
      char = {
        meta = { schemaVersion = 1, createdAt = time(), lastUpdated = time() },
      }
    }
  })

  self.AceDatabase.RegisterCallback(self, "OnProfileChanged", "OnProfileEvent")
  self.AceDatabase.RegisterCallback(self, "OnProfileCopied", "OnProfileEvent")
  self.AceDatabase.RegisterCallback(self, "OnProfileReset", "OnProfileEvent")
end

local function RefreshProfilePointers()
  Data.profile = Data.AceDatabase.profile
  Data.char = Data.AceDatabase.char
end

function Data:OnProfileEvent(...)
  RefreshProfilePointers()
end
