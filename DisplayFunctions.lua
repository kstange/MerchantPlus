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

-- Push us into shared object
local Display = {}
Shared.Display = Display

-- This display function shows an infinity symbol if the supply is infinite (-1)
function Display:Supply(data)
	local key = self
	if data[key] >= 0 then
		return data[key]
	else
		return "∞"
	end
end

-- This display function shows a blank if the stack size is 1 to keep the display clean
function Display:Quantity(data)
	local key = self
	if  data[key] > 1 then
		return data[key]
	else
		return ""
	end
end
