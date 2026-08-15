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

  mod:RegisterMessage("GMM_COMPANION_SUMMONED", function(...) API:OnSummoned(...) end)
end

--------------------------------------------------------------------------------
--- Module API
--------------------------------------------------------------------------------

function API:AnnounceSummon(petId)
  local petInfo = C_PetJournal.GetPetInfoTableByPetID(petId)
  local settings = self.db:GetCompanionSettings()
  local name = settings["UseCustomName"] and petInfo.customName or petInfo.name
  local msgFormat = settings["MessageFormat"] or "Welcome %s!"
  local channelTarget = settings["Channel"] or "SAY"
  C_ChatInfo.SendChatMessage(format(msgFormat, name), channelTarget)
end

function API:OnSummoned(_, petId, userInitiated)
  if userInitiated then
    self:AnnounceSummon(petId)
  end
end

function API:HandleAction(action, items)
  -- items = { everything users passed after action }
  -- Could be: { "zone", "[item:123]", "[item:456]"}
  -- or: {"[item:123]", "[item:456]"}
  -- or: {"zone"} -- scope without items means action of list or clear.

  local scope, itemsToProcess = self:ExtractScope(items);
end

function API:ExtractScope(items)
  -- Returns <scope or global>, <items or {}>.
  -- Steps:
  -- 1. Check if items[1] is scope or items
  -- 2. Get Scope from Map or just use Global.
  -- 3. Determine if remaining args are Items.
  -- 4. Return scope + Items or {}
end

function API:Add(scope, key1, key2, petGUIDs, weight)
  self.db:AddPetsToScope(scope, key1, key2, petGUIDs, weight)
end

function API:Remove() end

function API:Clear() end

function API:List() end
