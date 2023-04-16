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

-- Push us into shared object
local Addon = {}
Shared.Addon = Addon

local InitialWidth = nil
local MerchantItems = {}
local MerchantFilter = nil

local MP_ITEM   = 1
local MP_PRICE  = 2
local MP_STACK  = 3
local MP_SUPPLY = 4
local MP_AVAIL  = 5

-- This gets called any time that our tab becomes focused or any time MerchantFrame_Update()
-- gets called.  We want to know if Blizzard starts messing with things from other tabs.
function MerchantPlus_Update()
	local plustab = MerchantFrameTabPlus:GetID()                        -- Our tab ID
	local show    = MerchantFrame.selectedTab == plustab                -- Our tab is requested
	local changed = MerchantFrame.lastTab ~= MerchantFrame.selectedTab  -- The tab was switched
	local buyback = MerchantFrame.selectedTab == 2                      -- Buyback tab is active
	local normal  = MerchantFrame.selectedTab == 1                      -- Normal Merchant tab is active
	local width   = show and 800 or InitialWidth or 336                 -- Fallback to known good width

	-- We do this here because Blizzard won't if our tab is selected
	if show and changed then
		MerchantFrame_CloseStackSplitFrame()
		MerchantFrame.lastTab = MerchantFrame.selectedTab

		MerchantFrame:SetTitle(UnitName("npc"))
		MerchantFrame:SetPortraitToUnit("npc")
	end

	-- Set the width of the frame wider or back to the default depending on the tab
	-- we're switching to
	MerchantFrame:SetWidth(width)

	-- If we're transitioning to another tab, show the correct number of items
	-- Otherwise, hide all of them because we're doing something different
	for i = 1, buyback and BUYBACK_ITEMS_PER_PAGE
	            or normal and MERCHANT_ITEMS_PER_PAGE
	            or max(MERCHANT_ITEMS_PER_PAGE, BUYBACK_ITEMS_PER_PAGE) do
		local button = _G["MerchantItem"..i]
		button:SetShown(not show)
	end

	-- Hide the filtering dropdown and clear the filter as we'll be doing something else
	MerchantFrameLootFilter:SetShown(not show)
	if show and changed then
		-- Save and clear the filter on the merchant
		MerchantFilter = GetMerchantFilter()
		SetMerchantFilter(LE_LOOT_FILTER_ALL)
	elseif MerchantFilter then
		-- Restore the saved filter to the merchant
		SetMerchantFilter(MerchantFilter)
		MerchantFilter = nil
		MerchantFrame_Update()
	end

	-- We show our own frame objects if wanted
	MerchantPlusFrame:SetShown(show)

	-- Set up the frame for ourselves.  We blindly adjust frames we know that the official
	-- blizzard code will fix when it transitions to another official tab.  We also need to undo
	-- anything weird that Blizzard might do because sometimes it assumes our tab is the buyback
	-- tab.
	if show then
		-- Hide all the buttons from the merchant page
		MerchantPageText:Hide()
		MerchantPrevPageButton:Hide()
		MerchantNextPageButton:Hide()

		-- Hide the Buyback background
		BuybackBG:Hide()

		-- Update the state of repair buttons
		MerchantFrame_UpdateRepairButtons()

		-- Re-anchor the Buyback and Currency elements to things that won't move around
		MerchantBuyBackItem:ClearAllPoints()
		MerchantBuyBackItem:SetPoint("BOTTOM", MerchantFrame, "BOTTOMLEFT", 252.5, 33)
		MerchantBuyBackItem:Show()
		MerchantExtraCurrencyInset:ClearAllPoints()
		MerchantExtraCurrencyInset:SetPoint("RIGHT", MerchantMoneyInset, "LEFT", 5, 0)
		MerchantExtraCurrencyInset:SetSize(166, 23)
		MerchantExtraCurrencyBg:ClearAllPoints()
		MerchantExtraCurrencyBg:SetPoint("RIGHT", MerchantMoneyBg, "LEFT", -4, 0)
		MerchantExtraCurrencyBg:SetSize(159, 19)

		-- Update the state of the buyback button
		MerchantPlus_UpdateBuyback()

		-- Show the frame backgrounds related to the repair and buyback
		MerchantFrameBottomLeftBorder:Show()
		MerchantFrameBottomRightBorder:Show()

		MerchantPlus_List()
	end
