local addonName, _ = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")

mod.Core.Automation = mod.Core.Automation or {}

local Auto = mod.Core.Automation

LibStub("AceEvent-3.0"):Embed(Auto)
LibStub("AceTimer-3.0"):Embed(Auto)

--------------------------------------------------------------------------------
--- Local Constants and Functions
--------------------------------------------------------------------------------

local INSTANCE_TYPES = {

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
  return INSTANCE_TYPES[instanceType] or "GLOBAL"
end

-- These events are when to automatically summon a companion.
local EVENTS_TO_REGISTER = {
  "ZONE_CHANGED_NEW_AREA", --> Player changes major Zone, et, Orgrimmar -> Durotar.
  "ZONE_CHANGED",          --> Player changes minor zone, eg, Valley of Honor -> The Drag.
  "PLAYER_MOUNT_DISPLAY_CHANGED",
  "PLAYER_UNGHOST",        --> Fired After being a ghost
  "PLAYER_ALIVE",          --> Fired After being resurrected.
  "PLAYER_CONTROL_GAINED", --> After Taxi
  "UNIT_EXITED_VEHICLE",   --> After exiting vehicle.
}

local REGISTERED_EVENTS = {}

--------------------------------------------------------------------------------
--- Namespace API
--------------------------------------------------------------------------------

function Auto:Init(core)
  self.core = core
  for _, event in ipairs(EVENTS_TO_REGISTER) do
    if not REGISTERED_EVENTS[event] then
      self:RegisterEvent(event, "Handler")
      REGISTERED_EVENTS[event] = true
    end
  end
end

function Auto:Handler(...)
  local settings = self.core.db:GetCompanionSettings()
  if not settings.Automation[GetInstanceZoneType()] then
    return
  end

  if not settings.Automation.forcesummon and C_PetJournal.GetSummonedPetGUID() then
    return
  end

  if (self:IsTimerActive()) then
    return
  end

  if not HasFullControl() then
    return
  end

  local delay = settings.Automation.delay
  self._summonTimer = self:ScheduleTimer(function()
    self.core:RequestCompanion(false)
  end, delay)
end

function Auto:IsTimerActive()
  if self._summonTimer ~= nil then
    local timeLeft = self:TimeLeft(self._summonTimer)
    return timeLeft > 0
  end
  return false
end
