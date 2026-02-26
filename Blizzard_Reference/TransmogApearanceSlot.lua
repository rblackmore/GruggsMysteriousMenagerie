TransmogSlotMixin = {};

function TransmogSlotMixin:OnClick(buttonName)
  if not self.slotData then
    return;
  end

  local outfitSlotInfo = self:GetSlotInfo();
  if not outfitSlotInfo then
    return;
  end

  if buttonName == "LeftButton" then
    PlaySound(SOUNDKIT.UI_TRANSMOG_GEAR_SLOT_CLICK);
    self:OnSelect();
  elseif buttonName == "RightButton" then
    if outfitSlotInfo.hasPending then
      PlaySound(SOUNDKIT.UI_TRANSMOG_REVERTING_GEAR_SLOT);
      C_TransmogOutfitInfo.RevertPendingTransmog(self.slotData.transmogLocation:GetSlot(),
        self.slotData.transmogLocation:GetType(), self.slotData.currentWeaponOptionInfo.weaponOption);
      self:OnSelect();
    end
  end

  self:OnEnter();
end

function TransmogSlotMixin:OnEnter()
  if not self.slotData or not self.slotData.transmogLocation then
    return;
  end

  local outfitSlotInfo = self:GetSlotInfo();
  if not outfitSlotInfo then
    return;
  end

  local function ProcessErrorTooltip()
    if outfitSlotInfo.error == Enum.TransmogOutfitSlotError.Ok then
      return;
    end

    local wrapped = true;
    GameTooltip_AddErrorLine(GameTooltip, outfitSlotInfo.errorText, wrapped);
  end

  local function ProcessWarningTooltip()
    if outfitSlotInfo.warning == Enum.TransmogOutfitSlotWarning.Ok then
      return;
    end

    -- If we are also displaying an error, add a line break.
    if outfitSlotInfo.error ~= Enum.TransmogOutfitSlotError.Ok and outfitSlotInfo.errorText ~= "" then
      GameTooltip_AddBlankLineToTooltip(GameTooltip);
    end

    local wrapped = true;
    GameTooltip_AddErrorLine(GameTooltip, outfitSlotInfo.warningText, wrapped);
  end

  local transmogLocation = self.slotData.transmogLocation;
  if transmogLocation:IsIllusion() then
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");

    local name = C_TransmogCollection.GetIllusionStrings(outfitSlotInfo.transmogID);
    if not name or not outfitSlotInfo.canTransmogrify or outfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Unassigned or outfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Hidden then
      GameTooltip:SetText(WEAPON_ENCHANTMENT);

      if outfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Hidden then
        GameTooltip_AddColoredLine(GameTooltip, TRANSMOGRIFY_TOOLTIP_HIDDEN, TRANSMOGRIFY_FONT_COLOR);
      end
    elseif name then
      GameTooltip:AddLine(name);
    end

    ProcessErrorTooltip();
    ProcessWarningTooltip();

    GameTooltip:Show();
  else
    -- For some edgecases, a player may have a slot set to 'show equipped' with no gear in that slot, which can return the hidden appearance transmogID for correct rendering on the model.
    -- Do not show the hidden item name in this case on the tooltip.
    local isHiddenEquipped = outfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Equipped and
    C_TransmogCollection.IsAppearanceHiddenVisual(outfitSlotInfo.transmogID);

    local itemID = C_TransmogCollection.GetSourceItemID(outfitSlotInfo.transmogID);
    if not itemID or not outfitSlotInfo.canTransmogrify or isHiddenEquipped or outfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Unassigned or outfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Hidden then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");

      -- Use weapon option name if set.
      -- Use different names if slots are split.
      local slot = transmogLocation:GetSlot();
      local slotName = _G[transmogLocation:GetSlotName()];
      if self.slotData.currentWeaponOptionInfo.weaponOption ~= Enum.TransmogOutfitSlotOption.None then
        slotName = self.slotData.currentWeaponOptionInfo.name;
      elseif C_TransmogOutfitInfo.GetSecondarySlotState(slot) then
        if slot == Enum.TransmogOutfitSlot.ShoulderRight then
          slotName = RIGHTSHOULDERSLOT;
        elseif slot == Enum.TransmogOutfitSlot.ShoulderLeft then
          slotName = LEFTSHOULDERSLOT;
        end
      end
      GameTooltip:SetText(slotName);

      if outfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Hidden then
        GameTooltip_AddColoredLine(GameTooltip, TRANSMOGRIFY_TOOLTIP_HIDDEN, TRANSMOGRIFY_FONT_COLOR);
      end

      ProcessErrorTooltip();
      ProcessWarningTooltip();

      GameTooltip:Show();
    elseif itemID then
      local item = Item:CreateFromItemID(itemID);
      self.itemDataLoadedCancelFunc = item:ContinueWithCancelOnItemLoad(function()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip_AddColoredLine(GameTooltip, item:GetItemName(), item:GetItemQualityColor().color);

        ProcessErrorTooltip();
        ProcessWarningTooltip();

        GameTooltip:Show();
      end);
    end
  end
