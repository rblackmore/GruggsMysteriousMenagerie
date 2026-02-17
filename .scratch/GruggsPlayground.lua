--------------------------------------------------------------------------------
--- GruggsPlayground Mixin

GruggsPlaygroundMixin = {}

function GruggsPlaygroundMixin:OnLoad()
  PanelTemplates_SetNumTabs(self, 0)

  tinsert(UISpecialFrames, self:GetName())
end

function GruggsPlaygroundMixin:RegisterTab(options)
  local page = options.page
  local text = options.text
  local pageTitle = page.Title
  local index = (self.numTabs or 0) + 1
  local tabName = self:GetName() .. "Tab" .. index

  local tabButton = CreateFrame("Button", tabName, self, "GruggsPlaygroundTabButton")
  tabButton:SetID(index)
  tabButton:SetText(text)
  PanelTemplates_TabResize(tabButton, 4)
  tabButton:ClearAllPoints()

  if index == 1 then
    -- FIRST TAB Anchor to Self
    tabButton:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 11, 2)
  end

  self._pages = self.pages or {}
  self._pages[index] = page
  page:SetParent(self)
  page:Hide()

  PanelTemplates_SetNumTabs(self, index)

  if not self.selectedTab then
    self:SetTab(1)
  end
end

function GruggsPlaygroundMixin:OnMouseDown(button)
  if button == "LeftButton" then
    self:StartMoving()
  end
end

function GruggsPlaygroundMixin:OnMouseUp(button)
  if button == "LeftButton" then
    self:StopMovingOrSizing()
  end
end

function GruggsPlaygroundMixin:OnShow()
  PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
end

function GruggsPlaygroundMixin:OnHide()
  PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
end

function GruggsPlaygroundMixin:SetTab(tabId)
  PanelTemplates_SetTab(self, tabId)
  self:UpdateSelectedTab()
end

function GruggsPlaygroundMixin:GetPageByIndex(index)
  if self._pages then
    return self._pages[index]
  end
end

function GruggsPlaygroundMixin:UpdateSelectedTab()
  local selected = PanelTemplates_GetSelectedTab(self)

  if self._pages then
    for i, page in ipairs(self._pages) do
      if page then
        page:SetShown(i == selected)
      end
    end
  end

  local selectedPage = self:GetPageByIndex(selected)
  
  self:SetTitle(selectedPage.Title or "Gruggs Playground Window")
end

TabButtonMixin = {}

function TabButtonMixin:OnClick(button)
  if button == "LeftButton" then
    local tabId = self:GetID()
    local parent = self:GetParent()
    parent:SetTab(tabId)
    PlaySound(SOUNDKIT.UI_TOYBOX_TABS);
  end
end

--------------------------------------------------------------------------------
--- Some Global helper functions

function GruggsPlayground_ToggleWindow()
  local GruggsPlayground = _G["GruggsPlayground"]

  if GruggsPlayground:IsVisible() then
    GruggsPlayground:Hide()
  else
    GruggsPlayground:Show()
  end
end