end

function MerchantPlus_List()
	MerchantItems = {}
	local items = GetMerchantNumItems()
	for i = 1, items do
		local item = {}
		item.itemKey = { itemID = GetMerchantItemID(i) }
		item.name, item.texture, item.price, item.quantity, item.numAvailable, item.isPurchasable, item.isUsable, item.extendedCost = GetMerchantItemInfo(i)
		item.index = i
		item.tooltip = C_TooltipInfo.GetMerchantItem(i)
		MerchantItems[i] = item
	end
	MerchantPlusItemList:RefreshScrollFrame()
end

-- Blizzard doesn't put this functionality in a separate function so we have to
-- duplicate it here.
function MerchantPlus_UpdateBuyback()
	local numBuybackItems = GetNumBuybackItems();
	local buybackName, buybackTexture, buybackPrice, buybackQuantity, buybackNumAvailable, buybackIsUsable, buybackIsBound = GetBuybackItemInfo(numBuybackItems);
	if ( buybackName ) then
		MerchantBuyBackItemName:SetText(buybackName);
		SetItemButtonCount(MerchantBuyBackItemItemButton, buybackQuantity);
		SetItemButtonStock(MerchantBuyBackItemItemButton, buybackNumAvailable);
		SetItemButtonTexture(MerchantBuyBackItemItemButton, buybackTexture);
		MerchantFrameItem_UpdateQuality(MerchantBuyBackItem, GetBuybackItemLink(numBuybackItems), buybackIsBound);
		MerchantBuyBackItemMoneyFrame:Show();
		MoneyFrame_Update("MerchantBuyBackItemMoneyFrame", buybackPrice);
		MerchantBuyBackItem:Show();

	else
		MerchantBuyBackItemName:SetText("");
		MerchantBuyBackItemMoneyFrame:Hide();
		SetItemButtonTexture(MerchantBuyBackItemItemButton, "");
		SetItemButtonCount(MerchantBuyBackItemItemButton, 0);
		MerchantFrameItem_UpdateQuality(MerchantBuyBackItem, nil);
		-- Hide the tooltip upon sale
		if ( GameTooltip:IsOwned(MerchantBuyBackItemItemButton) ) then
			GameTooltip:Hide();
		end
	end
end

local function MerchantPlus_SearchStarted()
	return true
end

local function MerchantPlus_GetEntry(index)
	return MerchantItems[index]
end

local function MerchantPlus_GetNumEntries()
	return #MerchantItems
end

local function MerchantPlus_TableBuilderLayout(tableBuilder)
	tableBuilder:SetHeaderContainer(MerchantPlusItemList:GetHeaderContainer())

	local function AddColumn(tableBuilder, title, cellType, index, fixed, width, leftPadding, rightPadding, ...)
		local column = tableBuilder:AddColumn()
		column:ConstructHeader("BUTTON", "AuctionHouseTableHeaderStringTemplate", MerchantPlusItemList, title, index)
		column:ConstructCells("FRAME", cellType, ...)
		if fixed then
			column:SetFixedConstraints(width, 0)
		else
			column:SetFillConstraints(width, 0)
		end
		column:SetCellPadding(leftPadding, rightPadding)
		return column
	end

	-- Stack
	AddColumn(tableBuilder, "Stack", "MerchantPlusTableNumberTemplate", MP_STACK, true, 44, 0, 8, "quantity")

	-- Supply
	AddColumn(tableBuilder, "Supply", "MerchantPlusTableNumberTemplate", MP_SUPPLY, true, 50, 0, 8, "numAvailable")

	-- Item Name
	AddColumn(tableBuilder, "Item", "AuctionHouseTableCellItemDisplayTemplate", MP_ITEM, false, 1, 4, 0, MerchantPlusItemList, false, false)

	-- Price
	AddColumn(tableBuilder, "Price", "MerchantPlusTablePriceTemplate", MP_PRICE, true, 146, 0, 14)

	-- Available
	AddColumn(tableBuilder, "Available", "MerchantPlusTableTextTemplate", MP_AVAIL, true, 58, 8, 0, "isPurchasable")
end


MerchantPlusTableNumberMixin = CreateFromMixins(TableBuilderCellMixin)
MerchantPlusTableTextMixin   = CreateFromMixins(TableBuilderCellMixin)
MerchantPlusTablePriceMixin  = CreateFromMixins(TableBuilderCellMixin)

