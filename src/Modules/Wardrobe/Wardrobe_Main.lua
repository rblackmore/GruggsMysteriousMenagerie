local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceEvent-3.0
local wardrobeModule = addOn:NewModule("WardrobeModule");

function wardrobeModule:OnInitialize()
  self:RegisterEvent("ADDON_LOADED", "OnAddonLoaded")
end

function wardrobeModule:OnAddonLoaded(event, addon)
  if addon == "Blizzard_Transmog" then
    self:SetupFrame()
  end
end

function wardrobeModule:SetupFrame()
  local tabOwner = TransmogFrame.WardrobeCollection
  local gmm_transmogFrame = CreateFrame("Frame", nil, tabOwner.TabContent, "GMM_WardrobeFrame")
  gmm_transmogFrame:ClearAllPoints()
  gmm_transmogFrame:SetAllPoints(tabOwner.TabContent)
  gmm_transmogFrame:SetFrameStrata(tabOwner.TabContent:GetFrameStrata())
  gmm_transmogFrame:SetFrameLevel(tabOwner.TabContent:GetFrameLevel() + 1)
  gmm_transmogFrame.tabOwner = tabOwner
  gmm_transmogFrame.tabID = tabOwner:AddNamedTab("Menagerie", gmm_transmogFrame)
  self:UnregisterEvent("ADDON_LOADED")
  self.wardrobeFrame = gmm_transmogFrame
end
