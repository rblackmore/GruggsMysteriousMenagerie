--------------------------------------------------------------------------------
--- TransmogWardrobeCompanionsMixin
--------------------------------------------------------------------------------
GMM_TransmogCompanionsMixin = {
  EVENTS_TO_REGISTER = {},
  COLLECTION_TEMPLATES = {
    ["COLLECTION_ITEM"] = {
      template = "GMM_CompanionModelTemplate", initFunc = GMM_CompanionModelMixin.Init
    }
  }
}


--- Script Handlers
--------------------------------------------------------------------------------
function GMM_TransmogCompanionsMixin:OnLoad()
  self.PagedContent:SetElementTemplateData(self.COLLECTION_TEMPLATES)
  self.ActiveTabTitle:SetText("Companions")
  self:RegisterEvents()
end

function GMM_TransmogCompanionsMixin:OnShow()
  self:Refresh()
end

function GMM_TransmogCompanionsMixin:OnHide()
end

function GMM_TransmogCompanionsMixin:OnEvent(event, ...)
  if (self[event]) then
    self[event](self, ...)
  end
end

function GMM_TransmogCompanionsMixin:Refresh()
  self:RefreshCollectionEntries()
end

--- Event Handlers
--------------------------------------------------------------------------------


--- Initialization Logic
--------------------------------------------------------------------------------

function GMM_TransmogCompanionsMixin:RegisterEvents()
  for i, event in ipairs(self.EVENTS_TO_REGISTER) do
    self:RegisterEvent(event)
  end
end

function GMM_TransmogCompanionsMixin:AttachToWardrobeCollection()
  local container = TransmogFrame
      and TransmogFrame.WardrobeCollection
      and TransmogFrame.WardrobeCollection.TabContent
  if not container then
    return false
  end

  self:SetParent(container)
  self:SetFrameStrata(container:GetFrameStrata())
  self:SetFrameLevel(container:GetFrameLevel() + 1)
  self:ClearAllPoints()
  self:SetAllPoints(container)
  self.wardrobeCollection = TransmogFrame.WardrobeCollection
  return true
end

--- Paged Content Collection Management
--------------------------------------------------------------------------------
function GMM_TransmogCompanionsMixin:RefreshCollectionEntries()
  -- Get pet Data then SetCollectionEntries
  self.ownedPetIDs = C_PetJournal.GetOwnedPetIDs()
  self.petCollectionEntries = {}
  for i, petID in ipairs(self.ownedPetIDs) do
    self.petCollectionEntries[i] = C_PetJournal.GetPetInfoTableByPetID(petID)
  end
  self:SetCollectionEntries(self.petCollectionEntries, true)
end

function GMM_TransmogCompanionsMixin:SetCollectionEntries(entries, retainCurrentPage)
  -- Add Sorting Function Here?

  local collectionElements = {}
  for i, itemEntry in ipairs(entries) do
    local element = {
      templateKey = "COLLECTION_ITEM",
      petInfo = itemEntry,
      collectionFrame = self
    }
    table.insert(collectionElements, element)
  end

  -- Sort here with above function that will totally exist at some point in the future 😜

  local collectionData = { { elements = collectionElements } }
  local dataProvider = CreateDataProvider(collectionData)
  self.PagedContent:SetDataProvider(dataProvider, retainCurrentPage)
end

--------------------------------------------------------------------------------
--- Load Frame On Demand
--------------------------------------------------------------------------------
local function OnEvent(self, event, ...)
  if event == "ADDON_LOADED" then
    local addOnName = select(1, ...)
    if addOnName == "Blizzard_Transmog" then
      GMM_CompanionsFrame = CreateFrame("Frame", nil, nil, "GMM_TransmogCompanionsTemplate")
      GMM_CompanionsFrame:AttachToWardrobeCollection()
      TransmogFrame.WardrobeCollection.gmmCompanionsTabID =
          TransmogFrame.WardrobeCollection:AddNamedTab("Companions", GMM_CompanionsFrame)
      TransmogFrame.WardrobeCollection:UpdateTabs()
      self:UnregisterEvent("ADDON_LOADED")
    end
  end

  if event == "PLAYER_LOGIN" then
    local f = CreateFrame("PlayerModel", nil, UIParent, "GMM_CompanionModelTemplate")
    f:SetDisplayInfo(39380)
    -- f:SetUnit("player")
    f:SetRotation(math.pi * -0.15)
    f:SetPortraitZoom(0.5)
    f:SetPoint("CENTER")
    f:RefreshCamera()
    f:Show()
  end
end

local EventHandler = CreateFrame("Frame")

EventHandler:RegisterEvent("ADDON_LOADED")
EventHandler:RegisterEvent("PLAYER_LOGIN")
EventHandler:SetScript("OnEvent", OnEvent)

-- function GMM_TransmogCompanionsMixin:UpdatePetList()
--   local dataProvider = CreateDataProvider()
--   local numPets, ownedPetCount = C_PetJournal.GetNumPets()
--   local ownedIds = C_PetJournal.GetOwnedPetIDs()

--   for i = 1, ownedPetCount do
--     dataProvider:Insert({ index = i, petId = ownedIds[i] })
--   end

--   self.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
-- end

-- function GMM_TransmogCompanionsMixin:InitPetListItem(item, data)
--   if not data or not data.petId then
--     return
--   end

--   local speciesID, customName, level, xp, maxXp, displayID, favorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable =
--       C_PetJournal.GetPetInfoByPetID(data.petId)

--   item.petId = data.petId
--   item.index = data.index
--   item.icon:SetTexture(icon)

--   if customName then
--     item.name:SetText(customName)
--     item.subName:SetText("(" .. name .. ")")
--     item.subName:Show()
--   else
--     item.name:SetText(name)
--     item.subName:Hide()
--   end

--   if self.selectedPet.petId == data.petId then
--     item.selected = true;
--     item.selectedTexture:Show()
--   else
--     item.selected = false
--     item.selectedTexture:Hide()
--   end

--   item:SetScript("OnEnter", function()
--     self:SetPetModel(displayID)
--   end)

--   item:SetScript("OnLeave", function()
--     self:SetPetModel(self.selectedPet.displayID)
--   end)

--   item:SetScript("OnClick", function()
--     self:SelectPetByPetID(item.petId)
--   end)

--   item:Show()
-- end


--------------------------------------------------------------------------------
--- PetListButtonMixin
--------------------------------------------------------------------------------

-- GMM_PetListButtonMixin = {}

-- function GMM_PetListButtonMixin:OnLoad()
--   self:RegisterForClicks("LeftButtonUp")
-- end

-- function GMM_TransmogCompanionsMixin:SelectPetByPetID(petId)
--   local speciesID, customName, level, xp, maxXp, displayID, favorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable =
--       C_PetJournal.GetPetInfoByPetID(petId)

--   self.selectedPet.petId = petId
--   self.selectedPet.displayID = displayID
--   self.selectedPet.speciesID = speciesID

--   self:UpdatePetList()
-- end

-- function GMM_TransmogCompanionsMixin:SetPetModel(displayId)
--   local companionModel = self.companionModel

--   if displayId then
--     companionModel:SetDisplayInfo(displayId)

--     companionModel:Show()
--   else
--     companionModel:Hide()
--   end
-- end
