GMMPetListMixin = {}
local EVENTS_TO_REGISTER = { "TRANSMOGRIFY_OPEN" }
function GMMPetListMixin:OnLoad()
  for i, event in ipairs(EVENTS_TO_REGISTER) do
    self:RegisterEvent(event)
  end

  self:ConfigureScrollView()
  self:ConfigureModel()
end

function GMMPetListMixin:ConfigureScrollView()
  local view = CreateScrollBoxListLinearView()
  view:SetElementInitializer("GMMPetListButton", function(item, data)
    self:InitPetListItem(item, data)
  end)
  view:SetPadding(0, 0, 32, 0, 0)
  ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view)
  self.selectedPet = { index = 0, petId = nil }
end

function GMMPetListMixin:ConfigureModel()
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
    print(me:GetPosition())
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

function GMMPetListMixin:OnShow()
  self:UpdatePetList()
end

function GMMPetListMixin:OnHide()
end

function GMMPetListMixin:OnEvent(event, ...)
  if event == "TRANSMOGRIFY_OPEN" then
    C_Timer.After(0.1, function()
      TransmogFrame.WardrobeCollection:AddNamedTab("Companions", self)
    end)
  end
end

function GMMPetListMixin:UpdatePetList()
  local dataProvider = CreateDataProvider()
  local numPets, ownedPetCount = C_PetJournal.GetNumPets()
  local ownedIds = C_PetJournal.GetOwnedPetIDs()

  for i = 1, ownedPetCount do
    dataProvider:Insert({ index = i, petId = ownedIds[i] })
  end

  self.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
end

function GMMPetListMixin:InitPetListItem(item, data)
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

function GMMPetListMixin:SelectPetByPetID(petId)
  local speciesID, customName, level, xp, maxXp, displayID, favorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable =
      C_PetJournal.GetPetInfoByPetID(petId)

  self.selectedPet.petId = petId
  self.selectedPet.displayID = displayID
  self.selectedPet.speciesID = speciesID

  self:UpdatePetList()
end

function GMMPetListMixin:SetPetModel(displayId)
  local companionModel = self.companionModel

  if displayId then
    companionModel:SetDisplayInfo(displayId)

    companionModel:Show()
  else
    companionModel:Hide()
  end
end

PetListButtonMixin = {}

function PetListButtonMixin:OnLoad()
  self:RegisterForClicks("LeftButtonUp")
end
