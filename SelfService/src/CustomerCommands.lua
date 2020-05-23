local _, ns = ...;

ns.CustomerCommands = {
	search = function(customer, message)
		-- Only allow searching with a small delay.
		if GetTime() - customer.LastSearch < 2 then return end;
		customer.LastSearch = GetTime();

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
		local results = {};
		for term in message:gmatch("[^+%s]+") do
			local matches = ns.Search[string.lower(term)];

			-- Ignore terms that don't match anything
			if matches then
				if #results == 0 then
					for n, result in ipairs(matches) do
						results[n] = result;
					end
				else
					-- If we have multiple terms, only show results that match all.
					results = ns.ifilter(results, function(result)
						for _, newEntry in ipairs(matches) do
							if newEntry.Id == result.Id then return true end;
						end
						return false;
					end);
				end
			end
		end

		if #results > 0 then
			customer:replyJoin("", ns.imap(results, function(result) return result.Link end), " ");
		else
			customer:reply(ns.L.enUS.NO_RESULTS);
		end
	end,

	buy = function(customer, message)
		if ns.CurrentOrder and ns.CurrentOrder.CustomerName ~= customer.Name then
			customer:reply(ns.L.enUS.BUSY);
			return;
		end

		customer:addToOrder(ns.getLinkedItemIds(message));
	end,

	help = function(customer, message)
		customer:reply(ns.L.enUS.HELP);
	end
};
