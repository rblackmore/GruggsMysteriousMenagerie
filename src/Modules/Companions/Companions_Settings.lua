local addonName, _ = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0, GMM_Companion
local companionModule = addOn:GetModule("CompanionModule")

local Settings = companionModule.Settings
local Data = addOn.Data

--------------------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------------------

function Settings:Init()
  -- Initialize Companion Settings Namespace on database.
  -- Pull from Database.lua in Core, and separate out the settings part that is strictly Companion Related.
end

function Settings:GetCompanionSettings()
  return Data.Settings.profile.companions
end

function Settings:GetAutomationSettings()
  return Data.Settings.profile.companions.Automation
end

function Settings:GetPetOfTheDaySettings()
  return Data.Settings.profile.companions.Automation.petoftheday
end

function Settings:SetPetOfTheDay(petID)
  local podsettings = Settings:GetPetOfTheDaySettings()
  podsettings.petID = petID
  podsettings.Date = date("*t")
end

function Settings:SetActivePetAsPetOfTheDay()
  local currentPetGUID = C_PetJournal.GetSummonedPetGUID()
  if not currentPetGUID then return end
  Settings:SetPetOfTheDay(currentPetGUID)
end

function Settings:GetPetOfTheDay()
  local podsettings = Settings:GetPetOfTheDaySettings();
  local today = date("*t")
  local summonedOn = podsettings.Date

  if not summonedOn or summonedOn.day ~= today.day or summonedOn.month ~= today.month or summonedOn.year ~= today.year then
    return false, podsettings.PetId
  end

  return true, podsettings.PetId
end

function Settings:ClearPetOfTheDay()
  local podsettings = Settings:GetPetOfTheDaySettings()
  podsettings.PetId = nil
  podsettings.Date = nil
end

function Settings:IsPetOfTheDayEnabled()
  return Settings:GetPetOfTheDaySettings().Enabled
end
