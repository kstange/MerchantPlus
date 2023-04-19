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
	local data = self:GetElementData()
	self.HighlightTexture:Show()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetMerchantItem(data.index)
	-- Show compare only on shift key since tooltips are so far right
	if IsShiftKeyDown() then
		GameTooltip_ShowCompareItem(GameTooltip)
	end
	if CanAffordMerchantItem(data.index) == false then
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
	if ( self.hasStackSplit == 1 ) then
		StackSplitFrame:Hide()
	end
end

-- Override GetID to return the Merchant index for MerchantFrame's benefit
function MerchantPlusItemListLineMixin:GetID()
	local data = self:GetElementData()
	return data.index
end

-- This should handle all the work related to previewing or buying items.
function MerchantPlusItemListLineMixin:OnClick(button)
	local data = self:GetElementData()

	-- TODO: I am not getting right clicks?
	if Addon.Trace then print("clicked:", button) end

	-- Allow us to just call built-in Merchant functions
	local realtab = MerchantFrame.selectedTab
	MerchantFrame.selectedTab = 1

	-- This helps the MerchantFrame functions work
	-- TODO: Automatically replicate the data into the line to make
	--       this more reliable and use self in SplitStack() as well.
	self.extendedCost = data.extendedCost
	self.showNonrefundablePrompt = data.showNonrefundablePrompt
	self.price = data.price
	self.count = data.count
	self.link = data.link
	self.name = data.name
	self.texture = data.texture

	-- Call the OnModifiedClick function for MerchantItemButton
	if IsModifiedClick() then
		MerchantItemButton_OnModifiedClick(self, button)

	-- Call the OnClick function for MerchantItemButton
	else
		MerchantItemButton_OnClick(self, button)
	end
	MerchantFrame.selectedTab = realtab
end

-- This function is called by SplitStackFrame when submitting to
-- actually purchase the requested number of items.
function MerchantPlusItemListLineMixin:SplitStack(split)
	local data = self:GetElementData()

	if Addon.Trace then print("splitstack:", split) end

	-- This function helps MerchantFrame functions find the item index
	data.GetID = function()
		local data = self:GetElementData()
		return data.index
	end

	if data.extendedCost or data.showNonrefundablePrompt then
		MerchantFrame_ConfirmExtendedItemCost(data, split)
	elseif split > 0 then
		BuyMerchantItem(data.index, split)
	end
end

-- This should happen if a user picks up an item from the vendor to drag it to their bags, which is
-- not a common action but supported by the default UI.
--function MerchantPlusItemListLineMixin:OnDragStart(button)
	-- TODO: The user is trying to pick up an item and drag it somewhere
	-- Can't seem to get this to fire at all
--end
