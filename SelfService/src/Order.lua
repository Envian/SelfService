-- This file is part of SelfService.
--
-- SelfService is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- SelfService is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with SelfService.  If not, see <https://www.gnu.org/licenses/>.
local ADDON_NAME, ns = ...;

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
		TradeAttempted = false
	}
	data.State = ns.OrderStates[data.State.RestoreState or data.State.Name];
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

function ns.OrderClass:removeFromOrder(recipe)
	if recipe.IsCrafted then
		self:debit({{Id = recipe.ProductId, Count = 1}});
		self.Craftables[recipe.Id] = self.Craftables[recipe.Id] ~= 1 and self.Craftables[recipe.Id] - 1 or nil;
	else
		self.Enchants[recipe.Id] = self.Enchants[recipe.Id] ~= 1 and self.Enchants[recipe.Id] - 1 or nil;
	end

	self:credit(recipe.Mats);
end

function ns.OrderClass:addToOrder(recipe)
	if recipe.IsCrafted then
		self:credit({{Id = recipe.ProductId, Count = 1}});
		self.Craftables[recipe.Id] = (self.Craftables[recipe.Id] or 0) + 1;
	else
		self.Enchants[recipe.Id] = (self.Enchants[recipe.Id] or 0) + 1;
	end

	self:debit(recipe.Mats);
end

function ns.OrderClass:isTradeAcceptable(tradeMats)
	local mustBeCraftable = false;

	for i=1,6 do
		if ns.isEmpty(tradeMats[i]) then
			mustBeCraftable = true;
		elseif not self.ItemBalance[tradeMats[i].Id] or self.ItemBalance[tradeMats[i].Id] < 0 then
			ns.debugf(ns.LOG_ORDER_UNDESIRED_ITEM, tradeMats[i].Id, tradeMats[i].Count);
			return false;
		end
	end

	if mustBeCraftable then
		local tradeTotals = {};

		for i=1,6 do
			if not ns.isEmpty(tradeMats[i]) then
				tradeTotals[tradeMats[i].Id] = (tradeTotals[tradeMats[i].Id] or 0) + tradeMats[i].Count;
			end
		end

		for itemId, balance in pairs(self.ItemBalance) do
			if (tradeTotals[itemId] or 0) < balance then
				ns.debugf(ns.LOG_ORDER_INSUFFICIENT_ITEMS, itemId, balance, itemId, tradeTotals[itemId] or 0);
				return false;
			end
		end
	end

	ns.debug(ns.LOG_ORDER_TRADE_ACCEPTABLE);
	return true;
end

function ns.OrderClass:isOrderCraftable()
	for itemId, balance in pairs(self.ItemBalance) do
		if balance > 0 then return false end;
	end
	return true;
end

function ns.OrderClass:isDeliverable()
	for craftable in pairs(self.Craftables) do
		craftable = ns.Recipes[craftable];

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

	for enchant in pairs(self.Enchants) do
		enchant = ns.Recipes[enchant];

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

function ns.OrderClass:nextEnchant()
	local recipeId = next(self.Enchants, nil);
	return ns.Recipes[recipeId];
end

function ns.OrderClass:finishEnchant(recipeId)
	self.Enchants[recipeId] = self.Enchants[recipeId] ~= 1 and self.Enchants[recipeId] - 1 or nil;
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
