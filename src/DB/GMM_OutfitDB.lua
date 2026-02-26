local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local companionModule = addOn:GetModule("CompanionModule")

local defaults = {
  ["char"] = {
    ["Outfits"] = {}
  }
}

function addOn:InitializeTransmogDatabase()
  addOn.outfitDb = LibStub("AceDB-3.0"):New("GMM_OUTFITS_DB", defaults, true)
end

function addOn:GetActiveOutfitTable()
  local outfitid = C_TransmogOutfitInfo.GetActiveOutfitID()
  return self:GetOutfitTableOrNil(outfitid)
end

function addOn:GetOutfitTableOrNil(outfitid)
  return self.outfitDb.char["Outfits"][outfitid]
end
