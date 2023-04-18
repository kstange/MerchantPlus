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

	Addon:UpdateVendor()
	local count = Addon:GetNumEntries()
	if count == 0 then
		self.ResultsText:Show()
		self.ResultsText:SetText(BROWSE_NO_RESULTS)
		self.ScrollBox:ClearDataProvider()
	else
		self.ResultsText:Hide()
		local dataProvider = CreateDataProvider(Addon.MerchantItems)
		self.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
	end
end

-- This fuction will sort based on the request.
function MerchantPlusItemListMixin:Sort(lhs, rhs)
	local order, state = self:GetSortOrder()
	if not lhs then
		return false
	end
	if not rhs then
		return true
	end
	local result = lhs.index < rhs.index
	local key = nil
	local invert = false
	if order == Addon.MP_ITEM then
		result = SortUtil.CompareUtf8i(lhs.name, rhs.name) < 1
	elseif order == Addon.MP_PRICE then
		if lhs.extendedCost == rhs.extendedCost then
			if not lhs.extendedCost then
				if lhs.price ~= rhs.price then
					result = lhs.price < rhs.price
				end
			else
				-- TODO: Sorting by price with item costs??
				local lhitems = GetMerchantItemCostInfo(lhs.index)
				local rhitems = GetMerchantItemCostInfo(rhs.index)
				if lhitems ~= rhitems then
					result = lhitems < rhitems
				end
			end
		else
			if lhs.extendedCost then
				result = false
			else
				result = true
			end
		end
	elseif order == Addon.MP_STACK then
		key = 'quantity'
	elseif order == Addon.MP_SUPPLY then
		key = 'numAvailable'
	elseif order ==  Addon.MP_AVAIL then
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

	self.ScrollBox:GetDataProvider():SetSortComparator(function(lhs, rhs)
		return MerchantPlusItemList:Sort(lhs, rhs)
	end)
end

-- Returns a table containing the sort order and state
function MerchantPlusItemListMixin:GetSortOrder()
	return self.sortOrder, self.sortOrderState
end