local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
addOn:SetDefaultModuleState(false)
addOn:SetDefaultModuleLibraries("AceEvent-3.0", "AceConsole-3.0")

---@class AceAddon: AceTimer-3.0
local companionModule = addOn:NewModule("CompanionModule", "AceTimer-3.0");
---@class AceAddon: AceConsole-3.0, AceEvent-3.0
local Options = addOn:NewModule("Options")
---@class AceAddon: AceConsole-3.0, AceEvent-3.0
local PetJournal = addOn:NewModule("GMM_PetJournal")
---@class AceAddon: AceConsole-3.0, AceEvent-3.0
local MapInfo = addOn:NewModule("GMM_MapInfo")

_G["GMM"] = addonTable
_G["GMM_AddOn"] = addOn
_G["GMM_Companions"] = companionModule
_G["GMM_Options"] = Options
_G["GMM_PetJournal"] = PetJournal
_G["GMM_MapInfo"] = MapInfo


local registeredEvents = {}
-------------------------------------------------------------------------------
--- Public API

function addOn:OnInitialize()
  self:InitializeDatabase()
  self:InitializeTransmogDatabase()

  Options:InitializeOptions()
  self:RegisterChatCommand("gmm", "SlashCommand")
  self:RegisterChatCommand("gmsummon", function()
    companionModule:SummonCompanion(true)
  end)
end

function addOn:OnEnable()
  for name, module in self:IterateModules() do
    module:Enable()
  end
end

function addOn:OnDisable()
  for name, module in self:IterateModules() do
    module:Disable()
  end
end

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
