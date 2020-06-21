local _, ns = ...;

ns.CustomerCommands = {
	search = function(customer, message)
		-- Only allow searching with a small delay.
		if time() - customer.LastSearch < 2 then return end;
		customer.LastSearch = time();

		local searchResults = ns.searchRecipes(message);
		local resultLinks = {};
		local noHits = {};

		for _, search in ipairs(searchResults) do
			for _, result in ipairs(search.Results) do
				table.insert(resultLinks, result.Link);
			end
		end

		if not ns.isEmpty(resultLinks) then
			customer:replyJoin("", resultLinks);
		else
			customer:reply(ns.L.enUS.NO_RESULTS);
		end
	end,

	buy = function(customer, message)
		-- HACK: Enforces Exclusivity
		if ns.CurrentOrder and ns.CurrentOrder.CustomerName ~= customer.Name then
			customer:reply(ns.L.enUS.BUSY);
		else
			local orders = ns.searchRecipes(message);
			local addedIds = {};

			for _, search in ipairs(orders) do
				if #search.Results > 1 then
					customer:replyf(ns.L.enUS.MULTIPLE_SEARCH_RESULTS, #search.Results, search.Term);
				elseif #search.Results == 1 then
					table.insert(addedIds, search.Results[1].Id);
				end
			end

			if not ns.isEmpty(addedIds) then
				customer.CurrentOrder:handleEvent("ORDER_REQUEST", addedIds);
				ns.infof(ns.LOG_ORDER_PLACED, customer.Name, #addedIds);
			else
				customer:reply(ns.L.enUS.NO_RESULTS);
			end
		end
	end,

	cancel = function(customer, message)
		if not customer.CurrentOrder then
			customer:reply(ns.L.enUS.NO_ORDERS_TO_CANCEL);
		else
			local cancellations = ns.searchRecipes(message);
			local cancelledIds = {};

			for _, search in ipairs(cancellations) do
				if #search.Results > 1 then
					customer:replyf(ns.L.enUS.MULTIPLE_SEARCH_RESULTS, #search.Results, search.Term);
				elseif #search.Results == 1 then
					table.insert(cancelledIds, search.Results[1].Id);
				end
			end

			if not ns.isEmpty(cancelledIds) then
				customer.CurrentOrder:handleEvent("CANCEL_REQUEST", cancelledIds);
				ns.infof(ns.LOG_ORDER_CANCELLED, customer.Name, #cancelledIds);
			else
				customer:reply(ns.L.enUS.NO_RESULTS);
			end
		end
	end,

	status = function(customer)
		if not customer.CurrentOrder then
			customer:reply(ns.L.enUS.INACTIVE_CUSTOMER);
		else
			if not ns.isEmpty(customer.CurrentOrder.Enchants) then
				customer:replyJoin(ns.L.enUS.STATUS_ENCHANTS, ns.getOrderLinks(customer.CurrentOrder.Enchants));
			end

			if not ns.isEmpty(customer.CurrentOrder.Craftables) then
				customer:replyJoin(ns.L.enUS.STATUS_CRAFTS, ns.getOrderLinks(customer.CurrentOrder.Craftables));
			end
		end
	end,

	help = function(customer, message)
		customer:reply(ns.L.enUS.HELP);
	end
};
