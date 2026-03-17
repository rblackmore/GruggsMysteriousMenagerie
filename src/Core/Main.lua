--------------------------------------------------------------------------------
--- Main Addon Initialization and Lifecycle Management
--------------------------------------------------------------------------------
local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

addOn:SetDefaultModuleState(false)
addOn:SetDefaultModuleLibraries("AceEvent-3.0", "AceConsole-3.0")

-- addOn.Core = addOn.Core or {}
addOn.DB = {}
addOn.UI = {}
addOn.UI.ConfigFrames = {}
addOn.Config = {}
addOn.SlashCmd = {}

function addOn:OnInitialize()
  self.DB:Init()
  self.UI:Init()
  self.Config:Init()
  self.SlashCmd:Init()
end

function addOn:OnEnable() end

function addOn:OnDisable() end
