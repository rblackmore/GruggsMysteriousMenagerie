local addonName, _ = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:GetModule("CompanionModule")

mod.Core = mod.Core or {}
mod.Core.EventHandler = {}
mod.Core.Automation = mod.Core.Automation or {}

local Core = mod.Core

LibStub("AceEvent-3.0"):Embed(Core.EventHandler)

--------------------------------------------------------------------------------
--- Private Functions
--------------------------------------------------------------------------------
local function SummonCompanion(petId, userInitiated)
  local currentCompanion = C_PetJournal.GetSummonedPetGUID()

  if currentCompanion == petId then
    return false
  end

  C_PetJournal.SummonPetByGUID(petId)

  mod:SendMessage("GMM_COMPANION_SUMMONED", petId, userInitiated)
end

--------------------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------------------
function Core:Init(db, cache)
  self.db = db
  self.cache = cache
  self.Automation:Init(self)
end

function Core:PickRandomPetId()
  local list = self.cache:GetEffectivePetList()

  if not list or not list.order or #list.order == 0 then
    return nil, "No Pets in the current effective list"
  end

  local rando = math.random(#list.order)
  local petId = list.order[rando]
  return petId
end

function Core:GetPetOfTheDay()
  local podSettings = self.db.settingsProfile.companions["Automation"]["petoftheday"]
  local summonedDate = podSettings.Date
  local today = date("*t")

  if not summonedDate or summonedDate.day ~= today.day or summonedDate.month ~= today.month or summonedDate.year ~= today.year then
    local petId = self:PickRandomPetId()
    self.db:SetPetOfTheDay(petId)
  end
  return podSettings.PetId
end

function Core:ClearPetOfTheDay()
  local settings = self.db:GetCompanionSettings()
  local podSettings = settings["Automation"]["petoftheday"]
  podSettings.PetId = nil
  podSettings.Date = nil
end

function Core:SetActivePetAsPetOfTheDay()
  local currentPetGUID = C_PetJournal.GetSummonedPetGUID()
  if not currentPetGUID then
    return
  end

  self.db:SetPetOfTheDay(currentPetGUID)
end

--- TODO: Review the logic of this function. It seems to iterate through list of pets to find one to pick.
--- Consider a binary search instead?
function Core:PickWeightedRandom()
  local list = self.cache:GetEffectivePetList()

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

function Core:RequestCompanion(userInitiated)
  local settings = self.db:GetCompanionSettings()
  local podSettings = settings["Automation"]["petoftheday"]
  local petId

  if podSettings.Enabled then
    petId = self:GetPetOfTheDay()
  else
    petId = self:PickWeightedRandom() or self:PickRandomPetId()
  end

  if InCombatLockdown() then
    self.EventHandler:RegisterEvent("PLAYER_REGEN_ENABLED", function()
      SummonCompanion(petId, userInitiated)
      self.EventHandler:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end)
  else
    SummonCompanion(petId, userInitiated)
  end
end

function Core:SummonOrDismissRandomCompanion(userInitiated)
  local currentCompanion = C_PetJournal.GetSummonedPetGUID()
  if currentCompanion then
    C_PetJournal.SummonPetByGUID(currentCompanion)
    return
  end

  self:RequestCompanion(userInitiated)
end
