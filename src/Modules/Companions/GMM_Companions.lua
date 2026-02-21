local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule");

function mod:OnInitialize()
  self:InitializeAutomation()
  self.CompanionDB = addOn.db["profile"]["Companions"]
  self.Settings = self.CompanionDB["Settings"]
end

function mod:OnEnable()
  for name, mod in self:IterateModules() do
    mod:Enable()
  end
end

function mod:OnDisable()
  for name, mod in self:IterateModules() do
    mod:Disable()
  end
end

-- Using a priority list, chooses a random petId from a variety of Data Tables.
function mod:ChooseRandomCompanion(force)
  local podSettings = self.Settings["Automation"]["PetOfTheDay"]

  if podSettings.Enabled and not force then
    return self:GetPetofTheDay()
  end

  local outfitDb = addOn:GetActiveOutfitTable()

  if outfitDb and outfitDb.Total > 0 then
    local rando = math.random(#outfitDb)
    return outfitDb[rando]
  end

  -- TODO: Pick Random from other sources.

  -- Ultimate Default - Just pick any owned pet.
  local ownedPetIds = C_PetJournal.GetOwnedPetIDs()
  return ownedPetIds[math.random(#ownedPetIds)]
end

-- Calls SummonCompanion Immediately if not in Combat, else registers for 'PLAYER_REGEN_ENABLED' and calls When out of combat.
function mod:CallSummonCompanion(petId)
  if InCombatLockdown() then
    self:RegisterEvent("PLAYER_REGEN_ENABLED", function()
      mod:SummonCompanion(petId)
      self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end)
  else
    mod:SummonCompanion(petId)
  end
end

function mod:SummonCompanion(petId)
  local currentPet = C_PetJournal.GetSummonedPetGUID()
  if petId == currentPet then
    return false
  end

  C_PetJournal.SummonPetByGUID(petId)
  return true
end

function mod:AnnounceSummon(petId)
  local dbSettings = self.Settings
  local petData = C_PetJournal.GetPetInfoTableByPetID(petId)

  local name = dbSettings["UseCustomName"] and petData.customName or petData.name

  local msgFormat = dbSettings["MessageFormat"]
  local channel = dbSettings["Channel"]

  C_ChatInfo.SendChatMessage(format(msgFormat, name), channel)
end

function mod:SetPetOfTheDay(petId)
  local podSettings = self.Settings["Automation"]["PetOfTheDay"]
  local currentDate = date("*t")
  podSettings.PetId = petId
  podSettings.Date = {
    ["year"] = currentDate.year,
    ["month"] = currentDate.month,
    ["day"] = currentDate.day,
  }
end

function mod:GetPetofTheDay()
  local podSettings = self.Settings["Automation"]["PetOfTheDay"]
  local summonedDate = podSettings.Date
  local today = date("*t")
  if summonedDate.year ~= today.year or summonedDate.month ~= today.month or summonedDate.day ~= today.day then
    self:SetPetOfTheDay(self:ChooseRandomCompanion(true))
  end
  return podSettings.PetId
end