end

function TransmogSlotMixin:OnLeave()
  if self.itemDataLoadedCancelFunc then
    self.itemDataLoadedCancelFunc();
    self.itemDataLoadedCancelFunc = nil;
  end

  GameTooltip:Hide();
end

function TransmogSlotMixin:OnSelect()
  local forceRefresh = false;
  self.slotData.transmogFrame:SelectSlot(self, forceRefresh);
end

function TransmogSlotMixin:Init(slotData)
  self.slotData = slotData;
  self.lastOutfitSlotInfo = nil;
end

function TransmogSlotMixin:Release()
  self:SetSelected(false);
  self:SetParent(nil);
end

function TransmogSlotMixin:GetEffectiveTransmogID()
  local outfitSlotInfo = self:GetSlotInfo();
  if not outfitSlotInfo then
    return Constants.Transmog.NoTransmogID;
  end

  return outfitSlotInfo.transmogID;
end

function TransmogSlotMixin:GetSlotInfo()
  if not self.slotData or not self.slotData.transmogLocation then
    return nil;
  end

  local slotInfo = C_TransmogOutfitInfo.GetViewedOutfitSlotInfo(self.slotData.transmogLocation:GetSlot(),
    self.slotData.transmogLocation:GetType(), self.slotData.currentWeaponOptionInfo.weaponOption);

  -- Some specific weapons may not be able to support illusions.
  if self.slotData.transmogLocation:IsIllusion() then
    local appearanceType = Enum.TransmogType.Appearance;
    local appearanceSlotInfo = C_TransmogOutfitInfo.GetViewedOutfitSlotInfo(self.slotData.transmogLocation:GetSlot(),
      appearanceType, self.slotData.currentWeaponOptionInfo.weaponOption);
    if appearanceSlotInfo then
      -- If we have a valid warning state, make sure it can show relative to other possible warnings.
      local cannotSupportIllusions = appearanceSlotInfo.transmogID ~= Constants.Transmog.NoTransmogID and
      not TransmogUtil.CanEnchantSource(appearanceSlotInfo.transmogID);
      if cannotSupportIllusions and slotInfo.warning < Enum.TransmogOutfitSlotWarning.WeaponDoesNotSupportIllusions then
        slotInfo.warning = Enum.TransmogOutfitSlotWarning.WeaponDoesNotSupportIllusions;
        slotInfo.warningText = TRANSMOGRIFY_ILLUSION_INVALID_ITEM;
      end
    end
  end

  return slotInfo;
end

function TransmogSlotMixin:GetSlot()
  if not self.slotData or not self.slotData.transmogLocation then
    return nil;
  end

  return self.slotData.transmogLocation:GetSlot();
end

function TransmogSlotMixin:GetTransmogLocation()
  if not self.slotData then
    return nil;
  end

  return self.slotData.transmogLocation;
end

function TransmogSlotMixin:GetCurrentWeaponOptionInfo()
  if not self.slotData then
    return nil;
  end

  return self.slotData.currentWeaponOptionInfo;
end

function TransmogSlotMixin:SetCurrentWeaponOptionInfo(weaponOptionInfo)
  if not self.slotData or not weaponOptionInfo.enabled then
    return;
  end

  self.slotData.currentWeaponOptionInfo = weaponOptionInfo;
  if self.slotData.transmogLocation:IsAppearance() then
    C_TransmogOutfitInfo.SetViewedWeaponOptionForSlot(self.slotData.transmogLocation:GetSlot(),
      weaponOptionInfo.weaponOption);
  end
end

