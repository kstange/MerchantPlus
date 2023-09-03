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

-- From Metadata.lua
local Metadata = Shared.Metadata
local Callbacks = Metadata.OptionCallbacks

-- From DataFunctions.lua
local Data = Shared.Data

-- From SortFunctions.lua
local Sort = Shared.Sort

-- Push us into shared object
local Addon = {}
Shared.Addon = Addon

-- Push a debugging function into the shared object
local function trace(...)
	if Addon:GetOption("Trace") and ... then
		print(...)
	end
end
Shared.Trace = trace

local InitialWidth = nil
local SwitchOnOpen = false
local BuybackDirty = false

MerchantPlusFrameMixin = {}

-- Re-anchor the Buyback and Currency elements to things that won't move around
function MerchantPlusFrameMixin:OnLoad()
	MerchantExtraCurrencyInset:ClearAllPoints()
	MerchantExtraCurrencyInset:SetPoint("RIGHT", MerchantMoneyInset, "LEFT", 5, 0)
	MerchantExtraCurrencyInset:SetSize(166, 23)
	MerchantExtraCurrencyBg:ClearAllPoints()
	MerchantExtraCurrencyBg:SetPoint("RIGHT", MerchantMoneyBg, "LEFT", -4, 0)
	MerchantExtraCurrencyBg:SetSize(159, 19)
end

MerchantPlusTabMixin = {}

