--------------------------------------------------------------------------------
--- Main Addon Initialization and Lifecycle Management
--------------------------------------------------------------------------------
local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0, GMM_Addon
local addOn = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

addOn:SetDefaultModuleState(false)
addOn:SetDefaultModuleLibraries("AceEvent-3.0", "AceConsole-3.0")

---@class GMM_Addon
---@field DB table
---@field UI {ConfigFrames: table}
---@field Config table
---@field SlashCmd table
---@field Utilities table
---@field Modules { Pet: fun(): AceModule, Mount: fun(): AceModule, ... }

Mixin(addOn,
  {
    DB = {},
    UI = {
      ConfigFrames = {} },
    Config = {},
    SlashCmd = {},
    Utilities = {},
    Modules = {
      Pet = function() return addOn:GetModule("CompanionModule") end,
      comp = function() return addOn:GetModule("CompanionModule") end,
      comps = function() return addOn:GetModule("CompanionModule") end,
      pet = function() return addOn:GetModule("CompanionModule") end,
      pets = function() return addOn:GetModule("CompanionModule") end,
      Mount = function() return addOn:GetModule("MountModule") end
    },
  })

function addOn:OnInitialize()
  self.DB:Init()
  self.UI:Init()
  self.Config:Init()
  self.SlashCmd:Init()
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
