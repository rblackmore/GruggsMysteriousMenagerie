local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")

local Commands = mod.Commands
local Enums = addonTable.Enums
local Maps = addonTable.Maps

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

function Commands:Init(db, core)
  self.db = db
  self.core = core
  -- TODO: Remove these chat commands in a later update.
  mod:RegisterChatCommand("gmsummon", function(...)
    mod:Printf("/gmsummon command is deprecated and will be removed in a future update, use '/gmm summon' instead")
    Commands:Summon(...)
  end)
  mod:RegisterChatCommand("gmmsummon", function(...)
    mod:Printf("/gmmsummon command is deprecated and will be removed in a future update, use '/gmm summon' instead")
    Commands:Summon(...)
  end)

  mod:RegisterMessage("GMM_COMPANION_SUMMONED", function(...) Commands:OnSummoned(...) end)
end

--------------------------------------------------------------------------------
--- Module API
--------------------------------------------------------------------------------

function Commands:Summon(...)
  local arg1 = select(1, ...) and select(1, ...):lower()

  if arg1 and arg1 == "setpod" or arg1 == "pod" then
    self.core:SetActivePetAsPetOfTheDay()
    return
  end

  if arg1 and arg1 == "dismiss" then
    self.core:SummonOrDismissRandomCompanion(true)
  else
    self.core:RequestCompanion(true)
  end
end

function Commands:AnnounceSummon(petId)
  local petInfo = C_PetJournal.GetPetInfoTableByPetID(petId)
  local settings = self.db:GetCompanionSettings()
  local name = settings["UseCustomName"] and petInfo.customName or petInfo.name
  local msgFormat = settings["MessageFormat"] or "Welcome %s!"
  local channelTarget = settings["Channel"] or "SAY"
  C_ChatInfo.SendChatMessage(format(msgFormat, name), channelTarget)
end

function Commands:OnSummoned(_, petId, userInitiated)
  if userInitiated then
    self:AnnounceSummon(petId)
  end
end

function Commands:HandleAction(action, items)
  -- items = { everything users passed after action }
  -- Could be: { "zone", "[item:123]", "[item:456]"}
  -- or: {"[item:123]", "[item:456]"}
  -- or: {"zone"} -- scope without items means action of list or clear.

  local scope, itemsToProcess = self:ExtractScope(items);
end

function Commands:ExtractScope(items)
  -- Returns <scope or global>, <items or {}>.
  -- Steps:
  -- 1. Check if items[1] is scope or items
  -- 2. Get Scope from Map or just use Global.
  -- 3. Determine if remaining args are Items.
  -- 4. Return scope + Items or {}
end

function Commands:Add(scope, key1, key2, petGUIDs, weight)
  self.db:AddPetsToScope(scope, key1, key2, petGUIDs, weight)
end

function Commands:Remove() end

function Commands:Clear() end

function Commands:List() end
