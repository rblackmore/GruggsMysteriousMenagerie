---@diagnostic disable: duplicate-set-field
local addonName, addonTable = ...
local addOn = addonTable.addOn

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local gmmOptions = {
  name = "Gruggs Mysterious Menagerie",
  type = "group",
  args = {
    desc = {
      name = "Gruggs Mysterious Menagerie",
      type = "description",
      fontSize = "large"

    }
  }
}
function addOn:InitializeOptions()
  AceConfig:RegisterOptionsTable("GMM_Options", gmmOptions)
  local frame, id = AceConfigDialog:AddToBlizOptions("GMM_Options", "GMM")
  addOn["GMMOptionsFrame"] = {
    ["Frame"] = frame,
    ["Id"] = id,
  }
end
