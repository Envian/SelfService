local _, ns = ...;

-- Recipe Definition
ns.RecipeClass = {};
ns.RecipeClass.__index = ns.RecipeClass;

local enchantRecipeClass = {};
enchantRecipeClass.__index = enchantRecipeClass;
setmetatable(enchantRecipeClass, ns.RecipeClass);

local craftRecipeClass = {};
craftRecipeClass.__index = craftRecipeClass;
setmetatable(craftRecipeClass, ns.RecipeClass);


function ns.RecipeClass:newEnchant(id, recipe)
	if not recipe or not recipe.Search then error("Recipes require a template with Search criteria") end

	recipe.Name = nil;
	recipe.Owned = false;
	recipe.Id = id;
	recipe.Type = "Enchanting";
	recipe.IsCrafted = false;
	recipe.CraftFocusName = nil;
	recipe.CraftFocusId = nil;
	recipe.Mats = {};

	setmetatable(recipe, enchantRecipeClass);
	return recipe;
end

function ns.RecipeClass:register()
	if ns.Recipes[self.Id] then
		-- Conflict, likely between enchanting Id and other craft Id
		-- This code will likely never run.
		errorf(ns.LOG_CONFLICT, self.Name, ns.Recipes[self.Id].Name);
		errorf(ns.LOG_CONFLICT_HIDING, self.Name);
	else
		ns.Recipes[self.Id] = self;
		for _, searchTerm in ipairs(self.Search) do
			local recipesForResult = ns.Search[searchTerm:lower()] or {};
			recipesForResult[#recipesForResult + 1] = self;
			ns.Search[searchTerm:lower()] = recipesForResult;
		end
	end
end

function enchantRecipeClass:loadFromIndex(index)
	local name, _ = GetCraftInfo(index);

	self.Name = name;
	self.Owned = true;
	self.Link = GetCraftItemLink(index);
	self.CraftFocusName = GetCraftSpellFocus(index);
	self.CraftFocusId = ns.Data.Enchanting_Craft_Focus_Map[GetCraftSpellFocus(index)];
	self.Mats = {};

	-- Load mats
	for n = 1,GetCraftNumReagents(index),1 do
		local matname, _, count, _ = GetCraftReagentInfo(index, n);
		local link = GetCraftReagentItemLink(index, n);
		self.Mats[n] = {
			Name = matname,
			Id = ns.getItemIdFromLink(link),
			Link = link,
			Count = count
		};
	end

	self:register();
end
