local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

addOn.Config = addOn.Config or {}
addOn.UI = addOn.UI or {}
addOn.UI.ConfigFrames = addOn.UI.ConfigFrames or {}
addOn.SlashCmd = addOn.SlashCmd or {}
local Config = addOn.Config
local SlashCmd = addOn.SlashCmd
--------------------------------------------------------------------------------
--- Local Helper Functions
--------------------------------------------------------------------------------
local function BuildOptionsTable()
  return {
    name = "Gruggs Mysterious Menagerie",
    type = "group",
    handler = Config,
    args = {
      desc = {
        name = "Gruggs Mysterious Menagerie",
        type = "description",
        fontSize = "large"

      }
    }
  }
end
--------------------------------------------------------------------------------
--- Options Module API
--------------------------------------------------------------------------------

function Config:Init()
  local options = BuildOptionsTable()
  AceConfig:RegisterOptionsTable("GMM_Configuration", options)
  local frame, frameId = AceConfigDialog:AddToBlizOptions("GMM_Configuration", "GMM")
  addOn.UI.ConfigFrames["GMM_Configuration"] = { frame = frame, frameId = frameId }

  local profileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(addOn.db)
  AceConfig:RegisterOptionsTable("GMM_Profiles", profileOptions)
  frame, frameId = AceConfigDialog:AddToBlizOptions("GMM_Profiles", "Profiles", "GMM")
  addOn.UI.ConfigFrames["GMM_Profiles"] = { frame = frame, frameId = frameId }

  addOn:RegisterChatCommand("gmm", function(...)
    SlashCmd:OpenConfig(...)
  end)
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

function Config:GetValue(info)
  if info.arg then
    return addOn.dbp[info.arg][info[#info]]
  else
    return addOn.dbp[info[#info]]
  end
end

function Config:SetValue(info, value)
  if info.arg then
    addOn.dbp[info.arg][info[#info]] = value
  else
    addOn.dbp[info[#info]] = value
  end
end
