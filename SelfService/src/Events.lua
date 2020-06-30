-- This file is part of SelfService.
--
-- SelfService is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- SelfService is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with SelfService.  If not, see <https://www.gnu.org/licenses/>.
local ADDON_NAME, ns = ...;

ns.EVENT = {
	ENABLE = "ENABLED",
	DISABLE = "DISABLED"
}

local handlers = {
	[ns.EVENT.ENABLE] = {},
	[ns.EVENT.DISABLE] = {},
}

function ns.registerEvent(name, handler)
	if not handlers[name] then error("Invalid event passed to registerEvent", 2) end;
	if not type(handler) == "function" then error("Invalid handler passed to registerEvent", 2) end;

	table.insert(handlers[name], handler);
end

local function fireEvent(event, ...)
	for _,handler in ipairs(handlers[event]) do
		handler(...);
	end
end

function ns.enableAddon()
	if not ns.Enabled then
		fireEvent(ns.EVENT.ENABLE);
		ns.Enabled = true;
		ns.print(ns.LOG_ENABLED);
	else
		ns.print(ns.LOG_ALREADY_ENABLED);
	end
end

function ns.disableAddon()
	if ns.Enabled then
		fireEvent(ns.EVENT.DISABLE);
		ns.Enabled = false;
		ns.print(ns.LOG_DISABLED);
	else
		ns.print(ns.LOG_ALREADY_DISABLED);
	end
end
