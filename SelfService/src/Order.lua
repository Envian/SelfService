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
		ReceivedMats = nil
	}
	setmetatable(data, ns.OrderClass);
	return data;
end

function ns.OrderClass:process(event, ...)
	print("Old State: "..self.State.Name);
	self.State = self.State[event](ns.Customers[ns.CurrentOrder.CustomerName], ...) or self.State;
	print("New State: "..self.State.Name);
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
	self.ReceivedMats = {};

	for id, count in pairs(self.RequiredMats) do
		local _, itemLink = GetItemInfo(id);
		print("addToOrder - Required Material: "..itemLink.."x"..self.RequiredMats[id]);
	end
end

function ns.OrderClass:isTradeAcceptable()
	-- TODO: Generalize to support additional statuses
	local tradeMats = self:totalTradeMats();

	for id, count in pairs(self.RequiredMats) do
		local _, itemLink = GetItemInfo(id);
		print("Acceptable - Required Material: "..itemLink.."x"..self.RequiredMats[id]);
	end

	for id, count in pairs(self.RequiredMats) do
		local _, itemLink = GetItemInfo(id);

		if tradeMats[id] and count ~= tradeMats[id] then
			print("Discrepancy between received and required mats!");
			print("Required: "..itemLink.."x"..count);
			print("In window: "..itemLink.."x"..tradeMats[id]);
			return false;
		end
	end

	for id, count in pairs(tradeMats) do
		local _, itemLink = GetItemInfo(id);
		print("Checking "..itemLink.." from tradeMats...");
		print("itemID: "..ns.getItemIdFromLink(itemLink));
		print("Checked ID: "..id.."x"..self.RequiredMats[id]);

		if not self.RequiredMats[id] then
			print("Received material not required for order: "..itemLink.."x"..count);
			return false;
		end
	end

	print("Got exact materials.");
	return true;
end

function ns.OrderClass:totalTradeMats()
	local tradeMats = {};

	for i=1, 6 do
		local stack = ns.CurrentTrade[i];
		if stack then
			local _, itemLink = GetItemInfo(stack.id);
			print("Adding "..itemLink.." to tradeMats");
			tradeMats[stack.id] = (tradeMats[stack.id] or 0) + stack.quantity;
			print("Added "..itemLink.."x"..stack.quantity.." to tradeMats: "..tradeMats[stack.id].." total");
		end
	end

	return tradeMats;
end

function ns.OrderClass:addReceivedMats(tradeMats)
	self.ReceivedMats = self:totalTradeMats(tradeMats);
	print("Added received mats.");
end

function ns.OrderClass:closeTrade()
	-- Scan trade window slots and add contents to ReceivedMats\
	self:addReceivedMats(self:totalTradeMats());
	ns.CurrentTrade = {};
end

function ns.OrderClass:endOrder()
	-- Set Status to delivered or cancelled
	-- self.Status = ns.OrderClass.STATUSES.DELIVERED;
	-- self.Status = ns.OrderClass.STATUSES.CANCELLED;
	-- ArchiveOrder();

	-- Order is complete, i.e. delivered or cancelled. Reset customer's
	-- current order and global current order
	ns.getCustomer(ns.CurrentOrder.CustomerName).CurrentOrder = nil;
	ns.CurrentOrder = nil;
end
