local addonName, addonTable = ...
local addOn = addonTable.addOn
local module = addOn:NewModule("CompanionModule", "AceTimer-3.0")
function module:OnInitialize()
  _G["GMM_CompanionModule"] = module
  self:InitializeOptions()
  self:InitializeAutomation()
end

function module:OnEnable()
  for name, mod in self:IterateModules() do
    mod:Enable()
  end
  self:InitializeCompanionDB()
end

function module:OnDisable()
  for name, module in self:IterateModules() do
    module:Disable()
  end
end

function module:SummonCompanion(announce)
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

function module:SummonRandom()
  local randoPet = self:PickRandomPet()

  C_PetJournal.SummonPetByGUID(randoPet.petID)

  return randoPet, true
end

function module:SummonPetOfTheDay()
  local settings = self.Settings["Automation"]["PetOfTheDay"]
  local summonedDate = settings.Date
  local currentDate = date("*t")
  if not settings.Pet then
    settings.Pet = self:PickRandomPet()
  end
  if summonedDate.year ~= currentDate.year or summonedDate.month ~= currentDate.month or summonedDate.day ~= currentDate.day then
    settings.Pet = self:PickRandomPet()
    settings.Date = {
      ["year"] = currentDate.year,
      ["month"] = currentDate.month,
      ["day"] = currentDate.day,
    }
  end

  if C_PetJournal.GetSummonedPetGUID() ~= settings.Pet.petID then
    C_PetJournal.SummonPetByGUID(settings.Pet.petID)
    return settings.Pet, true
  end

  return settings.Pet, false
end

-- TODO: Maybe update this to work if settings are not restricted. see: https://x.com/deadlybossmods/status/1176
function module:AnnounceSummon(pet)
  local dbSettings = self.Settings

  local name = dbSettings["UseCustomName"] and pet.customName or pet.name

  local msgFormat = dbSettings["MessageFormat"]
  local channel = dbSettings["Channel"]

  SendChatMessage(format(msgFormat, name), channel)
end

function module:PickRandomPet()
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
function module:GetEligableSummons()
  local currentZoneCompanions = self:GetCurrentZoneCompanionList()

  local summonedId = C_PetJournal.GetSummonedPetGUID()
  if summonedId then
    currentZoneCompanions[summonedId] = nil
  end

  return currentZoneCompanions
end
