--
-- Merchant Plus
--
-- Locales\zhCN.lua -- zhCN Localization File
--
-- Use of this source code is governed by an MIT-style
-- license that can be found in the LICENSE file or at
-- https://opensource.org/licenses/MIT.
--

-- Please use CurseForge to submit localization content for another language:
-- https://www.curseforge.com/wow/addons/merchant-plus/localization

-- luacheck: no max line length

local Locale = GetLocale()
if Locale ~= "zhCN" then return end

local _, Shared = ...
local L = Shared.Locale

-- 以下配置项的默认值为其键名本身
L["Stack"] = "堆叠数"
L["Supply"] = "供应量"
L["Item"] = "物品"
L["Price"] = "价格"
L["Usable"] = "可使用"
L["Available"] = "可购买"
L["Index"] = "索引"
L["Item ID"] = "物品ID"
L["Type"] = "类型"
L["Subtype"] = "子类型"
L["Collectable"] = "可收藏"
L["Expansion"] = "资料片"

-- 以下长文本使用简短键名，因此英文也需显式定义
L["OPTIONS_TITLE_MAIN"] = "%s 主选项"
L["OPTIONS_TITLE_TAB_DEFAULT"] = "默认显示 %s"
L["OPTIONS_DESCRIPTION_TAB_DEFAULT"] = "所有商人默认使用增强界面。\n原版商人界面仍可随时访问。"
L["OPTIONS_TITLE_SORT_REMEMBER"] = "记住排序方式"
L["OPTIONS_DESCRIPTION_SORT_REMEMBER"] = "在不同商人之间切换时，保留上一次的排序方式。\n按住 CTRL 键点击列标题，可将当前商人排序方式重置为游戏默认。"
L["OPTIONS_TITLE_WINDOW_WIDTH"] = "商人窗口宽度"
L["OPTIONS_DESCRIPTION_WINDOW_WIDTH"] = "设置增强界面的窗口宽度。\n推荐 %d，原版宽度为 %d。\n请确保窗口能容纳已勾选显示的列！"
L["OPTIONS_TITLE_COLUMNS"] = "显示的列"
L["OPTIONS_DESCRIPTION_COLUMNS"] = "选择商人界面中需要显示的列。"
L["OPTIONS_TITLE_COLUMN_OPTIONS"] = "列设置项"
L["OPTIONS_TITLE_COLUMN_ITEM_SHOW_STACK"] = "在商品名称后显示堆叠数量"
