local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0, GMM_Companion
local companionModule = addOn:GetModule("CompanionModule")

local Automation = companionModule.Automation
local Summoning = companionModule.Summoning
local Settings = companionModule.Settings

local MapUtils = addonTable.MapUtils
local Enums = addonTable.Enums
local CombatLockdownUtils = addonTable.CombatLockdownUtils

LibStub("AceEvent-3.0"):Embed(Automation)
LibStub("AceTimer-3.0"):Embed(Automation)

--------------------------------------------------------------------------------
--- Local Constants and Functions
--------------------------------------------------------------------------------

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

local function announceSummon(petId)
  local petInfo = C_PetJournal.GetPetInfoTableByPetID(petId)
  local settings = Settings:GetCompanionSettings()
  local name = settings["UseCustomName"] and petInfo.customName or petInfo.name
  local msgFormat = settings["MessageFormat"] or "Welcome %s!"
  local channelTarget = settings["Channel"] or "SAY"
  C_ChatInfo.SendChatMessage(format(msgFormat, name), channelTarget)
end

local function onSummoned(_, petId, userInitiated)
  if userInitiated then
    announceSummon(petId)
  end
end

--------------------------------------------------------------------------------
--- Namespace API
--------------------------------------------------------------------------------

function Automation:Init()
  for _, event in ipairs(EVENTS_TO_REGISTER) do
    if not REGISTERED_EVENTS[event] then
      self:RegisterEvent(event, "Handler")
      REGISTERED_EVENTS[event] = true
    end
  end

  Automation:RegisterMessage("GMM_COMPANION_SUMMONED", onSummoned)
end

function Automation:Handler(...)
  local automationSettings = Settings:GetAutomationSettings()
  if not automationSettings[MapUtils.GetInstanceZoneType()] then
    return
  end

  if not automationSettings.forcesummon and C_PetJournal.GetSummonedPetGUID() then
    return
  end

  if (self:IsTimerActive()) then
    return
  end

  if not HasFullControl() then
    return
  end

  local delay = automationSettings.delay
  self._summonTimer = self:ScheduleTimer(function()
    Summoning:SummonRandomPet(false)
  end, delay)
end

function Automation:IsTimerActive()
  if self._summonTimer ~= nil then
    local timeLeft = self:TimeLeft(self._summonTimer)
    return timeLeft > 0
  end
  return false
end
