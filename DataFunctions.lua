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
-- Not used yet
--local L = Shared.Locale

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
	AirshipSchematic = 235691,
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
		if line.type == Enum.TooltipDataLineType.UsageRequirement and line.leftText == ITEM_SPELL_KNOWN then
			return true
		end
	end
	return false
end

-- Find the Item Profession state of the tooltip
function Data:GetItemProfession(tooltip)
	-- Initialize the list of professions once, they won't change while we're logged in!
	if not Data.professionInfo then
		Data.professionInfo = {}
		for _, id in pairs(Enum.Profession) do
			local skillLineID = C_TradeSkillUI.GetProfessionSkillLineID(id)
			local professionInfo = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
			if professionInfo.professionName ~= "" then
				table.insert(Data.professionInfo, professionInfo.professionName)
			end
		end
	end
	for _, line in ipairs(tooltip.lines) do
		-- Search for a profession in the UsageRequirement line, if there is one
		if line.type == Enum.TooltipDataLineType.UsageRequirement then
			for _, professionName in ipairs(Data.professionInfo) do
				if string.find(line.leftText, professionName) then
					return professionName
				end
			end
		end
	end
	return false
end

-- Check every source for an appearance to decide if the player has learned the appearance
function Data:AppearanceKnownFromAnySource(sourceid)
	if C_TransmogCollection.PlayerHasTransmogItemModifiedAppearance(sourceid) then
		return true
	else
		local sourceinfo = C_TransmogCollection.GetAppearanceSourceInfo(sourceid)
		local altsources = C_TransmogCollection.GetAllAppearanceSources(sourceinfo.itemAppearanceID)
		if altsources then
			for _, altsourceid in ipairs(altsources) do
				if C_TransmogCollection.PlayerHasTransmogItemModifiedAppearance(altsourceid) then
					return true
				end
			end
		end
	end
	return false
end

