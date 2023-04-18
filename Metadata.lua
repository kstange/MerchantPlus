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

