local addonName, _ = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")

mod.Core.Automation = mod.Core.Automation or {}

local Core = mod.Core
local Auto = mod.Core.Automation
local DB = mod.DB

LibStub("AceEvent-3.0"):Embed(Auto)
LibStub("AceTimer-3.0"):Embed(Auto)

--------------------------------------------------------------------------------
--- Local Helper Function and Tables
--------------------------------------------------------------------------------

local instanceTypes = {

  ["pvp"] = "BATTLEGROUND",
  ["arena"] = "ARENA",
  ["party"] = "DUNGEON",
  ["raid"] = "RAID",
  ["scenario"] = "SCENARIO",
  ["neighborhood"] = "NEIGHBORHOOD",
  ["none"] = "GLOBAL",
}

local function GetInstanceZoneType()
  if IsResting() then
    return "RESTING"
  end
  local _, instanceType = IsInInstance()
  return instanceType[instanceType] or "GLOBAL"
end

-- These events are when to automatically summon a companion.
local eventsToRegister = {
  "ZONE_CHANGED_NEW_AREA", --> Player changes major Zone, et, Orgrimmar -> Durotar.
  "ZONE_CHANGED",          --> Player changes minor zone, eg, Valley of Honor -> The Drag.
  "PLAYER_MOUNT_DISPLAY_CHANGED",
  "PLAYER_UNGHOST",        --> Fired After being a ghost
  "PLAYER_ALIVE",          --> Fired After being resurrected.
  "PLAYER_CONTROL_GAINED", --> After Taxi
  "UNIT_EXITED_VEHICLE",   --> After exiting vehicle.
}

local registeredEvents = {}

--------------------------------------------------------------------------------
--- Namespace API
--------------------------------------------------------------------------------

function Auto:Init()
  for _, event in ipairs(eventsToRegister) do
    if not registeredEvents[event] then
      self:RegisterEvent(event, "Handler")
      registeredEvents[event] = true
    end
  end
end

function Auto:Handler(...)
  if not DB.settingsProfile.companions.Automation[GetInstanceZoneType()] then
    return
  end

  if not DB.settingsProfile.companions.Automation.forcesummon and C_PetJournal.GetSummonedPetGUID() then
    return
  end

  if (self:IsTimerActive()) then
    return
  end

  if not HasFullControl() then
    return
  end

  local delay = DB.settingsProfile.companions.Automation.delay
  self._summonTimer = self:ScheduleTimer(function()
    local petId = Core:PickRandomPetId()
    if petId then
      Core:RequestCompanion(false)
    end
  end, delay)
end

function Auto:IsTimerActive()
  if self._summonTimer ~= nil then
    local timeLeft = self:TimeLeft(self._summonTimer)
    return timeLeft > 0
  end
  return false
end
