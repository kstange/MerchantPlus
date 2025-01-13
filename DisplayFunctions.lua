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

-- Push us into shared object
local Display = {}
Shared.Display = Display

-- This is a list of Collectable states to be filled in later
Display.CollectableState = {}

-- This display function returns the icon and display name for the merchant item
function Display:Item(data, options)
	local name = data.name or ""
	local quality = data.quality
	local quantity = data.quantity
	local texture = data.texture

	-- Apply item quality color
	local color = ITEM_QUALITY_COLORS[quality]
	if color then
		name = color.color:WrapTextInColorCode(name)
	end

	-- Append crafting quality icon
	local craftquality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(data.itemID)
	if craftquality then
		name = name .. " " .. C_Texture.GetCraftingReagentQualityChatIcon(craftquality)
	end

	if name and options['ShowStackSize'] and quantity > 1 then
		name = name .. " (" .. quantity .. ")"
	end

	return name, texture
end

-- This display function shows an infinity symbol if the supply is infinite (-1)
function Display:Supply(data)
	local key = self
	if data[key] >= 0 then
		return data[key]
	else
		return "∞"
	end
end

-- This display function shows a blank if the stack size is 1 to keep the display clean
function Display:Quantity(data)
	local key = self
	if  data[key] > 1 then
		return data[key]
	else
		return ""
	end
end

function Display:Collectable(data)
	local key = self
	if data[key] == Display.CollectableState.Collectable then
		return { atlas = 'bags-icon-addslots' }
	elseif data[key] == Display.CollectableState.Known then
		return { atlas = 'checkmark-minimal-disabled' }
	elseif data[key] == Display.CollectableState.Restricted then
		return { atlas = 'communities-icon-lock' }
	elseif data[key] == Display.CollectableState.Unavailable then
		return '130775'
--		return { atlas = 'common-icon-redx' }
	end
	return nil
end

-- Display the localized expansion name by number rather than the number itself
function Display:ExpansionName(data)
	local key = self
	if data[key] ~= nil then
		return _G['EXPANSION_NAME'..data[key]]
	else
		return ""
	end
end
