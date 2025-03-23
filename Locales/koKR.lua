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
if Locale ~= "koKR" then return end

local _, Shared = ...
local L = Shared.Locale

L["Available"] = "유효함"
L["Collectable"] = "수집가능"
L["Index"] = "순서"
L["Item"] = "아이템"
L["Item ID"] = "아이템 ID"
L["Price"] = "가격"
L["Stack"] = "수량"
L["Subtype"] = "하위분류"
L["Supply"] = "재고"
L["Type"] = "분류"
L["Usable"] = "사용가능"

L["ERROR_FALSE_COLLECTABLE_PET"] = "이 상인의 %s (%d) 아이템이 애완동물로 잘못 표시되어 있습니다. 이 문제를 %s에 알려 주세요."

L["OPTIONS_DESCRIPTION_COLUMNS"] = "상인에게 표시할 항목을 선택합니다."
L["OPTIONS_DESCRIPTION_SORT_REMEMBER"] = "다른 상인을 이용해도 마지막으로 사용한 정렬을 유지합니다. CTRL을 누른 채로 정렬 항목을 클릭하면 게임의 기본 정렬로 되돌릴 수 있습니다."
L["OPTIONS_DESCRIPTION_TAB_DEFAULT"] = "개선된 상인 인터페이스를 모든 상인에게 적용합니다. 기본 상인 탭으로 언제든지 전환할 수 있습니다."
L["OPTIONS_DESCRIPTION_WINDOW_WIDTH"] = "개선된 상인 인터페이스의 가로 폭을 설정합니다. 추천 값은 %d입니다. 기본 상인 창의 크기는 %d입니다. 각 항목의 폭이 잘 맞는지 확인하세요!"
L["OPTIONS_TITLE_COLUMNS"] = "표시되는 항목"
L["OPTIONS_TITLE_MAIN"] = "%s 주요 설정"
L["OPTIONS_TITLE_SORT_REMEMBER"] = "정렬 순서 기억하기"
L["OPTIONS_TITLE_TAB_DEFAULT"] = "%s 탭을 기본적으로 보여주기"
L["OPTIONS_TITLE_WINDOW_WIDTH"] = "상인 창 가로 폭"
