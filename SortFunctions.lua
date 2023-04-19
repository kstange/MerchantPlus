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

-- Push us into shared object
local Sort = {}
Shared.Sort = Sort

-- Item Price: sort by magic:
--   Items with regular gold prices first, in cost order
--   Items with extended cost currency, ordered most to least significant
--     First by name of currency, then by amount of currency
function Sort:SortPrice(lhs, rhs)
	local result = nil

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
	return result
end
