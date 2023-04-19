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

-- From Metadata.lua
local Metadata = Shared.Metadata

MerchantPlusItemListMixin = {}

-- On load, setup the nineslice properly. This doesn't seem to work if defined in XML.
function MerchantPlusItemListMixin:OnLoad()
	if Addon.Trace then print("called: OnLoad") end
	self.NineSlice:ClearAllPoints()
	self.NineSlice:SetPoint("TOPLEFT", self.HeaderContainer, "BOTTOMLEFT")
	self.NineSlice:SetPoint("BOTTOMRIGHT")
end

-- Before the widget is shown, set it up to show results
function MerchantPlusItemListMixin:OnShow()
	if Addon.Trace then print("called: OnShow") end
	self:Init()
	self:UpdateTableBuilderLayout()
	self:RefreshScrollFrame()
	self.ScrollBox:ScrollToBegin()
end

-- Before the widget is hidden, clean up stuff
function MerchantPlusItemListMixin:OnHide()
	if Addon.Trace then print("called: OnHide") end
	ResetSetMerchantFilter()
	MerchantFrame_Update()
end

-- On init, we will need to create various structures
function MerchantPlusItemListMixin:Init()
	if Addon.Trace then print("called: Init") end
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

	self.tableBuilder:SetHeaderContainer(self.HeaderContainer)
	self.tableBuilder:SetDataProvider(self.GetDataRow)

	self.initialized = true
end

-- Update the layout of the table.
function MerchantPlusItemListMixin:UpdateTableBuilderLayout()
	if Addon.Trace then print("called: UpdateTableBuilderLayout") end

	self.tableBuilder:Reset()
	if self.layoutCallback then
		self:layoutCallback()
	end
	self.tableBuilder:SetTableWidth(self.ScrollBox:GetWidth())
	self.tableBuilder:Arrange()
end

-- Add a column to the TableBuilder
function MerchantPlusItemListMixin:AddColumn(title, celltype, index, fixed, width, left, right, ...)
	local tableBuilder = self.tableBuilder
	local column = tableBuilder:AddColumn()
	column:ConstructHeader("BUTTON", "MerchantPlusTableHeaderStringTemplate", title, index)
	column:ConstructCells("FRAME", celltype, ...)
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
	if Addon.Trace then print("called: RefreshScrollFrame") end

	if not self.initialized or not self:IsShown() then
		return
	end

	SetMerchantFilter(LE_LOOT_FILTER_ALL)
	local count = GetMerchantNumItems()
	if count == 0 then
		self.ResultsText:Show()
		self.ResultsText:SetText(BROWSE_NO_RESULTS)
		self.ScrollBox:ClearDataProvider()
	else
		self.ResultsText:Hide()
		local MerchantItems = self:UpdateMerchant()
		local dataProvider = CreateDataProvider(MerchantItems)
		self.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)

		self.ScrollBox:GetDataProvider():SetSortComparator(function(lhs, rhs)
			return self:Sort(lhs, rhs)
		end)
	end

end

-- Return the ElementData back directly to the TableBuilder
function MerchantPlusItemListMixin:GetDataRow()
	return self
end

-- Sync updated Merchant information
function MerchantPlusItemListMixin:UpdateMerchant()
	local items = GetMerchantNumItems()
	local MerchantItems = {}
	if Addon.Trace then print("called: UpdateMerchant", items) end
	for i = 1, items do
		MerchantItems[i] = self:UpdateMerchantItem(i)
	end
	return MerchantItems
end

-- Fetch the data for a single item by Merchant index
function MerchantPlusItemListMixin:UpdateMerchantItem(index)
	local item = {}
	item.itemKey = { itemID = GetMerchantItemID(index) }
	item.name, item.texture, item.price, item.quantity, item.numAvailable, item.isPurchasable, item.isUsable, item.extendedCost = GetMerchantItemInfo(index)
	item.index = index
	return item
end

-- This fuction will sort based on the request.
function MerchantPlusItemListMixin:Sort(lhs, rhs)
	local order, state = self:GetSortOrder()

	-- The sort method will sometimes send nil values
	if not lhs or not rhs then
		return false
	end

	-- Default sort by Merchant index if nothing else is set.
	-- Use this to ensure that equal values retain a deterministic
	-- sort, otherwise race conditions may occur where they shift
	-- randomly.
	local result = lhs['index'] < rhs['index']

	for _, col in pairs(Metadata.Columns) do
		if col.id == order and col.sortfunction then
			local sort = col.sortfunction(nil, lhs, rhs)
			if sort ~= nil then
				result = sort
			end
		elseif col.id == order and col.field then
			local key = col.field

			-- Handle item sort (by name only)
			if col.celltype == Metadata.CellTypes.Item then
				local namecheck = SortUtil.CompareUtf8i(lhs[key] or "", rhs[key] or "")
				if namecheck ~= 0 then
					result = namecheck == -1
				end

			-- Handle number sort
			elseif col.celltype == Metadata.CellTypes.Number then
				if lhs[key] ~= rhs[key] then
					result = lhs[key] < rhs[key]
				end

			-- Handle text sort
			elseif col.celltype == Metadata.CellTypes.Text then
				local namecheck = SortUtil.CompareUtf8i(lhs[key] or "", rhs[key] or "")
				if namecheck ~= 0 then
					result = namecheck == -1
				end

			-- TODO: Handle icon sort

			-- Handle boolean sort
			elseif col.celltype == Metadata.CellTypes.Boolean then
				if lhs[key] ~= rhs[key] then
					result = lhs[key]
				end
			end
		end
	end
	if state == 1 then
		return not result
	else
		return result
	end
end

-- Set the sort to the header that was selected, or if it's already selected,
-- reverse it
function MerchantPlusItemListMixin:SetSortOrder(index, state)
	if Addon.Trace then print("called: SetSortOrder") end

	if self.sortOrder == index and index ~= 0 and state == nil then
		if self.sortOrderState == 1 then
			self.sortOrderState = 0
		else
			self.sortOrderState = 1
		end
	else
		self.sortOrder = index
		self.sortOrderState = state or 0
	end

	if self.sortCallback then
		self:sortCallback()
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
