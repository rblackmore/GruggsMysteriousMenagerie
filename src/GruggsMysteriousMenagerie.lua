local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
addOn:SetDefaultModuleState(false)
addOn:SetDefaultModuleLibraries("AceEvent-3.0", "AceConsole-3.0")



_G["GMM"] = addonTable
_G["GMM_AddOn"] = addOn
-- _G["GMM_Companions"] = companionModule
-- _G["GMM_Options"] = Options


local registeredEvents = {}
-------------------------------------------------------------------------------
--- Public API

function addOn:OnInitialize()
  self:InitializeDatabase()

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

function addOn:SlashCommand(args)
  if InCombatLockdown() then
    self:Printf("Opening Settings when out of Combat")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", function()
      self:UnregisterEvent("PLAYER_REGEN_ENABLED")
      Settings.OpenToCategory(Options["ConfigFrames"]["GMM_Companions"]["Id"])
    end)
    registeredEvents["PLAYER_REGEN_ENABLED"] = true
    return
  else
    Settings.OpenToCategory(Options["ConfigFrames"]["GMM_Companions"]["Id"])
  end
end
