local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0, GMM_Companion
local companionModule = addOn:GetModule("CompanionModule")

local Cache = companionModule.Cache
local Settings = companionModule.Settings
local Summoning = companionModule.Summoning

local MapUtils = addonTable.MapUtils
local Enums = addonTable.Enums
local CombatLockdownUtils = addonTable.CombatLockdownUtils

--------------------------------------------------------------------------------
--- Private Functions
--------------------------------------------------------------------------------

local function summonCompanion(petId, userInitiated)
  if not petId then return end

  if C_PetJournal.IsCurrentlySummoned(petId) then
    return
  end

  C_PetJournal.SummonPetByGUID(petId)

  companionModule:SendMessage("GMM_COMPANION_SUMMONED", petId, userInitiated)
end

local function requestCompanion(userInitiated)
  local list = Cache:GetEffectivePetList()
  local petId, isTodaysPet, IsEnabled = Settings:GetPetOfTheDay()

  if not IsEnabled then
    petId = list:getRandom()
  end

  if IsEnabled and not isTodaysPet then
    petId = list:getRandom()
    Settings:SetPetOfTheDay(petId)
  end

  if not petId then
    petId = list:getRandom()
  end

  CombatLockdownUtils.Dispatch(
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

--------------------------------------------------------------------------------
--- TODO: Code to Review
--------------------------------------------------------------------------------

--- TODO: Review the logic of this function. It seems to iterate through list of pets to find one to pick.
--- Consider a binary search instead?

-- local function pickWeightedRandomPetId()
--   local list = Cache:GetEffectivePetList()

--   if not list or not list.order or #list.order == 0 then
--     return nil, "No Pets in the current effective list"
--   end

--   local weights = list.weights or {}
--   local totalW, tmp = 0, {}

--   for _, guid in ipairs(list.order) do
--     if list.pets and list.pets[guid] then
--       local speciesID = C_PetJournal.GetPetInfoByPetID(guid)
--       if speciesID then
--         local w = tonumber(weights[guid]) or 1.0
--         totalW = totalW + w
--         table.insert(tmp, { guid = guid, weight = w })
--       end
--     end
--   end

--   local rando = math.random() * totalW
--   local upto = 0

--   for _, item in ipairs(tmp) do
--     upto = upto + item.weight
--     if upto >= rando then
--       return item.guid
--     end
--   end

--   return nil, "Failed to pick a pet based on weights."
-- end
