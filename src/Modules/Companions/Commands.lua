local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")

local API = mod.API
local Enums = addonTable.Enums

--------------------------------------------------------------------------------
--- Local Functions and Constants
--------------------------------------------------------------------------------

local scopeMap = {
  global = { type = Enums.ListScope.Global, context = nil },
  g = { type = Enums.ListScope.Global, context = nil },
  continent = { type = Enums.ListScope.Continent, context = C_Map.GetBestMapForUnit("player") },
  c = { type = Enums.ListScope.Continent, context = C_Map.GetBestMapForUnit("player") },
  zone = { type = Enums.ListScope.Zone, context = C_Map.GetBestMapForUnit("player") },
  z = { type = Enums.ListScope.Zone, context = C_Map.GetBestMapForUnit("player") },
  outfit = { type = Enums.ListScope.Outfit, context = C_TransmogOutfitInfo.GetActiveOutfitID() },
  o = { type = Enums.ListScope.Outfit, context = C_TransmogOutfitInfo.GetActiveOutfitID() }
}
local function extractScope(items)
  -- Returns <scope or global>, <items or {}>.
  -- Steps:
  -- 1. Check if items[1] is scope or items
  -- 2. Get Scope from Map or just use Global.
  -- 3. Determine if remaining args are Items.
  -- 4. Return scope + Items or {}
end

--------------------------------------------------------------------------------
--- Module Lifecycle Functions
--------------------------------------------------------------------------------

function API:Init()
  -- TODO: Remove these chat commands in a later update.
  mod:RegisterChatCommand("gmsummon", function(...)
    mod:Printf("/gmsummon command is deprecated and will be removed in a future update, use '/gmm summon' instead")
    API:HandleSummonCommand(...)
  end)
  mod:RegisterChatCommand("gmmsummon", function(...)
    mod:Printf("/gmmsummon command is deprecated and will be removed in a future update, use '/gmm summon' instead")
    API:HandleSummonCommand(...)
  end)
end

--------------------------------------------------------------------------------
--- Module API
--------------------------------------------------------------------------------
function API:HandleAction(action, items)
  -- items = { everything users passed after action }
  -- Could be: { "zone", "[item:123]", "[item:456]"}
  -- or: {"[item:123]", "[item:456]"}
  -- or: {"zone"} -- scope without items means action of list or clear.

  local scope, itemsToProcess = extractScope(items);
end

function API:Add() end

function API:Remove() end

function API:Clear() end

function API:List() end
