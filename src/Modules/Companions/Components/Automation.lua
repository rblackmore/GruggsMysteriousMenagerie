local addonName, _ = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local CompanionModule = addOn:GetModule("CompanionModule")
---@class AceAddon: AceConsole-3.0, AceEvent-3.0
local MapInfo = addOn:GetModule("GMM_MapInfo")

local eventsToRegister = {
  "ZONE_CHANGED_NEW_AREA",    --> Player changes major Zone, et, Orgrimmar -> Durotar.
  "ZONE_CHANGED",             --> Player changes minor zone, eg, Valley of Honor -> The Drag.
  "UNIT_SPELLCAST_SUCCEEDED", --> For Capturting manual summoning of a Pet, used to replace pet of the day.
  "PLAYER_MOUNT_DISPLAY_CHANGED",
  "PLAYER_UNGHOST",           --> Fired After being a ghost
  "PLAYER_ALIVE",             --> Fired After being resurrected.
  "PLAYER_CONTROL_GAINED",    --> After Taxi
  "UNIT_EXITED_VEHICLE",      --> After exiting vehicle.
}

local registeredEvents = {}

function CompanionModule:InitializeAutomation()
  for _, event in ipairs(eventsToRegister) do
    if not registeredEvents[event] then
      self:RegisterEvent(event)
      registeredEvents[event] = true
    end
  end
end

function CompanionModule:PLAYER_REGEN_ENABLED()
  self:AutomationHandler();
end

function CompanionModule:PLAYER_MOUNT_DISPLAY_CHANGED()
  self:AutomationHandler()
end

function CompanionModule:ZONE_CHANGED_NEW_AREA()
  self:AutomationHandler()
end

function CompanionModule:ZONE_CHANGED()
  self:AutomationHandler()
end

function CompanionModule:PLAYER_UNGHOST()
  self:AutomationHandler()
end

function CompanionModule:PLAYER_ALIVE()
  self:AutomationHandler()
end

function CompanionModule:PLAYER_CONTROL_GAINED()
  self:AutomationHandler()
end

function CompanionModule:UNIT_EXITED_VEHICLE()
  self:AutomationHandler()
end

function CompanionModule:UNIT_SPELLCAST_SUCCEEDED(event, unit, castGUID, spellID)
  --[[
    TODO: Possible Ideas:
    Perhaps on load, I make a list of all pets, including their names, C_Spell.GetSpellInfo(spellID) will give me the name of the pet.
    I can then check the list ofr this name if it existes, then it was a pet that was summoned.
      I should also check the GUID, that it's type is '3' which usually indicates a spell cast by player
  ]]
  local settings = self.Settings["Automation"]["PetOfTheDay"]
  if not settings.Enabled or unit ~= "player" or string.sub(castGUID, 6, 6) ~= "3" then
    return
  end

  local info = C_Spell.GetSpellInfo(spellID)
  local petName = info.name

  local ownedPets = mod["OwnedPetData"]

  for k, v in pairs(ownedPets) do
    if v.name == petName then
      self:SetPetOfTheDay(v)
    end
  end
end

function CompanionModule:SetPetOfTheDay(pet)
  local settings = self.Settings["Automation"]["PetOfTheDay"]
  local currentDate = date("*t")
  settings.Pet = pet
  settings.Date = {
    ["year"] = currentDate.year,
    ["month"] = currentDate.month,
    ["day"] = currentDate.day,
  }
end

local currentTimerId = nil;

function CompanionModule:AutomationHandler()
  if (self:IsTimerActive()) then
    return
  end
  if InCombatLockdown() then
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    registeredEvents["PLAYER_REGEN_ENABLED"] = true
    return
  else
    self:UnregisterEvent("PLAYER_REGEN_ENABLED");
    registeredEvents["PLAYER_REGEN_ENABLED"] = false
  end

  if not HasFullControl() or C_PetJournal.GetSummonedPetGUID() then
    return
  end

  local settings = CompanionModule.Settings

  currentTimerId = self:ScheduleTimer(function()
    local zoneType = MapInfo:GetCurrentZoneType()
    if settings["Automation"][zoneType] then
      CompanionModule:SummonCompanion(false)
    end
  end, settings["Automation"]["delay"])
end

function CompanionModule:IsTimerActive()
  if currentTimerId ~= nil then
    local timeLeft = self:TimeLeft(currentTimerId)
    return timeLeft > 0
  end
  return false
end
