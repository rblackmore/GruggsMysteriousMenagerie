local addonName, addonTable = ...
addonTable.addOn = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
---@class AceAddon: AceConsole-3.0, AceEvent-3.0
local addOn = addonTable.addOn
_G["GMM"] = addOn
addOn:SetDefaultModuleState(false)
addOn:SetDefaultModuleLibraries("AceEvent-3.0", "AceConsole-3.0")

function addOn:OnInitialize()
  self:InitializeDatabase()
  
  self:InitializeOptions()
  self:InitializeProfiles()

  self:RegisterChatCommand("gmm", "SlashCommand")
  self:RegisterChatCommand("gmsummon", function()
    local module = addOn:GetModule("CompanionModule");
    module:SummonCompanion(true)
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
    return
  end
  Settings.OpenToCategory(self["CompanionOptionsFrame"]["Id"])
end
