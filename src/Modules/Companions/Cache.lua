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
local Cache = mod.Cache

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
--- Cache Publid API
--------------------------------------------------------------------------------
function Cache:Init(db)
  self.db = db
  self:RegisterBucketEvent(EVENTS_TO_REGISTER, BUCKET_INTERVAL, "RefreshEffectiveList")
  self:RegisterBucketEvent("PET_JOURNAL_LIST_UPDATE", BUCKET_INTERVAL, "Refresh")

  self.db:GetCompanionNamespace().RegisterCallback(self, "OnProfileChanged", "Refresh")
  self.db:GetCompanionNamespace().RegisterCallback(self, "OnProfileCopied", "Refresh")
  self.db:GetCompanionNamespace().RegisterCallback(self, "OnProfileReset", "Refresh")

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
  local list = self.db:GetEffectivePetList()
  self.EffectivePetList = list
  self:SendMessage("GMM_EFFECTIVE_PET_LIST_UPDATED")
  return list
end

function Cache:RefreshFallbackList()
  local list = self.db:GetFallbackList()
  self.FallbackList = list
  self:SendMessage("GMM_FALLBACK_PET_LIST_UPDATED")
  return list
end
