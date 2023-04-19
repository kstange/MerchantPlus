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

local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

local AddonName, Shared = ...

-- From Locales/Locales.lua
local L = Shared.Locale

-- From Metadata.lua
local Metadata = Shared.Metadata
local Callbacks = Metadata.OptionCallbacks

-- Push us into shared object
local Addon = {}
Shared.Addon = Addon

Addon.InitialWidth = nil
Addon.MerchantFilter = nil
Addon.SwitchOnOpen = false
Addon.Trace = false

Addon.MP_ITEM   = 1
Addon.MP_PRICE  = 2
Addon.MP_STACK  = 3
Addon.MP_SUPPLY = 4
Addon.MP_USABLE = 5
Addon.MP_AVAIL  = 6

-- Get an option for the AceConfigDialog
function Addon:GetOption(key)
	if not key then
		if self and self[#self] then
			key = self[#self]
		else
			return nil
		end
	end

	local value = false;
	local settings = _G[AddonName]

	if settings and settings[key] ~= nil then
		value = settings[key]
	elseif Metadata.Defaults and Metadata.Defaults[key] ~= nil then
		value = Metadata.Defaults[key]
	end

	--print("GetOption", key, value)
	return value
end

-- Set an option from the AceConfigDialog
function Addon:SetOption(...)
	local key = self[#self]
	if not key then	return nil end

	local value = ...
	local settings = _G[AddonName]

	--print("SetOption", key, value)
	if settings and settings[key] ~= value then
		settings[key] = value
	end
	if Metadata.OptionCallbacks and Metadata.OptionCallbacks[key] then
		--print("OptionCallback", key)
		local func = Metadata.OptionCallbacks[key]
		func(key, value)
	end
end

-- Actions related to changing the current frame tab
function Addon:SetTab(index)
	-- We only want to act on MerchantFrame
	if self == MerchantFrame then
		if Addon.Trace then print("called: SetTab") end
		if index == 1 and Addon:GetOption("TabDefault") and Addon.SwitchOnOpen then
			Addon.SwitchOnOpen = false
			PanelTemplates_SetTab(MerchantFrame, MerchantFrameTabPlus:GetID());
		end

		-- Update MerchantPlusFrame when its tab is selected
		if index == MerchantFrameTabPlus:GetID() then
			Addon:UpdateFrame()
		end
	end
end

-- This gets called any time that our tab becomes focused or any time MerchantFrame_Update()
-- gets called.  We want to know if Blizzard starts messing with things from other tabs.
function Addon:UpdateFrame()
	-- Don't do anything if the MerchantFrame isn't visible
	if not MerchantFrame:IsShown() then
		return
	end
	if Addon.Trace then print("called: UpdateFrame") end

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
	elseif (normal or buyback) and Addon.MerchantFilter then
		-- Restore the saved filter to the merchant
		SetMerchantFilter(Addon.MerchantFilter)
		Addon.MerchantFilter = nil
		MerchantFrame_Update()
	end

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
	end

	-- Restore the saved sort when switching to this frame
	if show and changed then
		if Addon:GetOption("SortRemember") then
			local sort = Addon:GetOption("SortOrder")
			MerchantPlusItemList:SetSortOrder(sort.order, sort.state)
		else
			MerchantPlusItemList:SetSortOrder(0)
		end
	end

	-- We show our own frame now that everything is done
	MerchantPlusFrame:SetShown(show)
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

function Addon:TableBuilderLayout(tableBuilder)
	if Addon.Trace then print("called: TableBuilderLayout") end
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
	AddColumn(tableBuilder, L["Stack"], "MerchantPlusTableNumberTemplate", Addon.MP_STACK, true, 50, 0, 8, "quantity")

	-- Supply
	AddColumn(tableBuilder, L["Supply"], "MerchantPlusTableNumberTemplate", Addon.MP_SUPPLY, true, 58, 0, 8, "numAvailable")

	-- Item Name
	AddColumn(tableBuilder, L["Item"], "MerchantPlusTableItemTemplate", Addon.MP_ITEM, false, 1, 4, 0)

	-- Price
	AddColumn(tableBuilder, L["Price"], "MerchantPlusTablePriceTemplate", Addon.MP_PRICE, true, 146, 0, 14)

	-- Usable
	AddColumn(tableBuilder, L["Usable"], "MerchantPlusTableBooleanTemplate", Addon.MP_USABLE, true, 58, 8, 0, "isUsable")
	-- Available
	AddColumn(tableBuilder, L["Available"], "MerchantPlusTableBooleanTemplate", Addon.MP_AVAIL, true, 70, 8, 0, "isPurchasable")
end

function Addon:Options_Sort_Update()
	local settings = _G[AddonName]
	local save = Addon:GetOption('SortRemember')
	local key = "SortOrder"
	if save then
		local order, state = MerchantPlusItemList:GetSortOrder()
		if settings then
			settings[key] = {
				order = order or 0,
				state = state or 0,
			}
		end
	else
		if settings then
			settings[key] = nil
		end
	end
end

-- Handle any events that are needed
function Addon:HandleEvent(event, target)
	if event == "MERCHANT_SHOW" then
		if Addon.Trace then print("called: MERCHANT_SHOW") end
		-- Store the width of the frame when it first opened so we can restore it
		if not Addon.InitialWidth then
			Addon.InitialWidth = MerchantFrame:GetWidth()
		end

		-- If the user wants our tab to show by default, flag that for
		-- the next tab switch event
		if Addon:GetOption("TabDefault") then
			Addon.SwitchOnOpen = true
		end
	end

	if event == "MERCHANT_UPDATE" then
		if Addon.Trace then print("called: MERCHANT_UPDATE") end
		MerchantPlusItemList:RefreshScrollFrame()
	end

	if event == "MERCHANT_FILTER_ITEM_UPDATE" then
		if Addon.Trace then print("called: MERCHANT_FILTER_ITEM_UPDATE") end
		MerchantPlusItemList:RefreshScrollFrame()
	end

	if event == "MERCHANT_CLOSED" then
		if Addon.Trace then print("called: MERCHANT_CLOSED") end
		-- Clear the saved filter so it returns to default on reopen
		Addon.MerchantFilter = nil
	end

	if event == "ADDON_LOADED" and target == AddonName then
		if not  _G[AddonName] then
			_G[AddonName] = {}
		end
		-- Don't register options unless they're defined.
		if Metadata.Options then
			Metadata.Options.get = Addon.GetOption
			Metadata.Options.set = Addon.SetOption
			ACR:RegisterOptionsTable(AddonName, Metadata.Options)
			ACD:AddToBlizOptions(AddonName, Metadata.FriendlyName)
		end
		Addon.Trace = Addon:GetOption("Trace")
	end
end

-- These are init steps specific to this addon
function Addon:Init()
	hooksecurefunc("PanelTemplates_SetTab", Addon.SetTab)
	hooksecurefunc("MerchantFrame_Update", Addon.UpdateFrame)

	Addon.Events = CreateFrame("Frame")
	Addon.Events:RegisterEvent("ADDON_LOADED")
	Addon.Events:RegisterEvent("MERCHANT_SHOW")
	Addon.Events:RegisterEvent("MERCHANT_UPDATE")
	Addon.Events:RegisterEvent("MERCHANT_FILTER_ITEM_UPDATE")
	Addon.Events:RegisterEvent("MERCHANT_CLOSED")
	Addon.Events:SetScript("OnEvent", Addon.HandleEvent)

	Callbacks.SortRemember = Addon.Options_Sort_Update
end

Addon:Init()
