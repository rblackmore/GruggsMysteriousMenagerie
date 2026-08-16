local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")

local Config = mod.Config
local Data = addOn.Data
local UI = addOn.UI
local API = mod.API

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

--------------------------------------------------------------------------------
--- Local Helper Functions
--------------------------------------------------------------------------------
local function BuildOptionsTable()
  local announcementOptions = {
    ["MessageFormat"] = {
      type = "input",
      name = "Message Format",
      desc = "Format of the message to display, use %s in place where pet name should be shown.",
      usage = "<Your message>",
      get = "GetValue",
      set = "SetValue",
    },
    ["UseCustomName"] = {
      type = "toggle",
      name = "Custom Name",
      desc = "Use Custom Name if one is set, otherwise Species Name.",
      get = "GetValue",
      set = "SetValue",
    },
    ["Channel"] = {
      type = "select",
      name = "Channel",
      desc = "The Channel to Announce your Summon to",
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
      name = "Pet of the Day",
      desc = "Saves the first pet summoned for the day, and summons only that one for the rest of the day.",
      get = function(info) return Data.Settings.profile.companions["Automation"]["petoftheday"].Enabled end,
      set = function(info, value) Data.Settings.profile.companions["Automation"]["petoftheday"].Enabled = value end,
    },
    ["UseFavoritesFallback"] = {
      type = "toggle",
      name = "Use Favorites as Fallback",
      desc = "Use only favorite pets as the fallback pool",
      get = function(info) return Data.Settings.profile.companions["UseFavoritesFallback"] end,
      set = function(info, value) Data.Settings.profile.companions["UseFavoritesFallback"] = value end,
    }
  }

  local automationOptions = {
    ["RESTING"] = {
      order = 1,
      type = "toggle",
      name = "Cities",
      desc = "Auto Summon In Cities (Resting)",
      get = function(info) return Data.Settings.profile.companions["Automation"]["RESTING"] end,
      set = function(info, value) Data.Settings.profile.companions["Automation"]["RESTING"] = value end
    },
    ["GLOBAL"] = {
      order = 2,
      type = "toggle",
      name = "Global",
      desc = "Auto Summon In the Open World",
      get = function(info) return Data.Settings.profile.companions["Automation"]["GLOBAL"] end,
      set = function(info, value) Data.Settings.profile.companions["Automation"]["GLOBAL"] = value end
    },
    ["DUNGEON"] = {
      order = 3,
      type = "toggle",
      name = "Dungeon",
      desc = "Auto Summon In Dungeons",
      get = function(info) return Data.Settings.profile.companions["Automation"]["DUNGEON"] end,
      set = function(info, value) Data.Settings.profile.companions["Automation"]["DUNGEON"] = value end
    },
    ["RAID"] = {
      order = 4,
      type = "toggle",
      name = "Raid",
      desc = "Auto Summon In the Raids",
      get = function(info) return Data.Settings.profile.companions["Automation"]["RAID"] end,
      set = function(info, value) Data.Settings.profile.companions["Automation"]["RAID"] = value end
    },
    ["BATTLEGROUND"] = {
      order = 5,
      type = "toggle",
      name = "Battleground",
      desc = "Auto Summon In Battlegrounds",
      get = function(info) return Data.Settings.profile.companions["Automation"]["BATTLEGROUND"] end,
      set = function(info, value) Data.Settings.profile.companions["Automation"]["BATTLEGROUND"] = value end
    },
    ["ARENA"] = {
      order = 6,
      type = "toggle",
      name = "Arena",
      desc = "Auto Summon In Arenas",
      get = function(info) return Data.Settings.profile.companions["Automation"]["ARENA"] end,
      set = function(info, value) Data.Settings.profile.companions["Automation"]["ARENA"] = value end
    },
    ["SCENARIO"] = {
      order = 7,
      type = "toggle",
      name = "Scenario",
      desc = "Auto Summon In the Scenarios",
      get = function(info) return Data.Settings.profile.companions["Automation"]["SCENARIO"] end,
      set = function(info, value) Data.Settings.profile.companions["Automation"]["SCENARIO"] = value end
    },
    ["Delay"] = {
      order = 10,
      type = "range",
      name = "Delay (Seconds)",
      desc = "Summon pet automatically after a short delay",
      min = 2,
      max = 20,
      step = 1,
      get = function(info) return Data.Settings.profile.companions["Automation"]["delay"] end,
      set = function(info, value) Data.Settings.profile.companions["Automation"]["delay"] = value end,
    },
    ["ForceSummon"] = {
      order = 11,
      type = "toggle",
      name = "Force Summon",
      desc = "Force Summon even if a pet is already summoned",
      get = function(info) return Data.Settings.profile.companions["Automation"]["forcesummon"] end,
      set = function(info, value) Data.Settings.profile.companions["Automation"]["forcesummon"] = value end
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
        name = "Announcement",
        type = "group",
        args = announcementOptions
      },
      companionAutomationGroup = {
        order = 2,
        inline = true,
        name = "Automation",
        type = "group",
        args = automationOptions
      },
      companionManagementGroup = {
        order = 3,
        inline = true,
        name = "Configuration",
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
  local frame, frameId = AceConfigDialog:AddToBlizOptions("GMM_Companions", "Companions", "GMM")
  UI:RegisterConfigurationFrame("GMM_Companions", frame, frameId)
end

--------------------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------------------
function Config:GetValue(info)
  if info.arg then
    return Data.Settings.profile.companions[info.arg][info[#info]]
  else
    return Data.Settings.profile.companions[info[#info]]
  end
end

function Config:SetValue(info, value)
  if info.arg then
    Data.Settings.profile.companions[info.arg][info[#info]] = value
  else
    Data.Settings.profile.companions[info[#info]] = value
  end
end
