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

	print("Current State: "..self.State.Name);
	self.State = self.State[event](customer, ...) or self.State;
	print("Next State: "..self.State.Name);
	for n = 1,10 do
		if self.State == currentState then break; end;

		print("Entered New State: "..self.State.Name);
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
		print("addToOrder - Required Material: "..itemLink.."x"..self.RequiredMats[id]);
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
			print("Discrepancy between received and required mats!");
			print("Required: ["..id.."]x"..count);
			print("In window: ["..id.."]x"..tradeMats[id]);
			return false;
		end
	end

	for id, count in pairs(tradeMats) do
		if not self.RequiredMats[id] then
			print("Received material not required for order: ["..id.."]x"..count);
			return false;
		end
	end

	print("Got exact materials.");
	return true;
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
