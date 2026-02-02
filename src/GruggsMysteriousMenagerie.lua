local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
addOn:SetDefaultModuleState(false)
addOn:SetDefaultModuleLibraries("AceEvent-3.0", "AceConsole-3.0")

---@class AceAddon: AceTimer-3.0
local companionModule = addOn:NewModule("CompanionModule", "AceTimer-3.0");
---@class AceAddon: AceConsole-3.0, AceEvent-3.0
local Options = addOn:NewModule("Options")
---@class AceAddon: AceConsole-3.0, AceEvent-3.0
local PetJournal = addOn:NewModule("GMM_PetJournal")
---@class AceAddon: AceConsole-3.0, AceEvent-3.0
local MapInfo = addOn:NewModule("GMM_MapInfo")

_G["GMM"] = addonTable
_G["GMM_AddOn"] = addOn
_G["GMM_Companions"] = companionModule
_G["GMM_Options"] = Options
_G["GMM_PetJournal"] = PetJournal
_G["GMM_MapInfo"] = MapInfo

-------------------------------------------------------------------------------
--- Public API

function addOn:OnInitialize()
  self:InitializeDatabase()

  Options:InitializeOptions()
  self:RegisterChatCommand("test", "PrintArgs")
  self:RegisterChatCommand("gmm", "SlashCommand")
  self:RegisterChatCommand("gmsummon", function()
    companionModule:SummonCompanion(true)
  end)
end

function addOn:OnEnable()
  for name, module in self:IterateModules() do
    module:Enable()
  end
end

function addOn:OnDisable()
  for name, module in self:IterateModules() do
    module:Disable()
  end
end

function addOn:SlashCommand(args)
  if InCombatLockdown() then
    return
  end
  Settings.OpenToCategory(Options["ConfigFrames"]["GMM_Companions"]["Id"])
end

function addOn:PrintArgs(args)
  local linkedPet = addOn:GetArgs(args)

  local isHyperLink, preString, payload, postString = ExtractHyperlinkString(linkedPet)

  -- local _, _, payload = string.find(linkedPet, "^|%x+|H(.+)|h%[.+%]")

  print("Extracted Data:")
  print("isHyperLink")
  print(isHyperLink)
  print("preString")
  print(preString)
  print("payload")
  print(payload)
  print("postString")
  print(postString)

  if (not isHyperLink) then
    return
  end
  local linkType = payload:match("^(%a+):")
  addOn:Print("Link Type: " .. linkType)
  local properties = {}
  for property in payload:sub(#linkType + 2):gmatch("([^:]+)") do
    table.insert(properties, property)
  end

  -- Now properties contains all your values
  local speciesID = properties[1]
  local level = properties[2]
  local breedQuality = properties[3]
  local maxHealth = properties[4]
  local power = properties[5] or "N/A" -- Optional; handle if not present
  local speed = properties[6] or "N/A" -- Optional; handle if not present
  local battlePetID = properties[7]
  local displayID = properties[8]

  -- Output the extracted values
  print("Species ID:", speciesID)
  print("Level:", level)
  print("Breed Quality:", breedQuality)
  print("Max Health:", maxHealth)
  print("Power:", power)
  print("Speed:", speed)
  print("Battle Pet ID:", battlePetID)
  print("Display ID:", displayID)
end

-- addOn:Print("Arg: " .. linkedPet)

-- local numpets = C_PetJournal.GetNumPets()

-- for idx = 1, numpets do
--   local petID, speciesID, owned, customName, level, favorite, isRevoked, speciesNameCheck =
--       C_PetJournal.GetPetInfoByIndex(idx)
--   if speciesNameCheck == searchString then
--     addOn:Print("Found:" .. petID)
--     addOn:Print("Found: " .. customName)
--     return petID
--   end