function TransmogSlotMixin:SetCurrentWeaponOption(weaponOption)
  if not self.slotData then
    return false;
  end

  -- If weaponOption is not set, set to the first valid option.
  local foundWeaponOption;
  for _index, weaponOptionInfo in ipairs(self.slotData.weaponOptionsInfo) do
    if weaponOptionInfo.enabled and (not weaponOption or weaponOptionInfo.weaponOption == weaponOption) then
      self:SetCurrentWeaponOptionInfo(weaponOptionInfo);
      foundWeaponOption = true;
      break;
    end
  end

  if not foundWeaponOption and self.slotData.artifactOptionsInfo then
    for _index, artifactOptionInfo in ipairs(self.slotData.artifactOptionsInfo) do
      if artifactOptionInfo.enabled and (not weaponOption or artifactOptionInfo.weaponOption == weaponOption) then
        self:SetCurrentWeaponOptionInfo(artifactOptionInfo);
        foundWeaponOption = true;
        break;
      end
    end
  end

  return foundWeaponOption;
end

TransmogAppearanceSlotMixin = CreateFromMixins(TransmogSlotMixin);

TransmogAppearanceSlotMixin.DEFAULT_WEAPON_OPTION_INFO = {
  weaponOption = Enum.TransmogOutfitSlotOption.None,
  name = "",
  enabled = true
};

TransmogAppearanceSlotMixin.DEFAULT_ICON_SIZE = 45;

function TransmogAppearanceSlotMixin:OnLoad()
  self.SavedFrame.Anim:SetScript("OnFinished", function()
    self.SavedFrame:Hide();
    self:Update();
  end);
end

function TransmogAppearanceSlotMixin:OnShow()
  self:Update();
end

function TransmogAppearanceSlotMixin:OnTransmogrifySuccess()
  -- Don't do anything if already animating.
  if not self.slotData or self.SavedFrame:IsShown() then
    return;
  end

  self.SavedFrame:Show();
  self.SavedFrame.Anim:Restart();
end

-- Overridden.
function TransmogAppearanceSlotMixin:Init(slotData)
  TransmogSlotMixin.Init(self, slotData);

  self:RefreshWeaponOptions();

  self.FlyoutDropdown:SetupMenu(function(_dropdown, rootDescription)
    rootDescription:SetTag("MENU_TRANSMOG_WEAPON_OPTIONS");

    local function IsChecked(optionInfo)
      return optionInfo.weaponOption == self.slotData.currentWeaponOptionInfo.weaponOption;
    end

    local function SetChecked(optionInfo)
      if optionInfo == self.slotData.currentWeaponOptionInfo then
        return;
      end

      self:SetCurrentWeaponOptionInfo(optionInfo);

      if self.illusionSlotFrame then
        self.illusionSlotFrame:SetCurrentWeaponOptionInfo(self.slotData.currentWeaponOptionInfo);
      end

      -- Force update selected slot data and refresh visuals based on new weapon option.
      local forceRefresh = true;
      self.slotData.transmogFrame:SelectSlot(self, forceRefresh);
    end

    local function CreateWarningIcon(frame, option)
      -- Do not check this option if it is the current weapon option.
      if self.slotData.currentWeaponOptionInfo.weaponOption == option then
        return;
      end

      if not self.slotData.transmogLocation then
        return;
      end

      -- Only create warning if this weapon option (or any associated illusion slot) has pending changes.
      local outfitSlotInfo = C_TransmogOutfitInfo.GetViewedOutfitSlotInfo(self.slotData.transmogLocation:GetSlot(),
        self.slotData.transmogLocation:GetType(), option);
      local hasSlotChanges = outfitSlotInfo and (outfitSlotInfo.hasPending or outfitSlotInfo.isTransmogrified);

      local hasIllusionSlotChanges = false;
      if self.illusionSlotFrame then
        local outfitIllusionSlotInfo = C_TransmogOutfitInfo.GetViewedOutfitSlotInfo(
        self.illusionSlotFrame:GetTransmogLocation():GetSlot(), self.illusionSlotFrame:GetTransmogLocation():GetType(),
          option);
        hasIllusionSlotChanges = outfitIllusionSlotInfo and
        (outfitIllusionSlotInfo.hasPending or outfitIllusionSlotInfo.isTransmogrified);
      end

      if not hasSlotChanges and not hasIllusionSlotChanges then
        return;
      end

      local warningIcon = frame:AttachTexture();
      warningIcon:SetPoint("RIGHT");
      warningIcon:SetAtlas("transmog-icon-warning-small", TextureKitConstants.UseAtlasSize);
    end

    for _index, weaponOptionInfo in ipairs(self.slotData.weaponOptionsInfo) do
      local elementDescription = rootDescription:CreateRadio(weaponOptionInfo.name, IsChecked, SetChecked,
        weaponOptionInfo);
      elementDescription:AddInitializer(function(frame, _description, _menu)
        CreateWarningIcon(frame, weaponOptionInfo.weaponOption);
      end);
      elementDescription:SetEnabled(weaponOptionInfo.enabled);
    end

    if self.slotData.artifactOptionsInfo and #self.slotData.artifactOptionsInfo > 0 then
      rootDescription:CreateDivider();
      rootDescription:CreateTitle(TRANSMOG_ARTIFACT_OPTIONS_HEADER);

      for _index, artifactOptionInfo in ipairs(self.slotData.artifactOptionsInfo) do
        local elementDescription = rootDescription:CreateRadio(artifactOptionInfo.name, IsChecked, SetChecked,
          artifactOptionInfo);
        elementDescription:AddInitializer(function(frame, _description, _menu)
          CreateWarningIcon(frame, artifactOptionInfo.weaponOption);
        end);
        elementDescription:SetEnabled(artifactOptionInfo.enabled);
      end
    end
  end);
