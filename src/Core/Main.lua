--------------------------------------------------------------------------------
--- Main Addon Initialization and Lifecycle Management
--------------------------------------------------------------------------------
local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0, GMM_Addon
local addOn = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
_G["GMM"] = addonTable
_G["GMM_AddOn"] = addOn
addOn:SetDefaultModuleState(false)
addOn:SetDefaultModuleLibraries("AceEvent-3.0", "AceConsole-3.0")

---@class GMM_Addon
---@field Data table
---@field UI {ConfigFrames: table, [any]: any }
---@field Config table
---@field SlashCmd table
---@field Modules { Pet: fun(): AceModule, Mount: fun(): AceModule, ... }

---@class GMM_Table
---@field Enums table
---@field MapUtils table
---@field CombatLockdownUtils table



Mixin(addOn,
  {
    Data = {},
    UI = {
      ConfigFrames = {} },
    Config = {},
    SlashCmd = {},
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
  self.Data:Init()
  self.UI:Init()
  self.Config:Init()
  self.SlashCmd:Init()
end

function addOn:OnEnable() end

function addOn:OnDisable() end
