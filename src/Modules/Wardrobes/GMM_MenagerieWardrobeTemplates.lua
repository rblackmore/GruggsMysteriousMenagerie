local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceConsole-3.0, AceEvent-3.0
local WardrobeModule = addOn:GetModule("GMM_WardrobeModule")

GMM_MenagerieElementModelMixin = {}

function GMM_MenagerieElementModelMixin:Init(elementData)

end

function GMM_MenagerieElementModelMixin:OnEnter() end

function GMM_MenagerieElementModelMixin:OnLeave() end

function GMM_MenagerieElementModelMixin:OnMouseUp() end

function GMM_MenagerieElementModelMixin:OnMouseDown() end
