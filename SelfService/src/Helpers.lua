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

ns.imap = function(list, callback)
	local result = {};
	for index, item in ipairs(list) do
		result[index] = callback(item);
	end
	return result;
end

ns.ifilter = function(list, callback)
	local result = {};
	for index, item in ipairs(list) do
		if callback(item) then result[#result + 1] = item end;
	end
	return result;
end

ns.getItemIdFromLink = function(link, type)
	type = type or "[^:]+"; -- type by default is any. Callers can pass in "item" or "enchant"
	local _, _, result = link:find("\124c[%a%d]+\124H"..type..":(%d+)[^\124]*\124h[^\124]*\124h\124r");
	return tonumber(result);
end

ns.getLinkedItemIds = function(text, type)
	type = type or "[^:]+"; -- type by default is any. Callers can pass in "item" or "enchant"
	local matches = {};
	for match in text:gmatch("\124c[%a%d]+\124H"..type..":(%d+)[^\124]*\124h[^\124]*\124h\124r") do
		matches[#matches + 1] = tonumber(match);
	end
	return matches;
end

ns.getOrderLinks = function(recipes)
	local links = {};

	for _, recipe in ipairs(recipes) do
		table.insert(links, recipe.Link);
	end

	return links;
end

ns.delink = function(text)
	return gsub(text, "\124c[^\124]+\124H[^\124]+\124h(%[[^%]]+%])\124h\124r", "%1");
end

ns.dumpTable = function(table, indent)
	indent = indent or "";

	if #indent >= 20 then
		print("< Truncated >")
		return;
	elseif type(table) == "table" then
		if ns.isEmpty(table) then
			print("{ }");
			return;
		end

		for key,value in pairs(table) do
			if type(value) == "table" then
				print(indent..ns.printType(key)..": {");
				ns.dumpTable(value, indent.."  ");
				print(indent.."}");
			else
				print(indent..ns.printType(key)..": "..ns.printType(value));
			end
		end
	else
		print(ns.printType(table));
	end
end

ns.printType = function(value)
	local actualType = type(value);
	if actualType == "function" then
		return "< Function >";
	elseif actualType == "string" then
		return "\""..value.."\"";
	elseif actualType == "boolean" then
		return value and "true" or "false";
	elseif actualType == "nil" then
		return "nil";
	else
		return value;
	end
end

ns.moneyToString = function(value)
	if type(value) ~= "number" then error("Invalid operand to moneyToString: "..tostring(value), 2) end;

	local copper = value % 100;
	local silver = math.floor(value/100) % 100;
	local gold   = math.floor(value/10000);

	local cashString = ((gold == 0 and silver == 0 and copper == 0) and "0c") or copper > 0 and tostring(copper).."c" or "";
	cashString = ((silver > 0 and tostring(silver).."s") or ((copper > 0 and gold > 0) and "0s") or "")..cashString;
	cashString = ((gold > 0 and tostring(gold).."g") or "")..cashString;

	return cashString;
end

ns.isEmpty = function(table)
	for _, _ in pairs(table) do
		return false
	end
	return true
end

-- Returns targetObject, remainingString, commandStack.
ns.pullFromCommandTable = function(commandObject, commandString)
	if type(commandString) ~= "string" or #commandString == 0 then return commandObject, commandString, {} end;

	local command = nil;
	local remainder = nil;
	local commandStack = {};

	while type(commandObject) == "table" do
		command, remainder = commandString:match("^%s*(%S+)%s*(.*)$");
		if not command then
			return commandObject, commandString, commandStack;
		end

		commandString = remainder;
		commandObject = commandObject[command:lower()];
		commandStack[#commandStack + 1] = command:lower();
	end

	return commandObject, commandString, commandStack;
end

ns.splitCommandArguments = function(arglist)
	if type(arglist) ~= "string" or #arglist == 0 then return {} end;

	local args = {};
	local i = 1;
	for arg in arglist:gmatch("%S+") do
	   args[i] = arg;
	   i = i + 1;
	end

	return args;
end

ns.searchRecipes = function(searchString)
	local results = {}
	-- First pass to pull all links out and add to results list
	searchString = searchString:gsub("\124c.-\124r", function(match) table.insert(results, {Term = match, Results = {ns.Recipes[ns.getItemIdFromLink(match)]}}); return ","; end);

	-- Second pass to get all non-link results
	--for term in searchString:gmatch("[^+,%s]+") do
	-- Comma delimited terms
	for searchTerm in searchString:gmatch("[^,]+") do
		-- Trim whitespace from the ends of the term
		searchTerm = string.lower(searchTerm:gsub("^%s*(.-)%s*$", "%1"));
		local subResults = {};

		-- Each search string within the term
		for subTerm in searchTerm:gmatch("[^+%s]+") do
			local matches = ns.Search[subTerm];

			-- Ignore terms that don't match anything
			if matches then
				if #subResults == 0 then
					subResults = matches;
				else
					-- If we have multiple terms, only show results that match all.
					subResults = ns.ifilter(subResults, function(result)
						for _, match in ipairs(matches) do
							if match.Id == result.Id then return true end;
						end
						return false;
					end);
				end
			end
		end

		table.insert(results, {Term = searchTerm, Results = subResults});
	end

	return results;
end
