--
-- Merchant Plus
--
-- Locales\zhTW.lua -- zhTW Localization File
--
-- Use of this source code is governed by an MIT-style
-- license that can be found in the LICENSE file or at
-- https://opensource.org/licenses/MIT.
--

-- Please use CurseForge to submit localization content for another language:
-- https://www.curseforge.com/wow/addons/merchant-plus/localization

-- luacheck: no max line length

local Locale = GetLocale()
if Locale ~= "zhTW" then return end

local _, Shared = ...
local L = Shared.Locale

L["Available"] = "可購買"
L["Collectable"] = "可收藏"
L["Index"] = "索引"
L["Item"] = "物品"
L["Item ID"] = "物品 ID"
L["Price"] = "價格"
L["Stack"] = "堆疊"
L["Subtype"] = "子類型"
L["Supply"] = "供應量"
L["Type"] = "類型"
L["Usable"] = "可用"

L["ERROR_FALSE_COLLECTABLE_PET"] = "此商家的 %s (%d) 被標示錯誤為寵物。請透過 %s 回報此問題"

L["OPTIONS_DESCRIPTION_COLUMNS"] = "選擇要在商人清單中顯示的欄位。"
L["OPTIONS_DESCRIPTION_SORT_REMEMBER"] = "在不同商人間切換時，保持你選擇的排序方式。按住 Ctrl 點擊分類標題欄可以恢復為預設排序。"
L["OPTIONS_DESCRIPTION_TAB_DEFAULT"] = "預設開啟清單式頁面。原版的商人頁面可以在分頁中切換。"
L["OPTIONS_DESCRIPTION_WINDOW_WIDTH"] = "設定增強商家介面的視窗寬度。建議值為 %d。標準商家視窗大小為 %d。確保顯示的欄位適合視窗!"
L["OPTIONS_TITLE_COLUMN_ITEM_SHOW_STACK"] = "顯示堆疊數量"
L["OPTIONS_TITLE_COLUMN_OPTIONS"] = "欄位選項"
L["OPTIONS_TITLE_COLUMNS"] = "顯示欄位"
L["OPTIONS_TITLE_MAIN"] = "%s 主選項"
L["OPTIONS_TITLE_SORT_REMEMBER"] = "記住排序方式"
L["OPTIONS_TITLE_TAB_DEFAULT"] = "預設顯示 %s 分頁"
L["OPTIONS_TITLE_WINDOW_WIDTH"] = "商家視窗寬度"
