local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local companionModule = addOn:GetModule("CompanionModule")

local L = addonTable.L

local Config = companionModule.Config
local Settings = companionModule.Settings
local UI = addOn.UI

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

--------------------------------------------------------------------------------
--- Local Helper Functions
--------------------------------------------------------------------------------
local function BuildOptionsTable()
  local announcementOptions = {
    ["MessageFormat"] = {
      type = "input",
      name = L["CS Message Format Name"],
      desc = L["CS Message Format Description"],
      usage = "<Your message>",
      get = "GetValue",
      set = "SetValue",
    },
    ["UseCustomName"] = {
      type = "toggle",
      name = L["CS Custom Name Name"],
      desc = L["CS Custom Name Description"],
      get = "GetValue",
      set = "SetValue",
    },
    ["Channel"] = {
      type = "select",
      name = L["CS Channel Name"],
      desc = L["CS Channel Description"],
      values = {
        ["SAY"] = "SAY",
        ["EMOTE"] = "EMOTE",
        ["YELL"] = "YELL",
        ["PARTY"] = "PARTY",
        ["RAID"] = "RAID",
        ["INSTANCE_CHAT"] = "INSTANCE_CHAT",
        ["GUILD"] = "GUILD",
      },
      get = "GetValue",
      set = "SetValue",
    }
  }

  local companionOptions = {
    ["EnablePetOfTheDay"] = {
      type = "toggle",
      name = L["CS Enable Pet of the Day Name"],
      desc = L["CS Enable Pet of the Day Description"],
      get = function(info) return Settings:GetCompanionSettings()["Automation"]["petoftheday"].Enabled end,
      set = function(info, value) Settings:GetCompanionSettings()["Automation"]["petoftheday"].Enabled = value end,
    },
    ["UseFavoritesFallback"] = {
      type = "toggle",
      name = L["CS Fallback To Favorites Name"],
      desc = L["CS Fallback To Favorites Description"],
      get = function(info) return Settings:GetCompanionSettings()["UseFavoritesFallback"] end,
      set = function(info, value)
        Settings:GetCompanionSettings()["UseFavoritesFallback"] = value
        companionModule:SendMessage("GMM_CONFIG_USEFAVORITES_CHANGED")
      end,
    }
  }

  local automationOptions = {
    ["RESTING"] = {
      order = 1,
      type = "toggle",
      name = L["CS Cities Name"],
      desc = L["CS Cities Description"],
      get = function(info) return Settings:GetCompanionSettings()["Automation"]["RESTING"] end,
      set = function(info, value) Settings:GetCompanionSettings()["Automation"]["RESTING"] = value end
    },
    ["GLOBAL"] = {
      order = 2,
      type = "toggle",
      name = L["CS Global Name"],
      desc = L["CS Global Description"],
      get = function(info) return Settings:GetCompanionSettings()["Automation"]["GLOBAL"] end,
      set = function(info, value) Settings:GetCompanionSettings()["Automation"]["GLOBAL"] = value end
    },
    ["DUNGEON"] = {
      order = 3,
      type = "toggle",
      name = L["CS Dungeons Name"],
      desc = L["CS Dungeons Description"],
      get = function(info) return Settings:GetCompanionSettings()["Automation"]["DUNGEON"] end,
      set = function(info, value) Settings:GetCompanionSettings()["Automation"]["DUNGEON"] = value end
    },
    ["RAID"] = {
      order = 4,
      type = "toggle",
      name = L["CS Raids Name"],
      desc = L["CS Raids Description"],
      get = function(info) return Settings:GetCompanionSettings()["Automation"]["RAID"] end,
      set = function(info, value) Settings:GetCompanionSettings()["Automation"]["RAID"] = value end
    },
    ["BATTLEGROUND"] = {
      order = 5,
      type = "toggle",
      name = L["CS Battlegrounds Name"],
      desc = L["CS BattleGrounds Description"],
      get = function(info) return Settings:GetCompanionSettings()["Automation"]["BATTLEGROUND"] end,
      set = function(info, value) Settings:GetCompanionSettings()["Automation"]["BATTLEGROUND"] = value end
    },
    ["ARENA"] = {
      order = 6,
      type = "toggle",
      name = L["CS Arenas Name"],
      desc = L["CS Arenas Description"],
      get = function(info) return Settings:GetCompanionSettings()["Automation"]["ARENA"] end,
      set = function(info, value) Settings:GetCompanionSettings()["Automation"]["ARENA"] = value end
    },
    ["SCENARIO"] = {
      order = 7,
      type = "toggle",
      name = L["CS Scenarios Name"],
      desc = L["CS Scenarios Description"],
      get = function(info) return Settings:GetCompanionSettings()["Automation"]["SCENARIO"] end,
      set = function(info, value) Settings:GetCompanionSettings()["Automation"]["SCENARIO"] = value end
    },
    ["Delay"] = {
      order = 10,
      type = "range",
      name = L["CS Delay Name"],
      desc = L["CS Delay Description"],
      min = 2,
      max = 20,
      step = 1,
      get = function(info) return Settings:GetCompanionSettings()["Automation"]["delay"] end,
      set = function(info, value) Settings:GetCompanionSettings()["Automation"]["delay"] = value end,
    },
    ["ForceSummon"] = {
      order = 11,
      type = "toggle",
      name = L["CS Force Summon Name"],
      desc = L["CS Force Summon Description"],
      get = function(info) return Settings:GetCompanionSettings()["Automation"]["forcesummon"] end,
      set = function(info, value) Settings:GetCompanionSettings()["Automation"]["forcesummon"] = value end
    }
  }

  local options = {
    name = "Companions",
    type = "group",
    handler = Config,
    args =
    {
      announcementGroup = {
        order = 1,
        inline = true,
        name = L["CS Category Announcement"],
        type = "group",
        args = announcementOptions
      },
      companionAutomationGroup = {
        order = 2,
        inline = true,
        name = L["CS Category Automation"],
        type = "group",
        args = automationOptions
      },
      companionManagementGroup = {
        order = 3,
        inline = true,
        name = L["CS Category General"],
        type = "group",
        args = companionOptions
      },
    }
  }
  return options
end

--------------------------------------------------------------------------------
--- Lifecycle Methods
--------------------------------------------------------------------------------
function Config:Init()
  local options = BuildOptionsTable()
  AceConfig:RegisterOptionsTable("GMM_Companions", options)
  local frame, frameId =
      AceConfigDialog:AddToBlizOptions("GMM_Companions", L["S Category Companions"], L["S Category Main"])
  UI:RegisterConfigurationFrame("GMM_Companions", frame, frameId)
end

--------------------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------------------
function Config:GetValue(info)
  if info.arg then
    return Settings:GetCompanionSettings()[info.arg][info[#info]]
  else
    return Settings:GetCompanionSettings()[info[#info]]
  end
end

function Config:SetValue(info, value)
  if info.arg then
    Settings:GetCompanionSettings()[info.arg][info[#info]] = value
  else
    Settings:GetCompanionSettings()[info[#info]] = value
  end
end
