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

-- Import a shared trace function if one exists
local trace = Shared.Trace or function() end

-- This defines a header that can be clicked to sort itself
MerchantPlusTableHeaderStringMixin = CreateFromMixins(TableBuilderElementMixin)

function MerchantPlusTableHeaderStringMixin:OnClick()
	trace("called: Header OnClick", self.key)
	if IsControlKeyDown() then
		self:GetParent():GetParent():SetSortOrder("")
	else
		self:GetParent():GetParent():SetSortOrder(self.key)
	end
	local headers = { self:GetParent():GetChildren() }
	for _, header in pairs(headers) do
		header:UpdateArrow()
	end
end

function MerchantPlusTableHeaderStringMixin:Init(key, title)
	self:SetText(title)
	self.key = key
	self:UpdateArrow()
	self:SetEnabled(key and true)
end

function MerchantPlusTableHeaderStringMixin:UpdateArrow()
	local order, state = self:GetParent():GetParent():GetSortOrder()
	if order == self.key then
		self.Arrow:Show()
		if state == 0 then
			self.Arrow:SetTexCoord(0, 1, 1, 0)
		elseif state == 1 then
			self.Arrow:SetTexCoord(0, 1, 0, 1)
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

-- TODO: Move key-specific behavior to Metadata or format function
function MerchantPlusTableNumberMixin:Populate(data)
	local key = self.key

	if key == "numAvailable" then
		if data[key] >= 0 then
			self.Text:SetText(data[key])
		else
			self.Text:SetText("∞")
		end
	elseif key == "quantity" then
		if  data[key] > 1 then
			self.Text:SetText(data[key])
		else
			self.Text:SetText("")
		end
	else
		self.Text:SetText(data[key])
	end
end

-- This defines a text field
MerchantPlusTableTextMixin = CreateFromMixins(MerchantPlusTableCellMixin)

function MerchantPlusTableTextMixin:Populate(data)
	local key = self.key

	self.Text:SetText(data[key] or "")
end

-- This defines a field for showing an icon
MerchantPlusTableIconMixin = CreateFromMixins(MerchantPlusTableCellMixin)

function MerchantPlusTableIconMixin:Populate(data)
	local key = self.key

	if data[key] then
		self.Icon:SetTexture(data[key])
		self.Icon:Show()
	else
		self.Icon:Hide()
	end
end

-- This defines a field for showing a boolean checkmark
MerchantPlusTableBooleanMixin = CreateFromMixins(MerchantPlusTableCellMixin)

function MerchantPlusTableBooleanMixin:Populate(data)
	local key = self.key

	self.Icon:SetShown(data[key])
end

-- This defines a field for showing prices
MerchantPlusTablePriceMixin = CreateFromMixins(TableBuilderCellMixin)

function MerchantPlusTablePriceMixin:Populate(data)
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
			local texture, value = GetMerchantItemCostItem(data.index, r)
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
		if self.MoneyDisplay.SilverDisplay.amount == 0 and self.MoneyDisplay.GoldDisplay.amount == 0 then
			self.MoneyDisplay.SilverDisplay:Hide()
		end
		self.MoneyDisplay.CopperDisplay.Text:SetTextColor(color.r, color.g, color.b)
		self.MoneyDisplay.SilverDisplay.Text:SetTextColor(color.r, color.g, color.b)
		self.MoneyDisplay.GoldDisplay.Text:SetTextColor(color.r, color.g, color.b)
	end
end

-- This defines a field for showing items
MerchantPlusTableItemMixin = CreateFromMixins(TableBuilderCellMixin)

function MerchantPlusTableItemMixin:Populate(data)
	if data.name then
		local name = data.name
		local quality = data.quality
		local color = ITEM_QUALITY_COLORS[quality]
		local craftquality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(data.itemID)
		local qualityicon = ""
		if craftquality then
			qualityicon = C_Texture.GetCraftingReagentQualityChatIcon(craftquality)
		end
		if color then
			self.Text:SetText(color.color:WrapTextInColorCode(name) .. " " .. qualityicon)
		else
			self.Text:SetText(name .. " " .. qualityicon)
		end
		self.Icon:SetTexture(data.texture)
	else
		self.Text:SetText("")
		self.Icon:SetTexture(134400)
	end
end
