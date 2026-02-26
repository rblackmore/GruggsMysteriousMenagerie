TransmogCharacterMixin = {
  DYNAMIC_EVENTS = {
    "VIEWED_TRANSMOG_OUTFIT_SLOT_SAVE_SUCCESS",
    "VIEWED_TRANSMOG_OUTFIT_CHANGED",
    "VIEWED_TRANSMOG_OUTFIT_SLOT_REFRESH",
    "VIEWED_TRANSMOG_OUTFIT_SLOT_WEAPON_OPTION_CHANGED",
    "VIEWED_TRANSMOG_OUTFIT_SECONDARY_SLOTS_CHANGED",
    "TRANSMOG_DISPLAYED_OUTFIT_CHANGED",
    "PLAYER_EQUIPMENT_CHANGED"
  },
  HELPTIP_INFO = {
    text = TRANSMOG_WEAPON_OPTIONS_HELPTIP,
    buttonStyle = HelpTip.ButtonStyle.Close,
    targetPoint = HelpTip.Point.TopEdgeCenter,
    alignment = HelpTip.Alignment.Center,
    system = "TransmogCharacter",
    acknowledgeOnHide = true,
    cvarBitfield = "closedInfoFramesAccountWide",
    bitfieldFlag = Enum.FrameTutorialAccount.TransmogWeaponOptions
  },
};

