local _, ns = ...;

-- Order Definition
ns.OrderClass = {};
ns.OrderClass.__index = ns.OrderClass;

-- TODO: PostMVP, add additional fields for archival purposes, e.g. profit
function ns.OrderClass:new(data, customerName)
	data = data or {
		CustomerName = customerName,
		State = ns.OrderStates.ORDER_PLACED,
		Craftables = {},
		Enchants = {},
		ItemBalance = {},
		MoneyBalance = 0,
		TradeAttempted = false,
		EnchantIndex = 1
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

function ns.OrderClass:addToOrder(recipe)
	if recipe.IsCrafted then
		table.insert(self.Craftables, recipe);
		self:credit({{Id = recipe.ProductId, Count = 1}});
	else
		table.insert(self.Enchants, recipe);
	end

	self:debit(recipe.Mats);
end

function ns.OrderClass:isTradeAcceptable(tradeMats)
	local tradeAcceptable = true;

	-- We do not want to accept any trade containing items unrelated to the order
	for _, mat in pairs(tradeMats) do
		if mat and mat.Id and not self.ItemBalance[mat.Id] then
			ns.debugf(ns.LOG_ORDER_UNDESIRED_ITEM, mat.Id, mat.Count);
			tradeAcceptable = false;
		end
	end

	if not isTradeAcceptable then
		return false;
	end

	tradeAcceptable = true;
	for n = 1,6 do
		if not tradeMats[n] or not tradeMats[n].Id then
			tradeAcceptable = false;
		end
	end

	if tradeAcceptable then
		ns.debugf(ns.LOG_ORDER_TRADE_ACCEPTABLE);
		return true;
	end

	local pendingBalance = {}
	for _, mat in pairs(self.ItemBalance) do
		if mat and mat.Id then
			pendingBalance[mat.Id] = (pendingBalance[mat.Id] or 0) + mat.Count;
		end
	end

	for itemId, quantityRequired in pairs(self.ItemBalance) do
		if quantityRequired - pendingBalance[itemId] > 0 then
			ns.debugf(ns.LOG_ORDER_INSUFFICIENT_ITEMS, itemId, quantityRequired, itemId, pendingBalance[itemId]);
			tradeAcceptable = false;
		end
	end

	if tradeAcceptable then
		ns.debugf(ns.LOG_ORDER_TRADE_ACCEPTABLE);
		return true;
	else
		-- messages posted above.
		return false;
	end
end

function ns.OrderClass:areAllMatsReceived()
	for itemId, balance in pairs(self:ItemBalance) do
		if balance > 0 return false;
	end
	return true;
end

function ns.OrderClass:isDeliverable()
	for _, craftable in ipairs(self.Craftables) do
		if GetItemCount(craftable.ProductId) < -self.ItemBalance[craftable.ProductId] then
			if craftable.CraftFocusId and GetItemCount(craftable.CraftFocusId) < 1 then
				ns.errorf(ns.LOG_CRAFT_FOCUS_NOT_FOUND, craftable.CraftFocusName);
			else
				ns.infof(ns.LOG_MORE_CRAFTS_REQUIRED, -(GetItemCount(craftable.ProductId) + self.ItemBalance[craftable.ProductId]), craftable.Name);
				ns.ActionQueue.castEnchant(craftable.Name);
			end

			return false;
		end
	end

	for _, enchant in ipairs(self.Enchants) do
		if GetItemCount(enchant.CraftFocusId) < 1 then
			ns.errorf(ns.LOG_CRAFT_FOCUS_NOT_FOUND, enchant.CraftFocusName);
			return false;
		end
	end

	return true;
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
