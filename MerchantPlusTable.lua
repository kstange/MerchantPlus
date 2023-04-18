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

-- This defines a header that can be clicked to sort itself
MerchantPlusTableHeaderStringMixin = CreateFromMixins(TableBuilderElementMixin)

function MerchantPlusTableHeaderStringMixin:OnClick()
	if IsControlKeyDown() then
		self:GetParent():GetParent():SetSortOrder(0)
	else
		self:GetParent():GetParent():SetSortOrder(self.index)
	end
	local headers = { self:GetParent():GetChildren() }
	for _, header in pairs(headers) do
		header:UpdateArrow()
	end
end

function MerchantPlusTableHeaderStringMixin:Init(title, index)
	self:SetText(title)
	self.index = index
	self:UpdateArrow()
	self:SetEnabled(index and true)
end

function MerchantPlusTableHeaderStringMixin:UpdateArrow()
	local order, state = self:GetParent():GetParent():GetSortOrder()
	if order == self.index then
		self.Arrow:Show()
		if state == 0 then
			self.Arrow:SetTexCoord(0, 1, 0, 1)
		elseif state == 1 then
			self.Arrow:SetTexCoord(0, 1, 1, 0)
		end
	else
		self.Arrow:Hide()
	end
end

-- Generic cell mixin for common mixin functions
MerchantPlusTableCellMixin = CreateFromMixins(TableBuilderCellMixin)

function MerchantPlusTableCellMixin:Init(key)
	self.key = key
end

-- This defines a numeric field
MerchantPlusTableNumberMixin = CreateFromMixins(MerchantPlusTableCellMixin)

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

-- This defines a text field
MerchantPlusTableTextMixin = CreateFromMixins(MerchantPlusTableCellMixin)

function MerchantPlusTableTextMixin:Populate(data, index)
	local key = self.key

	if key == "isPurchasable" or key == "isUsable" then
		self.Text:SetText(data[key] and "Yes" or "No")
	else
		self.Text:SetText("")
	end
end

-- This defines a field for showing an icon
MerchantPlusTableIconMixin = CreateFromMixins(MerchantPlusTableCellMixin)

function MerchantPlusTableIconMixin:Populate(data, index)
	local key = self.key

	if data[key] then
		self.Icon:SetTexture(data[key])
	end
end

-- This defines a field for showing a boolean checkmark
MerchantPlusTableBooleanMixin = CreateFromMixins(MerchantPlusTableCellMixin)

function MerchantPlusTableBooleanMixin:Populate(data, index)
	local key = self.key

	self.Icon:SetShown(data[key])
end

-- This defines a field for showing prices
MerchantPlusTablePriceMixin = CreateFromMixins(TableBuilderCellMixin)

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

-- This defines a field for showing items
MerchantPlusTableItemMixin = CreateFromMixins(TableBuilderCellMixin)

function MerchantPlusTableItemMixin:Populate(data, index)
	local name = data.name or "Unknown Item"
	local quality = select(3, GetItemInfo(data.itemKey.itemID))
	local color = ITEM_QUALITY_COLORS[quality]
	local craftquality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(data.itemKey.itemID)
	local icon = ""
	if craftquality then
		icon = C_Texture.GetCraftingReagentQualityChatIcon(craftquality)
	end
	if color then
		self.Text:SetText(color.color:WrapTextInColorCode(name) .. " " .. icon)
	else
		self.Text:SetText(name .. " " .. icon)
	end
	self.Icon:SetTexture(data.texture)
end
