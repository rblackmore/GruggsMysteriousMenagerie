local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local mod = addOn:NewModule("CompanionModule", "AceTimer-3.0");
_G["GMM_Companions"] = mod

function mod:OnInitialize()
  self:InitializeDatabasePointers()
  self:RegisterChatCommand("gmsummon", "SummonCommand")
  self:RegisterChatCommand("gmmsummon", "SummonCommand")
  self:RegisterMessage("GMM_COMPANION_SUMMONED", "OnCompanionSummoned")
end

function mod:OnEnable()
  if not self.CompanionsNS or not self.SettingsNS then
    self:InitializeDatabasePointers()
  end
end

function mod:OnDisable()
end

function mod:PickRandomPetId()
  local list = self.EffectivePetList or self:RefreshEffectivePetList()
  if not list or not list.order or #list.order == 0 then
    return nil, "No Pets in the current effective list"
  end

  local rando = math.random(#list.order)
  local petId = list.order[rando]
  return petId
end

function mod:PickWeightedRandom()
  local list = self.EffectivePetList or self:RefreshEffectivePetList()
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
        if w > 0 then
          totalW = totalW + w
          table.insert(tmp, { guid = guid, w = w })
        end
      else -- prune
        list.pets[guid] = nil
        if list.weights then list.weights[guid] = nil end
      end
    end
  end

  if totalW <= 0 or #tmp == 0 then
    return nil, "No valid pets with positive weights."
  end

  local r = math.random() * totalW
  local acc = 0
  for i = 1, #tmp do
    acc = acc + tmp[i].w
    if r <= acc then
      return tmp[i].guid
    end
  end
  return tmp[#tmp].guid
end

function mod:RequestCompanion(userInitiated)
  local podSettings = self.settingsProfile.companions["Automation"]["petoftheday"]
  local petId

  if podSettings.Enabled then
    petId = self:GetPetOfTheDay()
  else
    petId = self:PickWeightedRandom() or self:PickRandomPetId()
  end

  if InCombatLockdown() then
    self:RegisterEvent("PLAYER_REGEN_ENABLED", function()
      self:SummonCompanion(petId, userInitiated)
      self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end)
  else
    self:SummonCompanion(petId, userInitiated)
  end
end

function mod:SummonCompanion(petId, userInitiated)
  local currentCompanion = C_PetJournal.GetSummonedPetGUID()

  if currentCompanion == petId then
    return false
  end

  C_PetJournal.SummonPetByGUID(petId)

  self:SendMessage("GMM_COMPANION_SUMMONED", petId, userInitiated)
end

function mod:SummonCommand(...)
  local arg1 = select(1, ...)

  if arg1 and arg1:lower() == "setpod" or arg1:lower() == "pod" then
    self:SetActivePetAsPetOfTheDay()
    return
  end

  if arg1 and arg1:lower() == "dismiss" then
    mod:SummonOrDismissRandomCompanion(true)
  else
    self:RequestCompanion(true)
  end
end

function mod:SetActivePetAsPetOfTheDay()
  local currentPetGUID = C_PetJournal.GetSummonedPetGUID()
  if not currentPetGUID then
    return
  end

  local petInfo = C_PetJournal.GetPetInfoTableByPetID(currentPetGUID)
  local name = petInfo.customName or petInfo.name
  self:Print(format("Setting %s as pet of the day!", name))
  self:SetPetOfTheDay(currentPetGUID)
end

function mod:SummonOrDismissRandomCompanion(userInitiated)
  local currentCompanion = C_PetJournal.GetSummonedPetGUID()
  if currentCompanion then
    C_PetJournal.DismissSummonedPet(currentCompanion)
    return
  end

  self:RequestCompanion(userInitiated)
end

function mod:SetPetOfTheDay(petId)
  local podSettings = self.settingsProfile.companions["Automation"]["petoftheday"]
  local currentDate = date("*t")
  podSettings.PetId = petId
  podSettings.Date = {
    ["year"] = currentDate.year,
    ["month"] = currentDate.month,
    ["day"] = currentDate.day,
  }

  self.PetOfTheDay = { PetId = petId, Date = podSettings.Date }
end

function mod:GetPetOfTheDay()
  local podSettings = self.settingsProfile.companions["Automation"]["petoftheday"]
  local summonedDate = podSettings.Date
  local today = date("*t")
  if summonedDate.year ~= today.year or summonedDate.month ~= today.month or summonedDate.day ~= today.day then
    self:SetPetOfTheDay(self:PickRandomPetId())
  end
  return podSettings.PetId
end

function mod:OnCompanionSummoned(_, petId, userInitiated)
  if userInitiated then
    self:AnnounceSummon(petId)
  end
end

function mod:AnnounceSummon(petId)
  local petInfo = C_PetJournal.GetPetInfoTableByPetID(petId)
  local name = self.settingsProfile.companions["UseCustomName"] and petInfo.customName or petInfo.name
  local msgFormat = self.settingsProfile.companions["MessageFormat"]
  local channel = self.settingsProfile.companions["Channel"] or "SAY"
  C_ChatInfo.SendChatMessage(format(msgFormat, name), channel)
end
