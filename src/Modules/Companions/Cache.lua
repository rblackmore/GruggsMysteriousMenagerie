--------------------------------------------------------------------------------
--- Companions Cache
--- Handles caching of current effectivecompanion data and refreshing it on relevant events.
--------------------------------------------------------------------------------

local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")
---@class AceAddon: AceEvent-3.0, AceBucket-3.0, AceTimer-3.0
local Cache = mod:NewModule("CompanionCache", "AceEvent-3.0", "AceBucket-3.0", "AceTimer-3.0")

mod.DB = mod.DB or {}
local DB = mod.DB

local DEBOUNCE_SECONDS = 0.15
local PET_BUCKET_SEC = 0.5

function Cache:OnInitialize()
  self._refreshTimer = nil
end

function Cache:OnEnable()
  self:RegisterEvent("PLAYER_ENTERING_WORLD", "RequestRefresh")
  self:RegisterEvent("ZONE_CHANGED", "RequestRefresh")
  self:RegisterEvent("ZONE_CHANGED_INDOORS", "RequestRefresh")
  self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "RequestRefresh")
  self:RegisterEvent("NEW_WMO_CHUNK", "RequestRefresh") -- wtf is this event?

  self:RegisterBucketEvent("PET_JOURNAL_LIST_UPDATE", PET_BUCKET_SEC, "BucketRefresh")

  DB.CompanionsNS.RegisterCallback(self, "OnProfileChanged", "RequestRefresh")
  DB.CompanionsNS.RegisterCallback(self, "OnProfileCopied", "RequestRefresh")
  DB.CompanionsNS.RegisterCallback(self, "OnProfileReset", "RequestRefresh")

  self:RegisterEvent("TRANSMOG_COLLECTION_UPDATED", "RequestRefresh")
  self:RequestRefresh()
end

function Cache:OnDisable()
  if self._refreshTimer then
    self:CancelTimer(self._refreshTimer)
    self._refreshTimer = nil
  end
end

function Cache:BucketRefresh()
  self:RequestRefresh()
end

function Cache:RequestRefresh()
  if self._refreshTimer then
    self:CancelTimer(self._refreshTimer)
  end
  self._refreshTimer = self:ScheduleTimer(function()
    self._refreshTimer = nil
    self:DoRefresh()
  end, DEBOUNCE_SECONDS)
end

function Cache:DoRefresh()
  mod.DB:RefreshEffectivePetList()
  self:SendMessage("GMM_EFFECTIVE_PET_LIST_UPDATED")
end
