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

Addon.InitialWidth = nil
Addon.MerchantItems = {}
Addon.MerchantFilter = nil

Addon.MP_ITEM   = 1
Addon.MP_PRICE  = 2
Addon.MP_STACK  = 3
Addon.MP_SUPPLY = 4
Addon.MP_AVAIL  = 5

-- This allows us to detect when our tab is selected on the MerchantFrame
function Addon:SetTab(index)
	if self == MerchantFrame and index == MerchantFrameTabPlus:GetID() then
		Addon:UpdateFrame()
	end
end

-- This gets called any time that our tab becomes focused or any time MerchantFrame_Update()
-- gets called.  We want to know if Blizzard starts messing with things from other tabs.
function Addon:UpdateFrame()
	local plustab = MerchantFrameTabPlus:GetID()                        -- Our tab ID
	local show    = MerchantFrame.selectedTab == plustab                -- Our tab is requested
	local changed = MerchantFrame.lastTab ~= MerchantFrame.selectedTab  -- The tab was switched
	local buyback = MerchantFrame.selectedTab == 2                      -- Buyback tab is active
	local normal  = MerchantFrame.selectedTab == 1                      -- Normal Merchant tab is active
	local width   = show and 800 or Addon.InitialWidth or 336           -- Fallback to known good width

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
		Addon.MerchantFilter = GetMerchantFilter()
		SetMerchantFilter(LE_LOOT_FILTER_ALL)
	elseif MerchantFilter then
		-- Restore the saved filter to the merchant
		SetMerchantFilter(Addon.MerchantFilter)
		Addon.MerchantFilter = nil
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
		Addon:UpdateBuyback()

		-- Show the frame backgrounds related to the repair and buyback
		MerchantFrameBottomLeftBorder:Show()
		MerchantFrameBottomRightBorder:Show()

		MerchantPlusItemList:RefreshScrollFrame()
	end
end

function Addon:UpdateVendor()
	Addon.MerchantItems = {}
	local items = GetMerchantNumItems()
	for i = 1, items do
		local item = {}
		item.itemKey = { itemID = GetMerchantItemID(i) }
		item.name, item.texture, item.price, item.quantity, item.numAvailable, item.isPurchasable, item.isUsable, item.extendedCost = GetMerchantItemInfo(i)
		item.index = i
		item.tooltip = C_TooltipInfo.GetMerchantItem(i)
		Addon.MerchantItems[i] = item
	end
end

-- Blizzard doesn't put this functionality in a separate function so we have to
-- duplicate it here.
function Addon:UpdateBuyback()
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

function Addon:SearchStarted()
	return true
end

function Addon:GetEntry()
	return self
end

function Addon:GetNumEntries()
	return #Addon.MerchantItems
end

function Addon:TableBuilderLayout(tableBuilder)
	tableBuilder:SetHeaderContainer(MerchantPlusItemList.HeaderContainer)

	local function AddColumn(tableBuilder, title, cellType, index, fixed, width, leftPadding, rightPadding, ...)
		local column = tableBuilder:AddColumn()
		column:ConstructHeader("BUTTON", "MerchantPlusTableHeaderStringTemplate", title, index)
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
	AddColumn(tableBuilder, "Stack", "MerchantPlusTableNumberTemplate", Addon.MP_STACK, true, 50, 0, 8, "quantity")

	-- Supply
	AddColumn(tableBuilder, "Supply", "MerchantPlusTableNumberTemplate", Addon.MP_SUPPLY, true, 58, 0, 8, "numAvailable")

	-- Item Name
	AddColumn(tableBuilder, "Item", "MerchantPlusTableItemTemplate", Addon.MP_ITEM, false, 1, 4, 0)

	-- Price
	AddColumn(tableBuilder, "Price", "MerchantPlusTablePriceTemplate", Addon.MP_PRICE, true, 146, 0, 14)

	-- Available
	AddColumn(tableBuilder, "Available", "MerchantPlusTableTextTemplate", Addon.MP_AVAIL, true, 70, 8, 0, "isPurchasable")
end

-- Handle any events that are needed
function Addon:HandleEvent(event, target)
	if event == "MERCHANT_SHOW" and not Addon.InitialWidth then
		-- Store the width of the frame when it first opened so we can restore it
		Addon.InitialWidth = MerchantFrame:GetWidth()
	end

	if event == "ADDON_LOADED" and target == AddonName then
		-- Things that need to be delayed until after the addon is fully loaded
	end
end

-- These are init steps specific to this addon
function Addon:Init()
	hooksecurefunc("PanelTemplates_SetTab", Addon.SetTab)
	hooksecurefunc("MerchantFrame_Update", Addon.UpdateFrame)

	Addon.Events = CreateFrame("Frame")
	Addon.Events:RegisterEvent("ADDON_LOADED")
	Addon.Events:RegisterEvent("MERCHANT_SHOW")
	Addon.Events:SetScript("OnEvent", Addon.HandleEvent)
end

Addon:Init()
