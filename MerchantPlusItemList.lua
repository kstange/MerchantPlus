--
-- Merchant Plus
-- A Modern Scrollable UI for Merchants
--
-- Copyright 2023 - 2024 SimGuy
--
-- Use of this source code is governed by an MIT-style
-- license that can be found in the LICENSE file or at
-- https://opensource.org/licenses/MIT.
--

local _, Shared = ...

-- Import a shared trace function if one exists
local trace = Shared.Trace or function() end

MerchantPlusItemListMixin = {}

-- On load, set up the nineslice. The nineslice doesn't seem to work if defined in XML.
function MerchantPlusItemListMixin:OnLoad()
	trace("called: OnLoad")
	self.NineSlice:ClearAllPoints()
	self.NineSlice:SetPoint("TOPLEFT", self.HeaderContainer, "BOTTOMLEFT")
	self.NineSlice:SetPoint("BOTTOMRIGHT")
end

-- Before the widget is shown, set it up to show results
function MerchantPlusItemListMixin:OnShow()
	trace("called: OnShow")
	self:Init()
	self:UpdateTableBuilderLayout()
	self:RefreshScrollFrame()
	self.ScrollBox:ScrollToBegin()
end

-- Before the widget is hidden, clean up stuff
function MerchantPlusItemListMixin:OnHide()
	trace("called: OnHide")
end

-- On init, we will need to create various structures
function MerchantPlusItemListMixin:Init()
	trace("called: Init")
	if self.initialized then
		return
	end

	local view = CreateScrollBoxListLinearView()

	view:SetElementFactory(function(factory)
		factory("MerchantPlusItemListLineTemplate", function() end)
	end)

	ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view)

	local tableBuilder = CreateTableBuilder(nil)
	self.tableBuilder = tableBuilder

	ScrollUtil.RegisterTableBuilder(self.ScrollBox, tableBuilder, function(elementData)
		return elementData
	end)

	self.tableBuilder:SetHeaderContainer(self.HeaderContainer)
	self.tableBuilder:SetDataProvider(self.GetDataRow)

	self.initialized = true
end

-- Update the layout of the table.
function MerchantPlusItemListMixin:UpdateTableBuilderLayout()
	trace("called: UpdateTableBuilderLayout")
	if not self.initialized then
		return
	end

	self.tableBuilder:Reset()
	if self.SetTableLayout then
		self:SetTableLayout()
	end
	self.tableBuilder:SetTableWidth(self.ScrollBox:GetWidth())
	self.tableBuilder:Arrange()
end

-- Add a column to the TableBuilder
function MerchantPlusItemListMixin:AddColumn(key, title, celltype, fixed, width, left, right, col, options)
	local tableBuilder = self.tableBuilder
	local column = tableBuilder:AddColumn()
	column:ConstructHeader("BUTTON", "MerchantPlusTableHeaderStringTemplate", key, title)
	column:ConstructCells("FRAME", celltype, col, options)
	if fixed then
		column:SetFixedConstraints(width, 0)
	else
		column:SetFillConstraints(width, 0)
	end
	column:SetCellPadding(left, right)
	return column
end

-- Update the contents of the table.
function MerchantPlusItemListMixin:RefreshScrollFrame()
	trace("called: RefreshScrollFrame")

	if not self.initialized or not self:IsVisible() then
		return
	end

	local count = self.GetDataCount and self:GetDataCount() or 0
	if count > 0 and self.GetData and self.Sort then
		self.ResultsText:Hide()
		local dataProvider = CreateDataProvider(self:GetData())
		self.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
		self.ScrollBox:GetDataProvider():SetSortComparator(function(lhs, rhs)
			return self:Sort(lhs, rhs)
		end)
	else
		self.ResultsText:Show()
		self.ResultsText:SetText(BROWSE_NO_RESULTS)
		if self.ScrollBox.ClearDataProvider then
			self.ScrollBox:ClearDataProvider()
		else
			self.ScrollBox:FlushDataProvider()
		end
	end

end

-- Return the ElementData back directly to the TableBuilder
function MerchantPlusItemListMixin:GetDataRow()
	return self
end

-- Set the sort to the header that was selected, or if it's already selected,
-- reverse it
function MerchantPlusItemListMixin:SetSortOrder(key, state)
	trace("called: SetSortOrder")

	if self.sortOrder == key and key ~= "" and state == nil then
		if self.sortOrderState == 1 then
			self.sortOrderState = 0
		else
			self.sortOrderState = 1
		end
	else
		self.sortOrder = key
		self.sortOrderState = state or 0
	end

	if self.SortCallback then
		self:SortCallback()
	end

	if self.initialized and self:IsVisible() and self.ScrollBox:HasDataProvider() then
		self.ScrollBox:GetDataProvider():Sort()
		self.ScrollBox:ScrollToBegin()
	end
end

-- Returns a table containing the sort order and state
function MerchantPlusItemListMixin:GetSortOrder()
	return self.sortOrder, self.sortOrderState
end
