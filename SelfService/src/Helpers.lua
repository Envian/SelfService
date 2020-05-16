local _, ns = ...;

ns.imap = function(table, callback)
	local result = {};
	for index, item in ipairs(table) do
		result[index] = callback(item);
	end
	return result;
end

ns.ifilter = function(table, callback)
	local result = {};
	for index, item in ipairs(table) do
		if callback(item) then result[#result + 1] = item end;
	end
	return result;
end

ns.getItemIdFromLink = function(link)
	local _, _, id = string.find(link, ".*\124H[^:]+:(%d+).*");
	return id and tonumber(id) or nil;
end

ns.delink = function(text)
	return gsub(text, "\124c[^\124]+\124H[^\124]+\124h(%[[^%]]+%])\124h\124r", "%1");
end
