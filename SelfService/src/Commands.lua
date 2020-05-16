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

SLASH_SelfService1 = "/selfservice"
SLASH_SelfService2 = "/ss"
SlashCmdList["SelfService"] = function(msg, editbox)
	local msg = msg:lower()
	
	if(msg == "" or msg == nil) then
	    print("- Available SelfService Commands -")
	    print("disable - Turn off the bot")
	    print("enable - Turn on the bot")
	elseif(msg == "disable") then
		-- Call disable function
		print("Bot Disabled.")
	elseif(msg == "enable") then
		-- Call enable function
		print("Bot Enabled.")
	else
		print("Invalid argument.")
	end
end

function SelfServiceDisable()
	-- Disable the bot
end

function SelfServiceEnable()
	-- Enable the bot
end