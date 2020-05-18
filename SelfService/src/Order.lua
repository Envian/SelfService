local _, ns = ...;

ns.CurrentOrder = nil;

local TradeWindowContents;

-- Order Definition
ns.OrderClass = {};
ns.OrderClass.__index = ns.OrderClass;

DEBUG = ns.OrderClass;

-- TODO: PostMVP, add additional fields for archival purposes, i.e. profit
function ns.OrderClass:new(data, customer)
	data = data or {
		Customer = customer,
		Complete = false,
		Recipes = nil
		RequiredMats = nil,
		ReceivedMats = nil
	}
	setmetatable(data, ns.OrderClass);
	return data;
end

function ns.OrderClass:setOrder(recipes)
	local requiredMats = {};
	for _, recipe in ipairs(recipes) do
		for _, mat in ipairs(recipe.Mats) do
			requiredMats[mat.Id] = (requiredMats[mat.Id] or 0) + mat.Count;
		end
	end

	self.RequiredMats = requiredMats;
	self.Recipes = recipes;
end

function ns.OrderClass:addTradeWindowItem(id, itemName, quantity, slot)
	-- Edge case. We should never get a value out of bounds
	if slot < 1 or slot > 7 then
		print("Trade Window Slot Index Out Of Bounds: "..slot);
		return;
	end

	TradeWindowContents[slot] = {id, itemName, quantity};
end

function ns.OrderClass:removeTradeWindowItem(slot)
	TradeWindowContents[slot] = nil;
end

function ns.OrderClass:compareToCart()
	local requiredMats = self.Customer:getCart().Mats;

	for id, count in pairs(requiredMats) do
		local _, itemLink = GetItemInfo(id);

		if self.ReceivedMats[id] and count ~= self.ReceivedMats[id] then
			print("Discrepancy between received and required mats!");
			print("Required: "..itemLink.."x"..count);
			print("Received: "..itemLink.."x"..self.ReceivedMats[id]);
			return;
		else
			print("Required material not received: "..itemLink);
			return;
		end
	end

	print("Got exact materials!"); -- Accept trade?
end

function ns.OrderClass:closeTrade()
	-- Scan trade window slots and add contents to ReceivedMats
	for i=1, 7 do
		local stack = TradeWindowContents[i];
		local itemID = GetItemInfo(stack[1]);
		self.ReceivedMats[itemID] = (self.ReceivedMats[itemID] or 0) + stack[3];
		print("Added "..stack[2].."x"..stack[3].." to ReceivedMats: "..self.ReceivedMats[itemID].. " total");
	end
end

function ns.OrderClass:endOrder()
	-- ArchiveOrder();
	ns.CurrentOrder = nil;
end

function ns.OrderClass:isComplete()
	return self.Complete
end
