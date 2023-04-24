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
local Data = {}
Shared.Data = Data

-- From Metadata.lua
local Metadata = Shared.Metadata

-- List of additional functions to call to populate date
Data.Functions = {}

-- Sync updated Merchant information
function Data:UpdateMerchant()
	SetMerchantFilter(LE_LOOT_FILTER_ALL)
	local count = GetMerchantNumItems()
	local MerchantItems = {}
	trace("called: UpdateMerchant", count, #Data.Functions)
	for i = 1, count do
		local item = Data:GetMerchantItemInfo(i)
		for _, func in ipairs(Data.Functions) do
			MergeTable(item, func(i, item.link))
		end
		MerchantItems[i] = item
	end
	return MerchantItems
end

-- Fetch number of merchant items available
function Data:GetMerchantCount()
	SetMerchantFilter(LE_LOOT_FILTER_ALL)
	return GetMerchantNumItems()
end

-- Fetch the data for a single item by Merchant index
function Data:GetMerchantItemInfo(index)
	local item = {}
	item.itemID = GetMerchantItemID(index)
	item.link = GetMerchantItemLink(index)
	item.itemKey = { itemID = item.itemID }
	item.name, item.texture, item.price, item.quantity, item.numAvailable, item.isPurchasable, item.isUsable, item.extendedCost = GetMerchantItemInfo(index)
	item.index = index
	return item
end

-- Fetch extended item data for a single item by Merchant index
function Data:GetItemInfo(link)
	local item = {}
	if link then
		_, _, item.quality, item.level, item.minLevel, item.itemType, item.itemSubType, item.stackCount, item.equipLoc, _, item.sellPrice, item.classID, item.subclassID, item.bindType, item.expacID, item.setID, item.isCraftingReagent = GetItemInfo(link)
	end
	return item
end

-- Fetch tooltip item data for a single item by Merchant index
function Data:GetMerchantItemTooltip()
	-- inded ends up in self due to the way this is called
	local index = self
	local item = {}
	item.tooltip = C_TooltipInfo.GetMerchantItem(index)
	return item
end

-- This fuction will sort based on the request.
function Data:Sort(lhs, rhs)
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

	for ckey, col in pairs(Metadata.Columns) do
		if ckey == order and col.sortfunction then

			-- Handle custom sort function if provided
			local sort = col.sortfunction(nil, lhs, rhs)
			if sort ~= nil then
				result = sort
			end

		elseif ckey == order and col.field then
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

-- Since this code runs before MerchantPlus.lua we need to reset the trace function after init
function Data:Init()
	trace = Shared.Trace or function() end
end
