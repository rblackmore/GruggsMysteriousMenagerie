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
  "PET_JOURNAL_LIST_UPDATE",
  "TRANSMOG_COLLECTION_UPDATED"
}

function Cache:Init()
  self:RegisterBucketEvent(eventsToRegister, BUCKET_INTERVAL, "Refresh")

  DB.CompanionsNS.RegisterCallback(self, "OnProfileChanged", "Refresh")
  DB.CompanionsNS.RegisterCallback(self, "OnProfileCopied", "Refresh")
  DB.CompanionsNS.RegisterCallback(self, "OnProfileReset", "Refresh")

  self:Refresh()
end

function Cache:Refresh(...)
  self.EffectivePetList = DB:GetEffectivePetList()
  self:SendMessage("GMM_EFFECTIVE_PET_LIST_UPDATED")
  return self.EffectivePetList
end

function Cache:GetEffectivePetList()
  return self.EffectivePetList or self:Refresh()
end
