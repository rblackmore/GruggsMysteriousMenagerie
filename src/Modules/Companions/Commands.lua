local addonName, _ = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")

mod.Commands = mod.Commands or {}
local Commands = mod.Commands

function Commands:Init(db, core)
  self.db = db
  self.core = core
  -- TODO: Remove these chat commands in a later update.
  mod:RegisterChatCommand("gmsummon", function(...)
    mod:Printf("/gmsummon command is deprecated and will be removed in a future update, use '/gmm summon' instead")
    Commands:Summon(...)
  end)
  mod:RegisterChatCommand("gmmsummon", function(...)
    mod:Printf("/gmmsummon command is deprecated and will be removed in a future update, use '/gmm summon' instead")
    Commands:Summon(...)
  end)

  mod:RegisterMessage("GMM_COMPANION_SUMMONED", function(...) Commands:OnSummoned(...) end)
end

function Commands:Summon(...)
  local arg1 = select(1, ...) and select(1, ...):lower()

  if arg1 and arg1 == "setpod" or arg1 == "pod" then
    self.core:SetActivePetAsPetOfTheDay()
    return
  end

  if arg1 and arg1 == "dismiss" then
    self.core:SummonOrDismissRandomCompanion(true)
  else
    self.core:RequestCompanion(true)
  end
end

function Commands:AnnounceSummon(petId)
  local petInfo = C_PetJournal.GetPetInfoTableByPetID(petId)
  local settings = self.db:GetCompanionSettings()
  local name = settings["UseCustomName"] and petInfo.customName or petInfo.name
  local msgFormat = settings["MessageFormat"] or "Welcome %s!"
  local channelTarget = settings["Channel"] or "SAY"
  C_ChatInfo.SendChatMessage(format(msgFormat, name), channelTarget)
end

function Commands:OnSummoned(_, petId, userInitiated)
  if userInitiated then
    self:AnnounceSummon(petId)
  end
end
