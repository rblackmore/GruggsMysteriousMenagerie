local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0, GMM_Addon
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

---@class GMM_Data
local Data = addOn.Data
local Config = addOn.Config
local UI = addOn.UI

local CombatLockdownUtils = addonTable.CombatLockdownUtils


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

local Categories = {
  companions = "Companions",
  companion = "Companions",
  comp = "Companions",
  profile = "Profiles",
  profiles = "Profiles",
  prof = "Profiles"
}

--------------------------------------------------------------------------------
--- Config Module API
--------------------------------------------------------------------------------

function Config:Init()
  local options = BuildOptionsTable()
  AceConfig:RegisterOptionsTable("GMM_Configuration", options)
  local frame, frameId = AceConfigDialog:AddToBlizOptions("GMM_Configuration", "GMM")
  UI:RegisterConfigurationFrame("GMM_Configuration", frame, frameId)

  local profileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(Data.AceDatabase)
  AceConfig:RegisterOptionsTable("GMM_Profiles", profileOptions)
  frame, frameId = AceConfigDialog:AddToBlizOptions("GMM_Profiles", "Profiles", "GMM")
  UI:RegisterConfigurationFrame("GMM_Profiles", frame, frameId)
end

function Config:GetValue(info)
  if info.arg then
    return Data.profile[info.arg][info[#info]]
  else
    return Data.profile[info[#info]]
  end
end

function Config:SetValue(info, value)
  if info.arg then
    Data.profile[info.arg][info[#info]] = value
  else
    Data.profile[info[#info]] = value
  end
end

function Config:OpenConfig(args)
  CombatLockdownUtils.Dispatch(function()
    local categorySelect = Categories[args[1]]

    if categorySelect and addOn.UI.ConfigFrames["GMM_" .. categorySelect] then
      addOn:Printf("Catergory Selected: %s", categorySelect)
      Settings.OpenToCategory(addOn.UI.ConfigFrames["GMM_" .. categorySelect]["frameId"])
    else
      addOn:Printf("Opening Configuraiton Default")
      Settings.OpenToCategory(addOn.UI.ConfigFrames["GMM_Configuration"]["frameId"])
    end
  end, "Opening Settings when out of Combat")
end
