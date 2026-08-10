local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)


addOn.SlashCmd = addOn.SlashCmd or {}
local SlashCmd = addOn.SlashCmd
local Enums = addonTable.Enums

LibStub("AceConsole-3.0"):Embed(SlashCmd)

--------------------------------------------------------------------------------
--- Local Functions and Constants
--------------------------------------------------------------------------------

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

  local moduleName = args[1] and args[1]:lower()
  local action = args[2] and args[2]:lower()
  local scope = args[3] and args[3]:lower()

  if moduleName == "config" then
    table.remove(args, 1)
    self:OpenConfig(args)
    return
  end

  if moduleName == "summon" then
    local companionModule = addOn:GetModule("Companions")
    if companionModule then
      companionModule.Commands:Summon(args[2])
    end
    return
  end

  local module = addOn.Modules[moduleName]

  if not module then
    self:Print("Unknown Module: " .. SelectModuleName)
    -- TODO: Show Help
    return
  end

  if not action then
    self:Printf("Usage: /gmm %s <action> [items]", moduleName)
    -- TODO: Show Help
    return
  end

  if module.Commands.HandleAction then
    local items = { select(3, unpack(args)) }
    module.Commands:HandleAction(action, items)
  else
    self:Printf("%s module does not support actions", moduleName)
  end

  -- Default to opening Configuration.
  if not action or string.len(action) == 0 then
    self:OpenConfig("comp")
    return
  end

  addOn:Printf("Unknown Command Argument '%s'", action)
end
