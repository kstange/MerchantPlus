--
-- Merchant Plus
-- A Modern Scrollable UI for Merchants
--
-- Copyright 2023 SimGuy
--
-- Use of this source code is governed by an MIT-style
-- license that can be found in the LICENSE file or at
-- https://opensource.org/licenses/MIT.
--

local AddonName, Shared = ...

-- From Locales/Locales.lua
local L = Shared.Locale

-- From MerchantPlus.lua
local Addon = Shared.Addon

MerchantPlusItemListMixin = {}

-- On load, setup the nineslice properly. This doesn't seem to work if defined in XML.
function MerchantPlusItemListMixin:OnLoad()
	self.NineSlice:ClearAllPoints()
	self.NineSlice:SetPoint("TOPLEFT", MerchantPlusItemList.HeaderContainer, "BOTTOMLEFT")
	self.NineSlice:SetPoint("BOTTOMRIGHT")
end

-- Before the widget is shown, set it up to show results
function MerchantPlusItemListMixin:OnShow()
	self:Init()
	self:UpdateTableBuilderLayout()
	self:RefreshScrollFrame()
end

-- On init, we will need to create various structures
function MerchantPlusItemListMixin:Init()
	if self.initialized then
		return
	end

	local view = CreateScrollBoxListLinearView()

	view:SetElementFactory(function(factory, elementData)
		factory("MerchantPlusItemListLineTemplate", function(button, elementData)
			-- Nothing to do
		end)
	end)

	ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view)
	
	local tableBuilder = CreateTableBuilder(nil)
	self.tableBuilder = tableBuilder

	ScrollUtil.RegisterTableBuilder(self.ScrollBox, tableBuilder, function(elementData)
		return elementData
	end)

	self:UpdateTableBuilderLayout()
	self.tableBuilder:SetDataProvider(Addon.GetEntry)

	self:SetupSortManager()

	self.initialized = true
end

-- Update the layout of the table.
function MerchantPlusItemListMixin:UpdateTableBuilderLayout()
	self.tableBuilder:Reset()
	Addon:TableBuilderLayout(self.tableBuilder)
	self.tableBuilder:SetTableWidth(self.ScrollBox:GetWidth())
	self.tableBuilder:Arrange()
end

-- Update the contents of the table.
function MerchantPlusItemListMixin:RefreshScrollFrame()
	if not self.initialized or not self:IsShown() then
		return
	end

	local count = Addon:GetNumEntries()
	if count == 0 then
		self.ResultsText:Show()
		self.ResultsText:SetText(BROWSE_NO_RESULTS)
		self.ScrollBox:ClearDataProvider()
	else
		self.ResultsText:Hide()
		-- TODO: Replace IndexRange with a sortable DataProvider
		local dataProvider = CreateIndexRangeDataProvider(count)
		self.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
	end
end

-- This fuction will create a SortManager for helping sort the items that appear
-- in the list.
function MerchantPlusItemListMixin:SetupSortManager()
	local sortManager = SortUtil.CreateSortManager()
	sortManager:SetDefaultComparator(function(lhs, rhs)
		return lhs.rowData.itemKey.itemID < rhs.rowData.itemKey.itemID
	end)

	sortManager:SetSortOrderFunc(function()
		return self.sortOrder
	end)

	sortManager:InsertComparator(Addon.MP_ITEM, function(lhs, rhs)
		return SortUtil.CompareUtf8i(lhs.rowData.name, rhs.rowData.name)
	end)

	self.sortManager = sortManager
end

-- Returns the sortOrderState, which is 0 for ascending and 1 for descending
function MerchantPlusItemListMixin:GetSortOrderState(index)
	return self.sortOrderState
end

-- Set the sort to the header that was selected, or if it's already selected,
-- reverse it
function MerchantPlusItemListMixin:SetSortOrder(index)
	if self.sortOrder == index then
		if self.sortOrderState == 1 then
			self.sortOrderState = 0
		else
			self.sortOrderState = 1
		end
	else
		self.sortOrder = index
		self.sortOrderState = 0
	end
	-- TODO: Actually invoke the sort, but we don't have a DataProvider that
	-- knows how to use SortManager yet
	--self.ScrollBox:GetDataProvider():Sort()
end

-- Returns a table containing the sort order and state
function MerchantPlusItemListMixin:GetSortOrder()
	return { self.sortOrder, self.sortStateState }
end