-- Look at the item and determine if the item is collectable or known
--
-- Blizzard can't be trusted to put items in the right categories, so we're just
-- going to have to test for everything.
--
function Data:GetCollectable(link, itemdata)
	local item = {}
	local itemid = itemdata.itemID
	local itemcategory = Data:GetItemCategory(itemdata.tooltip)
	item.collectable = Data.CollectableState.Unsupported

	if not link then
		trace("logic: GetCollectable: item link was nil; may have tried to fetch info too early", itemid)
		return item
	end

	-- Toys
	--
	-- It's a toy! If we have it, we have it, if the toy is usable, we can
	-- collect it, otherwise we probably can't collect it yet
	--
	local toyid = C_ToyBox.GetToyInfo(itemid)
	if toyid then
		if PlayerHasToy(toyid) then
			item.collectable = Data.CollectableState.Known
		elseif C_ToyBox.IsToyUsable(toyid) then
			item.collectable = Data.CollectableState.Collectable
		else
			item.collectable = Data.CollectableState.Restricted
		end
		return item
	end

	-- Pets
	--
	-- If the pet collected at all, we know it, if it's usable and we don't know it
	-- we can collect it, othewise we probably just can't collect it yet
	--
	-- We're not storing enough data here when we have fewer than max to tell if we
	-- can collect more on this character
	--
	-- It's possible we could find a merchant pet that isn't collectable by this
	-- character (class or faction locked), but I didn't find any examples to test
	--
	-- This field could move; look for speciesID index
	local petinfo = { C_PetJournal.GetPetInfoByItemID(itemid) }
	local speciesID = petinfo[13]
	if speciesID then
		local count, max = C_PetJournal.GetNumCollectedInfo(speciesID)

		-- This is special metadata just for pets, because we might want to use this
		-- in our display, sorting, or filtering functionality since we're looking it
		-- up anyway
		item.collectedpets = { count = count, max = max }

		if count == 0 and itemdata.isUsable then
			item.collectable = Data.CollectableState.Collectable
		elseif count > 0 then
			item.collectable = Data.CollectableState.Known
		else
			item.collectable = Data.CollectableState.Restricted
		end
		return item
	end

	-- Mounts
	--
	-- If collected, then we know it, if it's usable we can collect it, otherwise
	-- we probably can't collect it yet
	--
	-- It's possible we could find a merchant mount that isn't collectable by this
	-- character (class or faction locked), but I didn't find any examples to test
	--
	local mountid = C_MountJournal.GetMountFromItem(itemid)
	if mountid then
		local mountinfo = { C_MountJournal.GetMountInfoByID(mountid) }

		-- This field could move; look for isCollected index
		if mountinfo[11] then
			item.collectable = Data.CollectableState.Known
		elseif itemdata.isUsable then
			item.collectable = Data.CollectableState.Collectable
		else
			item.collectable = Data.CollectableState.Restricted
		end
		return item
	end

	-- Decor
	--
	-- Check if the player has any of these anywhere, if not, then they are uncollected
	-- Housing items are always collectable, so we're counting having even one copy as "known"
	--
	if C_Item.IsDecorItem(itemid) then
		local decoritem = C_HousingCatalog.GetCatalogEntryInfoByItem(itemid, true)
		item.storedDecor = decoritem.quantity + decoritem.remainingRedeemable
		item.placedDecor = decoritem.numPlaced
		if decoritem.quantity + decoritem.numPlaced + decoritem.remainingRedeemable == 0 then
			item.collectable = Data.CollectableState.Collectable
		else
			item.collectable = Data.CollectableState.Known
		end
		return item
	end

	-- Profession Recipes
	--
	-- We are looking for a Requires skill line and spell ID 483 (Learning)
	-- This should hopefully rule out non-profession things that can be learned
	-- without missing legitimate recipes
	--
	-- If this item not known or usable, it is retricted (unsatified conditions)
	-- If it's not for our professions, it's unavailable
	--
	local _, spellID = C_Item.GetItemSpell(link)
	if spellID == 483 then
		local itemProf = Data:GetItemProfession(itemdata.tooltip)
		local profs = { GetProfessions() }
		local profMatch = false
		for _, prof in pairs(profs) do
			local profName = GetProfessionInfo(prof)
			if itemProf == profName then
				profMatch = true
				break
			end
		end
		if profMatch then
			if Data:GetItemKnown(itemdata.tooltip) then
				item.collectable = Data.CollectableState.Known
			elseif itemdata.isUsable then
				item.collectable = Data.CollectableState.Collectable
			else
				item.collectable = Data.CollectableState.Restricted
			end
		else
			item.collectable = Data.CollectableState.Unavailable
		end
		return item
	end

	-- Heirlooms
	--
	-- If this is an heirloom, the whole item is collectable unless it's known
	--
	if C_Heirloom.GetHeirloomInfo(itemid) then
		if C_Heirloom.PlayerHasHeirloom(itemid) then
			item.collectable = Data.CollectableState.Known
		-- Heirlooms that aren't known are always collectable
		else
			item.collectable = Data.CollectableState.Collectable
		end
		return item
	end

	-- Transmog Items
	--
	-- Try to find an appearance for this item by checking sourceid (aka ItemModifiedAppearanceId)
	-- of the item link, which should give us the version of the item actually appearing on the
	-- merchant. If we can't get a source from that, we'll try the itemID directly, which may work
	-- for some older items that have only one appearance type.
	--
	-- To make sure that we count an item as collected if we have an alternate source, we'll scan
	-- those sources if the first one comes back negative.
	--
	-- Starting with Warbands as long as the item is collectable it should be available to collect
	-- even if the armor type doesn't match the player's class.
	--
	if C_Item.IsDressableItemByID(link) then
		local _, sourceid = C_TransmogCollection.GetItemInfo(link)

		-- Fall back if the item link doesn't give us anything
		if not sourceid then
			trace("logic: GetCollectable: fell back to item ID on appearance source", itemid)
			_, sourceid = C_TransmogCollection.GetItemInfo(itemid)
		end

		-- If we fail this check the item likely isn't a single piece of equipment
		if sourceid then

			if Data:AppearanceKnownFromAnySource(sourceid) then
				item.collectable = Data.CollectableState.Known

			else
				local _, collectable = C_TransmogCollection.PlayerCanCollectSource(sourceid)

				if collectable then
					item.collectable = Data.CollectableState.Collectable
				else
					item.collectable = Data.CollectableState.Unavailable
				end
			end

		else
			-- Ensembles
			--
			-- Here we check to see if the item is actually an ensemble instead of a regular
			-- piece of equipment. We check to see if the player owns every appearance in this
			-- set and if they are missing even one, we mark it as available to collect, provided
			-- it's not otherwise restricted.
			--
			local setid = C_Item.GetItemLearnTransmogSet(link)
			if setid then
				local setSources = C_Transmog.GetAllSetAppearancesByID(setid)
				local setKnown = true
				for _, sourceinfo in ipairs(setSources) do
					if not Data:AppearanceKnownFromAnySource(sourceinfo.itemModifiedAppearanceID) then
						setKnown = false
					end
				end

				if setKnown then
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

	-- Special Collectable Items -- Usually customization parts
	--
	-- With some tooltip magic we tried to guess if this item has a special category.
	-- Hopefully doing it this way is localization agnostic.
	--
	-- If this is on the vendor and usable, it's collectable
	--
	-- We shouldn't ever see these kinds of items on the merchant if they can't be
	-- collected by this character or are known, but we'll try to check just
	-- in case.
	--
	-- There are probably a few more types of items that work like this, if you find
	-- this comment, feel free to submit suggestions.
	--
	if itemcategory == Data.ItemCategories.DrakewatcherManuscript or
	   itemcategory == Data.ItemCategories.AirshipSchematic then

		if Data:GetItemKnown(itemdata.tooltip) then
			item.collectable = Data.CollectableState.Known
		elseif itemdata.isUsable then
			item.collectable = Data.CollectableState.Collectable
		else
			item.collectable = Data.CollectableState.Restricted
		end
		return item
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
