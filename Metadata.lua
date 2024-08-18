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

-- From Locales/Locales.lua
local L = Shared.Locale

-- From DataFunctions.lua
local Data = Shared.Data

-- From DisplayFunctions.lua
local Display = Shared.Display

-- From SortFunctions.lua
local Sort = Shared.Sort

-- Push us into shared object
local Metadata = {}
Shared.Metadata = Metadata

Metadata.FriendlyName = "Merchant Plus"

-- This is a list of Collectable states
Metadata.CollectableState = {
	Unsupported =  -1,
	Collectable =   0,
	Known       =   1,
	Restricted  =   2,
	Unavailable =   3,
}
Data.CollectableState = Metadata.CollectableState
Display.CollectableState = Metadata.CollectableState

-- This is a list of supported cell types
Metadata.CellTypes = {
	Item    = "MerchantPlusTableItemTemplate",
	Price   = "MerchantPlusTablePriceTemplate",
	Number  = "MerchantPlusTableNumberTemplate",
	Text    = "MerchantPlusTableTextTemplate",
	Icon    = "MerchantPlusTableIconTemplate",
	Boolean = "MerchantPlusTableBooleanTemplate",
}
Sort.CellTypes = Metadata.CellTypes

-- This table defines the columns for the TableBuilder to use
Metadata.Columns = {
	item = {
		name = L["Item"],
		celltype = Metadata.CellTypes.Item,
		field = "name",
		datafunctions = { Data.GetItemInfo },
		required = true,
		fixed = false,
		width = 1,
		padding = { 6, 0 },
	},
	price = {
		name = L["Price"],
		celltype = Metadata.CellTypes.Price,
		field = nil,
		sortfunction = Sort.Price,
		required = true,
		fixed = true,
		width = 146,
		padding = { 0, 14 },
	},
	quantity = {
		name = L["Stack"],
		celltype = Metadata.CellTypes.Number,
		field = "quantity",
		displayfunction = Display.Quantity,
		required = false,
		fixed = true,
		width = 50,
		padding = { 0, 8 },
	},
	supply = {
		name = L["Supply"],
		celltype = Metadata.CellTypes.Number,
		field = "numAvailable",
		displayfunction = Display.Supply,
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
		datafunctions = { Data.GetItemInfo },
		required = false,
		fixed = true,
		width = 92,
		padding = { 8, 0 },
	},
	itemsubtype = {
		name = L["Subtype"],
		celltype = Metadata.CellTypes.Text,
		field = "itemSubType",
		datafunctions = { Data.GetItemInfo },
		required = false,
		fixed = true,
		width = 122,
		padding = { 8, 0 },
	},
	collectable = {
		name = L["Collectable"],
		celltype = Metadata.CellTypes.Icon,
		field = "collectable",
		datafunctions = { Data.GetItemInfo, Data.GetMerchantItemTooltip, Data.GetCollectable },
		displayfunction = Display.Collectable,
		required = false,
		fixed = true,
		width = 88,
		padding = { 0, 0 },
	}
}
Sort.Columns = Metadata.Columns

Metadata.ColumnSort = {
	'quantity',
	'supply',
	'item',
	'price',
	'usable',
	'purchasable',
	'collectable',
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
	WindowWidth = 800,
}

-- A table of function callbacks to call upon setting certain options.
-- This has to be populated by the Addon during its init process, since
-- the functions won't exist by this point, so this should remain empty
-- here.
Metadata.OptionCallbacks = {}

local function ListColumns()
	local columns = {}
	for k, v in pairs(Metadata.Columns) do
		if Metadata.Columns[k].required ~= true then
			columns[k] = v.name
		end
	end
	return columns
end

-- AceConfig Options table used to display a panel.
Metadata.Options = {
	type = "group",
	name = format(L["OPTIONS_TITLE_MAIN"], Metadata.FriendlyName) .. "     |cFFAAAAAA@project-version@",
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
		WindowWidth = {
			name = L["OPTIONS_TITLE_WINDOW_WIDTH"],
			desc = format(L["OPTIONS_DESCRIPTION_WINDOW_WIDTH"], Metadata.Defaults.WindowWidth, 336),
			type = "range",
			min = 336,
			max = 1800,
			step = 1,
			width = "double",
			order = 3,
		},
		Columns = {
			name = L["OPTIONS_TITLE_COLUMNS"],
			desc = L["OPTIONS_DESCRIPTION_COLUMNS"],
			type = "multiselect",
			width = "full",
			order = 4,
			values = ListColumns,
		},
	}
}

