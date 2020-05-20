local _, ns = ...

ns.populateEnchantingData = function(enchants)
	for id, enchant in pairs(enchants) do
		enchant.Owned = false;
		enchant.Id = id;
		enchant.Type = "Enchanting";
	end

	for n = 1,GetNumCrafts(),1 do
		local id = ns.getItemIdFromLink(GetCraftItemLink(n));
		if enchants[id] then
			local name, _ = GetCraftInfo(n);

			local enchant = enchants[id];
			enchant.Name = name;
			enchant.Owned = true;
			enchant.Link = GetCraftItemLink(n);
			enchant.Mats = {};

			for i = 1,GetCraftNumReagents(n),1 do
				local matname, _, count, _ = GetCraftReagentInfo(n, i);
				local itemLink = GetCraftReagentItemLink(n, i);
				enchant.Mats[i] = {
					Name = matname,
					Id = ns.getItemIdFromLink(itemLink),
					Link = itemLink,
					Count = count
				};
			end
		end
	end
end

ns.populateEnchantExtraData = function(extras)
	for itemId, recipe in pairs(extras) do
		ns.Recipes[itemId] = recipe;
	end
end

ns.populateGlobalData = function(crafts)
	for id, recipe in pairs(crafts) do
		if ns.Recipes[id] then
			-- Conflict, likely between enchanting Id and other craft Id
			-- This code will likely never run.
			print(string.format(ns.LOG_CONFLICT, recipe.Name, ns.Recipes[id].Name));
			print(string.format(ns.LOG_CONFLICT_HIDING, recipe.Name));
		elseif recipe.Owned then
			ns.Recipes[id] = recipe;
			for index, searchTerm in ipairs(recipe.Search) do
				local recipesForResult = ns.Search[searchTerm:lower()] or {};
				recipesForResult[#recipesForResult + 1] = recipe;
				ns.Search[searchTerm:lower()] = recipesForResult;
			end
		end
	end

	-- Sort search by value, so higher level ones show up first.
	for _,recipes in pairs(ns.Search) do
		-- table.sort(recipes, function(a, b) return a.Level > b.Level end);
	end
end