local _, ns = ...;

ns.Customers = {};
ns.getCustomer = function(name)
	local existing = ns.Customers[name];
	if existing then return existing end;

	local newCustomer = ns.CustomerClass:new(SelfService.Customers[name], name);
	SelfService.Customers[name] = newCustomer;
	ns.Customers[name] = newCustomer;
	return newCustomer;
end

-- Customer Definition
ns.CustomerClass = {};
ns.CustomerClass.__index = ns.CustomerClass;

DEBUG = ns.CustomerClass;

function ns.CustomerClass:new(data, name)
	data = data or {
		Name = name,
		LastWhisper = 0,
		LastSearch = 0,
		MessagesAvailable = 0
	}
	setmetatable(data, ns.CustomerClass);
	return data;
end

-- Hard coded - used to filter messages. Localization would cause issuses
ns.REPLY_PREFIX = "<BOT> ";

function ns.CustomerClass:getCart()
	if GetTime() - (self.LastWhisper or 0) > 30 * 60 then
		self.Cart = nil;
	end
	return self.Cart;
end

function ns.CustomerClass:setCart(recipes)
	local requiredMats = {};
	for _, recipe in ipairs(recipes) do
		for _, mat in ipairs(recipe.Mats) do
			requiredMats[mat.Id] = (requiredMats[mat.Id] or 0) + mat.Count;
		end
	end

	self.Cart = {
		Mats = requiredMats,
		Order = recipes
	};
end

function ns.CustomerClass:reply(message)
	if self.MessagesAvailable > 0 then
		self.MessagesAvailable = self.MessagesAvailable - 1;
		SendChatMessage(ns.REPLY_PREFIX .. message, "WHISPER", nil, self.Name);
	end
end

function ns.CustomerClass:replyf(message, ...)
	self:reply(message:format(...));
end

function ns.CustomerClass:replyJoin(message, list, delim)
	delim = delim or "";
	message = message or "";

	local maxLength = 255 - #ns.REPLY_PREFIX;
	local maxLinks = 5;

	if #list == 0 then
		self:reply(message);
		return;
	end

	message = message .. list[1];
	local _, links = ns.delink(message);

	for n = 2,#list,1 do
		local itemWithoutLinks, newLinks = ns.delink(list[n]);

		if (#ns.delink(message) + #delim + #itemWithoutLinks > maxLength) or (links + newLinks > 5) then
			self:reply(message);
			message = list[n];
			links = newLinks;
		else
			message = message .. delim .. list[n];
			links = links + newLinks;
		end
	end

	self:reply(message, priority);
end
