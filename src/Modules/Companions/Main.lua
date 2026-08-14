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
---@field DB table
---@field Core table,
---@field Commands table,
---@field Config table,
---@field Cache table

Mixin(mod, {
  DB = {},
  Core = {},
  Commands = {},
  Config = {},
  Cache = {},
})

function mod:OnInitialize()
  mod.DB:Init()
  mod.Cache:Init(mod.DB)
  mod.Core:Init(mod.DB, mod.Cache)
  mod.Commands:Init(mod.DB, mod.Core)
  mod.Config:Init(mod.DB)
end

function mod:OnEnable()
end

function mod:OnDisable()
end
