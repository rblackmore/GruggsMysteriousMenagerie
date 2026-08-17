local addonName, _ = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")

local API = mod.API
local Data = addOn.Data

--------------------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------------------

function API:GetCompanionSettings()
  return Data.Settings.profile.companions
end

function API:GetAutomationSettings()
  return Data.Settings.profile.companions.Automation
end

function API:GetPetOfTheDaySettings()
  return Data.Settings.profile.companions.Automation.petoftheday
end

function API:SetPetOfTheDay(petID)
  local podsettings = API:GetPetOfTheDaySettings()
  podsettings.petID = petID
  podsettings.Date = date("*t")
end

function API:SetActivePetAsPetOfTheDay()
  local currentPetGUID = C_PetJournal.GetSummonedPetGUID()
  if not currentPetGUID then return end
  API:SetPetOfTheDay(currentPetGUID)
end

function API:GetPetOfTheDay()
  local podsettings = API:GetPetOfTheDaySettings();
  local today = date("*t")
  local summonedOn = podsettings.Date

  if not summonedOn or summonedOn.day ~= today.day or summonedOn.month ~= today.month or summonedOn.year ~= today.year then
    return false, podsettings.PetId
  end

  return true, podsettings.PetId
end

function API:ClearPetOfTheDay()
  local podsettings = API:GetPetOfTheDaySettings()
  podsettings.PetId = nil
  podsettings.Date = nil
end

function API:IsPetOfTheDayEnabled()
  return API:GetPetOfTheDaySettings().Enabled
end
