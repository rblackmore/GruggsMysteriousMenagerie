---@diagnostic disable: duplicate-set-field
local addonName, addonTable = ...
local addOn = addonTable.addOn

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

function addOn:InitializeProfiles()
  local profileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

  AceConfig:RegisterOptionsTable("GMM_Profiles", profileOptions)
  local frame, id =
      AceConfigDialog:AddToBlizOptions("GMM_Profiles", "Profiles",
        addOn["GMMOptionsFrame"]["Id"])

  addOn["ProfileOptionsFrame"] =
  {
    ["Frame"] = frame,
    ["Id"] = id,
  }
end
