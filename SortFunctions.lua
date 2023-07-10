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

-- This is a list of supported cell types to be filled later
Sort.CellTypes = {}

-- This is a list of supported columns to be filled later
Sort.Columns = {}

local CurrencyCache = {}

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
						lhname = Sort:GetCurrencyName(lhlink)
					end
					if not rhname then
						rhname = Sort:GetCurrencyName(rhlink)
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

-- Cache currency names to reduce calls to GetItemInfo()
function Sort:GetCurrencyName(link)
	local id = GetItemInfoInstant(link)
	if CurrencyCache[id] then
		name = CurrencyCache[id]
	else
		name = GetItemInfo(link)
		if name then
			CurrencyCache[id] = name
		else
			name = ""
		end
	end
	return name
end

-- This function will sort based on the request
function Sort:Sort(lhs, rhs)
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

	local col = Sort.Columns[order]
	if col then
		if col.sortfunction then

			-- Handle custom sort function if provided
			local sort = col.sortfunction(nil, lhs, rhs)
			if sort ~= nil then
				result = sort
			end

		elseif col.field then
			local key = col.field

			-- Handle item sort (by name only)
			if col.celltype == Sort.CellTypes.Item then
				local namecheck = SortUtil.CompareUtf8i(lhs[key] or "", rhs[key] or "")
				if namecheck ~= 0 then
					result = namecheck == -1
				end

			-- Handle number sort
			elseif col.celltype == Sort.CellTypes.Number then
				if lhs[key] ~= rhs[key] then
					result = lhs[key] < rhs[key]
				end

			-- Handle text sort
			elseif col.celltype == Sort.CellTypes.Text then
				local namecheck = SortUtil.CompareUtf8i(lhs[key] or "", rhs[key] or "")
				if namecheck ~= 0 then
					result = namecheck == -1
				end

			-- TODO: Handle icon sort

			-- Handle boolean sort
			elseif col.celltype == Sort.CellTypes.Boolean then
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
