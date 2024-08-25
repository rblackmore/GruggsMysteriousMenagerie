---@diagnostic disable: duplicate-set-field
local addonName, addonTable = ...
local addOn = addonTable.addOn
local module = addOn:GetModule("CompanionModule")
-- ---@class AceModule
-- local Options = addOn:GetModule("Options")

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

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

function module:InitializeAutomation()
  for _, event in ipairs(eventsToRegister) do
    if not registeredEvents[event] then
      self:RegisterEvent(event)
      registeredEvents[event] = true
    end
  end
end

function module:PLAYER_REGEN_ENABLED()
  self:AutomationHandler();
end

function module:PLAYER_MOUNT_DISPLAY_CHANGED()
  self:AutomationHandler()
end

function module:ZONE_CHANGED_NEW_AREA()
  self:AutomationHandler()
end

function module:ZONE_CHANGED()
  self:AutomationHandler()
end

function module:PLAYER_UNGHOST()
  self:AutomationHandler()
end

function module:PLAYER_ALIVE()
  self:AutomationHandler()
end

function module:PLAYER_CONTROL_GAINED()
  self:AutomationHandler()
end

function module:UNIT_EXITED_VEHICLE()
  self:AutomationHandler()
end

function module:UNIT_SPELLCAST_SUCCEEDED(event, unit, castGUID, spellID)
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

  local ownedPets = module["OwnedPetData"]

  for k, v in pairs(ownedPets) do
    if v.name == petName then
      self:SetPetOfTheDay(v)
    end
  end
end

function module:SetPetOfTheDay(pet)
  local settings = self.Settings["Automation"]["PetOfTheDay"]
  local currentDate = date("*t")
  settings.Pet = pet
  settings.Date = {
    ["year"] = currentDate.year,
    ["month"] = currentDate.month,
    ["day"] = currentDate.day,
  }
end

function module:AutomationHandler()
  if InCombatLockdown() then
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    registeredEvents["PLAYER_REGEN_ENABLED"] = true
    return
  else
    self:UnregisterEvent("PLAYER_REGEN_ENABLED");
    registeredEvents["PLAYER_REGEN_ENABLED"] = false
  end

  if not HasFullControl() then
    return
  end

  if C_PetJournal.GetSummonedPetGUID() then -- don't summon if pet already summoned
    return
  end
  local settings = module.Settings
  self:ScheduleTimer(function()
    local zoneType = addOn:GetCurrentZoneType()
    if settings["Automation"][zoneType] then
      module:SummonCompanion(false)
    end
  end, settings["Automation"]["delay"])
end
