local addonName, _ = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")

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

function mod:InitializeAutomation()
  for _, event in ipairs(eventsToRegister) do
    if not registeredEvents[event] then
      self:RegisterEvent(event)
      registeredEvents[event] = true
    end
  end
end

function mod:PLAYER_REGEN_ENABLED()
  self:AutomationHandler();
end

function mod:PLAYER_MOUNT_DISPLAY_CHANGED()
  self:AutomationHandler()
end

function mod:ZONE_CHANGED_NEW_AREA()
  self:AutomationHandler()
end

function mod:ZONE_CHANGED()
  self:AutomationHandler()
end

function mod:PLAYER_UNGHOST()
  self:AutomationHandler()
end

function mod:PLAYER_ALIVE()
  self:AutomationHandler()
end

function mod:PLAYER_CONTROL_GAINED()
  self:AutomationHandler()
end

function mod:UNIT_EXITED_VEHICLE()
  self:AutomationHandler()
end

function mod:AutomationHandler()
  if not mod.Settings.Automation[addOn.MapInfo:GetCurrentZoneType()] then
    return
  end

  if not mod.Settings["Automation"]["forcesummon"] and C_PetJournal.GetSummonedPetGUID() then
    return
  end

  -- Triggers a timer to summon the pet after x seconds.
  if (self:IsTimerActive()) then
    return
  end
  if not HasFullControl() then
    return
  end

  local delay = mod.Settings.Automation.delay
  self.currentTimerId = self:ScheduleTimer(function()
    local petId = self:ChooseRandomCompanion()
    if petId then
      self:CallSummonCompanion(petId)
    end
  end, delay)
end

function mod:IsTimerActive()
  if self.currentTimerId ~= nil then
    local timeLeft = self:TimeLeft(self.currentTimerId)
    return timeLeft > 0
  end
  return false
end
