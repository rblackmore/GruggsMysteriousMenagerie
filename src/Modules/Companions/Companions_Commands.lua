local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0, GMM_Companion
local companionModule = addOn:GetModule("CompanionModule")

local Commands = companionModule.Commands
local Database = companionModule.Database
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
    Database:AddPetToWorld(petGUID)
  end

  if scope == SCOPES.continent then
    local success, continentID = Utilities:GetContinentIDForMap(C_Map.GetBestMapForUnit("player"))
    Database:AddPetToContinent(petGUID, continentID)
  end

  if scope == SCOPES.zone then
    local mapId = C_Map.GetBestMapForUnit("player")
    local success, continentId = Utilities:GetContinentIDForMap(mapId)
    Database:AddPetToZone(petGUID, continentId, mapId)
  end

  if scope == SCOPES.outfit then
    local outfitId = C_TransmogOutfitInfo.GetActiveOutfitID()
    Database:AddPetToOutfit(petGUID, outfitId)
  end
end

local function remove(scope, petGUID)
  if scope == SCOPES.world then
    Database:RemovePetFromWorld(petGUID)
  end

  if scope == SCOPES.continent then
    local success, continentId = Utilities:GetContinentIDForMap(C_Map.GetBestMapForUnit("player"))
    if success then
      Database:RemovePetFromContinent(petGUID, continentId)
    end
  end

  if scope == SCOPES.zone then
    local mapId = C_Map.GetBestMapForUnit("player")
    local success, continentId = Utilities:GetContinentIDForMap(mapId)
    if success then
      Database:RemovePetFromZone(petGUID, continentId, mapId)
    end
  end

  if scope == SCOPES.outfit then
    local outfitId = C_TransmogOutfitInfo.GetActiveOutfitID()
    if outfitId then
      Database:RemovePetFromOutfit(petGUID, outfitId)
    end
  end
end

local function list(scope)
  local list = Database:GetListForContextScope(scope)
  if not list or not list.pets then
    addOn:Printf("No Pets for %s", scope)
    return
  end

  local mapInfo = Utilities:GetPlayerMapInfoForScope(scope)

  local location = mapInfo and mapInfo.name or scope

  addOn:Printf("Pets in %s", location)
  local num = 0
  for i, v in ipairs(list.order) do
    local petTable = C_PetJournal.GetPetInfoTableByPetID(v)
    addOn:Printf("[%d] %s", i, petTable.name)
  end
end

local function clear(scope)
  if scope == SCOPES.world then
    Database:ClearList(scope)
  end

  if scope == SCOPES.continent then
    local success, continentId = Utilities:GetContinentIDForMap(C_Map.GetBestMapForUnit("player"))
    if success then
      Database:ClearList(scope, continentId)
    end
  end

  if scope == SCOPES.zone then
    local mapId = C_Map.GetBestMapForUnit("player")
    local success, continentId = Utilities:GetContinentIDForMap(mapId)
    if success then
      Database:ClearList(scope, continentId, mapId)
    end
  end

  if scope == SCOPES.outfit then
    local outfitId = C_TransmogOutfitInfo.GetActiveOutfitID()
    if outfitId then
      Database:ClearList(scope, outfitId)
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
function Commands:HandleAction(action, ...)
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
