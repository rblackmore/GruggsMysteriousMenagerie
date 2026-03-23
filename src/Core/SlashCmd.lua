local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)


addOn.SlashCmd = addOn.SlashCmd or {}
local SlashCmd = addOn.SlashCmd

LibStub("AceConsole-3.0"):Embed(SlashCmd)

function SlashCmd:Init()
  self:RegisterChatCommand("gmm", "HandleCommand")
end

function SlashCmd:OpenConfig(...)
  if InCombatLockdown() then
    addOn:Print("Opening Settings when out of Combat")
    addOn:RegisterEvent("PLAYER_REGEN_ENABLED", function(...)
      addOn:UnregisterEvent("PLAYER_REGEN_ENABLED")
      self:OpenConfig(...)
    end)
    return
  else
    local categorySelect = select(1, ...)

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
  local args = strsplittable(" ", input)

  local command = args[1] and args[1]:lower()

  if command == "config" then
    self:OpenConfig(args[2])
    return
  end

  if command == "summon" then
    local companionModule = addOn:GetModule("CompanionModule", true)
    if companionModule then
      companionModule.Commands:Summon(args[2])
    end
    return
  end

  if not command or string.len(command) == 0 then
    self:OpenConfig("comp")
    return
  end

  addOn:Printf("Unknown Command Argument '%s'", command)
end
