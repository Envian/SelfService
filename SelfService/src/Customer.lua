local _, ns = ...;

-- Customer Definition
local CustomerClass = {};
CustomerClass.__index = CustomerClass;

ns.getCustomer = function(name)
	if not string.find(name, "-") then
		name = name.."-"..GetRealmName();
	end

	local existing = ns.Customers[name];
	if existing then return existing end;

	local newCustomer = CustomerClass:new(SelfServiceData.Customers[name], name);
	SelfServiceData.Customers[name] = newCustomer;
	ns.Customers[name] = newCustomer;
	return newCustomer;
end

ns.normalizeName = function(name)
	name = name:match("^%s*([^%s-]*)");
	if not name then return nil end;
	return name:lower():gsub("^([\128-\255]?.)", string.upper).."-"..GetRealmName();
end


function CustomerClass:new(data, name)
	data = data or {
		Name = name,
		LastWhisper = 0,
		LastSearch = 0,
		MessagesAvailable = 0,
		CurrentOrder = nil
	}
	data.CurrentOrder = data.CurrentOrder and ns.OrderClass:new(data.CurrentOrder, name);
	setmetatable(data, CustomerClass);
	return data;
end

function CustomerClass:handleCommand(command, message)
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

function CustomerClass:addToOrder(recipeIds)
	if self.CurrentOrder and self.CurrentOrder.State.Phase ~= "ORDERING" then
		self:reply(ns.L.enUS.ORDER_IN_PROGRESS);
		return;
	end

	-- Check recipe Ids. Can we do them?
	for _, recipeId in recipeIds do
		local recipe = ns.Recipes[recipeId];

		if not recipe or not recipe.Owned then
			-- TODO: What do we do if they order something we don't have?
			self:reply(ns.L.enUS.RECIPES_UNAVAILABLE);
			return;
		end
	end

	local addedLinks = {};
	if not self.CurrentOrder then self.CurrentOrder = ns.OrderClass:new(nil, self.Name) end;

	for _, recipeId in recipeIds do
		ns.CurrentOrder = self.CurrentOrder; -- HACK: Enforces exclusivity.
		self.CurrentOrder:addToOrder(ns.Recipes[recipeId]);
		addedLinks:insert(ns.Recipes[recipeId].Link);
	end

	addedLinks:insert(ORDER_PLACED_ENDING);
	self:replyJoin(ns.L.enUS.ORDER_PLACED, addedLinks);
end

function CustomerClass:reply(message)
	if self.MessagesAvailable > 0 then
		self.MessagesAvailable = self.MessagesAvailable - 1;
		SendChatMessage(ns.REPLY_PREFIX .. message, "WHISPER", nil, self.Name);
	end
end

function CustomerClass:replyf(message, ...)
	self:reply(message:format(...));
end

function CustomerClass:whisper(message)
	SendChatMessage(ns.REPLY_PREFIX .. message, "WHISPER", nil, self.Name);
end

function CustomerClass:whisperf(message, ...)
	self:whisper(message:format(...));
end

function CustomerClass:replyJoin(message, list, delim)
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
