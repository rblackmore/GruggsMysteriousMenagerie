--------------------------------------------------------------------------------
-- Companion Module Initialization and Lifecycle
--------------------------------------------------------------------------------
---
local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:NewModule("CompanionModule", "AceTimer-3.0");

mod.DB = {}
mod.Core = {}
mod.Commands = {}
mod.Config = {}
mod.Cache = {}

function mod:OnInitialize()
  mod.DB:Init()
  mod.Core:Init()
  mod.Commands:Init()
  mod.Config:Init()
  mod.Cache:Init()
end

function mod:OnEnable()
end

function mod:OnDisable()
end
