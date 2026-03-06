local addonName, _ = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")
---@class AceAddon: AceEvent-3.0, AceTimer-3.0
local Auto = mod:NewModule("CompanionAutomation", "AceEvent-3.0", "AceTimer-3.0")

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

function Auto:OnInitialize()
  for _, event in ipairs(eventsToRegister) do
    if not registeredEvents[event] then
      self:RegisterEvent(event, "AutomationHandler")
      registeredEvents[event] = true
    end
  end
end

function Auto:AutomationHandler(...)
  if not mod.SettingsNS.profile.companions.Automation[addOn.MapInfo:GetCurrentZoneType()] then
    return
  end

  if not mod.SettingsNS.profile.companions.Automation.forcesummon and C_PetJournal.GetSummonedPetGUID() then
    return
  end

  -- Triggers a timer to summon the pet after x seconds.
  if (self:IsTimerActive()) then
    return
  end

  if not HasFullControl() then
    return
  end

  local delay = mod.SettingsNS.profile.companions.Automation.delay
  self._summonTimer = self:ScheduleTimer(function()
    local petId = mod:PickRandomPetId()
    if petId then
      mod:RequestCompanion(petId)
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
