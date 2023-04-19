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

	local key = nil
	local invert = false

	-- Item Name: sort alphabetically
	if order == Metadata.Columns.item.id then
		local namecheck = SortUtil.CompareUtf8i(lhs['name'] or "Unknown Item", rhs['name'] or "Unknown Item")
		if namecheck ~= 0 then
			result = namecheck == -1
		end

	-- Item Price: sort by magic:
	--   Items with regular gold prices first, in cost order
	--   Items with extended cost currency, ordered most to least significant
	--     First by name of currency, then by amount of currency
	elseif order == Metadata.Columns.price.id then
		-- If extendedCost state is the same, compare the values
		if lhs['extendedCost'] == rhs['extendedCost'] then
			-- This is just gold, check which side is higher
			if not lhs['extendedCost'] then
				-- If the value is the same, allow to fall back to index
				if lhs['price'] ~= rhs['price'] then
					result = lhs['price'] < rhs['price']
				end

			-- This is extended cost, compare the currencies
			else
				-- Get the number of currencies required for each item
				local lhitems = GetMerchantItemCostInfo(lhs['index'])
				local rhitems = GetMerchantItemCostInfo(rhs['index'])

				local difference = 0

				-- Loop through all currencies
				for i = 1, MAX_ITEM_COST do
					-- If we've already found a difference, stop
					if difference ~= 0 then
						break
					end

					-- Get the currency item and number required
					local li = 1 + lhitems - i
					local ri = 1 + rhitems - i
					local _, lhvalue, lhlink, lhname = GetMerchantItemCostItem(lhs['index'], li)
					local _, rhvalue, rhlink, rhname = GetMerchantItemCostItem(rhs['index'], ri)

					-- If one side has something and the other has nothing
					-- put those with no item first
					if lhvalue <= 0 and rhvalue > 0 then
						difference = -1
					elseif lhvalue > 0 and rhvalue <= 0 then
						difference = 1
					elseif lhvalue > 0 and rhvalue > 0 then

						-- If this is an item instead of a currency, get its name
						if not lhname then
							lhname = GetItemInfo(lhlink)
						end
						if not rhname then
							rhname = GetItemInfo(rhlink)
						end

						-- Sort the currency by name first
						-- If names are the same, sort by value
						-- If values are the same, fall back to index
						local namecheck = SortUtil.CompareUtf8i(lhname, rhname)
						if namecheck == 0 then
							if lhvalue < rhvalue then
								difference = -1
							elseif lhvalue > rhvalue then
								difference = 1
							end
						else
							difference = namecheck
						end
					end
				end

				-- If the sort indicated there was a difference, return that result,
				-- otherwise we fall back to the sort by index.
				if difference ~= 0 then
					result = difference == -1
				end
			end
		else
			if lhs.extendedCost then
				result = false
			else
				result = true
			end
		end
	-- Stack Size: sort numerically
	elseif order == Metadata.Columns.quantity.id then
		key = 'quantity'

	-- Supply: sort numerically
	elseif order == Metadata.Columns.supply.id then
		key = 'numAvailable'

	-- Usable: sort true > false
	elseif order == Metadata.Columns.usable.id then
		if lhs['isUsable'] ~= rhs['isUsable'] then
			result = lhs['isUsable']
		end

	-- Available: sort true > false
	elseif order == Metadata.Columns.purchasable.id then
		if lhs['isPurchasable'] ~= rhs['isPurchasable'] then
			result = lhs['isPurchasable']
		end
	end
	if key then
		if lhs[key] ~= rhs[key] then
			if not invert then
				result = lhs[key] < rhs[key]
			else
				result = lhs[key] > rhs[key]
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
