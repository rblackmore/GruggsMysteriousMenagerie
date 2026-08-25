TransmogWardrobeMixin = {
  HELPTIP_INFO = {
    [Enum.FrameTutorialAccount.TransmogSets] =
    {
      text = TRANSMOG_SETS_HELPTIP,
      buttonStyle = HelpTip.ButtonStyle.Close,
      targetPoint = HelpTip.Point.BottomEdgeCenter,
      alignment = HelpTip.Alignment.Center,
      offsetY = 5,
      system = "TransmogWardrobe",
      acknowledgeOnHide = true,
      cvarBitfield = "closedInfoFramesAccountWide",
      bitfieldFlag = Enum.FrameTutorialAccount.TransmogSets
    },
    [Enum.FrameTutorialAccount.TransmogCustomSets] =
    {
      text = TRANSMOG_CUSTOM_SETS_HELPTIP,
      buttonStyle = HelpTip.ButtonStyle.Close,
      targetPoint = HelpTip.Point.BottomEdgeCenter,
      alignment = HelpTip.Alignment.Center,
      offsetY = 5,
      system = "TransmogWardrobe",
      acknowledgeOnHide = true,
      cvarBitfield = "closedInfoFramesAccountWide",
      bitfieldFlag = Enum.FrameTutorialAccount.TransmogCustomSets
    },
    [Enum.FrameTutorialAccount.TransmogSituations] =
    {
      text = TRANSMOG_SITUATIONS_HELPTIP,
      buttonStyle = HelpTip.ButtonStyle.Close,
      targetPoint = HelpTip.Point.BottomEdgeCenter,
      alignment = HelpTip.Alignment.Center,
      offsetY = 5,
      system = "TransmogWardrobe",
      acknowledgeOnHide = true,
      cvarBitfield = "closedInfoFramesAccountWide",
      bitfieldFlag = Enum.FrameTutorialAccount.TransmogSituations
    },
    [Enum.FrameTutorialAccount.TransmogCustomSetsMigration] =
    {
      text = TRANSMOG_CUSTOM_SETS_MIGRATION_HELPTIP,
      buttonStyle = HelpTip.ButtonStyle.Close,
      targetPoint = HelpTip.Point.BottomEdgeCenter,
      alignment = HelpTip.Alignment.Center,
      offsetY = 5,
      system = "TransmogWardrobe",
      acknowledgeOnHide = true,
      cvarBitfield = "closedInfoFramesAccountWide",
      bitfieldFlag = Enum.FrameTutorialAccount.TransmogCustomSetsMigration
    }
  },
};

function TransmogWardrobeMixin:OnLoad()
  TabSystemOwnerMixin.OnLoad(self);
  self:SetTabSystem(self.TabHeaders);

  self.itemsTabID = self:AddNamedTab(TRANSMOG_TAB_ITEMS, self.TabContent.ItemsFrame);
  self.setsTabID = self:AddNamedTab(TRANSMOG_TAB_SETS, self.TabContent.SetsFrame);
  self.custmSetsTabID = self:AddNamedTab(TRANSMOG_TAB_CUSTOM_SETS, self.TabContent.CustomSetsFrame);
  self.situationsTabID = self:AddNamedTab(TRANSMOG_TAB_SITUATIONS, self.TabContent.SituationsFrame);

  self:UpdateTabs();
  self.TabContent.ItemsFrame:Init(self);
  self.TabContent.SetsFrame:Init(self);
  self.TabContent.CustomSetsFrame:Init(self);
end

function TransmogWardrobeMixin:OnShow()
  self:SetToDefaultAvailableTab();

  -- Situation info may have changed in between showing transmog frame.
  self.TabContent.SituationsFrame:Init();
  self:UpdateTabs();
end

function TransmogWardrobeMixin:OnHide()
  self.TabContent.ItemsFrame:Reset();
end

function TransmogWardrobeMixin:UpdateTabs()
  self.TabHeaders:SetTabShown(self.itemsTabID, true);
  self.TabHeaders:SetTabShown(self.setsTabID, true);
  self.TabHeaders:SetTabShown(self.custmSetsTabID, true);
  self.TabHeaders:SetTabShown(self.situationsTabID, true);
end

function TransmogWardrobeMixin:SetToDefaultAvailableTab()
  self:SetToItemsTab();
end

function TransmogWardrobeMixin:SetToItemsTab()
  if TabSystemOwnerMixin.GetTab(self) ~= self.itemsTabID then
    self:SetTab(self.itemsTabID);
  end
end

function TransmogWardrobeMixin:SetTab(tabID)
  TabSystemOwnerMixin.SetTab(self, tabID);

  self:CheckShowHelptips(tabID);
end

function TransmogWardrobeMixin:CheckShowHelptips(tabID)
  -- Hide any showing wardrobe helptips.
  HelpTip:HideAllSystem("TransmogWardrobe");

  local helpTipParent = self:GetTabButton(tabID);
  local bitfieldFlag;

  -- Only show custom set migration helptip if the player has any custom sets, otherwise mark it as seen and check the other tips.
  if not GetCVarBitfield("closedInfoFramesAccountWide", Enum.FrameTutorialAccount.TransmogCustomSetsMigration) then
    local customSets = C_TransmogCollection.GetCustomSets();
    if #customSets > 0 then
      bitfieldFlag = Enum.FrameTutorialAccount.TransmogCustomSetsMigration;
      helpTipParent = self:GetTabButton(self.custmSetsTabID);
    else
      local helptipInfo = self.HELPTIP_INFO[Enum.FrameTutorialAccount.TransmogCustomSetsMigration];
      if helptipInfo then
        SetCVarBitfield(helptipInfo.cvarBitfield, helptipInfo.bitfieldFlag, true);
      end
    end
  end

  if not bitfieldFlag then
    if tabID == self.setsTabID then
      bitfieldFlag = Enum.FrameTutorialAccount.TransmogSets;
    elseif tabID == self.custmSetsTabID then
      bitfieldFlag = Enum.FrameTutorialAccount.TransmogCustomSets;
    elseif tabID == self.situationsTabID then
      bitfieldFlag = Enum.FrameTutorialAccount.TransmogSituations;
    end
  end

  if bitfieldFlag and not GetCVarBitfield("closedInfoFramesAccountWide", bitfieldFlag) then
    local helptipInfo = self.HELPTIP_INFO[bitfieldFlag];
    if not helptipInfo then
      return;
    end

    HelpTip:Show(helpTipParent, helptipInfo);
  end
end

function TransmogWardrobeMixin:UpdateSlot(slotData, forceRefresh)
  self.TabContent.ItemsFrame:UpdateSlot(slotData, forceRefresh);
  self:SetToItemsTab();
end
