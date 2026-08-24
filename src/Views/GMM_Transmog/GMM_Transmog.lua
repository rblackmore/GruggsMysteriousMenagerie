local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)

local GMM_TransmogMenagerieMixin = {}

local GMM_TransmogMenagerie = CreateFrame("Frame", nil, nil, "GMM_TransmogMenagerieTemplate")
