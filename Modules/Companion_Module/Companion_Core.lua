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

function module:InitializePetData()
  -- Loop over all Pet Ids, if they are set as favorite, add the Id to list.
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

--[[
  Gets Eligable Summons.
  Filters out currently summoned pet from current zone pets.
  More Filters to come, based on class, race, faction etc.
  --]]
function module:GetEligableSummons()
  local currentZoneCompanions = self:GetCurrentZoneCompanionList()

  local inverted = {}
  for k, v in ipairs(currentZoneCompanions) do
    inverted[v] = k
  end

  local summonedId = C_PetJournal.GetSummonedPetGUID()
  inverted[summonedId] = nil

  return inverted
end

function module:SummonCompanion(announce)
  local settings = self.db["profile"].Settings
  local summonedId

  if settings["PetOfTheDay"].Enabled then
    summonedId = self:SummonPetofTheDay()
  else
    summonedId = self:SummonRandomCompanion()
  end

  if not announce then
    return
  end

  self:AnnounceSummon(summonedId)
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

function module:PickRandomPetId()
  local eligablePets = self:GetEligableSummons()

  local randoPetId = eligablePets[math.random(#eligablePets)]

  return randoPetId
end

function module:SummonRandomCompanion()
  local randoPetId = self:PickRandomPetId()

  C_PetJournal.SummonPetByGUID(randoPetId)

  return randoPetId
end

-- TODO: Maybe update this to work if settings are not restricted. see: https://x.com/deadlybossmods/status/1176
function module:AnnounceSummon(petId)
  local _, customName, _, _, _, _, _, name = C_PetJournal.GetPetInfoByPetID(petId)

  local useCustomName = self.db["profile"].Settings["UseCustomName"]
  local name = useCustomName and customName or name

  local msgFormat = companionModule.db["profile"].Settings["MessageFormat"]
  local channel = Options.db["profile"]["Channel"]

  SendChatMessage(format(msgFormat, name), channel)
end
