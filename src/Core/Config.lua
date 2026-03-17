local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

addOn.Config = addOn.Config or {}
addOn.UI = addOn.UI or {}
addOn.UI.ConfigFrames = addOn.UI.ConfigFrames or {}
local Config = addOn.Config
local DB = addOn.DB
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
  addOn.UI:RegisterConfigurationFrame("GMM_Configuration", frame, frameId)

  local profileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(addOn.DB.AceDatabase)
  AceConfig:RegisterOptionsTable("GMM_Profiles", profileOptions)
  frame, frameId = AceConfigDialog:AddToBlizOptions("GMM_Profiles", "Profiles", "GMM")
  addOn.UI:RegisterConfigurationFrame("GMM_Profiles", frame, frameId)
end

function Config:GetValue(info)
  if info.arg then
    return DB.dbp[info.arg][info[#info]]
  else
    return DB.dbp[info[#info]]
  end
end

function Config:SetValue(info, value)
  if info.arg then
    DB.dbp[info.arg][info[#info]] = value
  else
    DB.dbp[info[#info]] = value
  end
end
