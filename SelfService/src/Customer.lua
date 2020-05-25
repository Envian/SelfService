local _, ns = ...;

ns.getCustomer = function(name)
	if not string.find(name, "-") then
		name = name.."-"..GetRealmName();
	end

	local existing = ns.Customers[name];
	if existing then return existing end;

	local newCustomer = ns.CustomerClass:new(SelfServiceData.Customers[name], name);
	SelfServiceData.Customers[name] = newCustomer;
	ns.Customers[name] = newCustomer;
	return newCustomer;
end

ns.normalizeName = function(name)
	name = name:match("^%s*([^%s-]*)");
	if not name then return nil end;
	return name:gsub("^([\128-\255]?.)", string.upper).."-"..GetRealmName();
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
	data.CurrentOrder = data.CurrentOrder and ns.OrderClass:new(data.CurrentOrder, name);
	setmetatable(data, ns.CustomerClass);
	return data;
end

function ns.CustomerClass:handleCommand(command, message)
	-- Do we send a greeting?
	if self.LastWhisper == 0 then
		ns.infof(ns.LOG_NEW_CUSTOMER, self.Name);
		self.MessagesAvailable = 1; -- Allows an extra message in this case.
		self:reply(ns.L.enUS.FIRST_TIME_CUSTOMER);
	elseif GetTime() - self.LastWhisper > 30 * 60 then
		ns.infof(ns.LOG_RETURNING_CUSTOMER, self.Name);
		self.MessagesAvailable = 1;
		self:reply(ns.L.enUS.RETURNING_CUSTOMER);
	end

	self.MessagesAvailable = 2; -- Safeguard against spam.

	local cmdFunction = ns.CustomerCommands[command:lower()];
	if not cmdFunction then
		self:reply(ns.L.enUS.UNKNOWN_COMMAND);
	else
		cmdFunction(self, message);
	end

	self.LastWhisper = GetTime();
	self.MessagesAvailable = 0;
end

function ns.CustomerClass:getOrder()
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
			self.CurrentOrder = order;
			ns.CurrentOrder = self.CurrentOrder;
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

function ns.CustomerClass:whisper(message)
	SendChatMessage(ns.REPLY_PREFIX .. message, "WHISPER", nil, self.Name);
end

function ns.CustomerClass:whisperf(message, ...)
	self:whisper(message:format(...));
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
