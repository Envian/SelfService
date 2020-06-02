local _, ns = ...;

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
				print("}")
			else
				print(indent..ns.printType(key)..": "..ns.printType(value));
			end
		end
	else
		print(ns.printType);
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

	local cashString = copper > 0 and tostring(copper).."c" or "";
	cashString = (silver > 0 and tostring(silver).."s ") or ""..cashString;
	cashString = (gold > 0 and tostring(gold).."s ") or ""..cashString;

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

ns.searchRecipes = function(searchString)
	local results = {}
	for term in searchString:gmatch("[^+%s]+") do
		local matches = ns.Search[string.lower(term)];

		-- Ignore terms that don't match anything
		if matches then
			if #results == 0 then
				-- Clones the array (we'll modify it later.)
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
	return results;
end
