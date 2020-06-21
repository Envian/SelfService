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

ns.CustomerCommands = {
	search = function(customer, message)
		-- Only allow searching with a small delay.
		if time() - customer.LastSearch < 2 then return end;
		customer.LastSearch = time();

		-- Do we have links? Check links
		local links = ns.getLinkedItemIds(message);
		if #links > 0 then
			local requestedRecipe = ns.Recipes[links[1]];
			if requestedRecipe and requestedRecipe.Owned then
				customer:replyf(ns.L.enUS.RECIPES_OWNED, requestedRecipe.Link);
			else
				customer:reply(ns.L.enUS.RECIPES_UNAVAILABLE);
			end
			return;
		end

		-- Search by terms
		local results = ns.searchRecipes(message);

		if #results > 0 then
			customer:replyJoin("", ns.imap(results, function(result) return result.Link end), " ");
		else
			customer:reply(ns.L.enUS.NO_RESULTS);
		end
	end,

	buy = function(customer, message)
		-- HACK: Enforces Exclusivity
		if ns.CurrentOrder and ns.CurrentOrder.CustomerName ~= customer.Name then
			customer:reply(ns.L.enUS.BUSY);
			return;
		end

		local orders = ns.getLinkedItemIds(message);
		if #orders == 0 then
			local result = ns.searchRecipes(message);
			if #result == 1 then
				orders = { result[1].Id };
			else
				if #result > 1 then
					customer:replyf(ns.L.enUS.ORDER_MULTIPLE_SEARCH_RESULTS, #result);
				else
					customer:reply(ns.L.enUS.NO_RESULTS);
				end
				return;
			end
		end
		customer:addToOrder(orders);
		ns.infof(ns.LOG_ORDER_PLACED, customer.Name, #orders);
	end,

	help = function(customer, message)
		customer:reply(ns.L.enUS.HELP);
	end
};
