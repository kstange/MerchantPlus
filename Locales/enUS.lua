--
-- Merchant Plus
--
-- Locales\enUS.lua -- enUS Localization File
--
-- Use of this source code is governed by an MIT-style
-- license that can be found in the LICENSE file or at
-- https://opensource.org/licenses/MIT.
--

-- Please use CurseForge to submit localization content for another language:
-- https://www.curseforge.com/wow/addons/merchant-plus/localization

-- allow enUS to fill empty strings for other locales
--local Locale = GetLocale()
--if Locale ~= "enUS" then return end

local _, Shared = ...
local L = Shared.Locale

-- Defaults for these are the keys themselves
--L["Stack"] = "Stack"
--L["Supply"] = "Supply"
--L["Item"] = "Item"
--L["Price"] = "Price"
--L["Usable"] = "Usable"
--L["Available"] = "Available"
--L["Index"] = "Index"
--L["Item ID"] = "Item ID"
--L["Type"] = "Type"
--L["Subtype"] = "Subtype"
--L["Collectable"] = "Collectable"

-- Using short keys for these long strings, so enUS needs to be defined as well
L["OPTIONS_TITLE_MAIN"] = "%s Main Options"
L["OPTIONS_TITLE_TAB_DEFAULT"] = "Show %s tab by default"
L["OPTIONS_DESCRIPTION_TAB_DEFAULT"] = "Use the enhanced merchant interface for all merchants. The standard merchant tab can still be accessed at any time."
L["OPTIONS_TITLE_SORT_REMEMBER"] = "Remember sort order"
L["OPTIONS_DESCRIPTION_SORT_REMEMBER"] = "Keep the last used sort when switching between merchants. You can reset a merchant to the game's standard sort by holding CTRL while clicking on a column heading."
L["OPTIONS_TITLE_WINDOW_WIDTH"] = "Merchant window width"
L["OPTIONS_DESCRIPTION_WINDOW_WIDTH"] = "Set the width of the merchant window when Merchant Plus is selected. The recommended value is 800. The standard Merchant window size is 336. Make sure your selected columns fit in the window!"
L["OPTIONS_TITLE_COLUMNS"] = "Displayed Columns"
L["OPTIONS_DESCRIPTION_COLUMNS"] = "Select the columns to be shown on merchants."
L["ERROR_FALSE_COLLECTABLE_PET"] = "%s (%d) on this merchant is mislabeled as a pet. Please report this issue via %s"
