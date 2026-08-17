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
  if scope == SCOPES.world then
    API:AddPetToWorld(petGUID)
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
  if scope == SCOPES.world then
    API:RemovePetFromWorld(petGUID)
  end

  if scope == SCOPES.continent then
    local success, continentId = Utilities:GetContinentIDForMap(C_Map.GetBestMapForUnit("player"))
    if success then
      API:RemovePetFromContinent(petGUID, continentId)
    end
  end

  if scope == SCOPES.zone then
    local mapId = C_Map.GetBestMapForUnit("player")
    local success, continentId = Utilities:GetContinentIDForMap(mapId)
    if success then
      API:RemovePetFromZone(petGUID, continentId, mapId)
    end
  end

  if scope == SCOPES.outfit then
    local outfitId = C_TransmogOutfitInfo.GetActiveOutfitID()
    if outfitId then
      API:RemovePetFromOutfit(petGUID, outfitId)
    end
  end
end

local function list(scope)
  local list = API:GetListForContextScope(scope)
  if not list or not list.pets then
    addOn:Printf("No Pets for %s", scope)
    return
  end

  addOn:Printf("Pets in %s", scope)
  local num = 0
  for i, v in ipairs(list.order) do
    local petTable = C_PetJournal.GetPetInfoTableByPetID(v)
    addOn:Printf("[%d] %s", i, petTable.name)
  end
end

local function clear(scope)
  if scope == SCOPES.world then
    API:ClearList(scope)
  end

  if scope == SCOPES.continent then
    local success, continentId = Utilities:GetContinentIDForMap(C_Map.GetBestMapForUnit("player"))
    if success then
      API:ClearList(scope, continentId)
    end
  end

  if scope == SCOPES.zone then
    local mapId = C_Map.GetBestMapForUnit("player")
    local success, continentId = Utilities:GetContinentIDForMap(mapId)
    if success then
      API:ClearList(scope, continentId, mapId)
    end
  end

  if scope == SCOPES.outfit then
    local outfitId = C_TransmogOutfitInfo.GetActiveOutfitID()
    if outfitId then
      API:ClearList(scope, outfitId)
    end
  end
end

local function getScopeWithArgs(...)
  local args = { ... }
  local scope = SCOPES[args[1]]

  if not scope then
    return SCOPES.world, args
  end

  return scope, { select(2, ...) }
end

--------------------------------------------------------------------------------
--- Module API
--------------------------------------------------------------------------------
function API:HandleAction(action, ...)
  -- ... = { everything users passed after action }
  -- Could be: { "zone", "[item:123]", "[item:456]"}
  -- or: {"[item:123]", "[item:456]"}
  -- or: {"zone"} -- scope without items means action of list or clear.

  local scope, args = getScopeWithArgs(...);

  if action == actions.add then
    if LinkUtil.IsLinkType(args[1], LinkTypes.BattlePet) then
      local _, linkOptions, _ = LinkUtil.ExtractLink(args[1])
      local _, _, _, _, _, _, petGUID = LinkUtil.SplitLinkOptions(linkOptions)
      add(scope, petGUID)
    end
  end

  if action == actions.remove then
    if LinkUtil.IsLinkType(args[1], LinkTypes.BattlePet) then
      local _, linkOptions, _ = LinkUtil.ExtractLink(args[1])
      local _, _, _, _, _, _, petGUID = LinkUtil.SplitLinkOptions(linkOptions)
      remove(scope, petGUID)
    end
  end

  if action == actions.list then
    list(scope)
  end

  if action == actions.clear then
    clear(scope)
  end
end
