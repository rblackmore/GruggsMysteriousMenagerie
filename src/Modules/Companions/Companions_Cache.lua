--------------------------------------------------------------------------------
--- Companions Cache
--- Handles caching of current effectivecompanion data and refreshing it on relevant events.
--------------------------------------------------------------------------------

local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0, GMM_Companion
local companionsModule = addOn:GetModule("CompanionModule")

local Data = addOn.Data
local Cache = companionsModule.Cache
local Database = companionsModule.Database

LibStub("AceTimer-3.0"):Embed(Cache)
LibStub("AceBucket-3.0"):Embed(Cache)
LibStub("AceEvent-3.0"):Embed(Cache)

--- Local Constants
local BUCKET_INTERVAL = 0.5

local EVENTS_TO_REGISTER = {
  "PLAYER_ENTERING_WORLD",
  "ZONE_CHANGED",
  "ZONE_CHANGED_INDOORS",
  "ZONE_CHANGED_NEW_AREA",
  "NEW_WMO_CHUNK",
  "TRANSMOG_COLLECTION_UPDATED"
}
--------------------------------------------------------------------------------
--- Cache Local State
--------------------------------------------------------------------------------

local effectivePetListCache = nil
local fallbackPetList = nil

--------------------------------------------------------------------------------
--- Cache Public API
--------------------------------------------------------------------------------
function Cache:Init()
  self:RegisterBucketEvent(EVENTS_TO_REGISTER, BUCKET_INTERVAL, "RefreshEffectiveList")
  self:RegisterBucketEvent("PET_JOURNAL_LIST_UPDATE", BUCKET_INTERVAL, "RefreshEffectiveList")

  Data.Companions.RegisterCallback(self, "OnProfileChanged", "RefreshEffectiveList")
  Data.Companions.RegisterCallback(self, "OnProfileCopied", "RefreshEffectiveList")
  Data.Companions.RegisterCallback(self, "OnProfileReset", "RefreshEffectiveList")

  self:RegisterMessage("GMM_CONFIG_USEFAVORITES_CHANGED", "RefreshFallback")

  self:RefreshEffectiveList()
end

function Cache:RefreshEffectiveList()
  local list = Database:GetCurrentContextPetList()
  effectivePetListCache = list

  if not effectivePetListCache and not fallbackPetList then
    fallbackPetList = Database:BuildFallbackList()
  end

  self:SendMessage("GMM_EFFECTIVE_PET_LIST_UPDATED")
  return effectivePetListCache or fallbackPetList
end

function Cache:RefreshFallback()
  fallbackPetList = Database:BuildFallbackList()
end

function Cache:GetEffectivePetList()
  return effectivePetListCache or fallbackPetList or Cache:RefreshEffectiveList()
end
