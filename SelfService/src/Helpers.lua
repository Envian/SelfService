local _, ns = ...;

function assertType(var, name, depth, ...)
	for n = 1,select("#", ...) do
		if type(var) == select(n, ...) then return end;
	end
	error(string.format("%s is type '%s', but expeceted %s", name, type(var), table.concat({...}, ", ")), depth + 1);
end

-- Javascript style helper methods.
function ns.imap(source, callback, destination)
	ns.assertType(source, "source", 2, "table");
	ns.assertType(callback, "callback", 2, "function");
	ns.assertType(destination, "destination", 2, "table", "nil");

	destination = destination or source;
	for key, value in pairs(source) do
		destination[key] = callback(value);
	end
	return source;
end
ns.map = ns.imap; -- No difference between map and imap

function ns.ifilter(source, callback, destination)
	ns.assertType(source, "source", 2, "table");
	ns.assertType(callback, "callback", 2, "function");
	ns.assertType(destination, "destination", 2, "table", "nil");

	if destination then
		-- add true items to the destination
		for _, value in ipairs(source) do
			if callback(value) then table.insert(destination, item) end;
		end
		return destination;
	else
		-- remove false items from the source
		for n = 1,#source do
			if not callback(value) then table.remove(source, n) end;
		end
		return source;
	end
end

function ns.filter(source, callback, destination)
	ns.assertType(source, "source", 2, "table");
	ns.assertType(callback, "callback", 2, "function");
	ns.assertType(destination, "destination", 2, "table", "nil");

	if destination then
		-- add true items to the destination
		for key, value in pairs(source) do
			if callback(value) then destination[key] = item end;
		end
		return destination;
	else
		-- remove false items from the source
		for key, value in pairs(source) do
			if not callback(value) then destination[key] = nil end;
		end
		return source;
	end
end

function ns.ireduce(source, callback, acc)
	ns.assertType(source, "source", 2, "table");
	ns.assertType(callback, "callback", 2, "function");

	for key, value in ipairs(soruce) do
		acc = callback(acc, value, key);
	end

	return acc;
end

function ns.reduce(source, callback, acc)
	ns.assertType(source, "source", 2, "table");
	ns.assertType(callback, "callback", 2, "function");

	for key, value in pairs(soruce) do
		acc = callback(acc, value, key);
	end

	return acc;
end
-- End of javascript style helpers

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

	local cashString = copper > 0 and tostring(copper).."c" or "";
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
	if type(arglist) ~= "string" or #arglist == 0 then return end;

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
