local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)

local defaults = {
  ["char"] = {
    ["Outfits"] = {}
  }
}

function addOn:InitializeTransmogDatabase()
  addOn.outfitDb = LibStub("AceDB-3.0"):New("GMM_OUTFITS_DB", defaults, true)
end
