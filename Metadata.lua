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

-- From SortFunctions.lua
local Sort = Shared.Sort

-- Push us into shared object
local Metadata = {}
Shared.Metadata = Metadata

Metadata.FriendlyName = "Merchant Plus"

-- Compatibility for WoW 10.1.0
local GetAddOnMetadata = _G.GetAddOnMetadata or C_AddOns.GetAddOnMetadata

-- This is a list of supported cell types
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
		name = L["Item"],
		celltype = Metadata.CellTypes.Item,
		field = "name",
		datafunction = "GetItemInfo",
		required = true,
		fixed = false,
		width = 1,
		padding = { 4, 0 },
	},
	price = {
		name = L["Price"],
		celltype = Metadata.CellTypes.Price,
		field = nil,
		sortfunction = Sort.SortPrice,
		required = true,
		fixed = true,
		width = 146,
		padding = { 0, 14 },
	},
	quantity = {
		name = L["Stack"],
		celltype = Metadata.CellTypes.Number,
		field = "quantity",
		required = false,
		fixed = true,
		width = 50,
		padding = { 0, 8 },
	},
	supply = {
		name = L["Supply"],
		celltype = Metadata.CellTypes.Number,
		field = "numAvailable",
		required = false,
		fixed = true,
		width = 58,
		padding = { 0, 8 },
	},
	usable = {
		name = L["Usable"],
		celltype = Metadata.CellTypes.Boolean,
		field = "isUsable",
		required = false,
		fixed = true,
		width = 58,
		padding = { 0, 0 },
	},
	purchasable = {
		name = L["Available"],
		celltype = Metadata.CellTypes.Boolean,
		field = "isPurchasable",
		required = false,
		fixed = true,
		width = 70,
		padding = { 0, 0 },
	},
	index = {
		name = L["Index"],
		celltype = Metadata.CellTypes.Number,
		field = "index",
		required = false,
		fixed = true,
		width = 52,
		padding = { 0, 8 },
	},
	id = {
		name = L["Item ID"],
		celltype = Metadata.CellTypes.Number,
		field = "itemID",
		required = false,
		fixed = true,
		width = 60,
		padding = { 0, 8 },
	},
	itemtype = {
		name = L["Type"],
		celltype = Metadata.CellTypes.Text,
		field = "itemType",
		datafunction = "GetItemInfo",
		required = false,
		fixed = true,
		width = 92,
		padding = { 8, 0 },
	},
	itemsubtype = {
		name = L["Subtype"],
		celltype = Metadata.CellTypes.Text,
		field = "itemSubType",
		datafunction = "GetItemInfo",
		required = false,
		fixed = true,
		width = 122,
		padding = { 8, 0 },
	},
}

Metadata.ColumnSort = {
	'quantity',
	'supply',
	'item',
	'price',
	'usable',
	'purchasable',
	'index',
	'id',
	'itemtype',
	'itemsubtype',
}

-- A table indicating the defaults for Options by key.
-- Only populate options where the default isn't false
Metadata.Defaults = {
	TabDefault = true,
	Columns = {
		quantity    = true,
		supply      = true,
		item        = true,
		price       = true,
		usable      = true,
		purchasable = true,
	},
}

-- A table of function callbacks to call upon setting certain options.
-- This has to be populated by the Addon during its init process, since
-- the functions won't exist by this point, so this should remain empty
-- here.
Metadata.OptionCallbacks = {}

local function ListColumns()
	local columns = {}
	for k, v in pairs(Metadata.Columns) do
		columns[k] = v.name
	end
	return columns
end

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
		Columns = {
			name = L["OPTIONS_TITLE_COLUMNS"],
			desc = L["OPTIONS_DESCRIPTION_COLUMNS"],
			type = "multiselect",
			width = "full",
			order = 3,
			values = ListColumns,
		},
	}
}

