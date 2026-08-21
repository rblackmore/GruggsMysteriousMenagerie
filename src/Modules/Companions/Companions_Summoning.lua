local addonName, _ = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0, GMM_Companion
local companionModule = addOn:GetModule("CompanionModule")

local Cache = companionModule.Cache
local Settings = companionModule.Settings
local Summoning = companionModule.Summoning
local Utilities = addOn.Utilities

--------------------------------------------------------------------------------
--- Private Functions
--------------------------------------------------------------------------------

local function summonCompanion(petId, userInitiated)
  local currentCompanion = C_PetJournal.GetSummonedPetGUID()

  if currentCompanion == petId then
    return false
  end

  C_PetJournal.SummonPetByGUID(petId)

  companionModule:SendMessage("GMM_COMPANION_SUMMONED", petId, userInitiated)
end

local function pickRandomPetId()
  local list = Cache:GetEffectivePetList()

  if not list or not list.order or #list.order == 0 then
    return nil, "No Pets in the current effective list"
  end

  local rando = math.random(#list.order)
  local petId = list.order[rando]
  return petId
end

--- TODO: Review the logic of this function. It seems to iterate through list of pets to find one to pick.
--- Consider a binary search instead?
local function pickWeightedRandomPetId()
  local list = Cache:GetEffectivePetList()

  if not list or not list.order or #list.order == 0 then
    return nil, "No Pets in the current effective list"
  end

  local weights = list.weights or {}
  local totalW, tmp = 0, {}

  for _, guid in ipairs(list.order) do
    if list.pets and list.pets[guid] then
      local speciesID = C_PetJournal.GetPetInfoByPetID(guid)
      if speciesID then
        local w = tonumber(weights[guid]) or 1.0
        totalW = totalW + w
        table.insert(tmp, { guid = guid, weight = w })
      end
    end
  end

  local rando = math.random() * totalW
  local upto = 0

  for _, item in ipairs(tmp) do
    upto = upto + item.weight
    if upto >= rando then
      return item.guid
    end
  end

  return nil, "Failed to pick a pet based on weights."
end

local function requestCompanion(userInitiated)
  local current
  local petId

  if Settings:IsPetOfTheDayEnabled() then
    current, petId = Settings:GetPetOfTheDay()
    if not current then
      petId = pickWeightedRandomPetId() or pickRandomPetId()
      Settings:SetPetOfTheDay(petId)
    end
  else
    petId = pickWeightedRandomPetId() or pickRandomPetId()
  end

  Utilities:DispatchIfInCombatLockdown(
    function() summonCompanion(petId, userInitiated) end, nil)
end

--------------------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------------------

function Summoning:SummonOrDismissRandomPet(userInitiated)
  local currentCompanion = C_PetJournal.GetSummonedPetGUID()

  if currentCompanion then
    C_PetJournal.SummonPetByGUID(currentCompanion)
    return
  end

  requestCompanion(userInitiated)
end

function Summoning:SummonRandomPet(userInitiated)
  requestCompanion(userInitiated)
end
