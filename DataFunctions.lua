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

-- Item Categories: Find a localized string that will help identify some special items
Data.ItemCategoriesQueried = 0
Data.ItemCategoriesReturned = 0
Data.ItemCategories = {
	DrakewatcherManuscript = 196970,
}

-- Sync updated Merchant information
function Data:UpdateMerchant()
	SetMerchantFilter(LE_LOOT_FILTER_ALL)
	local count = GetMerchantNumItems()
	local MerchantItems = {}
	trace("called: UpdateMerchant", count, #Data.Functions)
	for i = 1, count do
		local item = Data:GetMerchantItemInfo(i)
		for _, func in ipairs(Data.Functions) do
			MergeTable(item, func(i, item.link, item))
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

-- Finish gathering tooltip data for ItemCategory entries
function Data:FinishItemCategories()
	Data.ItemCategoriesReturned = Data.ItemCategoriesReturned + 1
	if Data.ItemCategoriesReturned == Data.ItemCategoriesQueried then
		for name, id in pairs(Data.ItemCategories) do
			local tooltip = C_TooltipInfo.GetItemByID(id)
			print(tooltip, tooltip.lines, tooltip.lines[2])
			Data.ItemCategories[name] = Data:GetItemCategory(tooltip)
		end
	end
end

-- Find the Item Category string in the tooltip
function Data:GetItemCategory(tooltip)
	for _, line in ipairs(tooltip.lines) do
		if string.find(line.leftText, "|cFF66BBFF") then
			return string.sub(line.leftText, 11)
		end
	end
	return nil
end

-- Find the Item Known state of the tooltip 
function Data:GetItemKnown(tooltip)
	for _, line in ipairs(tooltip.lines) do
		if line.type == Enum.TooltipDataLineType.RestrictedSpellKnown then
			return true
		end
	end
	return false
end

-- Look at the item and determine if the item is collectable or known
function Data:GetCollectable(link, itemdata)
	local item = {}
	local itemid = itemdata.itemID
	local class = itemdata.classID
	local subclass = itemdata.subclassID
	local itemcategory = Data:GetItemCategory(itemdata.tooltip)
	item.collectible = nil

	if class == Enum.ItemClass.Recipe then
		if itemdata.isUsable then
			if Data:GetItemKnown(itemdata.tooltip) then
				item.collectable = "known"
			else
				item.collectable = "collectable"
			end
		else
			item.collectable = "nope"
		end
	elseif class == Enum.ItemClass.Weapon or class == Enum.ItemClass.Armor then
		if C_Heirloom.GetHeirloomInfo(itemid) then
			if C_Heirloom.PlayerHasHeirloom(itemid) then
				item.collectable = "known"
			-- Heirlooms that aren't known are always collectable
			else
				item.collectable = "collectable"
			end
		elseif C_TransmogCollection.PlayerHasTransmogByItemInfo(link) then
			item.collectable = "known"
		else
			local _, sourceid    = C_TransmogCollection.GetItemInfo(link)
			local _, collectable = C_TransmogCollection.PlayerCanCollectSource(sourceid)
			if collectable then
				item.collectable = "collectable"
			else
				item.collectable = "nope"
			end
		end
	elseif class == Enum.ItemClass.Miscellaneous then
		if subclass == Enum.ItemMiscellaneousSubclass.CompanionPet then
			local petinfo = { C_PetJournal.GetPetInfoByItemID(itemid) }
			local count, max = C_PetJournal.GetNumCollectedInfo(petinfo[13])
			if itemdata.isUsable then
				if count == max then
					item.collectable = "known"
				elseif count == 0 then
					item.collectable = "collectable"
				elseif count < max then
					item.collectable = "known (" .. count .. "/" .. max .. ")"
				else
					item.collectable = "nope"
				end
			else
				item.collectable = "nope"
			end
		elseif subclass == Enum.ItemMiscellaneousSubclass.Mount then
			local mountid = C_MountJournal.GetMountFromItem(itemid)
			local mountinfo = { C_MountJournal.GetMountInfoByID(mountid) }
			if mountinfo[11] then
				item.collected = "known"
			elseif itemdata.isUsable then
				item.collectable = "collectable"
			else
				item.collectable = "nope"
			end
		else
			-- See if this is a toy
			local toyid = C_ToyBox.GetToyInfo(itemid)
			if toyid then
				if PlayerHasToy(toyid) then
					item.collectable = "known"
				elseif itemdata.isUsable then
					item.collectable = "collectable"
				else
					item.collectable = "nope"
				end
			end
			-- If this is on the vendor and usable, it's collectable
			if itemcategory == Data.ItemCategories.DrakewatcherManuscript then
				item.collectable = "collectable"
			end
		end
	elseif class == Enum.ItemClass.Consumable and Enum.ItemConsumableSubclass.Other then
		-- ensemble appears here
	-- TODO: ensembles, illusions
	else
		item.collectable = nil
	end
	return item
end

-- Since this code runs before MerchantPlus.lua we need to reset the trace function after init
-- Also initialize the ItemCategories data now
function Data:Init()
	trace = Shared.Trace or function() end

	for name, id in pairs(Data.ItemCategories) do
		Data.ItemCategoriesQueried = Data.ItemCategoriesQueried + 1
		local item = Item:CreateFromItemID(id)
		item:ContinueOnItemLoad(Data.FinishItemCategories)
	end

end
