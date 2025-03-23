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

L["Available"] = "可购买"
L["Collectable"] = "收藏品"
L["Index"] = "索引"
L["Item"] = "物品"
L["Item ID"] = "物品 ID"
L["Price"] = "价格"
L["Stack"] = "堆叠"
L["Subtype"] = "子类型"
L["Supply"] = "供应量"
L["Type"] = "类型"
L["Usable"] = "可用"

L["ERROR_FALSE_COLLECTABLE_PET"] = "该商家的 %s (%d) 被错误标记为宠物。 请通过 %s 报告此问题"

L["OPTIONS_DESCRIPTION_COLUMNS"] = "选择要显示的栏位。"
L["OPTIONS_DESCRIPTION_SORT_REMEMBER"] = "在不同商人间切换时，保持你选择的排序方式。按住 Ctrl 点击分类标题可以将排序重置为默认。"
L["OPTIONS_DESCRIPTION_TAB_DEFAULT"] = "开启商人界面时，默认显示清单式页面。默认的暴雪商人介面仍可以在分页中切换。"
L["OPTIONS_TITLE_COLUMNS"] = "显示栏位"
L["OPTIONS_TITLE_MAIN"] = "%s 主选项"
L["OPTIONS_TITLE_SORT_REMEMBER"] = "记住排序方向"
L["OPTIONS_TITLE_TAB_DEFAULT"] = "默认显示 %s 分页"
