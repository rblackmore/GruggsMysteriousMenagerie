local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)

addOn.UI = addOn.UI or {}
local UI = addOn.UI

function UI:Init()
end

function UI:RegisterConfigurationFrame(frameName, frame, frameId)
  self.ConfigFrames = self.ConfigFrames or {}
  self.ConfigFrames[frameName] = { frame = frame, frameId = frameId }
end