-- Set up the Merchant Plus Tab
function MerchantPlusTabMixin:OnLoad()
	PanelTemplates_SetNumTabs(MerchantPlusTabFrame, #MerchantPlusTabFrame.Tabs)
	PanelTemplates_SetTab(MerchantPlusTabFrame, 0)
end

-- Handle the click on the tab
function MerchantPlusTabMixin:OnClick()
	PanelTemplates_SetTab(MerchantPlusTabFrame, self:GetID())
end

-- Get an option for our own use (fake a request from Ace)
function Addon:GetOption(group, key)
	local table = { group }
	if key ~= nil then
		table.type = "multiselect"
	end
	table.GetOption = Addon.GetAceOption
	return table:GetOption(key)
end

-- Get an option for the AceConfigDialog
function Addon:GetAceOption(key)
	local group = self[#self]

	local value = false;
	local settings = _G[AddonName]

	if self.type == "multiselect" then
		if settings and settings[group] ~= nil then
			value = settings[group][key] or false
		elseif Metadata.Defaults and Metadata.Defaults[group] ~= nil then
			value = Metadata.Defaults[group][key] or false
		end
	else
		if settings and settings[group] ~= nil then
			value = settings[group]
		elseif Metadata.Defaults and Metadata.Defaults[group] ~= nil then
			value = Metadata.Defaults[group]
		end
	end

	return value
end

-- Set an option from the AceConfigDialog
function Addon:SetAceOption(value)
	local key = self[#self]
	if not key then	return nil end

	local settings = _G[AddonName]

	if self.type == "multiselect" then
		if settings then
			if not settings[key] then
				if Metadata.Defaults and Metadata.Defaults[key] then
					settings[key] = Metadata.Defaults[key]
				else
					settings[key] = {}
				end
			end
			if settings[key][value] == nil then
				settings[key][value] = true
			else
				settings[key][value] = nil
			end
		end
	else
		if settings and settings[key] ~= value then
			settings[key] = value
		end
	end
	if Metadata.OptionCallbacks and Metadata.OptionCallbacks[key] then
		local func = Metadata.OptionCallbacks[key]
		func(key, value)
	end
end

-- Actions related to changing the current frame tab
function Addon:SetTab(index)
	-- We only want to act on MerchantFrame
	if self == MerchantFrame then
		trace("called: SetTab MerchantFrame", index)

		-- Reset the filter back to Blizzard's default
		ResetSetMerchantFilter()
		MerchantFrame_UpdateFilterString()

		-- If on tab 1 and Merchant Plus is requested, immediately switch
		if index == 1 and SwitchOnOpen then
			SwitchOnOpen = false
			PanelTemplates_SetTab(MerchantPlusTabFrame, 1)

		-- Otherwise deselect our tab
		else
			if  PanelTemplates_GetSelectedTab(MerchantPlusTabFrame) == 1 then
				PanelTemplates_SetTab(MerchantPlusTabFrame, 0)
			end
		end

	elseif self == MerchantPlusTabFrame then
		trace("called: SetTab MerchantPlusTabFrame", index)

		-- Update MerchantPlusFrame when its tab is selected
		if index == 1 then

			-- We're on the Buyback tab, but we need the merchant to be on
			-- tab 1 so that the native click handlers work properly
			if PanelTemplates_GetSelectedTab(MerchantFrame) == 2 then
				SwitchOnOpen = true

				-- This taints MerchantFrame.selectedTab, but there's no
				-- other way to force the Frame to think it's on the
				-- Merchant tab if transitioning from the Buyback tab.
				--
				-- The taint clears itself if the user transitions to
				-- the Merchant tab manually at any time.
				PanelTemplates_SetTab(MerchantFrame, 1)
			end

			-- Deselect the Merchant tab, since we should always be
			-- transitioning from it, but we don't want to change the
			-- internal value ot selectedTab.
			PanelTemplates_DeselectTab(MerchantFrameTab1)
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

	-- Check if our tab is selected
	local show = PanelTemplates_GetSelectedTab(MerchantPlusTabFrame) == 1

	-- Check if we are on the Buyback tab
	local buyback = PanelTemplates_GetSelectedTab(MerchantFrame) == 2

	-- We should have saved the width, but if not use 336 which has been standard for a while
	local width = show and 800 or InitialWidth or 336

	trace("called: UpdateFrame; show", show)

	-- Set the width of the frame wider or back to the default
	MerchantFrame:SetWidth(width)

	-- Hide or show MerchantItem buttons
	for i = 1, BUYBACK_ITEMS_PER_PAGE do
		local button = _G["MerchantItem"..i]
		button:SetShown(not show and (i <= MERCHANT_ITEMS_PER_PAGE or buyback))
	end

	-- Hide or show the filtering dropdown
	MerchantFrameLootFilter:SetShown(not show)

	-- Set up the frame if our tab is selected
	if show then
		-- Set the portrait and name of the frame
		MerchantFrame:SetTitle(UnitName("npc"))
		MerchantFrame:SetPortraitToUnit("npc")

		-- Hide all the buttons from the merchant page
		MerchantPageText:Hide()
		MerchantPrevPageButton:Hide()
		MerchantNextPageButton:Hide()

		-- Hide the Buyback background
		BuybackBG:Hide()

		-- Update the state of repair buttons
		MerchantFrame_UpdateRepairButtons()

		-- For 10.1.7 - Update the state of the Sell All Junk button
		if C_MerchantFrame.IsSellAllJunkEnabled and C_MerchantFrame.IsSellAllJunkEnabled() then
			-- The button is anchored weirdly unless the Repair Buttons are shown.
			if not CanMerchantRepair() then
				MerchantSellAllJunkButton:ClearAllPoints()
				MerchantSellAllJunkButton:SetPoint("BOTTOM", MerchantFrame, "BOTTOMLEFT", 170, 33)
			end

			local hasJunkItems = C_MerchantFrame.GetNumJunkItems() > 0;
			MerchantSellAllJunkButton.Icon:SetDesaturated(not hasJunkItems);
			MerchantSellAllJunkButton:SetEnabled(hasJunkItems);
			MerchantSellAllJunkButton:Show()
		end

		-- Reanchor and show the Buyback button
		-- Reanchoring works around an issue with ElvUI when switching from the Buyback tab
		MerchantBuyBackItem:ClearAllPoints()
		MerchantBuyBackItem:SetPoint("BOTTOM", MerchantFrame, "BOTTOMLEFT", 263.5, 33)
		MerchantBuyBackItem:Show()

		-- Update the Buyback button if something happened while we weren't looking
		if BuybackDirty then
			Addon:UpdateBuyback()
		end

		-- For 10.1.5 - Show the UndoFrame arrow in the Buyback Button
		if UndoFrame and UndoFrame.Arrow then
			UndoFrame.Arrow:Show()
		end

		-- Show the frame backgrounds related to the repair and buyback
		MerchantFrameBottomLeftBorder:Show()

		-- This was merged into MerchantFrameBottomLeftBorder in 10.1.5
		if MerchantFrameBottomRightBorder then
			MerchantFrameBottomRightBorder:Show()
		end
	end

	-- Show or hide our own frame now that everything is set up
	MerchantPlusFrame:SetShown(show)
end

-- If a buyback happens when we are on the buyback tab, flag that we need to update it next
-- time UpdateFrame() is called.
function Addon:HandleBuyback()
	local buybackTab = PanelTemplates_GetSelectedTab(MerchantFrame) == 2
	trace("called: HandleBuyback", buybackTab)
	if buybackTab then
		BuybackDirty = true
	end
end

-- Blizzard doesn't put this functionality in a separate function so we have to duplicate it here.
-- MerchantFrame_Update() would take care of this when the inventory changes, but only when it
-- thinks the Merchant tab is active, meaning if you buy back from the Buyback tab it will not
-- update.
--
-- This taints the ItemButton and elements, but we will attempt to clear taint when the window
-- closes in hopes that it doesn't spread.
--
-- To minimize how often this gets called, we will only call it if a buyback happens while on
-- the buyback tab.
function Addon:UpdateBuyback()
	local count = GetNumBuybackItems()
	local name, texture, price, quantity, _, _, isBound = GetBuybackItemInfo(count)

	trace("called: UpdateBuyback", name)

	if not BuybackDirty then
		return
	end

	if ( name ) then
		MerchantBuyBackItemName:SetText(name)
		SetItemButtonCount(MerchantBuyBackItemItemButton, quantity)
		SetItemButtonTexture(MerchantBuyBackItemItemButton, texture)
		MerchantFrameItem_UpdateQuality(MerchantBuyBackItem, GetBuybackItemLink(count), isBound)
		MerchantBuyBackItemMoneyFrame:Show()
		MoneyFrame_Update("MerchantBuyBackItemMoneyFrame", price)
	else
		MerchantBuyBackItemName:SetText("")
		SetItemButtonCount(MerchantBuyBackItemItemButton, nil)
		SetItemButtonTexture(MerchantBuyBackItemItemButton, nil)
		MerchantFrameItem_UpdateQuality(MerchantBuyBackItem, nil)
		MerchantBuyBackItemMoneyFrame:Hide()
		MoneyFrame_Update("MerchantBuyBackItemMoneyFrame", 0)
		-- Hide the tooltip upon sale
		if GameTooltip:IsOwned(MerchantBuyBackItemItemButton) then
			GameTooltip:Hide()
		end
	end

	MerchantBuyBackItem:Show()

	BuybackDirty = false
end

-- A callback for when UpdateTableBuilderLayout is called to define the columns that are shown
function Addon:SetTableLayout()
	trace("called: SetTableLayout")
	Data.Functions = {}
	for _, key in ipairs(Metadata.ColumnSort) do
		local col = Metadata.Columns[key]
		local enabled = Addon:GetOption("Columns", key)
		local required = col.required
		trace("column status:", key, enabled)
		if enabled or required then
			if col.datafunctions then
				for _, func in ipairs(col.datafunctions) do
					if type(func) == "function" then
						tInsertUnique(Data.Functions, func)
					end
				end
			end
			MerchantPlusItemList:AddColumn(key, col.name, col.celltype, col.fixed, col.width, col.padding[1], col.padding[2], col)
		end
	end
end

-- Update the displayed columns when they change
function Addon:UpdateColumns()
	MerchantPlusItemList:UpdateTableBuilderLayout()
end

-- Update the saved sort when saving is toggled
function Addon:UpdateSort()
	trace("called: Options_Sort_Update")
	local settings = _G[AddonName]
	local save = Addon:GetOption('SortRemember')
	if save then
		local order, state = MerchantPlusItemList:GetSortOrder()
		if settings then
			settings["SortOrder"] = order or ""
			settings["SortState"] = state or 0
		end
	else
		if settings then
			settings["SortOrder"] = nil
			settings["SortState"] = nil
		end
	end
end

-- Handle any events that are needed
function Addon:HandleEvent(event, target)
	if event == "MERCHANT_SHOW" then
		trace("called: MERCHANT_SHOW")
		-- Store the width of the frame when it first opened so we can restore it
		if not InitialWidth then
			InitialWidth = MerchantFrame:GetWidth()
		end

		-- If the user wants our tab to show by default, flag that for
		-- the next tab switch event
		if Addon:GetOption("TabDefault") then
			SwitchOnOpen = true
		end

		-- Restore the saved sort when opening the vendor if configured
		if Addon:GetOption("SortRemember") then
			local order = Addon:GetOption("SortOrder")
			local state = Addon:GetOption("SortState")
			MerchantPlusItemList:SetSortOrder(order, state)
		else
			MerchantPlusItemList:SetSortOrder("")
		end
	end

	-- This generally means the merchant's contents changed
	if event == "MERCHANT_UPDATE" then
		trace("called: MERCHANT_UPDATE")
		MerchantPlusItemList:RefreshScrollFrame()
	end

	-- I haven't yet found a case where we need to do anything as this is
	-- usually followed by MERCHANT_UPDATE
	if event == "MERCHANT_FILTER_ITEM_UPDATE" then
		trace("called: MERCHANT_FILTER_ITEM_UPDATE")
	end

	if event == "MERCHANT_CLOSED" then
		trace("called: MERCHANT_CLOSED")
		-- Hide the MerchantPlus frame so we don't call OnShow before
		-- MerchantFrame sets itself up.
		MerchantPlusFrame:Hide()
		PanelTemplates_SetTab(MerchantPlusTabFrame, 0)
		-- Close any confirmation dialogs if we are closed
		StaticPopup_Hide("CONFIRM_PURCHASE_NONREFUNDABLE_ITEM")
		StaticPopup_Hide("CONFIRM_PURCHASE_TOKEN_ITEM")
		StaticPopup_Hide("CONFIRM_HIGH_COST_ITEM")
		StaticPopup_Hide("CONFIRM_PURCHASE_ITEM_DELAYED")
		Addon:ClearMerchantTaint()
	end

	-- If player's inventory changed, the items available on the vendor might change
	if event == "UNIT_INVENTORY_CHANGED" then
		trace("called: UNIT_INVENTORY_CHANGED")
		MerchantPlusItemList:RefreshScrollFrame()
	end

	if event == "ADDON_LOADED" and target == AddonName then
		if not  _G[AddonName] then
			_G[AddonName] = {}
		end
		trace("called: ADDON_LOADED")
		-- Don't register options unless they're defined.
		if Metadata.Options then
			Metadata.Options.get = Addon.GetAceOption
			Metadata.Options.set = Addon.SetAceOption
			ACR:RegisterOptionsTable(AddonName, Metadata.Options)
			ACD:AddToBlizOptions(AddonName, Metadata.FriendlyName)
		end
		MerchantPlusItemList.SetTableLayout = Addon.SetTableLayout
		MerchantPlusItemList.SortCallback   = Addon.UpdateSort
		MerchantPlusItemList.GetDataCount   = Data.GetMerchantCount
		MerchantPlusItemList.GetData        = Data.UpdateMerchant
		MerchantPlusItemList.Sort           = Sort.Sort

		-- Detect ElvUI and register callback to apply the skin
		if ElvUI then
			Addon.ElvUI = unpack(ElvUI)
			Addon.ElvUISkin = Addon.ElvUI:GetModule('Skins')
			Addon.ElvUISkin:AddCallbackForAddon('MerchantPlus', 'Merchant Plus', Addon.ElvUILoad)
		end
	end
end

-- Calling native functions may taint variables in secure frames, but we
-- can nil them to hopefully ensure the taint doesn't propagate.
function Addon:ClearTaint(n)
	local t = _G[n]
	trace("called: ClearTaint", n)
	for k in pairs(t) do
		local secure, addon = issecurevariable(t, k)
		if secure == false and addon == AddonName then
			t[k] = nil
			local fixed = issecurevariable(t, k)
			trace("tainted:", n, addon, k, "| cleared:", fixed)
		end
	end
end

-- Provide a function to hook for MerchantFrame actions
function Addon:ClearMerchantTaint()
	Addon:ClearTaint("MerchantFrame")
	Addon:ClearTaint("MerchantBuyBackItem")
	Addon:ClearTaint("MerchantBuyBackItemItemButton")
	Addon:ClearTaint("MerchantBuyBackItemMoneyFrame")
end

-- When the Merchant Frame opens, we need to reskin any headers that may have
-- been created since we last checked
function Addon:ElvUIHeaders()
	trace("called: ElvUIHeaders")
	for i, header in next, { MerchantPlusItemList.HeaderContainer:GetChildren() } do
		if not header.IsSkinned then
			header:DisableDrawLayer('BACKGROUND')
			header:CreateBackdrop('Transparent')
			header.IsSkinned = true
		end
	end
end

-- When loading, if ElvUI is skinning the Merchant Frame, we'll try to adopt
-- the same style
function Addon:ElvUILoad()
	local E = Addon.ElvUI
	local S = Addon.ElvUISkin
	trace("called: ElvUILoad")

	-- Only skin us if the Merchant Frame is skinned
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.merchant) then return end

	trace("skinning: ElvUI")
	S:HandleTab(MerchantPlusTab)
	MerchantPlusTab:ClearAllPoints()
	MerchantPlusTab:Point('TOPLEFT', MerchantFrameTab2, 'TOPRIGHT', -5, 0)

	MerchantPlusFrame:StripTextures()
	MerchantPlusItemList:StripTextures()
	S:HandleTrimScrollBar(MerchantPlusItemList.ScrollBar)
	MerchantPlusItemList.ScrollBar:ClearAllPoints()
	MerchantPlusItemList.ScrollBar:Point('TOPRIGHT', MerchantPlusItemList, -6, -16)
	MerchantPlusItemList.ScrollBar:Point('BOTTOMRIGHT', MerchantPlusItemList, -6, 16)
	MerchantPlusItemList.ScrollBox:SetTemplate('Transparent')
	MerchantPlusItemList.NineSlice:SetTemplate('Transparent')
	MerchantPlusItemList.NineSlice:SetInside(MerchantPlusItemList)
	MerchantPlusItemList:SetTemplate('Transparent')

	hooksecurefunc(MerchantPlusItemList, "RefreshScrollFrame", Addon.ElvUIHeaders)
end

-- These are init steps specific to this addon
function Addon:Init()
	hooksecurefunc("PanelTemplates_SetTab", Addon.SetTab)
	hooksecurefunc("MerchantFrame_Update", Addon.UpdateFrame)

	-- Buyback while on the Buyback tab
	hooksecurefunc("BuybackItem", Addon.HandleBuyback)

	-- Attempt to clear tainted table data from the MerchantFrame
	-- after buying something
	hooksecurefunc("BuyMerchantItem", Addon.ClearMerchantTaint)

	Addon.Events = CreateFrame("Frame")
	Addon.Events:RegisterEvent("ADDON_LOADED")
	Addon.Events:RegisterEvent("MERCHANT_SHOW")
	Addon.Events:RegisterEvent("MERCHANT_UPDATE")
	Addon.Events:RegisterEvent("MERCHANT_FILTER_ITEM_UPDATE")
	Addon.Events:RegisterEvent("MERCHANT_CLOSED")
	Addon.Events:RegisterEvent("UNIT_INVENTORY_CHANGED")
	Addon.Events:SetScript("OnEvent", Addon.HandleEvent)

	Callbacks.SortRemember = Addon.UpdateSort
	Callbacks.Columns = Addon.UpdateColumns
end

Addon:Init()
Data:Init()
