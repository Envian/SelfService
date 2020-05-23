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
		RequiredMats = nil,
		RequiredMoney = 0,
		ReceivedMats = {},
		ReceivedMoney = 0,
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
	local requiredMats = {};
	for _, recipe in ipairs(recipes) do
		for _, mat in ipairs(recipe.Mats) do
			requiredMats[mat.Id] = (requiredMats[mat.Id] or 0) + mat.Count;
		end
	end

	self.Recipes = recipes;
	self.RequiredMats = requiredMats;

	for id, count in pairs(self.RequiredMats) do
		local _, itemLink = GetItemInfo(id);
	end
end

function ns.OrderClass:addTradedItems(items, money)
	self.ReceivedMoney = self.ReceivedMoney + money;
	for n = 1,6 do
		if items[n].Id then
			self.ReceivedMats[items[n].Id] = (self.ReceivedMats[items[n].Id] or 0) + items[n].Quantity;
		end
	end
end

function ns.OrderClass:isTradeAcceptable()
	-- TODO: Generalize to support additional statuses
	local tradeMats = ns.Trading.totalTrade();
	ns.dumpTable(tradeMats);

	for id, count in pairs(self.RequiredMats) do
		if tradeMats[id] and count ~= tradeMats[id] then
			ns.debugf(ns.LOG_ORDER_ITEM_QUANTITY_MISMATCH, id, count, id, tradeMats[id]);
			return false;
		end
	end

	for id, count in pairs(tradeMats) do
		if not self.RequiredMats[id] then
			ns.debugf(ns.LOG_ORDER_UNDESIRED_ITEM, id, count);
			return false;
		end
	end

	ns.debug(ns.LOG_ORDER_TRADE_ACCEPTABLE);
	return true;
end

function ns.OrderClass:reconcile(recipe)
	ns.info("Reconciling "..recipe.Name.." for the current order.");

	if not recipe then
		ns.error("ns.OrderClass:reconcile called with nil parameter.");
		return;
	end

	for _, mat in ipairs(recipe.Mats) do
		if not self.ReceivedMats[mat.Id] then
			ns.error("reconcile tried to remove mats we didn't receive");
			return;
		else
			self.ReceivedMats[mat.Id] = self.ReceivedMats[mat.Id] - mat.Count;

			if self.ReceivedMats[mat.Id] < 0 then
				ns.fatal("reconcile resulted in negative ReceivedMats.");
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