end

-- Overridden.
function TransmogAppearanceSlotMixin:Release()
  TransmogSlotMixin.Release(self);
  self:SetIllusionSlotFrame(nil);
end

function TransmogAppearanceSlotMixin:SetIllusionSlotFrame(illusionSlotFrame)
  self.illusionSlotFrame = illusionSlotFrame;
end

function TransmogAppearanceSlotMixin:GetIllusionSlotFrame()
  return self.illusionSlotFrame;
end

function TransmogAppearanceSlotMixin:SetSelected(selected)
  if not self.slotData then
    return;
  end

  self.SelectedFrame:SetShown(selected);

  if selected then
    local totalOptions = 0;
    if self.slotData.weaponOptionsInfo then
      totalOptions = totalOptions + #self.slotData.weaponOptionsInfo;
    end

    if self.slotData.artifactOptionsInfo then
      totalOptions = totalOptions + #self.slotData.artifactOptionsInfo;
    end

    self.FlyoutDropdown:SetShown(totalOptions > 1);
  else
    self.FlyoutDropdown:Hide();
  end
end

function TransmogAppearanceSlotMixin:RefreshWeaponOptions()
  if not self.slotData or not self.slotData.transmogLocation then
    return;
  end

  -- A weapon slot can have several weapon or artifact options associated with them, and players can select which option they are editing for an outfit via a dropdown.
  -- For example the main hand weapon slot may have both 1 handed and 2 handed weapon options.
  self.slotData.weaponOptionsInfo, self.slotData.artifactOptionsInfo = C_TransmogOutfitInfo.GetWeaponOptionsForSlot(self
  .slotData.transmogLocation:GetSlot());

  if (not self.slotData.weaponOptionsInfo or #self.slotData.weaponOptionsInfo == 0) and (not self.slotData.artifactOptionsInfo or #self.slotData.artifactOptionsInfo == 0) then
    self:SetCurrentWeaponOptionInfo(self.DEFAULT_WEAPON_OPTION_INFO);
  else
    -- See if the current weapon option still exists and is enabled. If it is, use that, otherwise select new option.
    local foundWeaponOption;
    if self.slotData.currentWeaponOptionInfo then
      foundWeaponOption = self:SetCurrentWeaponOption(self.slotData.currentWeaponOptionInfo);
    end

    -- Current option not found, select the preferred first option based on equipped gear for this slot.
    if not foundWeaponOption then
      local equippedWeaponOption = C_TransmogOutfitInfo.GetEquippedSlotOptionFromTransmogSlot(self.slotData
      .transmogLocation:GetSlot());
      if equippedWeaponOption then
        foundWeaponOption = self:SetCurrentWeaponOption(equippedWeaponOption);
      end
    end

    -- No current or preferred option found, select the first valid option instead.
    if not foundWeaponOption then
      local weaponOption = nil;
      foundWeaponOption = self:SetCurrentWeaponOption(weaponOption);
    end

    -- No valid options found, set to default.
    if not foundWeaponOption then
      self:SetCurrentWeaponOptionInfo(self.DEFAULT_WEAPON_OPTION_INFO);
    end
  end

  if self.illusionSlotFrame then
    self.illusionSlotFrame:SetCurrentWeaponOptionInfo(self.slotData.currentWeaponOptionInfo);
  end

  -- Close menu as it could show outdated data.
  self.FlyoutDropdown:CloseMenu();
end

function TransmogAppearanceSlotMixin:Update()
  if not self.slotData or not self.slotData.transmogLocation or not self:IsShown() then
    return;
  end

  local outfitSlotInfo = self:GetSlotInfo();
  if not outfitSlotInfo then
    return;
  end

  self:SetEnabled(outfitSlotInfo.canTransmogrify);

  -- Base icon texture.
  -- The texture will either be whatever is set in outfitSlotInfo, or the default slot texture if unset.
  if outfitSlotInfo.texture then
    self.Icon:SetTexture(outfitSlotInfo.texture);
    self.Icon:SetSize(self.DEFAULT_ICON_SIZE, self.DEFAULT_ICON_SIZE);
  else
    local unassignedAtlas = C_TransmogOutfitInfo.GetUnassignedAtlasForSlot(self.slotData.transmogLocation:GetSlot());
    if unassignedAtlas then
      self.Icon:SetAtlas(unassignedAtlas, TextureKitConstants.UseAtlasSize);
    end
  end

  -- Border art.
  local border = "transmog-gearslot-default";
  if not outfitSlotInfo.canTransmogrify then
    border = "transmog-gearslot-disabled";
  elseif outfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Assigned then
    border = "transmog-gearslot-transmogrified";
  elseif outfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Hidden then
    border = "transmog-gearslot-transmogrified-hidden";
  end

  self.Border:SetAtlas(border, TextureKitConstants.UseAtlasSize);
  self:SetHighlightAtlas(border, "ADD");

  -- Overlay icons.
  self.DisabledIcon:SetShown(not outfitSlotInfo.canTransmogrify);
  self.HiddenVisualIcon:SetShown(outfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Hidden);
  self.ShowEquippedIcon:SetShown(outfitSlotInfo.displayType == Enum.TransmogOutfitDisplayType.Equipped);
  self.WarningFrame:SetShown(outfitSlotInfo.warning ~= Enum.TransmogOutfitSlotWarning.Ok);

  -- Pending frame.
  if outfitSlotInfo.hasPending and not self.SavedFrame:IsShown() then
    self.PendingFrame:Show();
    self.PendingFrame.AnimLoop:Restart();

    -- Only play the intro animation if things actually changed on the slot.
    if not self.lastOutfitSlotInfo or self.lastOutfitSlotInfo.displayType ~= outfitSlotInfo.displayType or (self.lastOutfitSlotInfo.displayType ~= Enum.TransmogOutfitDisplayType.Unassigned and self.lastOutfitSlotInfo.transmogID ~= outfitSlotInfo.transmogID) then
      self.PendingFrame.AnimStart:Restart();
    end
  else
    self.PendingFrame.AnimStart:Stop();
    self.PendingFrame.AnimLoop:Stop();
    self.PendingFrame:Hide();
  end

  self.lastOutfitSlotInfo = outfitSlotInfo;
end

function TransmogAppearanceSlotMixin:GetCurrentIcons()
  -- Collect all icons associated for this slot (and illusion slot, if present) for all weapon option types.
  local transmogIcons = {};

  if not self.slotData then
    return transmogIcons;
  end

  local function PopulateIcons(weaponOption)
    local outfitSlotInfo = C_TransmogOutfitInfo.GetViewedOutfitSlotInfo(self.slotData.transmogLocation:GetSlot(),
      self.slotData.transmogLocation:GetType(), weaponOption);
    if outfitSlotInfo and outfitSlotInfo.texture then
      table.insert(transmogIcons, outfitSlotInfo.texture);
    end

    if self.illusionSlotFrame then
      local outfitIllusionSlotInfo = C_TransmogOutfitInfo.GetViewedOutfitSlotInfo(
      self.illusionSlotFrame:GetTransmogLocation():GetSlot(), self.illusionSlotFrame:GetTransmogLocation():GetType(),
        weaponOption);
      if outfitIllusionSlotInfo and outfitIllusionSlotInfo.texture then
        table.insert(transmogIcons, outfitIllusionSlotInfo.texture);
      end
    end
  end

  if self.slotData.weaponOptionsInfo then
    for _index, weaponOptionInfo in ipairs(self.slotData.weaponOptionsInfo) do
      PopulateIcons(weaponOptionInfo.weaponOption);
    end
  else
    PopulateIcons(self.slotData.currentWeaponOptionInfo.weaponOption);
  end

  return transmogIcons;
end
