local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
local companionModule = addOn:GetModule("Companions")


addOn.SlashCmd = addOn.SlashCmd or {}
local SlashCmd = addOn.SlashCmd
local Enums = addonTable.Enums

LibStub("AceConsole-3.0"):Embed(SlashCmd)

--------------------------------------------------------------------------------
--- Local Functions and Constants
--------------------------------------------------------------------------------

-- Possible List Action Verbs.
local listVerbs = {
  add = true,
  remove = true,
  clear = true,
  list = true,
}

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

local function GetArgTable(input)
  local args = {}
  local pos = 1
  local arg = nil

  repeat
    arg, pos = SlashCmd:GetArgs(input, 1, pos)
    if arg then
      table.insert(args, arg)
    end
  until pos == 1e9

  return args
end

local function GetScopeContext(scope)
  if not scope then
    return nil
  end

  scope = scope:lower()

  local result = scopeMap[scope]
  if not result then
    addOn:Printf("Unknown List Identifier %s", scope)
  end
  return result
end

local Modules = {
  CompanionModule = "Companions",
  MountModule = "Mounts",
}
local function SelectModuleName(itemLInk)
  if LinkUtil.IsLinkType(itemLInk, LinkTypes.BattlePet) then
    return Modules.CompanionModule
  elseif LinkUtil.IsLinkType(itemLInk, LinkTypes.MountEquipment) then
    -- TODO: Doesn't seem to be a mount Type, probably uses 'Spell', Investigate
  end
end

--------------------------------------------------------------------------------
--- Slash Command API
--------------------------------------------------------------------------------

function SlashCmd:Init()
  self:RegisterChatCommand("gmm", "HandleCommand")
  self:RegisterChatCommand("test", "Test")
end

function SlashCmd:OpenConfig(args)
  if InCombatLockdown() then
    addOn:Print("Opening Settings when out of Combat")
    addOn:RegisterEvent("PLAYER_REGEN_ENABLED", function(...)
      addOn:UnregisterEvent("PLAYER_REGEN_ENABLED")
      self:OpenConfig(args)
    end)
    return
  else
    local categorySelect = args[1]

    if categorySelect and (categorySelect == "comp" or categorySelect == "companions") then
      categorySelect = "Companions"
    elseif categorySelect and (categorySelect == "profile" or categorySelect == "profiles") then
      categorySelect = "Profiles"
    elseif categorySelect then
      addOn:Printf("Unknown Settings category '%s'", categorySelect)
    end

    if categorySelect and addOn.UI.ConfigFrames["GMM_" .. categorySelect] then
      Settings.OpenToCategory(addOn.UI.ConfigFrames["GMM_" .. categorySelect]["frameId"])
    else
      Settings.OpenToCategory(addOn.UI.ConfigFrames["GMM_Configuration"]["frameId"])
    end
  end
end

function SlashCmd:HandleCommand(input)
  local args = GetArgTable(input)

  local action = args[1] and args[1]:lower()

  if action == "config" then
    table.remove(args, 1)
    self:OpenConfig(args)
    return
  end

  if action == "summon" then
    if companionModule then
      companionModule.Commands:Summon(args[2])
    end
    return
  end

  if listVerbs[action] then
    table.remove(args, 1)
    self:HandleListAction(action, args)
    return
  end

  if not action or string.len(action) == 0 then
    self:OpenConfig("comp")
    return
  end

  addOn:Printf("Unknown Command Argument '%s'", action)
end

function SlashCmd:HandleListAction(action, args)
  addOn:Print("Handling List Action")
  --[[
    action = add, remove, list, clear

    Update (7-8-2026) -- No longer allowing scope in command, will default to global.
    args shoud be the following
    { <list-identity>, <item-link> }
    <list-identity> = global, continent, zone, outfit, g, c, z, o
    <item-link> = link pet or mount (possibly array)

    Step 1: Identify Link type, Pet or Mount, confirm all links in array are same type.
    Step 2: Get Appropriate Module
    Step 3: Extract ID(s) from hyperlinks. (perhaps these get sent to the Command and it extracts these instead.)
    Step #: Call Appropriate Command (Add, Remove, Clear, List)
  ]] --

  local itemLinks = args
  table.remove(itemLinks, 1) -- remove Verb Argument.
  local module = SelectModuleName(itemLinks[1])
  if (module == Modules.CompanionModule) then
    if action == "add" then
      -- TODO: Create petGUID list form item links
      companionModule.DB:AddPetToGlobal(itemLinks[1])
    elseif action == "remove" then
    elseif action == "clear" then
    elseif action == "list" then
    end
  end
end

-- local link = self:GetArgs(input)
-- if not link then
--   addOn:Print("No Arguments for Test")
-- end
-- local type, options, displayText = LinkUtil.ExtractLink(link)
-- addOn:Print("type: ", type)
-- addOn:Print("options: ", options)
-- addOn:Print("displayText: ", displayText)
