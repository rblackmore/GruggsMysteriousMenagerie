--------------------------------------------------------------------------------
--- Companions Cache
--- Handles caching of current effectivecompanion data and refreshing it on relevant events.
--------------------------------------------------------------------------------

local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")

local Cache = mod.Cache
local Data = addOn.Data
local API = mod.API

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
  self:RegisterBucketEvent("PET_JOURNAL_LIST_UPDATE", BUCKET_INTERVAL, "Refresh")

  Data.Companions.RegisterCallback(self, "OnProfileChanged", "Refresh")
  Data.Companions.RegisterCallback(self, "OnProfileCopied", "Refresh")
  Data.Companions.RegisterCallback(self, "OnProfileReset", "Refresh")

  self:Refresh()
end

function Cache:Refresh(...)
  self:RefreshEffectiveList()
end

function Cache:GetEffectivePetList()
  return effectivePetListCache or self:RefreshEffectiveList()
end

function Cache:RefreshEffectiveList()
  local list = API:GetCurrentContextPetList()

  effectivePetListCache = list
  self:SendMessage("GMM_EFFECTIVE_PET_LIST_UPDATED")
  return list
end

function API:GetEffectivePetList()
  return Cache:GetEffectivePetList()
end
