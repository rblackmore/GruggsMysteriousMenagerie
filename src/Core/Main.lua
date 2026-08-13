--------------------------------------------------------------------------------
--- Main Addon Initialization and Lifecycle Management
--------------------------------------------------------------------------------
local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

addOn:SetDefaultModuleState(false)
addOn:SetDefaultModuleLibraries("AceEvent-3.0", "AceConsole-3.0")

addOn.DB = {}
addOn.UI = {}
addOn.UI.ConfigFrames = {}
addOn.Config = {}
addOn.SlashCmd = {}
addOn.Modules = {}

function addOn:OnInitialize()
  self.DB:Init()
  self.UI:Init()
  self.Config:Init()
  self.SlashCmd:Init()
  addOn.Modules = {
    companion = addOn:GetModule("CompanionModule"),
    companions = addOn:GetModule("CompanionModule"),
    pet = addOn:GetModule("CompanionModule"),
    pets = addOn:GetModule("CompanionModule")
  }
end

function addOn:OnEnable() end

function addOn:OnDisable() end

function addOn:DeferIfInCombatLockdown(delegate, msg)
  if InCombatLockdown() then
    addOn:Print(msg);
    addOn:RegisterEvent("PLAYER_REGEN_ENABLED", function(...)
      addOn:UnregisterEvent("PLAYER_REGEN_ENABLED")
      delegate()
    end)
  else
    delegate()
  end
end
