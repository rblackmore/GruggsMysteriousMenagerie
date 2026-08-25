local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceEvent-3.0
local TransmogMenagerie = addOn:GetModule("TransmogMenagerie")

GMM_TransmogItemMixin = {}

function GMM_TransmogItemMixin:Init() end

function GMM_TransmogItemMixin:Reset() end

function GMM_TransmogItemMixin:OnEnter() end

function GMM_TransmogItemMixin:OnLeave() end

function GMM_TransmogItemMixin:OnMouseUp() end

function GMM_TransmogItemMixin:OnMouseDown() end
