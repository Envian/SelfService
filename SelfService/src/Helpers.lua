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
	_, _, result = link:find("^\124c[%a%d]+\124H"..type..":(%d+)[^\124]*\124h[^\124]*\124h\124r$");
	return results and results[1] or nil;
end

ns.getLinkedItemIds = function(text, type)
	type = type or "[^:]+"; -- type by default is any. Callers can pass in "item" or "enchant"
	local matches = {};
	for match in text:gmatch("\124c[%a%d]+\124H" .. type .. ":(%d+)[^\124]*\124h[^\124]*\124h\124r") do
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
	elseif not table then
		print(indent.."nil");
		return;
	elseif #table == 0 then
		print(indent.."{ }");
		return;
	else
		for key,value in pairs(table) do
			if type(value) == "table" then
				print(indent..(type(key) == "string" and "\""..key.."\"" or key)..": {");
				ns.dumpTable(value, indent.."  ");
				print("}")
			else
				print(indent..(type(key) == "string" and "\""..key.."\"" or key)..": "..(type(value) == "string" and "\""..value.."\"" or value) or "nil");
			end
		end
	end
end
