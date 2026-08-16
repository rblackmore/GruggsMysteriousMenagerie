local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")

local API = mod.API
local Utilities = addOn.Utilities
local Enums = Utilities.Enums

--------------------------------------------------------------------------------
--- Local Functions and Constants
--------------------------------------------------------------------------------

local SCOPES = Enums.SCOPES

local actions = {
  add = "add",
  remove = "remove",
  clear = "clear",
  list = "list"
}

local function add(scope, petGUID)
  if scope == SCOPES.global then
    API:AddPetToGlobal(petGUID)
  end

  if scope == SCOPES.continent then
    local success, continentID = Utilities:GetContinentIDForMap(C_Map.GetBestMapForUnit("player"))
    API:AddPetToContinent(petGUID, continentID)
  end

  if scope == SCOPES.zone then
    local mapId = C_Map.GetBestMapForUnit("player")
    local success, continentId = Utilities:GetContinentIDForMap(mapId)
    API:AddPetToZone(petGUID, continentId, mapId)
  end

  if scope == SCOPES.outfit then
    local outfitId = C_TransmogOutfitInfo.GetActiveOutfitID()
    API:AddPetToOutfit(petGUID, outfitId)
  end
end

local function remove(scope, petGUID)
  if scope == SCOPES.global then
    API:RemovePetFromGlobal(petGUID)
  end

  if scope == SCOPES.continent then
    local success, continentId = Utilities:GetContinentIDForMap(C_Map.GetBestMapForUnit("player"))
    API:RemovePetFromContinent(petGUID, continentId)
  end

  if scope == SCOPES.zone then
    local mapId = C_Map.GetBestMapForUnit("player")
    local success, continentId = Utilities:GetContinentIDForMap(mapId)
    API:RemovePetFromZone(petGUID, continentId, mapId)
  end

  if scope == SCOPES.outfit then
    local outfitId = C_TransmogOutfitInfo.GetActiveOutfitID()
    API:RemovePetFromOutfit(petGUID, outfitId)
  end
end

local function list(scope)
  local list
  if scope == SCOPES.global then
    list = API:GetListForScope(scope)
  end
  if scope == SCOPES.continent then
    local success, continentId = Utilities:GetContinentIDForMap(C_Map.GetBestMapForUnit("player"))
    list = API:GetListForScope(scope, continentId)
  end
  if scope == SCOPES.zone then
    local mapId = C_Map.GetBestMapForUnit("player")
    local success, continentId = Utilities:GetContinentIDForMap(mapId)
    list = API:GetListForScope(scope, continentId, mapId)
  end
  if scope == SCOPES.outfit then
    local outfitId = C_TransmogOutfitInfo.GetActiveOutfitID()
    list = API:GetListForScope(scope, outfitId)
  end

  _G["GMM_LISTED_PETS"] = list

  if not list or not list.pets then
    addOn:Printf("No Pets for %s", scope)
    return
  end

  addOn:Printf("Pets in %s", scope)
  local num = 0
  for k, v in pairs(list.pets) do
    addOn:Printf("Key: %s, Value: %s", k, v)
    if v then
      num = num + 1
      local petTable = C_PetJournal.GetPetInfoTableByPetID(k)
      addOn:Printf("[%d] %s", num, petTable.name)
    end
  end
end

local function clear(scope) end



local function getScopeAndItems(...)
  local args = { ... }
  local scope = SCOPES[args[1]]

  if not scope then
    return SCOPES.global, args[1]
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
      add(scope, petGUID)
    end
  end

  if action == actions.remove then
    if LinkUtil.IsLinkType(itemLink, LinkTypes.BattlePet) then
      local linkType, linkOptions, displayText = LinkUtil.ExtractLink(itemLink)
      local options = { LinkUtil.SplitLinkOptions(linkOptions) }
      local petGUID = options[7]
      remove(scope, petGUID)
    end
  end

  if action == actions.list then
    list(scope)
  end
end
