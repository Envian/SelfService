local _, ns = ...;

-- Order Definition
ns.OrderClass.STATUSES = {
	PENDING = 1,
	ORDERED = 2,
	GATHERED = 3,
	DELIVERED = 4,
	CANCELLED = 5
}

-- TODO: PostMVP, add additional fields for archival purposes, i.e. profit
function ns.OrderClass:new(data, customerName)
	data = data or {
		CustomerName = customerName,
		Status = ns.OrderClass.STATUSES.PENDING,
		Recipes = nil,
		RequiredMats = nil,
		ReceivedMats = nil
	}
	setmetatable(data, ns.OrderClass);
	return data;
end

function ns.OrderClass:addToOrder(recipes)
	local requiredMats = {};
	for _, recipe in ipairs(recipes) do
		for _, mat in ipairs(recipe.Mats) do
			requiredMats[mat.Id] = (requiredMats[mat.Id] or 0) + mat.Count;
		end
	end

	self.RequiredMats = requiredMats;
	self.Recipes = recipes;
	self.Status = ns.OrderClass.STATUSES.ORDERED;
end

function ns.OrderClass:compareToCart()
	for id, count in pairs(self.RequiredMats) do
		local _, itemLink = GetItemInfo(id);

		if self.ReceivedMats[id] and count ~= self.ReceivedMats[id] then
			print("Discrepancy between received and required mats!");
			print("Required: "..itemLink.."x"..count);
			print("Received: "..itemLink.."x"..self.ReceivedMats[id]);
			return;
		end
	end

	for id, count in pairs(self.ReceivedMats) do
		local _, itemLink = GetItemInfo(id);

		if not self.RequiredMats[id] then
			print("Received material not required for order: "..itemLink.."x"..count);
			return;
		end
	end

	print("Got exact materials!"); -- Accept trade?
end

function ns.OrderClass:closeTrade()
	-- Scan trade window slots and add contents to ReceivedMats
	for i=1, 6 do
		local stack = ns.CurrentTrade[i];
		local _, itemLink = GetItemInfo(stack.id);
		self.ReceivedMats[stack.id] = (self.ReceivedMats[stack.id] or 0) + stack.quantity;
		print("Added "..itemLink.."x"..stack.quantity.." to ReceivedMats: "..self.ReceivedMats[stack.id].. " total");
	end

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
