local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)

addOn.DB = addOn.DB or {}
local DB = addOn.DB

--------------------------------------------------------------------------------
--- API
--------------------------------------------------------------------------------
function DB:Init()
  self.AceDatabase = LibStub("AceDB-3.0"):New("GMM_DB", { profile = {}, char = {}, global = {} }, true)

  self["CompanionNS"] = self.AceDatabase:RegisterNamespace("Companions", {
    profile = {

      global = { pets = {}, order = {}, weights = {}, total = 0 },
      continents = {},
      zones = {},
      fallback = {},
      cities = {},
      meta = { schemaVersion = 1, createdAt = time(), lastUpdated = time() },
    },
    char = {
      outfits = {},
      meta = { schemaVersion = 1, createdAt = time(), lastUpdated = time() },
    }
  })

  self["MountNS"] = self.AceDatabase:RegisterNamespace("Mounts", {
    profile = {

      global = { mounts = {}, order = {}, total = 0 },
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

  self["SettingsNS"] = self.AceDatabase:RegisterNamespace("Settings", {
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
        mounts = {},
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

function DB:RefreshProfilePointers()
  self.dbp = self.AceDatabase.profile
  self.dbc = self.AceDatabase.char
end

function DB:OnProfileEvent(...)
  self:RefreshProfilePointers()
end
