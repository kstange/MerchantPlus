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

-- Using short keys for these long strings, so enUS needs to be defined as well
L["OPTIONS_TITLE_MAIN"] = "%s Options"
L["OPTIONS_TITLE_TAB_DEFAULT"] = "Show %s tab by default"
L["OPTIONS_DESCRIPTION_TAB_DEFAULT"] = "Use the enhanced merchant interface for all merchants. The standard Merchant tab can still be accessed at any time."
L["OPTIONS_TITLE_SORT_REMEMBER"] = "Remember sort order"
L["OPTIONS_DESCRIPTION_SORT_REMEMBER"] = "Keep the last used sort when switching between merchants."
