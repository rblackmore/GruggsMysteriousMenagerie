---@diagnostic disable: duplicate-set-field
local addonName, addonTable = ...
local addOn = addonTable.addOn
local module = addOn:GetModule("CompanionModule")
-- ---@class AceModule
-- local Options = addOn:GetModule("Options")

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local eventsToRegister = {
  -- "PET_JOURNAL_LIST_UPDATE",
  "ZONE_CHANGED_NEW_AREA", --> Player changes major Zone, et, Orgrimmar -> Durotar
  -- "ZONE_CHANGED",                --> Player changes minor zone, eg, Valley of Honor -> The Drag
  -- "UNIT_SPELLCAST_SUCCEEDED",
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

function module:ZONE_CHANGED_NEW_AREA()
  self:AutomationHandler()
end

function module:ZONE_CHANGED()
end

function module:UNIT_SPELLCAST_SUCCEEDED(unit, castGUID, spellID)
  --[[
    TODO: Possible Ideas:
    Perhaps on load, I make a list of all pets, including their names, C_Spell.GetSpellInfo(spellID) will give me the name of the pet.
    I can then check the list ofr this name if it existes, then it was a pet that was summoned.
      I should also check the GUID, that it's type is '3' which usually indicates a spell cast by player
  ]]
end

function module:AutomationHandler()
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
