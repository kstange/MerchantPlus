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
local Metadata = {}
Shared.Metadata = Metadata

Metadata.FriendlyName = "Merchant Plus"

-- Compatibility for WoW 10.1.0
local GetAddOnMetadata = _G.GetAddOnMetadata or C_AddOns.GetAddOnMetadata

--
Metadata.CellTypes = {
	Item    = "MerchantPlusTableItemTemplate",
	Price   = "MerchantPlusTablePriceTemplate",
	Number  = "MerchantPlusTableNumberTemplate",
	Text    = "MerchantPlusTableTextTemplate",
	Icon    = "MerchantPlusTableIconTemplate",
	Boolean = "MerchantPlusTableBooleanTemplate",
}

-- This table defines the columns for the TableBuilder to use
Metadata.Columns = {
	item = {
		id = 1,
		name = L["Item"],
		celltype = Metadata.CellTypes.Item,
		field = "name",
		required = true,
		default = { order = 3, enabled = true, },
		fixed = false,
		width = 1,
		padding = { 4, 0 },
	},
	price = {
		id = 2,
		name = L["Price"],
		celltype = Metadata.CellTypes.Price,
		field = nil,
		required = true,
		default = { order = 4, enabled = true, },
		fixed = true,
		width = 146,
		padding = { 0, 14 },
	},
	quantity = {
		id = 3,
		name = L["Stack"],
		celltype = Metadata.CellTypes.Number,
		field = "quantity",
		required = false,
		default = { order = 1, enabled = true, },
		fixed = true,
		width = 50,
		padding = { 0, 8 },
	},
	supply = {
		id = 4,
		name = L["Supply"],
		celltype = Metadata.CellTypes.Number,
		field = "numAvailable",
		required = false,
		default = { order = 2, enabled = true, },
		fixed = true,
		width = 58,
		padding = { 0, 8 },
	},
	usable = {
		id = 5,
		name = L["Usable"],
		celltype = Metadata.CellTypes.Boolean,
		field = "isUsable",
		required = false,
		default = { order = 5, enabled = true, },
		fixed = true,
		width = 58,
		padding = { 0, 0 },
	},
	purchasable = {
		id = 6,
		name = L["Available"],
		celltype = Metadata.CellTypes.Boolean,
		field = "isPurchasable",
		required = false,
		default = { order = 6, enabled = true, },
		fixed = true,
		width = 70,
		padding = { 0, 0 },
	},
}

-- A table indicating the defaults for Options by key.
-- Only populate options where the default isn't false
Metadata.Defaults = {
	TabDefault = true,
}

-- A table of function callbacks to call upon setting certain options.
-- This has to be populated by the Addon during its init process, since
-- the functions won't exist by this point, so this should remain empty
-- here.
Metadata.OptionCallbacks = {}

-- AceConfig Options table used to display a panel.
Metadata.Options = {
	type = "group",
	name = format(L["OPTIONS_TITLE_MAIN"], Metadata.FriendlyName) .. "     |cFFAAAAAA" .. (GetAddOnMetadata(AddonName, "Version") or "Unknown"),
	args = {
		TabDefault = {
			name = format(L["OPTIONS_TITLE_TAB_DEFAULT"], Metadata.FriendlyName),
			desc = L["OPTIONS_DESCRIPTION_TAB_DEFAULT"],
			type = "toggle",
			width = "full",
			order = 1,
		},
		SortRemember = {
			name = L["OPTIONS_TITLE_SORT_REMEMBER"],
			desc = L["OPTIONS_DESCRIPTION_SORT_REMEMBER"],
			type = "toggle",
			width = "full",
			order = 2,
		},
	}
}

