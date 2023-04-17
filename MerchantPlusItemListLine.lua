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

MerchantPlusItemListLineMixin = CreateFromMixins(TemplatedListElementMixin, TableBuilderRowMixin)

-- Upon entering a line, show the tooltip and highlight and update the cursor as appropriate
function MerchantPlusItemListLineMixin:OnLineEnter()
	self.HighlightTexture:Show()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetMerchantItem(self.rowData.index)
	-- Show compare only on shift key since tooltips are so far right
	if IsShiftKeyDown() then
		GameTooltip_ShowCompareItem(GameTooltip)
	end
	if CanAffordMerchantItem(self.rowData.index) == false then
		SetCursor("BUY_ERROR_CURSOR")
	else
		SetCursor("BUY_CURSOR")
	end
end

-- Upon leaving the line, hide the tooltip, highlight, and reset the cursor
function MerchantPlusItemListLineMixin:OnLineLeave()
	self.HighlightTexture:Hide()
	GameTooltip:Hide()
	ResetCursor()
end

-- Steps to be completed when a line is hidden
function MerchantPlusItemListLineMixin:OnHide()
	-- TODO: Confirm this is needed
	if ( self.hasStackSplit == 1 ) then
		StackSplitFrame:Hide()
	end
end

-- This should handle all the work related to previewing or buying items.
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

-- This should happen if a user picks up an item from the vendor to drag it to their bags, which is
-- not a common action but supported by the default UI.
function MerchantPlusItemListLineMixin:OnDragStart(button)
	-- TODO: The user is trying to pick up an item and drag it somewhere
	-- Can't seem to get this to fire at all
	print("Dragging")
end

