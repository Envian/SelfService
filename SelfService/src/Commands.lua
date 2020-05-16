local _, ns = ...;

ns.Commands = {
	search = function(terms, customer)
		-- Only allow searching with a small delay.
		if GetTime() - customer.LastSearch < 2 then return end;
		customer.LastSearch = GetTime();

		-- Do we have links? Check links
		local linkId = ns.getItemIdFromLink(terms);
		if linkId then
			local requestedRecipe = ns.Recipes[linkId];
			if requestedRecipe and requestedRecipe.Owned then
				customer:replyf(ns.L.enUS.RECIPES_OWNED, requestedRecipe.Link);
			else
				customer:reply(ns.L.enUS.RECIPES_UNAVAILABLE);
			end
			return;
		end

		-- Search by terms
		local results = {};
		for term in terms:gmatch("[^+%s]+") do
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


	help = function(args, customer)
		customer:reply(ns.L.enUS.HELP);
	end,
};
