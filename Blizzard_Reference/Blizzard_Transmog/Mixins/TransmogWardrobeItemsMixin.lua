TransmogWardrobeItemsMixin = {
  DYNAMIC_EVENTS = {
    "TRANSMOG_SEARCH_UPDATED",
    "TRANSMOG_COLLECTION_UPDATED",
    "UI_SCALE_CHANGED",
    "DISPLAY_SIZE_CHANGED",
    "TRANSMOG_COLLECTION_CAMERA_UPDATE",
    "VIEWED_TRANSMOG_OUTFIT_CHANGED",
    "VIEWED_TRANSMOG_OUTFIT_SLOT_REFRESH",
    "VIEWED_TRANSMOG_OUTFIT_SECONDARY_SLOTS_CHANGED",
    "VIEWED_TRANSMOG_OUTFIT_SLOT_SAVE_SUCCESS",
    "PLAYER_EQUIPMENT_CHANGED"
  },
  COLLECTION_TEMPLATES = {
    ["COLLECTION_ITEM"] = { template = "TransmogItemModelTemplate", initFunc = TransmogItemModelMixin.Init, resetFunc = TransmogItemModelMixin.Reset }
  },
  WEAPON_DROPDOWN_WIDTH = 168,
  WEAPON_SHEATHE_DROPDOWN_WIDTH = 190,
};

