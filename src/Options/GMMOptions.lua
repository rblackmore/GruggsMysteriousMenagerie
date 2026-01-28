local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceConsole-3.0, AceEvent-3.0
local Options = addOn:GetModule("Options")
---@class AceAddon: AceTimer-3.0
local CompanionModule = addOn:GetModule("CompanionModule")

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local function getOptionsTable()
  return {
    name = "Gruggs Mysterious Menagerie",
    type = "group",
    handler = Options,
    args = {
      desc = {
        name = "Gruggs Mysterious Menagerie",
        type = "description",
        fontSize = "large"

      }
    }
  }
end
-------------------------------------------------------------------------------
--- Public API

function Options:GetValue(info)
  if info.arg then
    return addOn:GetProfileDB()[info.arg][info[#info]]
  else
    return addOn:GetProfileDB()[info[#info]]
  end
end

function Options:SetValue(info, value)
  if info.arg then
    addOn:GetProfileDB()[info.arg][info[#info]] = value
  else
    addOn:GetProfileDB()[info[#info]] = value
  end
end

function Options:InitializeOptions()
  local gmmOptions = getOptionsTable()
  local companionOptions = CompanionModule:GetOptionsTable()
  local profileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(addOn.db)

  AceConfig:RegisterOptionsTable("GMM_Options", gmmOptions)
  AceConfig:RegisterOptionsTable("GMM_Profiles", profileOptions)
  AceConfig:RegisterOptionsTable("GMM_Companions", companionOptions)

  Options["OptionsFrame"] =
      AceConfigDialog:AddToBlizOptions("GMM_Options", "GMM")

  Options["CompanionOptionsFrame"] =
      AceConfigDialog:AddToBlizOptions("GMM_Companions", "Companions", "GMM")

  Options["ProfileOptionsFrame"] =
      AceConfigDialog:AddToBlizOptions("GMM_Profiles", "Profiles", "GMM")
end
