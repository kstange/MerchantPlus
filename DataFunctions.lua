--
-- Merchant Plus
-- A Modern Scrollable UI for Merchants
--
-- Copyright 2023 - 2024 SimGuy
--
-- Use of this source code is governed by an MIT-style
-- license that can be found in the LICENSE file or at
-- https://opensource.org/licenses/MIT.
--

local _, Shared = ...

-- Push us into shared object
local Data = {}
Shared.Data = Data

-- Init an empty trace function to replace later
local trace = function() end

-- From Locales/Locales.lua
local L = Shared.Locale

-- List of additional functions to call to populate data to be filled later
Data.Functions = {}

-- This is a list of Collectable states to be filled in later
Data.CollectableState = {}

-- Item Categories: Find a localized string that will help identify some special items
--
-- The idea here is to not have to hardcode known localized strings so we can match non-English
-- clients without having to test in every language or get help from translators
Data.ItemCategoriesQueried = 0
Data.ItemCategoriesReturned = 0
Data.ItemCategories = {
	DrakewatcherManuscript = 196970,
}

-- Merchant items with wrong Blizz classifications
-- 'Misc: Companion Pets' that aren't pets (but toys, except 174925)
local falsePets = {
	[37460] = true, -- Rope Pet Leash (verified): Toy
	[44820] = true, -- Red Ribbon Pet Leash (verified): Toy
	[71137] = true, -- Brewfest Keg Pony (wowhead); Brewfest event only: Toy
	[75040] = true, -- Flimsy Darkmoon Balloon (verified); DMF event only: Toy-like bag item
	[75041] = true, -- Flimsy Green Balloon (verified); DMF event only: Toy-like bag item
	[75042] = true, -- Flimsy Yellow Balloon (wowhead); DMF event only: Toy
	[174925] = true, -- Void Tendril Pet Leash (verified): One-time use item
	[174995] = true, -- Void Tendril Pet Leash (verified): Toy
	[229829] = true, -- Light Blue Balloon (verified): Temporary summon
	[229830] = true, -- Dark Blue Balloon (verified): Temporary summon
	[229831] = true, -- Gold Balloon (verified): Temporary summon
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
	local item = C_MerchantFrame.GetItemInfo(index)
	item.quantity = item.stackCount
	item.extendedCost = item.hasExtendedCost
	item.itemID = GetMerchantItemID(index)
	item.link = GetMerchantItemLink(index)
	item.itemKey = { itemID = item.itemID }
	item.index = index
	return item
end

-- Fetch extended item data for a single item by item link
function Data:GetItemInfo(link)
	local item = {}
	local _
	if link then
		_, _, item.quality, item.level, item.minLevel, item.itemType, item.itemSubType,
			item.stackCount, item.equipLoc, _, item.sellPrice, item.classID, item.subclassID,
			item.bindType, item.expacID, item.setID, item.isCraftingReagent,
			item.itemDescription = C_Item.GetItemInfo(link)
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

-- Finish gathering tooltip data for ItemCategory entries after preload is done
function Data:FinishItemCategories()
	Data.ItemCategoriesReturned = Data.ItemCategoriesReturned + 1
	if Data.ItemCategoriesReturned == Data.ItemCategoriesQueried then
		for name, id in pairs(Data.ItemCategories) do
			local tooltip = C_TooltipInfo.GetItemByID(id)
			Data.ItemCategories[name] = Data:GetItemCategory(tooltip)
		end
	end
end

-- Find the Item Category string in the tooltip
function Data:GetItemCategory(tooltip)
	for _, line in ipairs(tooltip.lines) do
		-- This is hacky: look for the first line with light blue text
		--
		-- Usually this will be something like "Crafting Reagent" or another
		-- type of description indicating a special category of item
		if string.find(line.leftText, "|cFF66BBFF") then
			return string.sub(line.leftText, 11)
		end
	end
	return nil
end

-- Find the Item Known state of the tooltip
function Data:GetItemKnown(tooltip)
	for _, line in ipairs(tooltip.lines) do
		-- If there's a RestrictedSpellKnown line in this tooltip we're
		-- trusting that we know this item
		if line.type == Enum.TooltipDataLineType.RestrictedSpellKnown then
			return true
		end
	end
	return false
end

-- Find the Item Profession state of the tooltip
function Data:GetItemProfession(tooltip, profession)
	for _, line in ipairs(tooltip.lines) do
		-- If the localized profession name passed is found in this
		-- RestrictedSkill line, we're assuming that it's our profession
		--
		-- This hopefully makes things localization agnostic
		if line.type == Enum.TooltipDataLineType.RestrictedSkill then
			if string.find(line.leftText, profession) then
				return true
			end
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
	item.collectable = Data.CollectableState.Unsupported

	-- Profession Recipes
	if class == Enum.ItemClass.Recipe then
		-- If this item is usable, it's either known or collectable
		if itemdata.isUsable then
			if Data:GetItemKnown(itemdata.tooltip) then
				item.collectable = Data.CollectableState.Known
			else
				item.collectable = Data.CollectableState.Collectable
			end
		-- If it's not usable, it's either not for our profession or
		-- we might not be able to learn it yet
		else
			-- Scan the item data for what profession this item requires
			local profs = { GetProfessions() }
			local profmatch = false
			for _, prof in pairs(profs) do
				local profname = GetProfessionInfo(prof)
				profmatch = Data:GetItemProfession(itemdata.tooltip, profname)
				if profmatch then
					break
				end
			end
			-- If it's not for our professions, it's unavailable, else it's restricted
			if not profmatch then
				item.collectable = Data.CollectableState.Unavailable
			else
				item.collectable = Data.CollectableState.Restricted
			end
		end

	-- Gear and Heirlooms
	elseif class == Enum.ItemClass.Weapon or class == Enum.ItemClass.Armor then

		-- If this is an heirloom, the whole item is collectable unless it's known
		if C_Heirloom.GetHeirloomInfo(itemid) then
			if C_Heirloom.PlayerHasHeirloom(itemid) then
				item.collectable = Data.CollectableState.Known
			-- Heirlooms that aren't known are always collectable
			else
				item.collectable = Data.CollectableState.Collectable
			end

		-- Examine this item as a regular piece of gear
		else
			-- Try to find an appearance for this item
			--
			-- C_TransmogCollection.PlayerHasTransmogByItemInfo seems to
			-- check against the lowest upgrade level's appearance but
			-- C_TransmogCollection.GetItemInfo seems to be reliable.
			local _, sourceid = C_TransmogCollection.GetItemInfo(link)

			-- Fall back if the item link doesn't give us anything
			if not sourceid then
				trace("logic: GetCollectable: fell back to item ID on appearance source", itemid)
				_, sourceid = C_TransmogCollection.GetItemInfo(itemid)
			end

			-- If this item has an appearance, see what we know about it
                        if sourceid then
				-- This field could move; look for isCollected
				local sourceinfo = { C_TransmogCollection.GetAppearanceSourceInfo(sourceid) }
				local isCollected = sourceinfo[5]

				-- If this appearance is known, we're done
				if isCollected then
					item.collectable = Data.CollectableState.Known

				-- If we don't know it, see if we can learn it
				else
					local _, collectable = C_TransmogCollection.PlayerCanCollectSource(sourceid)

					-- With warbands as long as the item is collectable it should be available
					if collectable then
						item.collectable = Data.CollectableState.Collectable
					else
						item.collectable = Data.CollectableState.Unavailable
					end
				end
			end
		end

	-- Pets, Mounts, Toys, Drakewatcher Manuscripts
	elseif class == Enum.ItemClass.Miscellaneous then

		-- This is a pet, let's see if we know it and how many we have
		if subclass == Enum.ItemMiscellaneousSubclass.CompanionPet and not falsePets[itemid] then
			-- This field could move; look for speciesID index
			local petinfo = { C_PetJournal.GetPetInfoByItemID(itemid) }
			local speciesID = petinfo[13]
			if speciesID then
				local count, max = C_PetJournal.GetNumCollectedInfo(speciesID)

				-- This is special metadata just for pets, because we might want to use this
				-- in our display, sorting, or filtering functionality since we're looking it
				-- up anyway
				item.collectedpets = { count = count, max = max }

				-- If the pet collected at all, we know it, if it's usable and we don't know it
				-- we can collect it, othewise we probably just can't collect it yet
				--
				-- We're not storing enough data here when we have fewer than max to tell if we
				-- can collect more on this character
				--
				-- It's possible we could find a merchant pet that isn't collectable by this
				-- character (class or faction locked), but I didn't find any examples to test
				if count == 0 and itemdata.isUsable then
					item.collectable = Data.CollectableState.Collectable
				elseif count > 0 then
					item.collectable = Data.CollectableState.Known
				else
					item.collectable = Data.CollectableState.Restricted
				end
			else
				print(format(L['ERROR_FALSE_COLLECTABLE_PET'], itemdata.name, itemid,
				             "https://github.com/kstange/MerchantPlus/issues"))
			end

		-- This is a mount, let's see if we know it
		elseif subclass == Enum.ItemMiscellaneousSubclass.Mount then
			local mountid = C_MountJournal.GetMountFromItem(itemid)
			if mountid then
				local mountinfo = { C_MountJournal.GetMountInfoByID(mountid) }

				-- This field could move; look for isCollected index
				-- If collected, then we know it, if it's usable we can collect it, otherwise
				-- we probably can't collect it yet
				--
				-- It's possible we could find a merchant mount that isn't collectable by this
				-- character (class or faction locked), but I didn't find any examples to test
				if mountinfo[11] then
					item.collectable = Data.CollectableState.Known
				elseif itemdata.isUsable then
					item.collectable = Data.CollectableState.Collectable
				else
					item.collectable = Data.CollectableState.Restricted
				end
			else
				trace("logic: GetCollectable: item in mount category was not collectable", itemid)
			end

		-- This could be anything! We'll have to just try to figure out what it is
		else
			-- Let's see if this is a toy
			local toyid = C_ToyBox.GetToyInfo(itemid)

			-- It's a toy! If we have it, we have it, if the toy is usable, we can
			-- collect it, otherwise we probably can't collect it yet
			if toyid then
				if PlayerHasToy(toyid) then
					item.collectable = Data.CollectableState.Known
				elseif C_ToyBox.IsToyUsable(toyid) then
					item.collectable = Data.CollectableState.Collectable
				else
					item.collectable = Data.CollectableState.Restricted
				end
			end

			-- With some tooltip magic we tried to guess if this item has a special category
			-- Let's see if it's a Drakewatcher Manuscript
			if itemcategory == Data.ItemCategories.DrakewatcherManuscript then

				-- If this is on the vendor and usable, it's collectable
				--
				-- We shouldn't ever see this kind of item on the merchant if it can't be
				-- collected by this character or is known, but we'll try to check just
				-- in case
				if Data:GetItemKnown(itemdata.tooltip) then
					item.collectable = Data.CollectableState.Known
				elseif itemdata.isUsable then
					item.collectable = Data.CollectableState.Collectable
				else
					item.collectable = Data.CollectableState.Restricted
				end
			end
		end

	-- This is a consumable! Sometimes these can be collected
	elseif class == Enum.ItemClass.Consumable and Enum.ItemConsumableSubclass.Other then

		-- Let's see if this is a toy
		local toyid = C_ToyBox.GetToyInfo(itemid)

		-- It's a toy! If we have it, we have it, if the toy is usable, we can
		-- collect it, otherwise we probably can't collect it yet
		if toyid then
			if PlayerHasToy(toyid) then
				item.collectable = Data.CollectableState.Known
			elseif C_ToyBox.IsToyUsable(toyid) then
				item.collectable = Data.CollectableState.Collectable
			else
				item.collectable = Data.CollectableState.Restricted
			end
		end

		-- We're going trust that if this item appears on the merchant and is dressable it's
		-- unlearned but collectable
		--
		-- This is known to cover Ensembles... ideally it would cover Illusions but it doesn't
		-- seem to do that and I couldn't find any other way to test them
		local dressable = C_Item.IsDressableItemByID(itemid)
		if dressable then
			if Data:GetItemKnown(itemdata.tooltip) then
				item.collectable = Data.CollectableState.Known
			elseif itemdata.isUsable then
				item.collectable = Data.CollectableState.Collectable
			else
				item.collectable = Data.CollectableState.Restricted
			end
		end
	end

	return item
end

-- Since this code runs before MerchantPlus.lua we need to reset the trace function after init
-- Also initialize the ItemCategories data now
function Data:Init()
	trace = Shared.Trace or function() end

	for _, id in pairs(Data.ItemCategories) do
		Data.ItemCategoriesQueried = Data.ItemCategoriesQueried + 1
		local item = Item:CreateFromItemID(id)
		item:ContinueOnItemLoad(Data.FinishItemCategories)
	end

end
