local addonName, addonTable = ...

local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)

L["Addon Name"] = "Gruggs Mysterious Menagerie"
-- Core Configuration
L["Open Settings When Out Of Combat"] = "Opening Settings When Out Of Combat"

-- Core Slash Command Feedback
L["Unknown Command Colon"] = "Unknown Command: "

-- Settings Category
L["S Category Main"] = "GMM"
L["S Category Companions"] = "Companions"
L["S Category Profiles"] = "Profiles"

-- Companion Settings
-- Companion Settings Category
L["CS Category Announcement"] = "Announcement"
L["CS Category Automation"] = "Automation"
L["CS Category General"] = "General"

-- Companion Settings Announcement
L["CS Message Format Name"] = "Message Format"
L["CS Message Format Description"] = "Format of the message to display, use %s in place where pet name should be shown."
L["CS Custom Name Name"] = "Custom Name"
L["CS Custom Name Description"] = "Use Custom Name if one is set, otherwise Species Name."
L["CS Channel Name"] = "Channel"
L["CS Channel Description"] = "Channel to announce companion to"

-- Companion Settings General
L["CS Enable Pet of the Day Name"] = "Pet of the Day"
L["CS Enable Pet of the Day Description"] = "Summons the same companion resetting daily"
L["CS Fallback To Favorites Name"] = "Fallback to Favorites"
L["CS Fallback To Favorites Description"] = "Use Favorites as fallback instead of all pets"

-- Companion Settings Automation
-- Companion Settings Automation Locations
L["CS Cities Name"] = "Cities"
L["CS Cities Description"] = "Summon when Resting"
L["CS Global Name"] = "Global"
L["CS Global Description"] = "Summon in World"
L["CS Dungeons Name"] = "Dungeons"
L["CS Dungeons Description"] = "Summon in Dungeons"
L["CS Raids Name"] = "Raids"
L["CS Raids Description"] = "Summon in Raids"
L["CS Battlegrounds Name"] = "Battlegrounds"
L["CS BattleGrounds Description"] = "Summon in Battlegrounds"
L["CS Arenas Name"] = "Arenas"
L["CS Arenas Description"] = "Summon in Arenas"
L["CS Scenarios Name"] = "Scenarios"
L["CS Scenarios Description"] = "Summon in Scenarios"

-- Companion Settings Automation Other
L["CS Delay Name"] = "Delay (Seconds)"
L["CS Delay Description"] = "Short delay after automatic summon trigger"
L["CS Force Summon Name"] = "Force Summon"
L["CS Force Summon Description"] = "Summon even if a pet is already summoned"

-- Transmog Wardrobe
L["TW Companions Header"] = "Companions"
L["TW Ground Mounts Header"] = "Gound Mounts (Coming Soon)"
L["TW Flying Mounts Header"] = "Flying Mounts (Coming Soon)"
