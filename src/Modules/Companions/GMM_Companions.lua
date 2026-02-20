local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule");

function mod:OnInitialize()
  self:InitializeAutomation()
end

function mod:OnEnable()
  for name, mod in self:IterateModules() do
    mod:Enable()
  end
  self:InitializeCompanionDB()
end

function mod:OnDisable()
  for name, mod in self:IterateModules() do
    mod:Disable()
  end
end

-- Using a priority list, chooses a random petId from a variety of Data Tables.
function mod:ChooseRandomCompanion()
  local outfitid = C_TransmogOutfitInfo.GetActiveOutfitID()
  local outfitDb = addOn:GetOutfitTableOrNil(outfitid)

  if outfitDb and outfitDb.Total > 0 then
    local rando = math.random(#outfitDb)
    return outfitDb[rando]
  end

  -- TODO: Pick Random from other sources.

  -- Ultimate Default - Just pick any owned pet.
  local ownedPetIds = C_PetJournal.GetOwnedPetIDs()
  return ownedPetIds[math.random(#ownedPetIds)]
end

-- Calls SummonNewCompanion Immediately if not in Combat, else registers for 'PLAYER_REGEN_ENABLED' and calls When out of combat.
function mod:CallSummonCompanion(petId)
  if InCombatLockdown() then
    self:RegisterEvent("PLAYER_REGEN_ENABLED", function()
      mod:SummonNewCompanion(petId)
      self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end)
  else
    mod:SummonNewCompanion(petId)
  end
end

function mod:SummonNewCompanion(petId)
  local currentPet = C_PetJournal.GetSummonedPetGUID()
  if petId == currentPet then
    return false
  end

  C_PetJournal.SummonPetByGUID(petId)
  local newpet = C_PetJournal.GetSummonedPetGUID()
  return newpet == petId
end

function mod:SummonCompanion(announce)
  local settings = self.Settings
  local summonedPet, hasSummoned

  if settings["Automation"]["PetOfTheDay"].Enabled then
    summonedPet, hasSummoned = self:SummonPetOfTheDay()
  else
    summonedPet, hasSummoned = self:SummonRandom()
  end

  if announce and hasSummoned then
    self:AnnounceSummon(summonedPet)
  end
end

function mod:SummonRandom()
  local randoPet = self:PickRandomPet()

  C_PetJournal.SummonPetByGUID(randoPet.petID)

  return randoPet, true
end

function mod:SummonPetOfTheDay()
  local settings = self.Settings["Automation"]["PetOfTheDay"]
  local summonedDate = settings.Date
  local currentDate = date("*t")
  if not settings.Pet then
    settings.Pet = self:PickRandomPet()
  end
  if summonedDate.year ~= currentDate.year or summonedDate.month ~= currentDate.month or summonedDate.day ~= currentDate.day then
    self:SetPetOfTheDay(self:PickRandomPet())
  end

  if C_PetJournal.GetSummonedPetGUID() ~= settings.Pet.petID then
    C_PetJournal.SummonPetByGUID(settings.Pet.petID)
    return settings.Pet, true
  end

  return settings.Pet, false
end

-- TODO: Maybe update this to work if settings are not restricted. see: https://x.com/deadlybossmods/status/1176
function mod:AnnounceSummon(pet)
  local dbSettings = self.Settings

  local name = dbSettings["UseCustomName"] and pet.customName or pet.name

  local msgFormat = dbSettings["MessageFormat"]
  local channel = dbSettings["Channel"]

  C_ChatInfo.SendChatMessage(format(msgFormat, name), channel)
end

function mod:PickRandomPet()
  local eligablePets = self:GetEligableSummons()
  local petIDs = {}
  local i = 0
  for k, v in pairs(eligablePets) do
    i = i + 1
    petIDs[i] = v
  end
  local pet = petIDs[math.random(#petIDs)]
  return pet
end

--[[
  Gets Eligable Summons.
  Filters out currently summoned pet from current zone pets.
  More Filters to come, based on class, race, faction etc.
  --]]
function mod:GetEligableSummons()
  local currentZoneCompanions = self:GetCurrentZoneCompanionList()

  local summonedId = C_PetJournal.GetSummonedPetGUID()
  if summonedId then
    currentZoneCompanions[summonedId] = nil
  end

  return currentZoneCompanions
end
