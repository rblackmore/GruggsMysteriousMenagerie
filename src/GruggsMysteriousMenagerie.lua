local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
addOn:SetDefaultModuleState(false)
addOn:SetDefaultModuleLibraries("AceEvent-3.0", "AceConsole-3.0")


_G["GMM"] = addonTable
_G["GMM_AddOn"] = addOn
-- _G["GMM_Companions"] = companionModule
-- _G["GMM_Options"] = Options
addOn.Core = addOn.Core or {}
addOn.DB = addOn.DB or {}
addOn.UI = addOn.UI or {}
addOn.UI.ConfigFrames = addOn.UI.ConfigFrames or {}
addOn.SlashCmd = addOn.SlashCmd or {}
addOn.Config = addOn.Config or {}

local registeredEvents = {}
-------------------------------------------------------------------------------
--- Public API

function addOn:OnInitialize()
  self.DB:Init()
  self.Config:Init()
  self.SlashCmd:Init()

  -- self:InitializeDatabase()

  -- Options:InitializeOptions()
  -- self:RegisterChatCommand("gmm", "SlashCommand")
  -- self:RegisterChatCommand("gmsummon", function()
  --   local petID = companionModule:ChooseRandomCompanion()
  --   companionModule:SummonCompanion(petID)
  --   companionModule:AnnounceSummon(petID)
  -- end)
end

function addOn:OnEnable() end

function addOn:OnDisable() end
