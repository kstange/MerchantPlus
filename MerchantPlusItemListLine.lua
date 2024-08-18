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

-- Import a shared trace function if one exists
local trace = Shared.Trace or function() end

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

-- Import data into the ItemListLine to emulate an ItemButton so native MerchantFrame functions
-- work on them.
function MerchantPlusItemListLineMixin:UpdateButtonData()
	local data = self:GetElementData()

	trace("called: UpdateButtonData", data.index)

	self:SetID(data.index)

	self.price        = data.price > 0 and data.price or nil
	self.extendedCost = data.extendedCost or nil
	self.name         = data.name
	self.link         = data.link
	self.texture      = data.texture
	self.count        = data.quantity
	self.numInStock   = data.numAvailable
	self.hasItem      = true

	self.showNonrefundablePrompt = not C_MerchantFrame.IsMerchantItemRefundable(data.index)

end

-- This should handle all the work related to previewing or buying items.
function MerchantPlusItemListLineMixin:OnClick(button)
	trace("clicked:", button)

	self:UpdateButtonData()

	-- Call the OnModifiedClick function for MerchantItemButton
	if IsModifiedClick() then
		MerchantItemButton_OnModifiedClick(self, button)

	-- Call the OnClick function for MerchantItemButton
	else
		MerchantItemButton_OnClick(self, button)
	end
end

-- This function is called by SplitStackFrame when submitting to
-- actually purchase the requested number of items.
function MerchantPlusItemListLineMixin:SplitStack(split)
	local data = self:GetElementData()

	trace("called: SplitStack", split)

	self:UpdateButtonData()

	if data.extendedCost or data.showNonrefundablePrompt then
		MerchantFrame_ConfirmExtendedItemCost(self, split)
	elseif split > 0 then
		BuyMerchantItem(data.index, split)
	end
end