function MerchantPlusTableNumberMixin:Init(key)
	self.key = key
end

function MerchantPlusTableTextMixin:Init(key)
	self.key = key
end

function MerchantPlusTableNumberMixin:Populate(data, index)
	local key = self.key

	if key == "numAvailable" then
		if data[key] > 0 then
			self.Text:SetText(data[key])
		else
			self.Text:SetText("∞")
		end
	elseif key == "quantity" and data[key] > 1 then
		self.Text:SetText(data[key])
	else
		self.Text:SetText("")
	end
end

function MerchantPlusTableTextMixin:Populate(data, index)
	local key = self.key

	if key == "isPurchasable"  then
		self.Text:SetText(data[key] and "Yes" or "No")
	else
		self.Text:SetText("")
	end
end

function MerchantPlusTablePriceMixin:Populate(data, index)
	self.AltCurrencyDisplay:SetShown(data.extendedCost)
	self.MoneyDisplay:SetShown(data.price > 0)
	local color = HIGHLIGHT_FONT_COLOR
	if CanAffordMerchantItem(data.index) == false then -- returns nil on gold items
		color = DISABLED_FONT_COLOR
	end

	if data.extendedCost then
		local items  = GetMerchantItemCostInfo(data.index)
		for i = 1, MAX_ITEM_COST do
			-- Put the most significant currency on the right instead of left
			-- by reversing the order of the items displayed
			local r = 1 + items - i
			local texture, value, link = GetMerchantItemCostItem(data.index, r)
			local currency = self.AltCurrencyDisplay['Item' .. i]
			if texture and value > 0 and r <= items then
				currency:SetText(value)
				local _, frame = currency:GetRegions()
				frame:SetTexture(texture)
				frame:ClearAllPoints()
				frame:SetSize(13, 13)
				frame:SetPoint("RIGHT", currency, "RIGHT", 0, 0)
				currency.Text:ClearAllPoints()
				currency.Text:SetPoint("RIGHT", frame, "LEFT", 0, 0)
				currency:SetWidth(max(currency:GetTextWidth() + 13, 32))

				-- Color the frame if the player can't afford this
				currency.Text:SetTextColor(color.r, color.g, color.b)

				-- Enable SmallDenominationTemplate to handle Tooltips
				currency.index = data.index
				currency.item  = r
				currency:Show()
			else
				currency:Hide()
				currency.index = nil
				currency.item  = nil
			end
		end
	end
	if data.price > 0 then
		self.MoneyDisplay:SetAmount(data.price)
		self.MoneyDisplay.CopperDisplay.Text:SetTextColor(color.r, color.g, color.b)
		self.MoneyDisplay.SilverDisplay.Text:SetTextColor(color.r, color.g, color.b)
		self.MoneyDisplay.GoldDisplay.Text:SetTextColor(color.r, color.g, color.b)
	end
end

MerchantPlusItemListMixin = {}

function MerchantPlusItemListMixin:OnLoad()
	self.headers = {}
	self.RefreshFrame:Hide()
	self.Background:SetAtlas("auctionhouse-background-index", true)
	self.Background:SetPoint("TOPLEFT", MerchantPlusItemList.HeaderContainer, "BOTTOMLEFT", 3, -3)
	self.Background:SetPoint("BOTTOMRIGHT", -3, 2)
	self.NineSlice:ClearAllPoints()
	self.NineSlice:SetPoint("TOPLEFT", MerchantPlusItemList.HeaderContainer, "BOTTOMLEFT", 0, 0)
	self.NineSlice:SetPoint("BOTTOMRIGHT")
end

function MerchantPlusItemListMixin:RegisterHeader(header)
	table.insert(self.headers, header)
end

function MerchantPlusItemListMixin:SetupSortManager()
	local sortManager = SortUtil.CreateSortManager()
	sortManager:SetDefaultComparator(function(lhs, rhs)
		return lhs.rowData.itemKey.itemID < rhs.rowData.itemKey.itemID
	end)

	sortManager:SetSortOrderFunc(function()
		return self.sortOrder
	end)

	sortManager:InsertComparator(MP_ITEM, function(lhs, rhs)
		return SortUtil.CompareUtf8i(lhs.rowData.name, rhs.rowData.name)
	end)

	self.sortManager = sortManager
