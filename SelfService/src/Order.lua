local _, ns = ...;

-- Order Definition
ns.OrderClass = {};
ns.OrderClass.__index = ns.OrderClass;

-- TODO: PostMVP, add additional fields for archival purposes, e.g. profit
function ns.OrderClass:new(data, customerName)
	data = data or {
		CustomerName = customerName,
		State = ns.OrderStates["ORDER_PLACED"],
		Recipes = nil,
		ItemBalance = {},
		MoneyBalance = 0,
		TradeAttempted = false,
		OrderIndex = 1
	}
	data.State = ns.OrderStates[data.State.Name];
	setmetatable(data, ns.OrderClass);
	return data;
end

function ns.OrderClass:handleEvent(event, ...)
	local currentState = self.State;
	local customer = ns.Customers[self.CustomerName];

	self.State = self.State[event](customer, ...) or self.State;
	for n = 1,10 do
		if self.State == currentState then break; end;

		ns.debugf(ns.LOG_ORDER_STATE_CHANGE, customer.Name, self.State.Name);
		currentState = self.State;
		self.State = self.State.ENTER_STATE(customer) or self.State;
	end
end

function ns.OrderClass:addToOrder(recipes)
	self.Recipes = recipes;
	for _, recipe in ipairs(recipes) do
		self:debit(recipe.Mats);
	end
end

-- function ns.OrderClass:addTradedItems(items, money)
-- 	self.ReceivedMoney = self.ReceivedMoney + money;
-- 	for n = 1,6 do
-- 		if items[n] and items[n].Id then
-- 			self.ReceivedMats[items[n].Id] = (self.ReceivedMats[items[n].Id] or 0) + items[n].Count;
-- 		end
-- 	end
-- end

function ns.OrderClass:isTradeAcceptable(tradeMats) -- table{K, V}, key=itemID, V=+/- number
	local receivedSufficientMats = true;
	tradeMats = ns.Trading.totalTrade();

	for id, count in pairs(self.ItemBalance) do
		if count - (tradeMats[id] or 0) > 0 then
			ns.debugf(ns.LOG_ORDER_INSUFFICIENT_ITEMS, id, tradeMats[id], id, count);
			receivedSufficientMats = false;
		end
	end

	-- Still do not want to accept any trade containing items unrelated to the order
	for id, count in pairs(tradeMats) do
		if not self.ItemBalance[id] then
			ns.debugf(ns.LOG_ORDER_UNDESIRED_ITEM, id, count);
			receivedSufficientMats = false;
		end
	end

	ns.debugf(ns.LOG_ORDER_TRADE_ACCEPTABLE);
	return receivedSufficientMats;
end

function ns.OrderClass:credit(matList, count)
	self:_modifyBalance(matList, -1, count);
end

function ns.OrderClass:debit(matList, count)
	self:_modifyBalance(matList, 1, count);
end

function ns.OrderClass:_modifyBalance(matList, factor, count)
	if type(matList) ~= "table" then
		error("Balance can only be modified with a list of mats.", 3);
	end
	count = count or #matList;
	if type(count) ~= "number" or count < 0 or count > #matList then
		error("Invalid count passed to credit/debit.", 3);
	end


	for n = 1,count do
		id, count = matList[n].Id, matList[n].Count;
		if id then
			self.ItemBalance[id] = (self.ItemBalance[id] or 0) + (count * factor);
			if self.ItemBalance[id] == 0 then
				self.ItemBalance[id] = nil;
			end
		end
	end
end

function ns.OrderClass:closeTrade()
	-- Scan trade window slots and add contents to ReceivedMats\
	-- self:addReceivedMats(self:totalTradeMats());
	-- ns.CurrentTrade = {};
end

function ns.OrderClass:endOrder()
	-- Set Status to delivered or cancelled
	-- self.Status = ns.OrderClass.STATUSES.DELIVERED;
	-- self.Status = ns.OrderClass.STATUSES.CANCELLED;
	-- ArchiveOrder();

	-- Order is complete, i.e. delivered or cancelled. Reset customer's
	-- current order and global current order
	-- ns.getCustomer(ns.CurrentOrder.CustomerName).CurrentOrder = nil;
	-- ns.CurrentOrder = nil;
end
