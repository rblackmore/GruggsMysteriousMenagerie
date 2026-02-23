local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)


--------------------------------------------------------------------------------
--- TransmogWardrobeCompanionsMixin
--------------------------------------------------------------------------------
GMM_TransmogCompanionsMixin = {
  EVENTS_TO_REGISTER = {
    "PET_JOURNAL_LIST_UPDATE"
  },
  COLLECTION_TEMPLATES = {
    ["COLLECTION_ITEM"] = {
      template = "GMM_CompanionModelTemplate", initFunc = GMM_CompanionModelMixin.Init
    }
  }
}


--- Script Handlers
--------------------------------------------------------------------------------
function GMM_TransmogCompanionsMixin:OnLoad()
  self.db = addOn.outfitDb.char
  self:InitFilterButton()
  self:InitCopyToButton()
  self.PagedContent:SetElementTemplateData(self.COLLECTION_TEMPLATES)
  self.ActiveTabTitle:SetText("Companions")
  self:RegisterEvents()
  self:InitSearchBox()
end

function GMM_TransmogCompanionsMixin:InitSearchBox()
  self.SearchBox:SetScript("OnHide", function(editBox) editBox:SetText("") end)
  self.SearchBox:SetScript("OnTextChanged",
    function(editbox, userInput)
      SearchBoxTemplate_OnTextChanged(editbox)
      self:OnSearchTextChanged(editbox:GetText(), userInput)
    end)
end

function GMM_TransmogCompanionsMixin:InitFilterButton()
  self.FilterButton:SetText("Filter")
  self.ShowUnused = true

  local function IsFamilyChecked(filterIndex)
    return C_PetJournal.IsPetTypeChecked(filterIndex)
  end

  local function SetFamilyChecked(filterIndex)
    C_PetJournal.SetPetTypeFilter(filterIndex, not IsFamilyChecked(filterIndex))
  end

  local function SetAllFamilyChecked(value)
    C_PetJournal.SetAllPetTypesChecked(value)
  end

  local function IsShowUnused()
    return self.ShowUnused
  end

  local function SetShowUnused()
    self.ShowUnused = not IsShowUnused()
    self:Refresh()
  end

  self.FilterButton:SetupMenu(function(_dropdown, rootDescription)
    rootDescription:SetTag("MENU_TRANSMOG_COMPANIONS_FILTER")
    rootDescription:CreateCheckbox("Show Unused", IsShowUnused, SetShowUnused)

    rootDescription:CreateDivider()

    local familiesSubmenu = rootDescription:CreateButton("Families");

    familiesSubmenu:CreateButton("Uncheck All", SetAllFamilyChecked, false)
    familiesSubmenu:CreateButton("Check All", SetAllFamilyChecked, true)

    for filterIndex = 1, C_PetJournal.GetNumPetTypes() do
      familiesSubmenu:CreateCheckbox(_G["BATTLE_PET_NAME_" .. filterIndex], IsFamilyChecked, SetFamilyChecked,
        filterIndex)
    end
  end)

  self.FilterButton:SetIsDefaultCallback(function()
    return C_PetJournal.IsUsingDefaultFilters() and self.ShowUnused
  end)

  self.FilterButton:SetDefaultCallback(function()
    C_PetJournal.SetDefaultFilters()
    self.ShowUnused = true
  end)
end

function GMM_TransmogCompanionsMixin:InitCopyToButton()
  local function GetNumOutfitsUnlocked()
    return C_TransmogOutfitInfo.GetNumberOfOutfitsUnlockedForSource(0) +
        C_TransmogOutfitInfo.GetNumberOfOutfitsUnlockedForSource(1) +
        C_TransmogOutfitInfo.GetNumberOfOutfitsUnlockedForSource(2)
  end

  self.CopyToButton:SetText("Copy To")

  local function CopyToOutfit(outfitID)
    local srcOutfitID = C_TransmogOutfitInfo.GetCurrentlyViewedOutfitID()
    local src = self:GetOrCreateOutfitTableFor(srcOutfitID)
    local dest = self:GetOrCreateOutfitTableFor(outfitID)
    self.db["Outfits"][outfitID] = src
  end

  local function CopyToAllOutfits()
    for i = 1, GetNumOutfitsUnlocked() do
      CopyToOutfit(C_TransmogOutfitInfo.GetOutfitsInfo()[i].outfitID)
    end
  end

  self.CopyToButton:SetupMenu(function(_dropdown, rootDescription)
    rootDescription:SetTag("MENU_TRANSMOG_COMPANIONS_COPYTO")

    rootDescription:CreateButton("Copy to All", CopyToAllOutfits)
    rootDescription:CreateDivider()

    for i = 1, GetNumOutfitsUnlocked() do
      local outfitInfo = C_TransmogOutfitInfo.GetOutfitsInfo()[i]

      if outfitInfo.outfitID ~= C_TransmogOutfitInfo.GetCurrentlyViewedOutfitID() then
        rootDescription:CreateButton(outfitInfo.name, CopyToOutfit, outfitInfo.outfitID)
      end
    end
  end)
