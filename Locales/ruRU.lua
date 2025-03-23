--
-- Merchant Plus
--
-- Locales\ruRU.lua -- ruRU Localization File
--
-- Use of this source code is governed by an MIT-style
-- license that can be found in the LICENSE file or at
-- https://opensource.org/licenses/MIT.
--

-- Please use CurseForge to submit localization content for another language:
-- https://www.curseforge.com/wow/addons/merchant-plus/localization

-- luacheck: no max line length

local Locale = GetLocale()
if Locale ~= "ruRU" then return end

local _, Shared = ...
local L = Shared.Locale

L["Available"] = "Доступно"
L["Collectable"] = "Собрано"
L["Expansion"] = "Дополнение"
L["Index"] = "Номер"
L["Item"] = "Предмет"
L["Item ID"] = "ID"
L["Price"] = "Цена"
L["Stack"] = "Стак"
L["Subtype"] = "Подтип"
L["Supply"] = "Кол-во"
L["Type"] = "Тип"
L["Usable"] = "Пригодно"

L["ERROR_FALSE_COLLECTABLE_PET"] = "%s (%d) у этого продавца ошибочно помечен как питомец. Пожалуйста, сообщите об этой проблеме через %s"
L["OPTIONS_DESCRIPTION_COLUMNS"] = "Выберите столбцы, которые будут отображаться у продавцов."
L["OPTIONS_DESCRIPTION_SORT_REMEMBER"] = "Сохраняйте последнюю использованную сортировку при переключении между торговцами. Вы можете сбросить торговца к стандартной сортировке игры, удерживая CTRL при нажатии на заголовок столбца."
L["OPTIONS_DESCRIPTION_TAB_DEFAULT"] = "Используйте расширенный интерфейс торговца для всех торговцев. Стандартная вкладка торговца по-прежнему доступна в любое время."
L["OPTIONS_DESCRIPTION_WINDOW_WIDTH"] = "Установите ширину окна расширенного интерфейса торговца. Рекомендуемое значение — %d. Стандартный размер окна торговца — %d. Убедитесь, что отображаемые столбцы помещаются в окно!"
L["OPTIONS_TITLE_COLUMN_ITEM_SHOW_STACK"] = "Показать размер стака"
L["OPTIONS_TITLE_COLUMN_OPTIONS"] = "Параметры столбца"
L["OPTIONS_TITLE_COLUMNS"] = "Отображаемые столбцы"
L["OPTIONS_TITLE_MAIN"] = "%s Основные параметры"
L["OPTIONS_TITLE_SORT_REMEMBER"] = "Запомнить порядок сортировки"
L["OPTIONS_TITLE_TAB_DEFAULT"] = "Показывать вкладку %s по умолчанию"
L["OPTIONS_TITLE_WINDOW_WIDTH"] = "Ширина торгового окна"
