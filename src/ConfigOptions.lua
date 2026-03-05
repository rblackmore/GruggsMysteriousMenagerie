local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceConsole-3.0, AceEvent-3.0
local Config = addOn:NewModule("Configuration")

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

--------------------------------------------------------------------------------
--- Local Helper Functions
--------------------------------------------------------------------------------
local function BuildOptionsTable()
  return {
    name = "Gruggs Mysterious Menagerie",
    type = "group",
    handler = Config,
    args = {
      desc = {
        name = "Gruggs Mysterious Menagerie",
        type = "description",
        fontSize = "large"

      }
    }
  }
end
--------------------------------------------------------------------------------
--- Options Module API
--------------------------------------------------------------------------------

function Config:OnInitialize()
  local options = BuildOptionsTable()
  AceConfig:RegisterOptionsTable("GMM_Configuration", options)
  local frame, frameId = AceConfigDialog:AddToBlizOptions("GMM_Configuration", "GMM")
  self.ConfigFrames = self.ConfigFrames or {}
  self.ConfigFrames["GMM_Configuration"] = { frame = frame, frameId = frameId }

  local profileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(addOn.db)
  AceConfig:RegisterOptionsTable("GMM_Profiles", profileOptions)
  frame, frameId = AceConfigDialog:AddToBlizOptions("GMM_Profiles", "Profiles", "GMM")
  self.ConfigFrames["GMM_Profiles"] = { frame = frame, frameId = frameId }


  self:RegisterChatCommand("gmm", "OpenConfigCommand")
end

function Config:OpenConfigCommand(...)
  if InCombatLockdown() then
    self:Printf("Opening Settings when out of Combat")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", function(...)
      self:UnregisterEvent("PLAYER_REGEN_ENABLED")
      self:OpenConfigCommand(...)
    end)
    return
  else
    local categorySelect = select(1, ...)

    if categorySelect and categorySelect == "comp" or categorySelect == "companions" then
      categorySelect = "Companions"
    elseif categorySelect and categorySelect == "profile" or categorySelect == "profiles" then
      categorySelect = "Profiles"
    elseif categorySelect then
      addOn:Printf("Category %s not found, opening general settings", categorySelect)
    end

    if categorySelect and self.ConfigFrames["GMM_" .. categorySelect] then
      Settings.OpenToCategory(self.ConfigFrames["GMM_" .. categorySelect]["frameId"])
    else
      Settings.OpenToCategory(self.ConfigFrames["GMM_Configuration"]["frameId"])
    end
  end
end

function Config:GetValue(info)
  if info.arg then
    return addOn.dbp[info.arg][info[#info]]
  else
    return addOn.dbp[info[#info]]
  end
end

function Config:SetValue(info, value)
  if info.arg then
    addOn.dbp[info.arg][info[#info]] = value
  else
    addOn.dbp[info[#info]] = value
  end
end

-- function Config:InitializeOptions()
--   local gmmOptions = getOptionsTable()
--   local companionOptions = CompanionModule:GetOptionsTable()
--   local profileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(addOn.db)

--   AceConfig:RegisterOptionsTable("GMM_Options", gmmOptions, slashCommands)
--   AceConfig:RegisterOptionsTable("GMM_Profiles", profileOptions)
--   AceConfig:RegisterOptionsTable("GMM_Companions", companionOptions)

--   Config["ConfigFrames"] = {}
--   local config = Config["ConfigFrames"];
--   config["GMM_Options"] = {}
--   config["GMM_Profiles"] = {}
--   config["GMM_Companions"] = {}

--   local frame, id = AceConfigDialog:AddToBlizOptions("GMM_Options", "GMM")
--   config["GMM_Options"]["Frame"] = frame
--   config["GMM_Options"]["Id"] = id

--   frame, id = AceConfigDialog:AddToBlizOptions("GMM_Profiles", "Profiles", "GMM")
--   config["GMM_Profiles"]["Frame"] = frame
--   config["GMM_Profiles"]["Id"] = id

--   frame, id = AceConfigDialog:AddToBlizOptions("GMM_Companions", "Companions", "GMM")
--   config["GMM_Companions"]["Frame"] = frame
--   config["GMM_Companions"]["Id"] = id
-- end
