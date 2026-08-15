--------------------------------------------------------------------------------
-- Companion Module Initialization and Lifecycle
--------------------------------------------------------------------------------
---
local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0, GMM_Companion
local mod = addOn:NewModule("CompanionModule", "AceTimer-3.0");

---@class GMM_Companion
---@field Data table
---@field Core table,
---@field Commands table,
---@field Config table,
---@field Cache table

Mixin(mod, {
  Data = {},
  Core = {},
  Commands = {},
  Config = {},
  Cache = {},
})

function mod:OnInitialize()
  mod.Data:Init()
  mod.Cache:Init(mod.Data)
  mod.Core:Init(mod.Data, mod.Cache)
  mod.Commands:Init(mod.Data, mod.Core)
  mod.Config:Init(mod.Data)
end

function mod:OnEnable()
end

function mod:OnDisable()
end
