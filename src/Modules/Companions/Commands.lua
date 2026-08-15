local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")

local API = mod.API
local Utilities = addOn.Utilities

--------------------------------------------------------------------------------
--- Local Functions and Constants
--------------------------------------------------------------------------------

local scopes = {
  global = "global",
  g = "global",
  continent = "continent",
  c = "continent",
  zone = "zone",
  z = "zone",
  outfit = "outfit",
  o = "outfit"
}

local function add(scope, petGUID)
  if scope == scopes.global then
    API:AddPetToGlobal(petGUID)
  end

  if scope == scopes.continent then
    local success, continentID = Utilities:GetContinentIDForMap(C_Map.GetBestMapForUnit("player"))
    API:AddPetToContinent(petGUID, continentID)
  end

  if scope == scopes.zone then
    local mapId = C_Map.GetBestMapForUnit("player")
    local success, continentId = Utilities:GetContinentIDForMap(mapId)
    API:AddPetToZone(petGUID, continentId, mapId)
  end

  if scope == scopes.outfit then
    local outfitId = C_TransmogOutfitInfo.GetActiveOutfitID()
    API:AddPetToOutfit(petGUID, outfitId)
  end
end

local function remove(scope, petGUID)

end
local function clear(scope) end
local function list(scope) end

local actions = {
  add = "add",
  remove = "remove",
  clear = "clear",
  list = "list"
}

local function getScopeAndItems(...)
  local args = { ... }
  local scope = scopes[args[1]]

  if not scope then
    return scopes.global, args[1]
  end

  return scope, args[2]
end



--------------------------------------------------------------------------------
--- Module API
--------------------------------------------------------------------------------
function API:HandleAction(action, ...)
  -- ... = { everything users passed after action }
  -- Could be: { "zone", "[item:123]", "[item:456]"}
  -- or: {"[item:123]", "[item:456]"}
  -- or: {"zone"} -- scope without items means action of list or clear.

  local scope, itemLink = getScopeAndItems(...);

  if action == actions.add then
    if LinkUtil.IsLinkType(itemLink, LinkTypes.BattlePet) then
      local linkType, linkOptions, displayText = LinkUtil.ExtractLink(itemLink)
      local options = { LinkUtil.SplitLinkOptions(linkOptions) }
      local petGUID = options[7]
      addOn:Printf("Adding %s to %s", displayText, scope)
      add(scope, petGUID)
    end
  end
end
