local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")

function mod:InitializeCompanionDB()
  self.CompanionDB = addOn.db["profile"]["Companions"]
  self.Settings = self.CompanionDB["Settings"]
end
