local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local CompanionModule = addOn:GetModule("CompanionModule")

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
  ["RefreshFavoritesList"] = {
    type = "execute",
    name = "Refresh",
    desc = "Refreshes Favorite Pets and Owned Pets in database. Alternatively, you can reload ui with /reload instead.",
    handler = CompanionModule,
    func = function()
      CompanionModule:RefreshFavorites()
      CompanionModule:RefreshOwnedPetData()
    end
  },
  ["EnablePetOfTheDay"] = {
    type = "toggle",
    name = "Enabled Pet of the Day",
    desc = "Saves the first pet summoned for the day, and summons only that one for the rest of the day.",
    handler = CompanionModule,
    get = function(info) return CompanionModule.Settings["Automation"]["PetOfTheDay"].Enabled end,
    set = function(info, value) CompanionModule.Settings["Automation"]["PetOfTheDay"].Enabled = value end,
  }
}

local automationOptions = {
  ["GLOBAL"] = {
    order = 2,
    type = "toggle",
    name = "Global",
    desc = "Auto Summon In the Open World",
    get = function(info) return CompanionModule.Settings["Automation"]["GLOBAL"] end,
    set = function(info, value) CompanionModule.Settings["Automation"]["GLOBAL"] = value end
  },
  ["SCENARIO"] = {
    order = 7,
    type = "toggle",
    name = "Scenario",
    desc = "Auto Summon In the Scenarios",
    get = function(info) return CompanionModule.Settings["Automation"]["SCENARIO"] end,
    set = function(info, value) CompanionModule.Settings["Automation"]["SCENARIO"] = value end
  },
  ["RAID"] = {
    order = 4,
    type = "toggle",
    name = "Raid",
    desc = "Auto Summon In the Raids",
    get = function(info) return CompanionModule.Settings["Automation"]["RAID"] end,
    set = function(info, value) CompanionModule.Settings["Automation"]["RAID"] = value end
  },
  ["DUNGEON"] = {
    order = 3,
    type = "toggle",
    name = "Dungeon",
    desc = "Auto Summon In Dungeons",
    get = function(info) return CompanionModule.Settings["Automation"]["DUNGEON"] end,
    set = function(info, value) CompanionModule.Settings["Automation"]["DUNGEON"] = value end
  },
  ["ARENA"] = {
    order = 6,
    type = "toggle",
    name = "Arena",
    desc = "Auto Summon In Arenas",
    get = function(info) return CompanionModule.Settings["Automation"]["ARENA"] end,
    set = function(info, value) CompanionModule.Settings["Automation"]["ARENA"] = value end
  },
  ["BATTLEGROUND"] = {
    order = 5,
    type = "toggle",
    name = "Battleground",
    desc = "Auto Summon In Battlegrounds",
    get = function(info) return CompanionModule.Settings["Automation"]["BATTLEGROUND"] end,
    set = function(info, value) CompanionModule.Settings["Automation"]["BATTLEGROUND"] = value end
  },
  ["RESTING"] = {
    order = 1,
    type = "toggle",
    name = "Cities",
    desc = "Auto Summon In Cities (Resting)",
    get = function(info) return CompanionModule.Settings["Automation"]["RESTING"] end,
    set = function(info, value) CompanionModule.Settings["Automation"]["RESTING"] = value end
  },
  ["Delay"] = {
    order = 10,
    type = "range",
    name = "Delay",
    desc = "Summon pet automatically after a short delay (seconds)",
    min = 2,
    max = 20,
    step = 1,
    get = function(info) return CompanionModule["Settings"]["Automation"]["delay"] end,
    set = function(info, value) CompanionModule["Settings"]["Automation"]["delay"] = value end,
  }
}

local options = {
  name = "Companions",
  type = "group",
  handler = CompanionModule,
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
      name = "Companions",
      type = "group",
      args = companionOptions
    },
  }
}

-------------------------------------------------------------------------------
--- Public API

function CompanionModule:GetValue(info)
  if info.arg then
    return CompanionModule.Settings[info.arg][info[#info]]
  else
    return CompanionModule.Settings[info[#info]]
  end
end

function CompanionModule:SetValue(info, value)
  if info.arg then
    CompanionModule.Settings[info.arg][info[#info]] = value
  else
    CompanionModule.Settings[info[#info]] = value
  end
end

function CompanionModule:GetOptionsTable()
  return options
end
