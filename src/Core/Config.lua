local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

addOn.Config = addOn.Config or {}
addOn.UI = addOn.UI or {}
addOn.UI.ConfigFrames = addOn.UI.ConfigFrames or {}
local Config = addOn.Config
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
