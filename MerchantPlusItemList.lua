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

-- From MerchantPlus.lua
local Addon = Shared.Addon

MerchantPlusItemListMixin = {}

-- On frame load, set the Background and NineSlice to the correct size for the widget
function MerchantPlusItemListMixin:OnLoad()
	self.headers = {}
	self.RefreshFrame:Hide()
	self.Background:SetAtlas("auctionhouse-background-index", true)
	self.Background:SetPoint("TOPLEFT", MerchantPlusItemList.HeaderContainer, "BOTTOMLEFT", 3, -3)
	self.Background:SetPoint("BOTTOMRIGHT", -3, 2)
	self.NineSlice:ClearAllPoints()
	self.NineSlice:SetPoint("TOPLEFT", MerchantPlusItemList.HeaderContainer, "BOTTOMLEFT")
	self.NineSlice:SetPoint("BOTTOMRIGHT")
end

-- On init, we will need to create various structures
function MerchantPlusItemListMixin:Init()
	if self.isInitialized then
		return
	end

	local view = CreateScrollBoxListLinearView()

	view:SetElementFactory(function(factory, elementData)
		factory("MerchantPlusItemListLineTemplate", function(button, elementData)
			-- Nothing to do
		end)
	end)

	ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view)
	
	local tableBuilder = CreateTableBuilder(nil)
	self.tableBuilder = tableBuilder

	ScrollUtil.RegisterTableBuilder(self.ScrollBox, tableBuilder, function(elementData)
		return elementData
	end)

	self:SetTableBuilderLayout(Addon.TableBuilderLayout)

	-- TODO: Figure out how to use real DataProvider with Sort functionality
	self:SetDataProvider(Addon.SearchStarted, Addon.GetEntry, Addon.GetNumEntries)
	self:SetupSortManager()

	self.isInitialized = true
end

-- This fuction will create a SortManager for helping sort the items that appear
-- in the list.
function MerchantPlusItemListMixin:SetupSortManager()
	local sortManager = SortUtil.CreateSortManager()
	sortManager:SetDefaultComparator(function(lhs, rhs)
		return lhs.rowData.itemKey.itemID < rhs.rowData.itemKey.itemID
	end)

	sortManager:SetSortOrderFunc(function()
		return self.sortOrder
	end)

	sortManager:InsertComparator(Addon.MP_ITEM, function(lhs, rhs)
		return SortUtil.CompareUtf8i(lhs.rowData.name, rhs.rowData.name)
	end)

	self.sortManager = sortManager
end

-- Returns the sortOrderState, which is 0 for ascending and 1 for descending
function MerchantPlusItemListMixin:GetSortOrderState(index)
	return self.sortOrderState
end

-- Set the sort to the header that was selected, or if it's already selected,
-- reverse it
function MerchantPlusItemListMixin:SetSortOrder(index)
	if self.sortOrder == index then
		if self.sortOrderState == 1 then
			self.sortOrderState = 0
		else
			self.sortOrderState = 1
		end
	else
		self.sortOrder = index
		self.sortOrderState = 0
	end
	-- TODO: Actually invoke the sort, but we don't have a DataProvider that
	-- knows how to use SortManager yet
	--self.ScrollBox:GetDataProvider():Sort()
end

-- Returns a table containing the sort order and state
function MerchantPlusItemListMixin:GetSortOrder()
	return { self.sortOrder, self.sortStateState }
end

-- TODO: Implement or eliminate these functions in order to eliminate dep on AuctionHouseItemListMixin
--
--  * SetDataProvider(searchStartedFunc, getEntry, getNumEntries, hasFullResultsFunc)
--  * SetRefreshFrameFunctions(totalQuantityFunc, refreshResultsFunc)
--  * SetTableBuilderLayout(tableBuilderLayoutFunction)
--  * UpdateTableBuilderLayout()
--  * OnShow()
--  * OnUpdate()
--  * Reset()
--  * SetState(state)
--  * ScrollToEntryIndex(entryIndex)
--  * GetScrollBoxDataIndexBegin()
--  * UpdateRefreshFrame()
--  * DirtyScrollFrame()
--  * UpdateSelectionHighlights()
--  * RefreshScrollFrame()
--  * OnScrollBoxScroll(scrollPercentage, visibleExtentPercentage, panExtentPercentage)
--  * GetHeaderContainer()
--
--  These are probably not actually needed:
--  * SetLineOnEnterCallback(callback)
--  * OnEnterListLine(line, rowData)
--  * SetLineOnLeaveCallback(callback)
--  * OnLeaveListLine(line, rowData)
--  * SetRefreshCallback(refreshCallback)
--  * CallRefreshCallback()
--  * SetSelectionCallback(selectionCallback)
--  * SetHighlightCallback(highlightCallback)
--  * SetLineTemplate(lineTemplate, ...)
--  * GetSelectedEntry()
--  * SetSelectedEntryByCondition(condition, scrollTo)
--  * SetCustomError(errorText)
--  * OnScrollBoxRangeChanged(sortPending)

-- These dummy functions mask functions from AuctionHouseItemListMixin and let me know if they get called
-- If anything breaks or logs, I know I have something to investigate
function MerchantPlusItemListMixin:SetLineOnEnterCallback(callback)
	print "SetLineOnEnterCallback called";
end
function MerchantPlusItemListMixin:OnEnterListLine(line, rowData)
	print "OnEnterListLine called";
end
function MerchantPlusItemListMixin:SetLineOnLeaveCallback(callback)
	print "SetLineOnLeaveCallback called";
end
function MerchantPlusItemListMixin:OnLeaveListLine(line, rowData)
	print "OnLeaveListLine called";
end
function MerchantPlusItemListMixin:SetRefreshCallback(refreshCallback)
	print "SetRefreshCallback called";
end
function MerchantPlusItemListMixin:CallRefreshCallback()
	print "CallRefreshCallback called";
end
function MerchantPlusItemListMixin:SetSelectionCallback(selectionCallback)
	print "SetSelectionCallback called";
end
function MerchantPlusItemListMixin:SetHighlightCallback(highlightCallback)
	print "SetHighlightCallback called";
end
function MerchantPlusItemListMixin:SetLineTemplate(lineTemplate, ...)
	print "SetLineTemplate called";
end
function MerchantPlusItemListMixin:GetSelectedEntry()
	print "GetSelectedEntry called";
end
function MerchantPlusItemListMixin:SetSelectedEntryByCondition(condition, scrollTo)
	print "SetSelectedEntryByCondition called";
end
function MerchantPlusItemListMixin:SetCustomError(errorText)
	print "SetCustomError called";
end
function MerchantPlusItemListMixin:OnScrollBoxRangeChanged(sortPending)
	print "OnScrollBoxRangeChanged called";
end

