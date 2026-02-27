local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceConsole-3.0, AceEvent-3.0
local WardrobeModule = addOn:GetModule("GMM_WardrobeModule")

GMM_MenagerieSlot = {
  Companions = 0,
  FlyingMounts = 1,
  GroundMounts = 2
}

function WardrobeModule:GetMenagerieSlotInfo()
  -- Returns an Array of Group slot infor like https://warcraft.wiki.gg/wiki/API_C_TransmogOutfitInfo.GetSlotGroupInfo
  local menagerieSlots = {}
  table.insert(menagerieSlots, {
    slot = GMM_MenagerieSlot.Companions,
    slotName = "Companions",
    icon = "category-icons_pets_active"
  })
  table.insert(menagerieSlots, {
    slot = GMM_MenagerieSlot.FlyingMounts,
    slotName = "Flying Mounts",
    icon = "shop-icon-mount-flying-selected"
  })
  table.insert(menagerieSlots, {
    slot = GMM_MenagerieSlot.GroundMounts,
    slotName = "Ground Mounts",
    icon = "category-icons_mounts_active"
  })
  return menagerieSlots
end