function TransmogWardrobeItemsMixin:OnLoad()
  self:InitFilterButton();
  self.PagedContent:SetElementTemplateData(self.COLLECTION_TEMPLATES);
  self.SearchBox:SetSearchType(self.searchType);
  self.WeaponDropdown:SetWidth(self.WEAPON_DROPDOWN_WIDTH);
  self.WeaponSheatheDropdown:SetWidth(self.WEAPON_SHEATHE_DROPDOWN_WIDTH);

  local function SetPendingDisplayTypeForSlot(displayType)
    local selectedSlotData = self:GetSelectedSlotCallback();
    if not selectedSlotData or not selectedSlotData.transmogLocation then
      return;
    end

    local transmogID = Constants.Transmog.NoTransmogID;
    C_TransmogOutfitInfo.SetPendingTransmog(selectedSlotData.transmogLocation:GetSlot(),
      selectedSlotData.transmogLocation:GetType(), selectedSlotData.currentWeaponOptionInfo.weaponOption, transmogID,
      displayType);
  end

  local displayTypeUnassignedButton = self.DisplayTypes.DisplayTypeUnassignedButton;
  local displayTypeEquippedButton = self.DisplayTypes.DisplayTypeEquippedButton;

  displayTypeUnassignedButton.SavedFrame.Anim:SetScript("OnFinished", function()
    displayTypeUnassignedButton.SavedFrame:Hide();
  end);

  displayTypeUnassignedButton:SetScript("OnLeave", GameTooltip_Hide);

  displayTypeUnassignedButton:SetScript("OnClick", function()
    PlaySound(SOUNDKIT.UI_TRANSMOG_ITEM_CLICK);
    SetPendingDisplayTypeForSlot(Enum.TransmogOutfitDisplayType.Unassigned);
  end);

  displayTypeEquippedButton.SavedFrame.Anim:SetScript("OnFinished", function()
    displayTypeEquippedButton.SavedFrame:Hide();
  end);

  displayTypeEquippedButton:SetScript("OnEnter", function(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT");
    GameTooltip_AddHighlightLine(GameTooltip, TRANSMOG_SLOT_DISPLAY_TYPE_EQUIPPED);
    GameTooltip_AddNormalLine(GameTooltip, TRANSMOG_SLOT_DISPLAY_TYPE_EQUIPPED_TOOLTIP);
    GameTooltip:Show();
  end);

  displayTypeEquippedButton:SetScript("OnLeave", GameTooltip_Hide);

  displayTypeEquippedButton:SetScript("OnClick", function()
    PlaySound(SOUNDKIT.UI_TRANSMOG_ITEM_CLICK);
    SetPendingDisplayTypeForSlot(Enum.TransmogOutfitDisplayType.Equipped);
  end);

  self.SecondaryAppearanceToggle.Checkbox:SetScript("OnClick", function(button)
    local selectedSlotData = self:GetSelectedSlotCallback();
    if not selectedSlotData or not selectedSlotData.transmogLocation then
      return;
    end

    local toggledOn = button:GetChecked();
    if toggledOn then
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    else
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
    end
    C_TransmogOutfitInfo.SetSecondarySlotState(selectedSlotData.transmogLocation:GetSlot(), toggledOn);
    self.SecondaryAppearanceToggle.Text:SetFontObject(toggledOn and "GameFontHighlight" or "GameFontNormal");
  end);

  self:Reset();
  self.DisplayTypes:Layout();
end

function TransmogWardrobeItemsMixin:OnShow()
  local hasAlternateForm, inAlternateForm = C_PlayerInfo.GetAlternateFormInfo();
  if hasAlternateForm then
    self:RegisterUnitEvent("UNIT_FORM_CHANGED", "player");
    self.inAlternateForm = inAlternateForm;
  end
  FrameUtil.RegisterFrameForEvents(self, self.DYNAMIC_EVENTS);

  self:Refresh();
end

function TransmogWardrobeItemsMixin:OnHide()
  self:UnregisterEvent("UNIT_FORM_CHANGED");
  FrameUtil.UnregisterFrameForEvents(self, self.DYNAMIC_EVENTS);
end

function TransmogWardrobeItemsMixin:OnEvent(event, ...)
  if event == "UNIT_FORM_CHANGED" then
    self:HandleFormChanged();
  elseif event == "TRANSMOG_SEARCH_UPDATED" then
    local searchType, collectionType = ...;
    if searchType == self.searchType and collectionType == self.activeCategoryID then
      self:RefreshCollectionEntries();

      if self.jumpToTransmogID then
        self:PageToTransmogID(self.jumpToTransmogID);
        self.jumpToTransmogID = nil;
      end
    end
  elseif event == "TRANSMOG_COLLECTION_UPDATED" then
    self:RefreshCollectionEntries();
  elseif event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" or event == "TRANSMOG_COLLECTION_CAMERA_UPDATE" then
    self:RefreshCameras();
  elseif event == "VIEWED_TRANSMOG_OUTFIT_CHANGED" then
    self:RefreshActiveSlotTitle();
    self:RefreshDisplayTypeButtons();
    self:RefreshSecondaryAppearanceToggle();
    self:RefreshCameras();
    self:RefreshPagedEntry();
  elseif event == "VIEWED_TRANSMOG_OUTFIT_SLOT_REFRESH" then
    self:RefreshDisplayTypeButtons();
    self:RefreshCollectionEntries();
    self:RefreshWeaponSheatheDropdown();
  elseif event == "VIEWED_TRANSMOG_OUTFIT_SECONDARY_SLOTS_CHANGED" then
    self:RefreshActiveSlotTitle();
    self:RefreshCameras();
  elseif event == "VIEWED_TRANSMOG_OUTFIT_SLOT_SAVE_SUCCESS" then
    local slot, type, weaponOption = ...;
    local selectedSlotData = self:GetSelectedSlotCallback();
    if not selectedSlotData or not selectedSlotData.transmogLocation then
      return;
    end

    -- Already set to true, do not stomp if multiple slots are changing.
    if self:GetOutfitSlotSavedState() then
      return;
    end

    local outfitSlotSaved = selectedSlotData.transmogLocation:GetSlot() == slot and
    selectedSlotData.transmogLocation:GetType() == type and
    selectedSlotData.currentWeaponOptionInfo.weaponOption == weaponOption;
    self:SetOutfitSlotSavedState(outfitSlotSaved);
  elseif event == "PLAYER_EQUIPMENT_CHANGED" then
    self:RefreshDisplayTypeButtons();
  end
end

function TransmogWardrobeItemsMixin:OnKeyDown(key)
  if key == WARDROBE_PREV_VISUAL_KEY or key == WARDROBE_NEXT_VISUAL_KEY or key == WARDROBE_UP_VISUAL_KEY or key == WARDROBE_DOWN_VISUAL_KEY then
    self:UpdateSelectedVisualFromKeyPress(key);
    return false;
  end
  return true;
end

function TransmogWardrobeItemsMixin:Init(wardrobeCollection)
  self.wardrobeCollection = wardrobeCollection;
end

function TransmogWardrobeItemsMixin:InitFilterButton()
  self.FilterButton:SetText(SOURCES);

  self.FilterButton:SetupMenu(function(_dropdown, rootDescription)
    rootDescription:SetTag("MENU_TRANSMOG_ITEMS_FILTER");

    rootDescription:CreateButton(CHECK_ALL, function()
      C_TransmogCollection.SetAllSourceTypeFilters(true);
      return MenuResponse.Refresh;
    end);

    rootDescription:CreateButton(UNCHECK_ALL, function()
      C_TransmogCollection.SetAllSourceTypeFilters(false);
      return MenuResponse.Refresh;
    end);

    local function IsChecked(filter)
      return C_TransmogCollection.IsSourceTypeFilterChecked(filter);
    end

    local function SetChecked(filter)
      C_TransmogCollection.SetSourceTypeFilter(filter, not IsChecked(filter));
    end

    for filterIndex = 1, C_TransmogCollection.GetNumTransmogSources() do
      if (C_TransmogCollection.IsValidTransmogSource(filterIndex)) then
        rootDescription:CreateCheckbox(_G["TRANSMOG_SOURCE_" .. filterIndex], IsChecked, SetChecked, filterIndex);
      end
    end
  end);

  self.FilterButton:SetIsDefaultCallback(function()
    return C_TransmogCollection.IsUsingDefaultFilters();
  end);

  self.FilterButton:SetDefaultCallback(function()
    return C_TransmogCollection.SetDefaultFilters();
  end);
end

function TransmogWardrobeItemsMixin:Reset()
  self.activeCategoryID = nil;
  self.lastWeaponCategoryID = nil;
  self.transmogLocation = nil;
  self.weaponSheatheCategoryID = nil;
  self.itemCollectionEntries = nil;
  self.chosenVisualSources = {};
  self.PagedContent:SetDataProvider(CreateDataProvider());
end

function TransmogWardrobeItemsMixin:HandleFormChanged()
  if IsUnitModelReadyForUI("player") then
    local _hasAlternateForm, inAlternateForm = C_PlayerInfo.GetAlternateFormInfo();
    if self.inAlternateForm ~= inAlternateForm then
      self.inAlternateForm = inAlternateForm;
      self:RefreshCollectionEntries();
    end
  end
end

function TransmogWardrobeItemsMixin:Refresh()
  self:RefreshActiveSlotTitle();
  self:RefreshFilterButtons();
  self:RefreshWeaponDropdown();
  self:RefreshDisplayTypeButtons();
  self:RefreshSecondaryAppearanceToggle();
  self:RefreshWeaponSheatheDropdown();
  self:RefreshCollectionEntries();
end

function TransmogWardrobeItemsMixin:RefreshActiveSlotTitle()
  local selectedSlotData = self:GetSelectedSlotCallback();
  if not selectedSlotData or not selectedSlotData.transmogLocation then
    self.ActiveSlotTitle:SetText("");
    return;
  end

  local slotName = _G[selectedSlotData.transmogLocation:GetSlotName()];
  if selectedSlotData.transmogLocation:IsIllusion() then
    slotName = WEAPON_ENCHANTMENT;
  else
    -- Use weapon option name if set.
    -- Use different names if slots are split.
    if selectedSlotData.currentWeaponOptionInfo.weaponOption ~= Enum.TransmogOutfitSlotOption.None then
      slotName = selectedSlotData.currentWeaponOptionInfo.name;
    elseif C_TransmogOutfitInfo.GetSecondarySlotState(selectedSlotData.transmogLocation:GetSlot()) then
      if selectedSlotData.transmogLocation:GetSlot() == Enum.TransmogOutfitSlot.ShoulderRight then
        slotName = RIGHTSHOULDERSLOT;
      elseif selectedSlotData.transmogLocation:GetSlot() == Enum.TransmogOutfitSlot.ShoulderLeft then
        slotName = LEFTSHOULDERSLOT;
      end
    end
  end
  self.ActiveSlotTitle:SetText(slotName);
end

function TransmogWardrobeItemsMixin:RefreshFilterButtons()
  local selectedSlotData = self:GetSelectedSlotCallback();
  if not selectedSlotData or not selectedSlotData.transmogLocation or selectedSlotData.transmogLocation:IsIllusion() then
    self.SearchBox:Hide();
    self.FilterButton:Hide();
    return;
  end

  self.SearchBox:Show();
  self.FilterButton:Show();

  -- Reapply current search, in case the collection has changed.
  self.SearchBox:UpdateSearch();
end

function TransmogWardrobeItemsMixin:RefreshWeaponDropdown()
  if not self.activeCategoryID then
    self.WeaponDropdown:Hide();
    return;
  end

  local selectedSlotData = self:GetSelectedSlotCallback();
  if not selectedSlotData or not selectedSlotData.transmogLocation or selectedSlotData.transmogLocation:IsIllusion() then
    self.WeaponDropdown:Hide();
    return;
  end

  local activeCollectionInfo = C_TransmogOutfitInfo.GetCollectionInfoForSlotAndOption(
  selectedSlotData.transmogLocation:GetSlot(), selectedSlotData.currentWeaponOptionInfo.weaponOption,
    self.activeCategoryID);
  if not activeCollectionInfo or not activeCollectionInfo.isWeapon then
    self.WeaponDropdown:Hide();
    return;
  end

  local validCategories = {};
  for categoryID = FIRST_TRANSMOG_COLLECTION_WEAPON_TYPE, LAST_TRANSMOG_COLLECTION_WEAPON_TYPE do
    local collectionInfo = C_TransmogOutfitInfo.GetCollectionInfoForSlotAndOption(
    selectedSlotData.transmogLocation:GetSlot(), selectedSlotData.currentWeaponOptionInfo.weaponOption, categoryID);
    if collectionInfo and collectionInfo.isWeapon then
      validCategories[categoryID] = collectionInfo.name;
    end
  end

  -- Only show weapon dropdown if there are more than 1 options to choose from.
  if table.count(validCategories) <= 1 then
    self.WeaponDropdown:Hide();
    return;
  end

  self.WeaponDropdown:Show();

  local function IsSelected(categoryID)
    return categoryID == self.activeCategoryID;
  end

  local function SetSelected(categoryID)
    if categoryID ~= self.activeCategoryID then
      self:SetActiveCategory(categoryID);

      -- Reapply current search on new collection.
      self:RefreshFilterButtons();
    end
  end

  self.WeaponDropdown:SetupMenu(function(_dropdown, rootDescription)
    rootDescription:SetTag("MENU_TRANSMOG_WEAPONS_FILTER");

    for categoryID, name in pairs(validCategories) do
      rootDescription:CreateRadio(name, IsSelected, SetSelected, categoryID);
    end
  end);
end

function TransmogWardrobeItemsMixin:RefreshDisplayTypeButtons()
  local unassignedButton = self.DisplayTypes.DisplayTypeUnassignedButton;
  local equippedButton = self.DisplayTypes.DisplayTypeEquippedButton;

  local selectedSlotData = self:GetSelectedSlotCallback();
  if not selectedSlotData or not selectedSlotData.transmogLocation then
    unassignedButton:Hide();
    equippedButton:Hide();
    return;
  end

  local outfitSlotInfo = C_TransmogOutfitInfo.GetViewedOutfitSlotInfo(selectedSlotData.transmogLocation:GetSlot(),
    selectedSlotData.transmogLocation:GetType(), selectedSlotData.currentWeaponOptionInfo.weaponOption);
  if not outfitSlotInfo then
    unassignedButton:Hide();
    equippedButton:Hide();
    return;
  end

  -- Slightly different logic if the current weapon option is an artifact option.
  local artifactOptionSelected = false;
  local artifactOptionsInfo = selectedSlotData.artifactOptionsInfo;
  if not artifactOptionsInfo and selectedSlotData.transmogLocation:IsIllusion() then
    -- Illusions have no knowledge of possible weapon options, try to grab them here.
    local _weaponOptionsInfo;
    _weaponOptionsInfo, artifactOptionsInfo = C_TransmogOutfitInfo.GetWeaponOptionsForSlot(selectedSlotData
    .transmogLocation:GetSlot());
  end

  if artifactOptionsInfo then
    for _index, artifactOptionInfo in ipairs(artifactOptionsInfo) do
      if artifactOptionInfo.weaponOption == selectedSlotData.currentWeaponOptionInfo.weaponOption then
        artifactOptionSelected = true;
        break;
      end
    end
  end

  unassignedButton:Show();
  equippedButton:SetShown(not artifactOptionSelected);

  local function SetDisplayTypeButtonState(displayTypeButton, selected)
    local stateAtlas;
    if selected then
      displayTypeButton.IconFrame.Border:SetAtlas("transmog-appearance-circFrame-active",
        TextureKitConstants.UseAtlasSize);
      displayTypeButton:SetNormalAtlas("common-button-tertiary-depressed-normal", TextureKitConstants.IgnoreAtlasSize);
      displayTypeButton:SetNormalFontObject("GameFontHighlight");

      if outfitSlotInfo.hasPending then
        stateAtlas = "common-button-tertiary-depressed-normal-glow-purple";
      else
        stateAtlas = "common-button-tertiary-depressed-normal-purple";
      end
    else
      displayTypeButton.IconFrame.Border:SetAtlas("transmog-appearance-circframe", TextureKitConstants.UseAtlasSize);
      displayTypeButton:SetNormalAtlas("common-button-tertiary-normal", TextureKitConstants.IgnoreAtlasSize);
      displayTypeButton:SetNormalFontObject("GameFontNormal");
    end

    if stateAtlas then
      displayTypeButton.StateTexture:SetAtlas(stateAtlas, TextureKitConstants.IgnoreAtlasSize);
      displayTypeButton.StateTexture:Show();

      if outfitSlotInfo.hasPending then
        displayTypeButton.PendingFrame:Show();
        displayTypeButton.PendingFrame.Anim:Restart();
      else
        displayTypeButton.PendingFrame.Anim:Stop();
        displayTypeButton.PendingFrame:Hide();
      end

      if self:GetOutfitSlotSavedState() then
        displayTypeButton.SavedFrame:Show();
        displayTypeButton.SavedFrame.Anim:Restart();

        local outfitSlotSaved = false;
        self:SetOutfitSlotSavedState(outfitSlotSaved);
      end
    else
      displayTypeButton.StateTexture:Hide();

      displayTypeButton.PendingFrame.Anim:Stop();
      displayTypeButton.PendingFrame:Hide();
    end

    -- Do not show hover or click states when selected.
    displayTypeButton:SetEnabled(not selected);
  end

  local unassignedAtlas;
  if selectedSlotData.transmogLocation:IsIllusion() then
    unassignedAtlas = "transmog-appearance-unassigned-enchant";
  else
    unassignedAtlas = C_TransmogOutfitInfo.GetUnassignedDisplayAtlasForSlot(selectedSlotData.transmogLocation:GetSlot());
  end

  -- Unassigned Button.
  local buttonText = artifactOptionSelected and TRANSMOG_SLOT_DISPLAY_TYPE_UNASSIGNED_ARTIFACT or
  TRANSMOG_SLOT_DISPLAY_TYPE_UNASSIGNED;
  local tooltipText = artifactOptionSelected and TRANSMOG_SLOT_DISPLAY_TYPE_UNASSIGNED_ARTIFACT_TOOLTIP or
  TRANSMOG_SLOT_DISPLAY_TYPE_UNASSIGNED_TOOLTIP;

  unassignedButton:SetText(buttonText);
  unassignedButton:SetScript("OnEnter", function(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT");
    GameTooltip_AddHighlightLine(GameTooltip, buttonText);
    GameTooltip_AddNormalLine(GameTooltip, tooltipText);
    GameTooltip:Show();
  end);

  unassignedButton.IconFrame.Icon:SetAtlas(unassignedAtlas, TextureKitConstants.UseAtlasSize);

  local isUnassigned = outfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Unassigned;
  SetDisplayTypeButtonState(unassignedButton, isUnassigned);

  -- Equipped Button.
  if equippedButton:IsShown() then
    local equippedIcon = equippedButton.IconFrame.Icon;
    if outfitSlotInfo.warning ~= Enum.TransmogOutfitSlotWarning.Ok then
      equippedIcon:SetAtlas(unassignedAtlas, TextureKitConstants.UseAtlasSize);
    else
      local textureName = GetInventoryItemTexture("player", selectedSlotData.transmogLocation:GetSlotID());
      if textureName then
        equippedIcon:SetTexture(textureName);
      else
        equippedIcon:SetAtlas(unassignedAtlas, TextureKitConstants.UseAtlasSize);
      end
    end

    local isEquipped = outfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Equipped;
    SetDisplayTypeButtonState(equippedButton, isEquipped);
  end
end

function TransmogWardrobeItemsMixin:RefreshSecondaryAppearanceToggle()
  local selectedSlotData = self:GetSelectedSlotCallback();
  if not selectedSlotData or not selectedSlotData.transmogLocation then
    return;
  end

  local slot = selectedSlotData.transmogLocation:GetSlot();
  local hasSecondary = C_TransmogOutfitInfo.SlotHasSecondary(slot);
  if hasSecondary then
    self.SecondaryAppearanceToggle:Show();
    local toggledOn = C_TransmogOutfitInfo.GetSecondarySlotState(slot);
    self.SecondaryAppearanceToggle.Checkbox:SetChecked(toggledOn);
    self.SecondaryAppearanceToggle.Text:SetFontObject(toggledOn and "GameFontHighlight" or "GameFontNormal");
  else
    self.SecondaryAppearanceToggle:Hide();
  end
end

function TransmogWardrobeItemsMixin:RefreshWeaponSheatheDropdown()
  local defaultSheatheCategory = nil;
  self:SetWeaponSheatheCategory(defaultSheatheCategory);

  local selectedSlotData = self:GetSelectedSlotCallback();
  if not selectedSlotData or not selectedSlotData.transmogLocation or selectedSlotData.transmogLocation:IsIllusion() or not (selectedSlotData.transmogLocation:IsEitherHand() or selectedSlotData.transmogLocation:IsRangedSlot()) then
    self.WeaponSheatheDropdown:Hide();
    return;
  end

  local outfitSlotInfo = C_TransmogOutfitInfo.GetViewedOutfitSlotInfo(selectedSlotData.transmogLocation:GetSlot(),
    selectedSlotData.transmogLocation:GetType(), selectedSlotData.currentWeaponOptionInfo.weaponOption);
  if not outfitSlotInfo or outfitSlotInfo.transmogID == Constants.Transmog.NoTransmogID or outfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Unassigned then
    self.WeaponSheatheDropdown:Hide();
    return;
  end

  self:SetWeaponSheatheCategory(outfitSlotInfo.sheatheCategory);

  local categoryInfo = C_TransmogOutfitInfo.GetAllTransmogOutfitOptionSheatheCategoryInfo(outfitSlotInfo.transmogID);
  if not categoryInfo or #categoryInfo <= 1 then
    self.WeaponSheatheDropdown:Hide();
    return;
  end

  self.WeaponSheatheDropdown:Show();

  local function IsSelected(categoryID)
    return categoryID == self.weaponSheatheCategoryID;
  end

  local function SetSelected(categoryID)
    if categoryID ~= self.weaponSheatheCategoryID then
      self:SetWeaponSheatheCategory(categoryID);

      C_TransmogOutfitInfo.SetPendingTransmogSheatheCategory(selectedSlotData.transmogLocation:GetSlot(),
        selectedSlotData.currentWeaponOptionInfo.weaponOption, self.weaponSheatheCategoryID);
    end
  end

  self.WeaponSheatheDropdown:SetupMenu(function(_dropdown, rootDescription)
    rootDescription:SetTag("MENU_TRANSMOG_WEAPONS_SHEATHE_FILTER");

    for _index, category in ipairs(categoryInfo) do
      rootDescription:CreateRadio(category.categoryName, IsSelected, SetSelected, category.sheatheCategory);
    end
  end);
end

function TransmogWardrobeItemsMixin:RefreshCollectionEntries()
  if not self.transmogLocation or not self.activeCategoryID then
    return;
  end

  if self.transmogLocation:IsIllusion() then
    self.itemCollectionEntries = C_TransmogCollection.GetIllusions(self.activeCategoryID);
  else
    self.itemCollectionEntries = C_TransmogCollection.GetCategoryAppearances(self.activeCategoryID,
      self.transmogLocation:GetData());
  end

  local retainCurrentPage = true;
  self:SetCollectionEntries(self.itemCollectionEntries, retainCurrentPage);
end

function TransmogWardrobeItemsMixin:RefreshCameras()
  self.PagedContent:ForEachFrame(function(frame)
    frame:RefreshItemCamera();
  end);
end

function TransmogWardrobeItemsMixin:RefreshPagedEntry()
  local selectedSlotData = self:GetSelectedSlotCallback();
  if not selectedSlotData or not selectedSlotData.transmogLocation then
    return;
  end

  local outfitSlotInfo = C_TransmogOutfitInfo.GetViewedOutfitSlotInfo(selectedSlotData.transmogLocation:GetSlot(),
    selectedSlotData.transmogLocation:GetType(), selectedSlotData.currentWeaponOptionInfo.weaponOption);
  if not outfitSlotInfo or outfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Unassigned or outfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Equipped then
    self.PagedContent.PagingControls:SetCurrentPage(1);
  else
    self:PageToTransmogID(outfitSlotInfo.transmogID);
  end
end

function TransmogWardrobeItemsMixin:SelectVisual(visualID)
  if not self.transmogLocation then
    return;
  end

  local sourceID;
  if self.transmogLocation:IsAppearance() then
    local mustBeUsable = true;
    sourceID = self:GetAnAppearanceSourceFromVisual(visualID, mustBeUsable);
  else
    for _index, itemEntry in ipairs(self.itemCollectionEntries) do
      if itemEntry.visualID == visualID then
        sourceID = itemEntry.sourceID;
        break;
      end
    end
  end

  -- Artifacts from other specs will not have something valid
  if sourceID ~= Constants.Transmog.NoTransmogID then
    local selectedSlotData = self:GetSelectedSlotCallback();
    if not selectedSlotData or not selectedSlotData.transmogLocation then
      return;
    end

    local displayType = Enum.TransmogOutfitDisplayType.Assigned;
    if selectedSlotData.transmogLocation:IsAppearance() then
      if C_TransmogCollection.IsAppearanceHiddenVisual(sourceID) then
        displayType = Enum.TransmogOutfitDisplayType.Hidden;
      end
    else
      if C_TransmogCollection.IsSpellItemEnchantmentHiddenVisual(sourceID) then
        displayType = Enum.TransmogOutfitDisplayType.Hidden;
      end
    end
    C_TransmogOutfitInfo.SetPendingTransmog(selectedSlotData.transmogLocation:GetSlot(),
      selectedSlotData.transmogLocation:GetType(), selectedSlotData.currentWeaponOptionInfo.weaponOption, sourceID,
      displayType);

    PlaySound(SOUNDKIT.UI_TRANSMOG_ITEM_CLICK);
  end
end

function TransmogWardrobeItemsMixin:UpdateSelectedVisualFromKeyPress(key)
  local selectedSlotData = self:GetSelectedSlotCallback();
  if not selectedSlotData or not selectedSlotData.transmogLocation then
    return;
  end

  -- Keyboard navigation only works if selecting something in the paged grid.
  local outfitSlotInfo = C_TransmogOutfitInfo.GetViewedOutfitSlotInfo(selectedSlotData.transmogLocation:GetSlot(),
    selectedSlotData.transmogLocation:GetType(), selectedSlotData.currentWeaponOptionInfo.weaponOption);
  if not outfitSlotInfo or outfitSlotInfo.transmogID == NoTransmogID or outfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Unassigned or outfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Equipped then
    return;
  end

  -- Get the current index relative to the entire displayed collection.
  local startingIndex = self.PagedContent:FindIndexByPredicate(function(elementData)
    if selectedSlotData.transmogLocation:IsAppearance() then
      local mustBeUsable = true;
      local sourceID = self:GetAnAppearanceSourceFromVisual(elementData.appearanceInfo.visualID, mustBeUsable);

      return sourceID == outfitSlotInfo.transmogID;
    else
      return elementData.appearanceInfo.sourceID == outfitSlotInfo.transmogID;
    end
  end);

  -- Could happen if the selected item is filtered out.
  if startingIndex == nil then
    return;
  end

  -- Find the updated target index that we should navigate to.
  local contentSize = self.PagedContent:GetSize();
  local templateKey = "COLLECTION_ITEM";
  local viewIndex = 1;
  local maxColumns, maxRows = self.PagedContent:TryGetMaxGridCountForTemplateInView(templateKey, viewIndex);
  if maxColumns == nil or maxRows == nil then
    return;
  end

  -- If moving would go past the ends, cap to the end. If on the end to start, wrap to the other cap.
  -- Moving up/down jumps a whole row.
  local targetIndex = startingIndex;
  if key == WARDROBE_PREV_VISUAL_KEY then
    targetIndex = targetIndex - 1;
    if targetIndex <= 0 then
      targetIndex = contentSize;
    end
  elseif key == WARDROBE_NEXT_VISUAL_KEY then
    targetIndex = targetIndex + 1;
    if targetIndex > contentSize then
      targetIndex = 1;
    end
  elseif key == WARDROBE_UP_VISUAL_KEY then
    if targetIndex == 1 then
      targetIndex = contentSize;
    else
      targetIndex = targetIndex - maxColumns;
      if targetIndex <= 0 then
        targetIndex = 1;
      end
    end
  elseif key == WARDROBE_DOWN_VISUAL_KEY then
    if targetIndex == contentSize then
      targetIndex = 1;
    else
      targetIndex = targetIndex + maxColumns;
      if targetIndex > contentSize then
        targetIndex = contentSize;
      end
    end
  end

  if targetIndex == startingIndex then
    return;
  end

  -- Select and page to new index.
  local targetElementData = self.PagedContent:GetElementDataByIndex(targetIndex);
  if self.transmogLocation:IsAppearance() then
    local mustBeUsable = true;
    local sourceID = self:GetAnAppearanceSourceFromVisual(targetElementData.appearanceInfo.visualID, mustBeUsable);

    local itemID = C_Transmog.GetItemIDForSource(sourceID);
    if not itemID then
      return;
    end

    -- Handles sparse cases, ensures things can be validly selected.
    local item = Item:CreateFromItemID(itemID);
    item:ContinueOnItemLoad(function()
      -- Since the player may have run another key press while waiting here on a previous item, make sure the starting info is still the same to ensure a valid state.
      local currentOutfitSlotInfo = C_TransmogOutfitInfo.GetViewedOutfitSlotInfo(
      selectedSlotData.transmogLocation:GetSlot(), selectedSlotData.transmogLocation:GetType(),
        selectedSlotData.currentWeaponOptionInfo.weaponOption);
      if currentOutfitSlotInfo.transmogID ~= outfitSlotInfo.transmogID or currentOutfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Unassigned or currentOutfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Equipped then
        return;
      end

      self:SelectVisual(targetElementData.appearanceInfo.visualID);
      self:RefreshPagedEntry();
    end);
  else
    self:SelectVisual(targetElementData.appearanceInfo.visualID);
    self:RefreshPagedEntry();
  end
end

function TransmogWardrobeItemsMixin:GetAnAppearanceSourceFromVisual(visualID, mustBeUsable)
  if not self.transmogLocation or not self.activeCategoryID then
    return nil;
  end

  local sourceID = self:GetChosenVisualSource(visualID);
  if sourceID == Constants.Transmog.NoTransmogID then
    local sources = CollectionWardrobeUtil.GetSortedAppearanceSources(visualID, self.activeCategoryID,
      self.transmogLocation);
    for _index, source in ipairs(sources) do
      -- First 1 if it doesn't have to be usable
      if not mustBeUsable or self:IsAppearanceUsableForActiveCategory(source) then
        sourceID = source.sourceID;
        break;
      end
    end
  end
  return sourceID;
end

function TransmogWardrobeItemsMixin:GetChosenVisualSource(visualID)
  return self.chosenVisualSources[visualID] or Constants.Transmog.NoTransmogID;
end

function TransmogWardrobeItemsMixin:SetChosenVisualSource(visualID, sourceID)
  self.chosenVisualSources[visualID] = sourceID;
end

function TransmogWardrobeItemsMixin:ValidateChosenVisualSources()
  for visualID, sourceID in pairs(self.chosenVisualSources) do
    if sourceID ~= Constants.Transmog.NoTransmogID then
      local keep = false;
      local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID);
      if sourceInfo and sourceInfo.isCollected and not sourceInfo.useError then
        keep = true;
      end

      if not keep then
        self.chosenVisualSources[visualID] = Constants.Transmog.NoTransmogID;
      end
    end
  end
end

function TransmogWardrobeItemsMixin:IsAppearanceUsableForActiveCategory(appearanceInfo)
  if not self.activeCategoryID then
    return false;
  end

  local inLegionArtifactCategory = TransmogUtil.IsCategoryLegionArtifact(self.activeCategoryID);
  return CollectionWardrobeUtil.IsAppearanceUsable(appearanceInfo, inLegionArtifactCategory);
end

function TransmogWardrobeItemsMixin:GetAppearanceNameTextAndColor(appearanceInfo)
  if not self.activeCategoryID then
    return nil, nil;
  end

  local inLegionArtifactCategory = TransmogUtil.IsCategoryLegionArtifact(self.activeCategoryID);
  return CollectionWardrobeUtil.GetAppearanceNameTextAndColor(appearanceInfo, inLegionArtifactCategory);
end

function TransmogWardrobeItemsMixin:SetAppearanceTooltip(frame)
  GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
  self.tooltipModel = frame;
  self.tooltipVisualID = frame:GetAppearanceInfo().visualID;
  self:RefreshAppearanceTooltip();
end

function TransmogWardrobeItemsMixin:RefreshAppearanceTooltip()
  if not self.tooltipVisualID or not self.transmogLocation or not self.activeCategoryID then
    return;
  end

  local sources = CollectionWardrobeUtil.GetSortedAppearanceSourcesForClass(self.tooltipVisualID,
    C_TransmogCollection.GetClassFilter(), self.activeCategoryID, self.transmogLocation);
  local appearanceData = {
    sources = sources,
    primarySourceID = self:GetChosenVisualSource(self.tooltipVisualID),
    selectedIndex = nil,
    showUseError = true,
    inLegionArtifactCategory = TransmogUtil.IsCategoryLegionArtifact(self.activeCategoryID),
    subheaderString = nil,
    warningString = CollectionWardrobeUtil.GetBestVisibilityWarning(self.tooltipModel, self.transmogLocation, sources),
    showTrackingInfo = false,
    slotType = nil
  }

  local _tooltipSourceIndex, _tooltipCycle = CollectionWardrobeUtil.SetAppearanceTooltip(GameTooltip, appearanceData);
end

function TransmogWardrobeItemsMixin:ClearAppearanceTooltip()
  self.tooltipModel = nil;
  self.tooltipVisualID = nil;
  GameTooltip:Hide();
end

function TransmogWardrobeItemsMixin:SetCollectionEntries(entries, retainCurrentPage)
  local compareEntries = function(element1, element2)
    local source1 = element1.appearanceInfo;
    local source2 = element2.appearanceInfo;

    if source1.isCollected ~= source2.isCollected then
      return source1.isCollected;
    end

    if source1.isUsable ~= source2.isUsable then
      return source1.isUsable;
    end

    if source1.isFavorite ~= source2.isFavorite then
      return source1.isFavorite;
    end

    if source1.canDisplayOnPlayer ~= source2.canDisplayOnPlayer then
      return source1.canDisplayOnPlayer;
    end

    if source1.isHideVisual ~= source2.isHideVisual then
      return source1.isHideVisual;
    end

    if source1.hasActiveRequiredHoliday ~= source2.hasActiveRequiredHoliday then
      return source1.hasActiveRequiredHoliday;
    end

    if source1.uiOrder and source2.uiOrder then
      return source1.uiOrder > source2.uiOrder;
    end

    return source1.sourceID > source2.sourceID;
  end

  local collectionElements = {};
  for _index, itemEntry in ipairs(entries) do
    if (itemEntry.isUsable and itemEntry.isCollected) or itemEntry.alwaysShowItem then
      local element = {
        templateKey = "COLLECTION_ITEM",
        appearanceInfo = itemEntry,
        collectionFrame = self
      };
      table.insert(collectionElements, element);
    end
  end

  table.sort(collectionElements, compareEntries);

  local collectionData = { { elements = collectionElements } };
  local dataProvider = CreateDataProvider(collectionData);
  self.PagedContent:SetDataProvider(dataProvider, retainCurrentPage);
end

function TransmogWardrobeItemsMixin:UpdateSlot(slotData, forceRefresh)
  if not slotData then
    return;
  end

  local transmogLocation = slotData.transmogLocation;
  if transmogLocation then
    local outfitSlotInfo = C_TransmogOutfitInfo.GetViewedOutfitSlotInfo(transmogLocation:GetSlot(),
      transmogLocation:GetType(), slotData.currentWeaponOptionInfo.weaponOption);
    if outfitSlotInfo then
      local isUnassignedOrEquipped = outfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Unassigned or
      outfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Equipped;
      if not transmogLocation:IsEqual(self.transmogLocation) or forceRefresh then
        self:SetActiveSlot(transmogLocation, forceRefresh);

        -- If initially setting to a new category and not one of the display type buttons, make sure we can correctly page to the entry we want once search filters update.
        if not isUnassignedOrEquipped then
          self.jumpToTransmogID = outfitSlotInfo.transmogID;
        end
      end

      if isUnassignedOrEquipped then
        self.PagedContent.PagingControls:SetCurrentPage(1);
      else
        self:PageToTransmogID(outfitSlotInfo.transmogID);
      end
    end
  end

  -- Force update filters to show collected or not.
  C_TransmogCollection.SetCollectedShown(transmogLocation ~= nil);
end

function TransmogWardrobeItemsMixin:GetActiveSlotInfo()
  return TransmogUtil.GetInfoForEquippedSlot(self.transmogLocation);
end

function TransmogWardrobeItemsMixin:SetActiveSlot(transmogLocation, forceRefresh)
  self:SetTransmogLocation(transmogLocation);
  local activeSlotInfo = self:GetActiveSlotInfo();

  -- Figure out a category.
  local categoryID;
  local useLastWeaponCategory = not forceRefresh and self.transmogLocation:IsEitherHand() and self.lastWeaponCategoryID and
  self:IsValidWeaponCategoryForSlot(self.lastWeaponCategoryID);
  if useLastWeaponCategory then
    categoryID = self.lastWeaponCategoryID;
  elseif activeSlotInfo.selectedSourceID ~= Constants.Transmog.NoTransmogID then
    local appearanceSourceInfo = C_TransmogCollection.GetAppearanceSourceInfo(activeSlotInfo.selectedSourceID);
    categoryID = appearanceSourceInfo and appearanceSourceInfo.category;
    if categoryID and not self:IsValidWeaponCategoryForSlot(categoryID) then
      categoryID = nil;
    end
  end

  if not categoryID then
    if self.transmogLocation:IsEitherHand() or self.transmogLocation:IsRangedSlot() then
      -- Find the first valid weapon category.
      for weaponCategoryID = FIRST_TRANSMOG_COLLECTION_WEAPON_TYPE, LAST_TRANSMOG_COLLECTION_WEAPON_TYPE do
        if self:IsValidWeaponCategoryForSlot(weaponCategoryID) then
          categoryID = weaponCategoryID;
          break;
        end
      end
    else
      categoryID = self.transmogLocation:GetArmorCategoryID();
    end
  end

  if categoryID and categoryID ~= self.activeCategoryID then
    self:SetActiveCategory(categoryID);
  end

  self:Refresh();
end

function TransmogWardrobeItemsMixin:IsValidWeaponCategoryForSlot(categoryID)
  local selectedSlotData = self:GetSelectedSlotCallback();
  if not selectedSlotData or not selectedSlotData.transmogLocation then
    return false;
  end

  local collectionInfo = C_TransmogOutfitInfo.GetCollectionInfoForSlotAndOption(
  selectedSlotData.transmogLocation:GetSlot(), selectedSlotData.currentWeaponOptionInfo.weaponOption, categoryID);
  return collectionInfo and collectionInfo.isWeapon;
end

function TransmogWardrobeItemsMixin:PageToTransmogID(transmogID)
  if transmogID == Constants.Transmog.NoTransmogID then
    self.PagedContent.PagingControls:SetCurrentPage(1);
    return;
  end

  self.PagedContent:GoToElementByPredicate(function(elementData)
    if self.transmogLocation:IsAppearance() then
      local mustBeUsable = true;
      local sourceID = self:GetAnAppearanceSourceFromVisual(elementData.appearanceInfo.visualID, mustBeUsable);

      return sourceID == transmogID;
    else
      return elementData.appearanceInfo.sourceID == transmogID;
    end
  end);
end

function TransmogWardrobeItemsMixin:GetActiveCategory()
  return self.activeCategoryID;
end

function TransmogWardrobeItemsMixin:SetActiveCategory(categoryID)
  if self.activeCategoryID == categoryID then
    return;
  end

  self.activeCategoryID = categoryID;

  local selectedSlotData = self:GetSelectedSlotCallback();
  if not selectedSlotData or not selectedSlotData.transmogLocation or not self.transmogLocation then
    return;
  end

  if self.transmogLocation:IsAppearance() then
    C_TransmogCollection.SetSearchAndFilterCategory(self.activeCategoryID);
    local collectionInfo = C_TransmogOutfitInfo.GetCollectionInfoForSlotAndOption(
    selectedSlotData.transmogLocation:GetSlot(), selectedSlotData.currentWeaponOptionInfo.weaponOption,
      self.activeCategoryID);
    if collectionInfo and collectionInfo.isWeapon then
      self.lastWeaponCategoryID = self.activeCategoryID;
    end
  end
end

function TransmogWardrobeItemsMixin:GetTransmogLocation()
  return self.transmogLocation;
end

function TransmogWardrobeItemsMixin:SetTransmogLocation(transmogLocation)
  self.transmogLocation = transmogLocation;
end

function TransmogWardrobeItemsMixin:GetWeaponSheatheCategory()
  return self.weaponSheatheCategoryID;
end

function TransmogWardrobeItemsMixin:SetWeaponSheatheCategory(categoryID)
  if self.weaponSheatheCategoryID == categoryID then
    return;
  end

  self.weaponSheatheCategoryID = categoryID;
end

function TransmogWardrobeItemsMixin:GetActiveSlot()
  return self.transmogLocation and self.transmogLocation:GetSlotName();
end

function TransmogWardrobeItemsMixin:HasActiveSecondaryAppearance()
  local secondaryAppearanceToggle = self.SecondaryAppearanceToggle;
  return secondaryAppearanceToggle:IsShown() and secondaryAppearanceToggle.Checkbox:GetChecked();
end

function TransmogWardrobeItemsMixin:GetOutfitSlotSavedState()
  return self.outfitSlotSaved;
end

function TransmogWardrobeItemsMixin:SetOutfitSlotSavedState(outfitSlotSaved)
  self.outfitSlotSaved = outfitSlotSaved;
end

function TransmogWardrobeItemsMixin:GetSelectedSlotCallback()
  return self.wardrobeCollection.GetSelectedSlotCallback();
end

function TransmogWardrobeItemsMixin:GetSlotFrameCallback(slot, type)
  return self.wardrobeCollection.GetSlotFrameCallback(slot, type);
end
