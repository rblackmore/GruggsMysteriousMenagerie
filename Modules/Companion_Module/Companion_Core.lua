local addonName, addonTable = ...
local addOn = addonTable.addOn
local module = addOn:NewModule("CompanionModule")
function module:OnInitialize()
  self:LoadDatabase()
end

function module:OnEnable()
  for name, module in self:IterateModules() do
    module:Enable()
  end
  self:InitializePetData()
end

function module:OnDisable()
  for name, module in self:IterateModules() do
    module:Disable()
  end
end

-- Initializes Database with List of Favorite Pets.
-- Also stores data in memory about all owned Pets.
function module:InitializePetData()
  if module.db.OwnedPetData == nil then
    module.db.OwnedPetData = {}
  end

  for petID, _, owned, customName, _, isFav, _, name in addOn.PetJournal:CompanionIterator() do
    if isFav then
      self:AddCompanionToZone("FavoritePets", petID, addOn.PetJournal:GetSimplePetTable(petID))
    end
    if owned then
      self.db.OwnedPetData[petID] = addOn.PetJournal:GetSimplePetTable(petID)
    end
  end
end

function module:SummonCompanion(announce)
  local settings = self:GetDatabaseSettings()
  local summonedPet

  if settings["Automation"]["PetOfTheDay"].Enabled then
    summonedPet = self:SummonPetofTheDay()
  else
    summonedPet = self:SummonRandom()
  end

  if not announce then
    return
  end

  self:AnnounceSummon(summonedPet)
end

function module:SummonRandom()
  local randoPet = self:PickRandomPet()

  C_PetJournal.SummonPetByGUID(randoPet.petID)

  return randoPet
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

function module:SummonPetofTheDay()
  local settings = self.db["profile"].Settings
  local petId

  local summonedDate = settings["PetOfTheDay"].Date
  local currentDate = date("*t")
  -- If Saved Date Is Today, used saved PetId
  if summonedDate.year == currentDate.year and summonedDate.month == currentDate.month and summonedDate.day == currentDate.day then
    if not settings["PetOfTheDay"].PetId then
      settings["PetOfTheDay"].PetId = self:PickRandomPetId()
    end
    petId = settings["PetOfTheDay"].PetId
  else
    settings["PetOfTheDay"].PetId = self:PickRandomPetId()
    petId = settings["PetOfTheDay"].PetId
    settings["PetOfTheDay"].Date = {
      ["year"] = currentDate.year,
      ["month"] = currentDate.month,
      ["day"] = currentDate.day,
    }
  end
  if C_PetJournal.GetSummonedPetGUID() ~= petId then
    C_PetJournal.SummonPetByGUID(petId)
  end

  return petId
end

-- TODO: Maybe update this to work if settings are not restricted. see: https://x.com/deadlybossmods/status/1176
function module:AnnounceSummon(pet)
  local dbSettings = self:GetDatabaseSettings()

  local name = dbSettings["UseCustomName"] and pet.customName or pet.name

  local msgFormat = dbSettings["MessageFormat"]
  local channel = dbSettings["Channel"]

  SendChatMessage(format(msgFormat, name), channel)
end