function TransmogCharacterMixin:OnLoad()
  self.SavedFrame.Anim:SetScript("OnFinished", function()
    self.SavedFrame:Hide();
  end);

  self.HideIgnoredToggle.Checkbox:SetScript("OnClick", function()
    local toggledOn = not GetCVarBool("transmogHideIgnoredSlots");
    if toggledOn then
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    else
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
    end

    SetCVar("transmogHideIgnoredSlots", toggledOn);
    self:RefreshHideIgnoredToggle();
    self:RefreshSlots();
  end);

  self.ClearAllPendingButton:SetScript("OnMouseDown", function(button)
    button.Icon:SetPoint("CENTER", 2, -2);
  end);

  self.ClearAllPendingButton:SetScript("OnMouseUp", function(button)
    button.Icon:SetPoint("CENTER");
  end);

  self.ClearAllPendingButton:SetScript("OnEnter", function(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT");
    GameTooltip:SetText(TRANSMOGRIFY_CLEAR_ALL_PENDING);
  end);

  self.ClearAllPendingButton:SetScript("OnLeave", GameTooltip_Hide);

  self.ClearAllPendingButton:SetScript("OnClick", function()
    PlaySound(SOUNDKIT.UI_TRANSMOG_REVERTING_GEAR_SLOT);
    C_TransmogOutfitInfo.ClearAllPendingTransmogs();
  end);

  local function OnSlotReleased(pool, slot)
    slot:Release();
    Pool_HideAndClearAnchors(pool, slot);
  end
  self.CharacterAppearanceSlotFramePool = CreateFramePool("BUTTON", self, "TransmogAppearanceSlotTemplate",
    OnSlotReleased);
  self.CharacterIllusionSlotFramePool = CreateFramePool("BUTTON", self, "TransmogIllusionSlotTemplate", OnSlotReleased);

  self.ModelScene.ControlFrame:SetModelScene(self.ModelScene);
end

function TransmogCharacterMixin:OnShow()
  local hasAlternateForm, inAlternateForm = C_PlayerInfo.GetAlternateFormInfo();
  if hasAlternateForm then
    self:RegisterUnitEvent("UNIT_FORM_CHANGED", "player");
    self.inAlternateForm = inAlternateForm;
  end
  FrameUtil.RegisterFrameForEvents(self, self.DYNAMIC_EVENTS);

  self.ModelScene:TransitionToModelSceneID(290, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, true);
  self:RefreshPlayerModel();
  self:RefreshHideIgnoredToggle();
end

function TransmogCharacterMixin:OnHide()
  self:UnregisterEvent("UNIT_FORM_CHANGED");
  FrameUtil.UnregisterFrameForEvents(self, self.DYNAMIC_EVENTS);

  self.selectedSlotData = nil;
end

function TransmogCharacterMixin:OnEvent(event, ...)
  if event == "UNIT_FORM_CHANGED" then
    self:HandleFormChanged();
  elseif event == "VIEWED_TRANSMOG_OUTFIT_SLOT_SAVE_SUCCESS" then
    local slot, type, _weaponOption = ...;
    local slotFrame = self:GetSlotFrame(slot, type);
    if slotFrame then
      slotFrame:OnTransmogrifySuccess();

      if not self.SavedFrame:IsShown() then
        self.SavedFrame:Show();
        self.SavedFrame.Anim:Restart();
      end
    end
  elseif event == "VIEWED_TRANSMOG_OUTFIT_SLOT_REFRESH" or event == "TRANSMOG_DISPLAYED_OUTFIT_CHANGED" then
    self:RefreshSlots();
  elseif event == "PLAYER_EQUIPMENT_CHANGED" then
    local clearCurrentWeaponOptionInfo = true;
    self:RefreshSlotWeaponOptions(clearCurrentWeaponOptionInfo);
    self:RefreshSelectedSlot();
  elseif event == "VIEWED_TRANSMOG_OUTFIT_CHANGED" or event == "VIEWED_TRANSMOG_OUTFIT_SECONDARY_SLOTS_CHANGED" then
    self:SetupSlots();
    self:RefreshSelectedSlot();
  elseif event == "VIEWED_TRANSMOG_OUTFIT_SLOT_WEAPON_OPTION_CHANGED" then
    local slot, weaponOption = ...;
    local appearanceType = Enum.TransmogType.Appearance;
    local slotFrame = self:GetSlotFrame(slot, appearanceType);
    if slotFrame then
      slotFrame:SetCurrentWeaponOption(weaponOption);

      local illusionSlotFrame = slotFrame:GetIllusionSlotFrame();
      if illusionSlotFrame then
        illusionSlotFrame:SetCurrentWeaponOptionInfo(slotFrame:GetCurrentWeaponOptionInfo());
      end
    end
  end
end

function TransmogCharacterMixin:Refresh()
  self:RefreshPlayerModel();
  self:RefreshSlots();
end

function TransmogCharacterMixin:HandleFormChanged()
  if IsUnitModelReadyForUI("player") then
    local _hasAlternateForm, inAlternateForm = C_PlayerInfo.GetAlternateFormInfo();
    if self.inAlternateForm ~= inAlternateForm then
      self.inAlternateForm = inAlternateForm;
      self:Refresh();
    end
  end
end

function TransmogCharacterMixin:SetupSlots()
  self.CharacterAppearanceSlotFramePool:ReleaseAll();
  self.CharacterIllusionSlotFramePool:ReleaseAll();

  local slotGroupData = C_TransmogOutfitInfo.GetSlotGroupInfo();
  for _index, groupData in ipairs(slotGroupData) do
    self:SetupSlotSection(groupData);
  end

  if self.selectedSlotData then
    -- Make sure we are selecting the same slot after refreshing our frames, if the slot still exists.
    local slotFrameFound = false;
    if self.selectedSlotData.transmogLocation then
      local slotFrame = self:GetSlotFrame(self.selectedSlotData.transmogLocation:GetSlot(),
        self.selectedSlotData.transmogLocation:GetType());
      if slotFrame then
        slotFrameFound = true;
        slotFrame:SetSelected(true);
      end
    end

    if not slotFrameFound then
      -- Whatever slot we were selecting is no longer present (split slot that is now hidden).
      self.selectedSlotData = nil;
    end
  end
end

function TransmogCharacterMixin:SetupSlotSection(groupData)
  local parentFrame;
  if groupData.position == Enum.TransmogOutfitSlotPosition.Left then
    parentFrame = self.LeftSlots;
  elseif groupData.position == Enum.TransmogOutfitSlotPosition.Right then
    parentFrame = self.RightSlots;
  elseif groupData.position == Enum.TransmogOutfitSlotPosition.Bottom then
    parentFrame = self.BottomSlots;
  end

  -- Appearance slots.
  for index, appearanceInfo in ipairs(groupData.appearanceSlotInfo) do
    local slotFrame = self.CharacterAppearanceSlotFramePool:Acquire();

    local transmogLocation = TransmogUtil.GetTransmogLocation(appearanceInfo.slotName, appearanceInfo.type,
      appearanceInfo.isSecondary);
    local slotData = {
      transmogLocation = transmogLocation,
      transmogFrame = TransmogFrame,
      currentWeaponOptionInfo = nil,
      -- Appearance specific fields.
      weaponOptionsInfo = nil,
      artifactOptionsInfo = nil
    };
    slotFrame.layoutIndex = index;

    slotFrame:Init(slotData);
    slotFrame:SetParent(parentFrame);
    slotFrame:Show();
  end

  -- Illusion slots, should only be created once their corresponding appearance slot is in place as they need to anchor off of it.
  local illusionAnchorOffset = 19;
  local appearanceType = Enum.TransmogType.Appearance;
  for _index, illusionInfo in ipairs(groupData.illusionSlotInfo) do
    local slotFrame = self:GetSlotFrame(illusionInfo.slot, appearanceType);
    assertsafe(slotFrame ~= nil);
    if slotFrame then
      local illusionSlotFrame = self.CharacterIllusionSlotFramePool:Acquire();
      slotFrame:SetIllusionSlotFrame(illusionSlotFrame);

      local transmogLocation = TransmogUtil.GetTransmogLocation(illusionInfo.slotName, illusionInfo.type,
        illusionInfo.isSecondary);
      local illusionSlotData = {
        transmogLocation = transmogLocation,
        transmogFrame = TransmogFrame,
        currentWeaponOptionInfo = slotFrame:GetCurrentWeaponOptionInfo()
      };

      illusionSlotFrame:Init(illusionSlotData);
      illusionSlotFrame:SetParent(slotFrame);
      illusionSlotFrame:SetFrameLevel(300);
      if groupData.position == Enum.TransmogOutfitSlotPosition.Left then
        illusionSlotFrame:SetPoint("RIGHT", slotFrame, "LEFT", -illusionAnchorOffset, 0);
      elseif groupData.position == Enum.TransmogOutfitSlotPosition.Right then
        illusionSlotFrame:SetPoint("LEFT", slotFrame, "RIGHT", illusionAnchorOffset, 0);
      elseif groupData.position == Enum.TransmogOutfitSlotPosition.Bottom then
        illusionSlotFrame:SetPoint("TOP", slotFrame, "BOTTOM", 0, illusionAnchorOffset);
      end
      illusionSlotFrame:Show();
    end
  end

  parentFrame:Layout();
end

function TransmogCharacterMixin:RefreshHideIgnoredToggle()
  if not DisplayTypeUnassignedSupported() then
    self.HideIgnoredToggle:Hide();
    return;
  end;

  local hideIgnored = GetCVarBool("transmogHideIgnoredSlots");
  self.HideIgnoredToggle.Checkbox:SetChecked(hideIgnored);
  self.HideIgnoredToggle.Text:SetFontObject(hideIgnored and "GameFontHighlight" or "GameFontNormal");
end

function TransmogCharacterMixin:RefreshPlayerModel()
  local modelScene = self.ModelScene;
  if modelScene.previousActor then
    modelScene.previousActor:ClearModel();
    modelScene.previousActor = nil;
  end

  local actor = modelScene:GetPlayerActor();
  if actor then
    local sheatheWeapons = false;
    local autoDress = true;
    local hideWeapons = false;
    actor:SetModelByUnit("player", sheatheWeapons, autoDress, hideWeapons, PlayerUtil.ShouldUseNativeFormInModelScene());
    modelScene.previousActor = actor;
  end
end

function TransmogCharacterMixin:RefreshSlotWeaponOptions(clearCurrentWeaponOptionInfo)
  for slotFrame in self.CharacterAppearanceSlotFramePool:EnumerateActive() do
    if clearCurrentWeaponOptionInfo then
      slotFrame:SetCurrentWeaponOptionInfo(slotFrame.DEFAULT_WEAPON_OPTION_INFO);
    end

    slotFrame:RefreshWeaponOptions();
  end
end

function TransmogCharacterMixin:RefreshSlots()
  local actor = self.ModelScene:GetPlayerActor();
  if not actor then
    return;
  end

  for slotFrame in self.CharacterAppearanceSlotFramePool:EnumerateActive() do
    slotFrame:Update();

    -- Slot that was selected is now disabled, will need to select a new slot.
    local selectedSlotTransmogLocation = self.selectedSlotData and self.selectedSlotData.transmogLocation or nil;
    local appearanceSlotTransmogLocation = slotFrame:GetTransmogLocation();
    if appearanceSlotTransmogLocation and selectedSlotTransmogLocation and appearanceSlotTransmogLocation:IsEqual(selectedSlotTransmogLocation) and not slotFrame:IsEnabled() then
      self.selectedSlotData = nil;
    end

    local illusionSlotFrame = slotFrame:GetIllusionSlotFrame();
    if illusionSlotFrame then
      illusionSlotFrame:Update();

      local illusionSlotTransmogLocation = illusionSlotFrame:GetTransmogLocation();
      if illusionSlotTransmogLocation and selectedSlotTransmogLocation and illusionSlotTransmogLocation:IsEqual(selectedSlotTransmogLocation) and not illusionSlotFrame:IsEnabled() then
        self.selectedSlotData = nil;
      end
    end

    -- Only attempt to set a slot's appearance on the actor if this is not a secondary slot (the primary slot will handle things for it).
    local linkedSlotInfo = C_TransmogOutfitInfo.GetLinkedSlotInfo(slotFrame.slotData.transmogLocation:GetSlot());
    if not linkedSlotInfo or linkedSlotInfo.primarySlotInfo.slot == slotFrame.slotData.transmogLocation:GetSlot() then
      -- Secondary slots.
      local secondaryAppearanceID = Constants.Transmog.NoTransmogID;
      if linkedSlotInfo then
        -- Use primary slot option.
        local outfitSlotInfo = C_TransmogOutfitInfo.GetViewedOutfitSlotInfo(linkedSlotInfo.secondarySlotInfo.slot,
          linkedSlotInfo.secondarySlotInfo.type, slotFrame:GetCurrentWeaponOptionInfo().weaponOption);
        if outfitSlotInfo then
          secondaryAppearanceID = outfitSlotInfo.transmogID;
        end
      end

      -- Illusions.
      local illusionID = Constants.Transmog.NoTransmogID;
      if illusionSlotFrame then
        local illusionSlotInfo = illusionSlotFrame:GetSlotInfo();
        if illusionSlotInfo and illusionSlotInfo.warning ~= Enum.TransmogOutfitSlotWarning.WeaponDoesNotSupportIllusions then
          illusionID = illusionSlotInfo.transmogID;
        end
      end

      local transmogLocation = slotFrame:GetTransmogLocation();
      if transmogLocation then
        local slotID = transmogLocation:GetSlotID();
        if slotID ~= nil then
          local appearanceID = slotFrame:GetEffectiveTransmogID();
          local itemTransmogInfo = ItemUtil.CreateItemTransmogInfo(appearanceID, secondaryAppearanceID, illusionID);
          local currentItemTransmogInfo = actor:GetItemTransmogInfo(slotID);

          -- Need the main category for mainhand.
          local mainHandCategoryID;
          local isLegionArtifact = false;
          if transmogLocation:IsMainHand() then
            mainHandCategoryID = C_TransmogOutfitInfo.GetItemModifiedAppearanceEffectiveCategory(appearanceID);
            isLegionArtifact = TransmogUtil.IsCategoryLegionArtifact(mainHandCategoryID);
            itemTransmogInfo:ConfigureSecondaryForMainHand(isLegionArtifact);
          end

          -- Update only if there is a change or it can recurse (offhand is processed first and mainhand might override offhand).
          if not itemTransmogInfo:IsEqual(currentItemTransmogInfo) or isLegionArtifact then
            if appearanceID == Constants.Transmog.NoTransmogID then
              actor:UndressSlot(slotID);
            else
              -- Don't specify a slot for ranged weapons.
              if mainHandCategoryID and TransmogUtil.IsCategoryRangedWeapon(mainHandCategoryID) then
                slotID = nil;
              end
              actor:SetItemTransmogInfo(itemTransmogInfo, slotID);
            end
          end
        end
      end
    end
  end

  -- Select valid slot now that everything has updated if needed.
  if not self.selectedSlotData then
    self:SetInitialSelectedSlot();
  end
end

function TransmogCharacterMixin:RefreshSelectedSlot()
  if not self.selectedSlotData then
    return;
  end

  local slotFrame = self:GetSlotFrame(self.selectedSlotData.transmogLocation:GetSlot(),
    self.selectedSlotData.transmogLocation:GetType());
  if slotFrame then
    local forceRefresh = true;
    TransmogFrame:SelectSlot(slotFrame, forceRefresh);
  end
end

function TransmogCharacterMixin:SetInitialSelectedSlot()
  local function FindValidSlotToSelect(slotsParent)
    for _index, slotFrame in ipairs(slotsParent:GetLayoutChildren()) do
      if slotFrame:IsEnabled() and slotFrame:GetTransmogLocation():IsAppearance() then
        local fromOnClick = false;
        slotFrame:OnSelect(fromOnClick);
        return true;
      end
    end
    return false;
  end

  local selectionFound = FindValidSlotToSelect(self.LeftSlots);

  if not selectionFound then
    selectionFound = FindValidSlotToSelect(self.BottomSlots);
  end

  if not selectionFound then
    selectionFound = FindValidSlotToSelect(self.RightSlots);
  end

  return selectionFound;
end

function TransmogCharacterMixin:UpdateSlot(slotData, forceRefresh)
  if not slotData then
    self.selectedSlotData = nil;
    return;
  end

  if not self.selectedSlotData or (slotData.transmogLocation and self.selectedSlotData.transmogLocation and not slotData.transmogLocation:IsEqual(self.selectedSlotData.transmogLocation)) then
    if self.selectedSlotData and self.selectedSlotData.transmogLocation:IsEitherHand() and not GetCVarBitfield("closedInfoFramesAccountWide", Enum.FrameTutorialAccount.TransmogWeaponOptions) then
      -- If the previous selected slot was either hand slot, and the associated help tip hasn't been acknowledged, mark it as seen as it should have been viewed by now.
      HelpTip:HideAllSystem("TransmogCharacter");
    end

    self.selectedSlotData = slotData;
    local showHelptip = self.selectedSlotData.transmogLocation:IsEitherHand() and
    not GetCVarBitfield("closedInfoFramesAccountWide", Enum.FrameTutorialAccount.TransmogWeaponOptions);
    for slotFrame in self.CharacterAppearanceSlotFramePool:EnumerateActive() do
      local selected = slotFrame.slotData.transmogLocation and self.selectedSlotData.transmogLocation and
      slotFrame.slotData.transmogLocation:IsEqual(self.selectedSlotData.transmogLocation);
      slotFrame:SetSelected(selected);

      if showHelptip and selected then
        -- Help tip parent is dependent on if the flyout dropdown is shown or not.
        local helpTipParent = slotFrame.FlyoutDropdown:IsShown() and slotFrame.FlyoutDropdown or slotFrame;
        HelpTip:Show(helpTipParent, self.HELPTIP_INFO);
      end
    end

    for slotFrame in self.CharacterIllusionSlotFramePool:EnumerateActive() do
      slotFrame:SetSelected(slotFrame.slotData.transmogLocation and self.selectedSlotData.transmogLocation and
      slotFrame.slotData.transmogLocation:IsEqual(self.selectedSlotData.transmogLocation));
    end
  elseif forceRefresh then
    self.selectedSlotData = slotData;
    -- Refresh the visuals on the actor.
    self:RefreshSlots();
  end
end

function TransmogCharacterMixin:GetSelectedSlotData()
  return self.selectedSlotData;
end

function TransmogCharacterMixin:GetSlotFrame(slot, type)
  for slotFrame in self.CharacterAppearanceSlotFramePool:EnumerateActive() do
    if slotFrame.slotData.transmogLocation and slotFrame.slotData.transmogLocation:GetSlot() == slot and slotFrame.slotData.transmogLocation:GetType() == type then
      return slotFrame;
    end
  end

  for slotFrame in self.CharacterIllusionSlotFramePool:EnumerateActive() do
    if slotFrame.slotData.transmogLocation and slotFrame.slotData.transmogLocation:GetSlot() == slot and slotFrame.slotData.transmogLocation:GetType() == type then
      return slotFrame;
    end
  end

  return nil;
end

function TransmogCharacterMixin:GetCurrentTransmogInfo()
  local transmogInfo = {};
  for slotFrame in self.CharacterAppearanceSlotFramePool:EnumerateActive() do
    local transmogLocation = slotFrame:GetTransmogLocation();
    local slotInfo = slotFrame:GetSlotInfo();
    if transmogLocation and not transmogLocation:IsSecondary() and slotInfo and slotInfo.transmogID ~= Constants.Transmog.NoTransmogID then
      transmogInfo[transmogLocation] = {
        transmogID = slotInfo.transmogID,
        hasPending = slotInfo.hasPending
      };
    end

    local illusionSlotFrame = slotFrame:GetIllusionSlotFrame();
    if illusionSlotFrame then
      local illusionTransmogLocation = illusionSlotFrame:GetTransmogLocation();
      local illusionSlotInfo = illusionSlotFrame:GetSlotInfo();

      if illusionTransmogLocation and not illusionTransmogLocation:IsSecondary() and illusionSlotInfo and illusionSlotInfo.transmogID ~= Constants.Transmog.NoTransmogID then
        transmogInfo[illusionTransmogLocation] = {
          transmogID = illusionSlotInfo.transmogID,
          hasPending = illusionSlotInfo.hasPending
        };
      end
    end
  end

  return transmogInfo;
end

function TransmogCharacterMixin:GetCurrentTransmogIcons()
  local transmogIcons = {};
  for slotFrame in self.CharacterAppearanceSlotFramePool:EnumerateActive() do
    local slotFrameIcons = slotFrame:GetCurrentIcons();
    for _index, slotFrameIcon in ipairs(slotFrameIcons) do
      table.insert(transmogIcons, slotFrameIcon);
    end
  end

  return transmogIcons;
end

-- Used for custom set data formats.
function TransmogCharacterMixin:GetItemTransmogInfoList()
  local actor = self.ModelScene:GetPlayerActor();
  if not actor then
    return nil;
  end

  return actor:GetItemTransmogInfoList();
end
