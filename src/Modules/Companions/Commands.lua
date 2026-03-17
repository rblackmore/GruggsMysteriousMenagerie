local addonName, _ = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")

mod.Commands = mod.Commands or {}

local Commands = mod.Commands
local Core = mod.Core
local DB = mod.DB

function Commands:Init()
  mod:RegisterChatCommand("gmsummon", function(...) Commands:Summon(...) end)
  mod:RegisterChatCommand("gmmsummon", function(...) Commands:Summon(...) end)
  mod:RegisterMessage("GMM_COMPANION_SUMMONED", function(...) Commands:OnSummoned(...) end)
end

function Commands:Summon(...)
  local arg1 = select(1, ...)

  if arg1 and arg1:lower() == "setpod" or arg1:lower() == "pod" then
    DB:SetActivePetAsPetOfTheDay()
    return
  end

  if arg1 and arg1:lower() == "dismiss" then
    Core:SummonOrDismissRandomCompanion(true)
  else
    Core:RequestCompanion(true)
  end
end

function Commands:AnnounceSummon(petId)
  local petInfo = C_PetJournal.GetPetInfoTableByPetID(petId)
  local name = DB.settingsProfile.companions["UseCustomName"] and petInfo.customName or petInfo.name
  local msgFormat = DB.settingsProfile.companions["MessageFormat"] or "Welcome %s!"
  local channelTarget = DB.settingsProfile.companions["Channel"] or "SAY"
  C_ChatInfo.SendChatMessage(format(msgFormat, name), channelTarget)
end

function Commands:OnSummoned(_, petId, userInitiated)
  if userInitiated then
    self:AnnounceSummon(petId)
  end
end
