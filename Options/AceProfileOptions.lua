---@diagnostic disable: duplicate-set-field
local addonName, addonTable = ...
local addOn = addonTable.addOn

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

function addOn:InitializeOptions()
  self.db = LibStub("AceDB-3.0"):New("PetSummonerDB", Options:GetDefaultDatabase(), true)
  self:ConfigureGlobalOptions()
  self:ConfigureOptionsProfiles()
end

function addOn:ConfigureGlobalOptions()
  AceConfig:RegisterOptionsTable("PetSummoner", self:GetOptionsTable(), "psconfig")
  local configFrame, configId = AceConfigDialog:AddToBlizOptions("PetSummoner", "Pet Summoner")

  self["OptionsFrame"] =
  {
    ["Frame"] = configFrame,
    ["Id"] = configId
  }
end

function addOn:ConfigureOptionsProfiles()
  local profileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

  AceConfig:RegisterOptionsTable("PetSummoner_Profiles", profileOptions, "psprofile")
  local profileFrame, profileId =
      AceConfigDialog:AddToBlizOptions("PetSummoner_Profiles", "Profiles", Options.GlobalSettingsDialog["Id"])

  self.ProfileSettingsDialog =
  {
    ["Frame"] = profileFrame,
    ["Id"] = profileId,
  }
end

-- function addOn:GetValue(info)
--   if info.arg then
--     return self.db.profile[info.arg][info[#info]]
--   else
--     return self.db.profile[info[#info]]
--   end
-- end

-- function addOn:GetValue(info, value)
--   if info.arg then
--     self.db.profile[info.arg][info[#info]] = value
--   else
--     self.db.profile[info[#info]] = value
--   end
-- end
