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

-- This is a list of Collectable states to be filled in later
Display.CollectableState = {}

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

function Display:Collectable(data)
	local key = self
	if data[key] == Display.CollectableState.Collectable then
		return { atlas = 'bags-icon-addslots' }
	elseif data[key] == Display.CollectableState.Known then
		return { atlas = 'checkmark-minimal-disabled' }
	elseif data[key] == Display.CollectableState.Restricted then
		return { atlas = 'communities-icon-lock' }
	elseif data[key] == Display.CollectableState.Unavailable then
		return '130775'
--		return { atlas = 'common-icon-redx' }
	end
	return nil
end
