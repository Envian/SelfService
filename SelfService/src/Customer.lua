local _, ns = ...;

ns.getCustomer = function(name)
	if not string.find(name, "-") then
		name = name.."-"..GetRealmName();
	end

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

function ns.CustomerClass:new(data, name)
	data = data or {
		Name = name,
		LastWhisper = 0,
		LastSearch = 0,
		MessagesAvailable = 0,
		CurrentOrder = nil
	}
	setmetatable(data, ns.CustomerClass);
	return data;
end

function ns.CustomerClass:getOrder()
	if GetTime() - (self.LastWhisper or 0) > 30 * 60 then
		self.CurrentOrder = nil;
	end
	return self.CurrentOrder;
end

function ns.CustomerClass:addToOrder(recipes)
	local order = self:getOrder();

	-- Temporary
	if order then
		self:reply(ns.L.enUS.ORDER_IN_PROGRESS);
	elseif not recipes or #recipes ~= 1 then
		self:reply(ns.L.enUS.ORDER_LIMIT);
	else
		local recipe = ns.Recipes[recipes[1]];
		if recipe and recipe.Owned then
			order = ns.OrderClass:new(nil, self.Name);
			order:addToOrder({ recipe });
			print("Recipe added to order.");
			self.CurrentOrder = order;
			print("Customer order assigned: "..self.CurrentOrder.CustomerName);
			ns.CurrentOrder = self.CurrentOrder;
			print("Global CurrentOrder assigned: "..ns.CurrentOrder.CustomerName);
			self:replyJoin(ns.L.enUS.ORDER_READY:format(recipe.Name),
				ns:imap(recipe.Mats, function(mat) return mat.Link end));
		else
			self:reply(ns.L.enUS.RECIPES_UNAVAILABLE);
		end
	end
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
