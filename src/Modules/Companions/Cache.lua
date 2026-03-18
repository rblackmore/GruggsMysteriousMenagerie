--------------------------------------------------------------------------------
--- Companions Cache
--- Handles caching of current effectivecompanion data and refreshing it on relevant events.
--------------------------------------------------------------------------------

local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")

mod.Cache = mod.Cache or {}
local DB = mod.DB
local Cache = mod.Cache

LibStub("AceTimer-3.0"):Embed(Cache)
LibStub("AceBucket-3.0"):Embed(Cache)
LibStub("AceEvent-3.0"):Embed(Cache)

local BUCKET_INTERVAL = 0.5

local eventsToRegister = {
  "PLAYER_ENTERING_WORLD",
  "ZONE_CHANGED",
  "ZONE_CHANGED_INDOORS",
  "ZONE_CHANGED_NEW_AREA",
  "NEW_WMO_CHUNK",
  "TRANSMOG_COLLECTION_UPDATED"
}

function Cache:Init()
  self:RegisterBucketEvent(eventsToRegister, BUCKET_INTERVAL, "RefreshEffectiveList")
  self:RegisterBucketEvent("PET_JOURNAL_LIST_UPDATE", BUCKET_INTERVAL, "Refresh")

  DB.CompanionsNS.RegisterCallback(self, "OnProfileChanged", "Refresh")
  DB.CompanionsNS.RegisterCallback(self, "OnProfileCopied", "Refresh")
  DB.CompanionsNS.RegisterCallback(self, "OnProfileReset", "Refresh")

  self:Refresh()
end

function Cache:Refresh(...)
  self:RefreshFallbackList()
  self:RefreshEffectiveList()
end

function Cache:GetEffectivePetList()
  return self.EffectivePetList or self:RefreshEffectiveList()
end

function Cache:GetFallbackList()
  return self.FallbackList or self:RefreshFallbackList()
end

function Cache:RefreshEffectiveList()
  local list = DB:GetEffectivePetList()
  self.EffectivePetList = list
  self:SendMessage("GMM_EFFECTIVE_PET_LIST_UPDATED")
  return list
end

function Cache:RefreshFallbackList()
  local useFavorites =
      DB.settingsProfile and
      DB.settingsProfile.companions and
      DB.settingsProfile.companions.UseFavoritesFallback

  local list = { pets = {}, order = {}, total = 0 }
  local petGUIDs = C_PetJournal.GetOwnedPetIDs()

  for i = 1, #petGUIDs do
    local speciesID, _, _, _, _, _, isFavorite = C_PetJournal.GetPetInfoByPetID(petGUIDs[i])
    if speciesID then
      if not useFavorites or isFavorite then
        DB:AddPet(list, petGUIDs[i])
      end
    end
  end

  self.FallbackList = list
  self:SendMessage("GMM_FALLBACK_PET_LIST_UPDATED")
  return list
end
