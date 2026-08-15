local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0, GMM_Addon
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)

local SlashCmd = addOn.SlashCmd
local Config = addOn.Config
local Modules = addOn.Modules

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

function SlashCmd:HandleConfig(...)
  Config:OpenConfig({ ... })
end

function SlashCmd:HandleSummon(...)
  local companionModule = Modules["Pet"]()
  local dismiss = select(1, ...) and select(1, ...):lower()
  if companionModule and dismiss == "dismiss" then
    companionModule.API:SummonOrDismissRandomPet(true)
  else
    companionModule.API:SummonRandomPet(true)
  end
end

function SlashCmd:HandleSetPetOfTheDay(...)
  local companionModule = Modules["Pet"]()
  if companionModule then
    companionModule.API:SetActivePetAsPetOfTheDay()
  end
end

function SlashCmd:HandleModule(moduleName, action, ...)
  local moduleGetter = Modules[moduleName]

  if not moduleGetter or type(moduleGetter) ~= "function" then
    self:Print("Unknown Module: " .. moduleName)
    return
  end

  local module = moduleGetter()

  if not action then
    self:Printf("Usage: /gmm %s <action> [items]", moduleName)
    return
  end

  if module.API and module.API.HandleAction then
    module.API:HandleAction(action, ...)
  else
    self:Printf("%s module does not support actions", moduleName)
  end
end

local COMMANDS = {
  ["config"] = SlashCmd.HandleConfig,
  ["c"] = SlashCmd.HandleConfig,
  ["summon"] = SlashCmd.HandleSummon,
  ["s"] = SlashCmd.HandleSummon,
  ["setpod"] = SlashCmd.HandleSetPetOfTheDay,
  ["pet"] = function(self, action, ...) self:HandleModule("Pet", action, ...) end,
  ["mount"] = function(self, action, ...) self:HandleModule("Mount", action, ...) end,
}

-- Main Command Handler for everyting /gmm
function SlashCmd:HandleCommand(input)
  local args = GetArgTable(input)

  local root = args[1] and args[1]:lower() or "config"

  local command = COMMANDS[root]
  if command then
    command(self, select(2, unpack(args)))
  else
    self:Print("Unknown Command: " .. root)
  end
end
