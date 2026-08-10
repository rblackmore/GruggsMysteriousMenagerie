local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)


addOn.SlashCmd = addOn.SlashCmd or {}
local SlashCmd = addOn.SlashCmd
local Config = addOn.Config

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

--------------------------------------------------------------------------------
--- Slash Command API
--------------------------------------------------------------------------------

function SlashCmd:Init()
  self:RegisterChatCommand("gmm", "HandleCommand")
  self:RegisterChatCommand("test", "Test")
end

-- Main Command Handler for everyting /gmm
function SlashCmd:HandleCommand(input)
  local args = GetArgTable(input)

  local moduleName = args[1] and args[1]:lower()
  local action = args[2] and args[2]:lower()

  if moduleName == "config" then
    Config:OpenConfig({ select(2, args) })
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
    self:Print("Unknown Module: " .. moduleName)
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
    Config:OpenConfig("comp")
    return
  end

  addOn:Printf("Unknown Command Argument '%s'", action)
end
