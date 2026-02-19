--------------------------------------------------------------------------------
--- TransmogWardrobeCompanionsMixin
--------------------------------------------------------------------------------
GMM_TransmogCompanionsMixin = {
  EVENTS_TO_REGISTER = {},
  COLLECTION_TEMPLATES = {
    ["COLLECTION_ITEM"] = {
      template = "GMM_CompanionModelTemplate",
    }
  }

}


--- Script Handlers
--------------------------------------------------------------------------------
function GMM_TransmogCompanionsMixin:OnLoad()
  self:RegisterEvents()
  self:ConfigureScrollView()
  self:ConfigureModel()
end

function GMM_TransmogCompanionsMixin:OnShow()
  self:UpdatePetList()
end

function GMM_TransmogCompanionsMixin:OnHide()
end

function GMM_TransmogCompanionsMixin:OnEvent(event, ...)
  if (self[event]) then
    self[event](self, ...)
  end
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

function GMM_TransmogCompanionsMixin:ConfigureScrollView()
  local view = CreateScrollBoxListLinearView()
  view:SetElementInitializer("GMM_PetListButtonTemplate", function(item, data)
    self:InitPetListItem(item, data)
  end)
  view:SetPadding(0, 0, 32, 0, 0)
  ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view)
  self.selectedPet = { index = 0, petId = nil }
end

function GMM_TransmogCompanionsMixin:ConfigureModel() -- TODO: Update this so it's part of a mixin for the model itself
  local companionModel = self.companionModel

  companionModel.isRotating = false
  companionModel.isDragging = false
  companionModel.currentRotation = math.pi * 0.25
  companionModel.currentZoom = 0

  companionModel:SetRotation(companionModel.currentRotation)

  companionModel:SetScript("OnMouseWheel", function(me, delta)
    local sensitivity = 0.5
    me.currentZoom = me.currentZoom + sensitivity * delta

    if me.currentZoom > 1.0 then
      me.currentZoom = 1.0
    elseif me.currentZoom < -5.0 then
      me.currentZoom = -5.0
    end

    local x, y, z = me:GetPosition()
    me:SetPosition(me.currentZoom, y, z)
    me:RefreshCamera()
  end)

  companionModel:SetScript("OnMouseDown", function(me, button)
    if button == "LeftButton" then
      companionModel.isRotating = true
    elseif button == "RightButton" then
      companionModel.isDragging = true
    end

    if button == "MiddleButton" then
      me.currentZoom = 0
      me.currentRotation = math.pi * 0.25
      companionModel:SetRotation(me.currentRotation)
      companionModel:SetPosition(0, 0, 0)
      companionModel:RefreshCamera()
    end
  end)

  companionModel:SetScript("OnMouseUp", function(me, button)
    if button == "LeftButton" then
      companionModel.isRotating = false
    end

    if button == "RightButton" then
      companionModel.isDragging = false
    end
  end)

  companionModel:SetScript("OnUpdate", function()
    if companionModel.isRotating then
      local x, y = GetCursorDelta()
      local sensitivity = 0.005
      companionModel.currentRotation = companionModel.currentRotation + x * sensitivity
      companionModel:SetRotation(companionModel.currentRotation)
    end

    if companionModel.isDragging then
      local posX, posY, posZ = companionModel:GetPosition()
      local cursorX, cursorY = GetCursorDelta()
      local sensitivity = 0.025
      companionModel:SetPosition(posX, posY + cursorX * sensitivity, posZ + cursorY * sensitivity)
    end
  end)
end

--- Pet List Management
--------------------------------------------------------------------------------
function GMM_TransmogCompanionsMixin:UpdatePetList()
  local dataProvider = CreateDataProvider()
  local numPets, ownedPetCount = C_PetJournal.GetNumPets()
  local ownedIds = C_PetJournal.GetOwnedPetIDs()

  for i = 1, ownedPetCount do
    dataProvider:Insert({ index = i, petId = ownedIds[i] })
  end

  self.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
end

function GMM_TransmogCompanionsMixin:InitPetListItem(item, data)
  if not data or not data.petId then
    return
  end

  local speciesID, customName, level, xp, maxXp, displayID, favorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable =
      C_PetJournal.GetPetInfoByPetID(data.petId)

  item.petId = data.petId
  item.index = data.index
  item.icon:SetTexture(icon)

  if customName then
    item.name:SetText(customName)
    item.subName:SetText("(" .. name .. ")")
    item.subName:Show()
  else
    item.name:SetText(name)
    item.subName:Hide()
  end

  if self.selectedPet.petId == data.petId then
    item.selected = true;
    item.selectedTexture:Show()
  else
    item.selected = false
    item.selectedTexture:Hide()
  end

  item:SetScript("OnEnter", function()
    self:SetPetModel(displayID)
  end)

  item:SetScript("OnLeave", function()
    self:SetPetModel(self.selectedPet.displayID)
  end)

  item:SetScript("OnClick", function()
    self:SelectPetByPetID(item.petId)
  end)

  item:Show()
end

function GMM_TransmogCompanionsMixin:SelectPetByPetID(petId)
  local speciesID, customName, level, xp, maxXp, displayID, favorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable =
      C_PetJournal.GetPetInfoByPetID(petId)

  self.selectedPet.petId = petId
  self.selectedPet.displayID = displayID
  self.selectedPet.speciesID = speciesID

  self:UpdatePetList()
end

function GMM_TransmogCompanionsMixin:SetPetModel(displayId)
  local companionModel = self.companionModel

  if displayId then
    companionModel:SetDisplayInfo(displayId)

    companionModel:Show()
  else
    companionModel:Hide()
  end
end

--------------------------------------------------------------------------------
--- PetListButtonMixin
--------------------------------------------------------------------------------

GMM_PetListButtonMixin = {}

function GMM_PetListButtonMixin:OnLoad()
  self:RegisterForClicks("LeftButtonUp")
end

--------------------------------------------------------------------------------
--- CompanionModelMixin
--------------------------------------------------------------------------------

GMM_CompanionModelMixin = {}

function GMM_CompanionModelMixin:OnLoad()

end

function GMM_CompanionModelMixin:Init()
end

function GMM_CompanionModelMixin:Reset()
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