end

function MerchantPlusItemListMixin:GetSortOrderState(index)
	return self.sortState
end

function MerchantPlusItemListMixin:SetSortOrder(index)
	if self.sortOrder == index then
		if self.sortState == 1 then
			self.sortState = 1
		else
			self.sortState = 2
		end
	else
		self.sortOrder = index
		self.sortState = 0
	end
	--self.ScrollBox:GetDataProvider():Sort()
end

function MerchantPlusItemListMixin:GetSortOrder()
	return { self.sortOrder, self.sortState }
end


MerchantPlusItemListLineMixin = CreateFromMixins(TemplatedListElementMixin, TableBuilderRowMixin)

function MerchantPlusItemListLineMixin:InitLine()
end

function MerchantPlusItemListLineMixin:OnLineEnter()
	self.HighlightTexture:Show()
	-- Hide tooltip if Alt is held down
	if not IsAltKeyDown() then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -420, 0)
		GameTooltip:SetMerchantItem(self.rowData.index)
		GameTooltip_ShowCompareItem(GameTooltip)
	end
	if CanAffordMerchantItem(self.rowData.index) == false then
		SetCursor("BUY_ERROR_CURSOR")
	else
		SetCursor("BUY_CURSOR")
	end
end

function MerchantPlusItemListLineMixin:OnLineLeave()
	self.HighlightTexture:Hide()
	GameTooltip:Hide()
	ResetCursor()
end

function MerchantPlusItemListLineMixin:OnHide()
	-- TODO: Confirm this is needed
	if ( self.hasStackSplit == 1 ) then
		StackSplitFrame:Hide()
	end
end

function MerchantPlusItemListLineMixin:OnClick(button)
	if IsModifiedClick() then
		-- This should handle most types of modified clicks, like DRESSUP
		if HandleModifiedItemClick(GetMerchantItemLink(self.rowData.index)) then
			return
		end
		-- TODO: This should pop up the the splitstack UI
		if IsModifiedClick("SPLITSTACK") then
			print("splitstack")
		end
	else
		-- TODO:
		-- MerchantFrame.refundItem gets set if the UI is trying to sell back a refundable item
		-- Otherwise calling PickupMerchantItem will attempt to pick up the active item or sell
		-- a held item
		-- Beyond that need to handle high price and extended cost warnings
		-- All cases of right click assuming we want to buy it
	end
end

function MerchantPlusItemListLineMixin:OnDragStart(button)
	-- TODO: The user is trying to pick up an item and drag it somewhere
	print("Dragging")
end

local function MerchantPlus_LineSelected(line, data)
	return false
end

-- Handle any events that are needed
function Addon:HandleEvent(event, target)
	if event == "MERCHANT_SHOW" and not InitialWidth then
		-- Store the width of the frame when it first opened so we can restore it
		InitialWidth = MerchantFrame:GetWidth()
	end

	if event == "ADDON_LOADED" and target == AddonName then

		MerchantPlusItemList:SetLineTemplate("MerchantPlusItemListLineTemplate")
		MerchantPlusItemList:SetSelectionCallback(MerchantPlus_LineSelected)
		MerchantPlusItemList:SetupSortManager()
		MerchantPlusItemList:SetTableBuilderLayout(MerchantPlus_TableBuilderLayout)
		MerchantPlusItemList:SetDataProvider(MerchantPlus_SearchStarted, MerchantPlus_GetEntry, MerchantPlus_GetNumEntries)
	end
end

-- These are init steps specific to this addon
-- This should be run before Core:Init()
function Addon:Init()
	hooksecurefunc("MerchantFrame_Update", MerchantPlus_Update)

	local alreadyloaded, finished = IsAddOnLoaded("Blizzard_AuctionHouseUI")
	if not finished and not alreadyloaded then
		local loaded, reason = LoadAddOn("Blizzard_AuctionHouseUI")
		if not loaded then
			print("Needed Blizzard_AuctionHouseUI to load, but it didn't load:", reason)
		end
	end

	Addon.Events = CreateFrame("Frame")
	Addon.Events:RegisterEvent("ADDON_LOADED")
	Addon.Events:RegisterEvent("MERCHANT_SHOW")
	Addon.Events:SetScript("OnEvent", Addon.HandleEvent)
end

Addon:Init()
