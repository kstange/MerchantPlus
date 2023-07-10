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

-- Init an empty trace function to replace later
local trace = function() end

-- List of additional functions to call to populate data to be filled later
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

-- Fetch extended item data for a single item by item link
function Data:GetItemInfo(link)
	local item = {}
	if link then
		_, _, item.quality, item.level, item.minLevel, item.itemType, item.itemSubType, item.stackCount, item.equipLoc, _, item.sellPrice, item.classID, item.subclassID, item.bindType, item.expacID, item.setID, item.isCraftingReagent = GetItemInfo(link)
	end
	return item
end

-- Fetch tooltip item data for a single item by Merchant index
function Data:GetMerchantItemTooltip()
	-- index ends up in self due to the way this is called
	local index = self
	local item = {}
	item.tooltip = C_TooltipInfo.GetMerchantItem(index)
	return item
end

-- Since this code runs before MerchantPlus.lua we need to reset the trace function after init
function Data:Init()
	trace = Shared.Trace or function() end
end
