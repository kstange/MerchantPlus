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
	self.NineSlice:SetPoint("TOPLEFT", self.HeaderContainer, "BOTTOMLEFT")
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

		self.ScrollBox:GetDataProvider():SetSortComparator(function(lhs, rhs)
			return self:Sort(lhs, rhs)
		end)
	end

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
	if order == Addon.MP_ITEM then
		local namecheck = SortUtil.CompareUtf8i(lhs['name'], rhs['name'])
		if namecheck ~= 0 then
			result = namecheck == -1
		end

	-- Item Price: sort by magic:
	--   Items with regular gold prices first, in cost order
	--   Items with extended cost currency, ordered most to least significant
	--     First by name of currency, then by amount of currency
	elseif order == Addon.MP_PRICE then
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
	elseif order == Addon.MP_STACK then
		key = 'quantity'

	-- Supply: sort numerically
	elseif order == Addon.MP_SUPPLY then
		key = 'numAvailable'

	-- Available: sort true > false
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

	self.ScrollBox:GetDataProvider():Sort()
end

-- Returns a table containing the sort order and state
function MerchantPlusItemListMixin:GetSortOrder()
	return self.sortOrder, self.sortOrderState
end