end

function GMM_TransmogCompanionsMixin:OnSearchTextChanged(queryText, userInput)
  C_PetJournal.SetSearchFilter(queryText)
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
  self:RefreshJournalEntries()
  self:RefreshTotalDisplay()
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

function GMM_TransmogCompanionsMixin:PET_JOURNAL_LIST_UPDATE()
  self:Refresh()
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
    self.petCollectionEntries[i].petId = petID
  end
  self:SetCollectionEntries(self.petCollectionEntries, true)
end

function GMM_TransmogCompanionsMixin:RefreshJournalEntries()
  -- Get pet Data then SetCollectionEntries
  local numPets, numOwned = C_PetJournal.GetNumPets()
  self.petCollectionEntries = {}

  for i = 1, numPets do
    local petID = C_PetJournal.GetPetInfoByIndex(i)
    if petID then
      self.petCollectionEntries[i] = C_PetJournal.GetPetInfoTableByPetID(petID)
      self.petCollectionEntries[i].petId = petID
    end
  end

  self:SetCollectionEntries(self.petCollectionEntries, true)
end

function GMM_TransmogCompanionsMixin:RefreshTotalDisplay()
  self.TotalDisplay.TotalValue:SetText(#self.petCollectionEntries)
end

function GMM_TransmogCompanionsMixin:SetCollectionEntries(entries, retainCurrentPage)
  -- Add Sorting Function Here?

  local function compare(left, right)
    local sourceLeft = left.petInfo
    local sourceRight = right.petInfo

    if (sourceLeft.isFavorite ~= sourceRight.isFavorite) then
      return sourceLeft.isFavorite
    end

    if sourceLeft.petType ~= sourceRight.petType then
      return sourceLeft.petType > sourceRight.petType
    end

    return sourceLeft.name < sourceRight.name
  end

  local outfitId = C_TransmogOutfitInfo.GetCurrentlyViewedOutfitID()
  local outfitDb = self:GetOutfitTableOrNil(outfitId)
  local collectionElements = {}
  for i, itemEntry in ipairs(entries) do
    local element = {
      templateKey = "COLLECTION_ITEM",
      petInfo = itemEntry,
      collectionFrame = self,
      isSelected = self:OutfitContainsPetId(outfitDb, itemEntry.petId)
    }
    if self.ShowUnused then
      table.insert(collectionElements, element)
    elseif element.isSelected then
      table.insert(collectionElements, element)
    end
  end

  table.sort(collectionElements, compare)

  local collectionData = { { elements = collectionElements } }
  local dataProvider = CreateDataProvider(collectionData)
  self.PagedContent:SetDataProvider(dataProvider, retainCurrentPage)
end

--------------------------------------------------------------------------------
--- Database Management
--------------------------------------------------------------------------------

-- TODO: Perhaps this shoudl be 'AddOrRemove, return ture for add, false if removed.'
function GMM_TransmogCompanionsMixin:AddOrRemovePetToOutfit(outfitid, petId)
  local db = self:GetOrCreateOutfitTableFor(outfitid)
  local hasId, index = self:OutfitContainsPetId(db, petId)
  if not hasId then
    table.insert(db, petId)
    db.Total = #db
    return true
  else
    table.remove(db, index)
    db.Total = #db
    return false
  end
end

function GMM_TransmogCompanionsMixin:GetOrCreateOutfitTableFor(outfitid)
  if self.db["Outfits"][outfitid] then
    return self.db["Outfits"][outfitid]
  end

  local outfitdb = {
    Total = 0
  }

  self.db["Outfits"][outfitid] = outfitdb
  return self.db["Outfits"][outfitid]
end

function GMM_TransmogCompanionsMixin:GetOutfitTableOrNil(outfitid)
  if self.db["Outfits"][outfitid] then
    return self.db["Outfits"][outfitid]
  else
    return nil
  end
end

--------------------------------------------------------------------------------
--- Utility
--------------------------------------------------------------------------------

function GMM_TransmogCompanionsMixin:OutfitContainsPetId(tbl, petId)
  if tbl == nil then return false end

  for i, v in ipairs(tbl) do
    if v == petId then
      return true, i
    end
  end
  return false, nil
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
      self:UnregisterEvent("ADDON_LOADED")
    end
  end
end

local EventHandler = CreateFrame("Frame")

EventHandler:RegisterEvent("ADDON_LOADED")
EventHandler:RegisterEvent("PLAYER_LOGIN")
EventHandler:SetScript("OnEvent", OnEvent)
