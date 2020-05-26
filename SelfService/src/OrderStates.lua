local _, ns = ...;

local noAction = function() end
local tradeCancelledAfterOrderReadyForDelivery = function(customer)
	customer:whisper(ns.L.enUS.TRADE_CANCELLED);
	ns.ActionQueue.clearButton();
	return ns.OrderStates.READY_FOR_DELIVERY;
end
-- Base state - All events which are not defiend fall back here, and return self.
-- Note: these are not actual blizzard events.
local baseOrderState = {
	ENTER_STATE = noAction,
	TRADE_SHOW = noAction,
	TRADE_ITEM_CHANGED = noAction, -- Argument is a Map<ItemId, Count> of ItemId to Count
	TRADE_MONEY_CHANGED = noAction,
	TRADE_ACCEPTED = noAction,
	REPLACE_ENCHANT = noAction,
	TRADE_CANCELLED = noAction,
	TRADE_COMPLETED = noAction,
	SPELLCAST_CHANGED = noAction,
	--ENCHANT_SUCCEEDED = noAction,
	SPELLCAST_FAILED = noAction
}
baseOrderState.__index = baseOrderState;

function baseOrderState:new(state)
	setmetatable(state, baseOrderState);
	return state;
end

ns.OrderStates = {
	ORDER_PLACED = baseOrderState:new({
		Name = "ORDER_PLACED",

		TRADE_SHOW = function(customer)
			customer:whisper(ns.L.enUS.ADD_EXACT_MATERIALS);
			ns.ActionQueue.clearButton();
			return ns.OrderStates.WAIT_FOR_MATS;
		end
	}),

	WAIT_FOR_MATS = baseOrderState:new({
		Name = "WAIT_FOR_MATS",

		TRADE_ITEM_CHANGED = function(customer, enteredItems)
			if customer.CurrentOrder:isTradeAcceptable() then
				ns.ActionQueue.clearButton();
				return ns.OrderStates.ACCEPT_MATS;
			end
		end,
		TRADE_ACCEPTED = function(customer, playerAccepted, customerAccepted)
			if playerAccepted == 0 and customerAccepted == 1 then
				customer:whisper(ns.L.enUS.EXACT_MATERIALS_REQUIRED);
			end
		end,
		TRADE_CANCELLED = function(customer)
			customer:whisper(ns.L.enUS.TRADE_CANCELLED);
			ns.ActionQueue.clearButton();
			return ns.OrderStates.ORDER_PLACED;
		end
	}),

	ACCEPT_MATS = baseOrderState:new({
		Name = "ACCEPT_MATS",

		ENTER_STATE = function(customer)
			ns.ActionQueue.acceptTrade();
		end,
		TRADE_ITEM_CHANGED = function(customer)
			if not customer.CurrentOrder:isTradeAcceptable() then
				ns.ActionQueue.clearButton();
				return ns.OrderStates.WAIT_FOR_MATS;
			end
		end,
		TRADE_CANCELLED = function(customer)
			customer:whisper(ns.L.enUS.TRADE_CANCELLED);
			ns.ActionQueue.clearButton();
			return ns.OrderStates.ORDER_PLACED;
		end,
		TRADE_COMPLETED = function(customer)
			customer:whisper(ns.L.enUS.CRAFTING_ORDER);
			ns.ActionQueue.clearButton();
			return ns.OrderStates.CRAFT_ORDER;
		end
	}),

	CRAFT_ORDER = baseOrderState:new({
		Name = "CRAFT_ORDER",

		-- Ensure we have the tools in bag, e.g. Runed Copper Rod
		-- Compile list of all CraftFocus items required to complete order
		-- Search bags for each CraftFocus
		-- Search bank bags for each missing CraftFocus
		-- When all CraftFocus items are in inventory, update OrderState to READY_FOR_DELIVERY

		ENTER_STATE = function(customer)
			if customer.CurrentOrder.Recipes[1].Type == "Enchanting" then
				customer:whisper(ns.L.enUS.ORDER_READY);
				ns.ActionQueue.clearButton();
				return ns.OrderStates.READY_FOR_DELIVERY;
			end
		end
	}),

	READY_FOR_DELIVERY = baseOrderState:new({
		Name = "READY_FOR_DELIVERY",

		ENTER_STATE = function(customer)
			if not customer.CurrentOrder.TradeAttempted then
				local i = string.find(customer.Name, "-");
				InitiateTrade(string.sub(customer.Name, 1, i-1));
				customer.CurrentOrder.TradeAttempted = true;
			end
		end,
		TRADE_SHOW = function(customer)
			-- TODO: update for non exact materials
			if customer.CurrentOrder.Recipes[1].Type == "Enchanting" then
				customer:whisper(ns.L.enUS.ADD_ENCHANTABLE_ITEM);
				ns.ActionQueue.clearButton();
				return ns.OrderStates.WAIT_FOR_ENCHANTABLE;
			else
				ns.ActionQueue.clearButton();
				return ns.OrderStates.DELIVER_ORDER;
			end
		end
	}),

	DELIVER_ORDER = baseOrderState:new({
		Name = "DELIVER_ORDER",

		TRADE_ITEM_CHANGED = function(customer, enteredItems)
			-- local itemName, _, quantity = GetTradeTargetItemInfo(slotChanged);
			-- local itemLink = GetTradeTargetItemLink(slotChanged);
			-- ns.CurrentTrade[slotChanged] = itemName ~= nil and { id = ns.getItemIdFromLink(itemLink), quantity = quantity } or nil;
		end,
		TRADE_CANCELLED = tradeCancelledAfterOrderReadyForDelivery,
	}),

	WAIT_FOR_ENCHANTABLE = baseOrderState:new({
		Name = "WAIT_FOR_ENCHANTABLE",

		TRADE_ITEM_CHANGED = function(customer, enteredItems)
			if enteredItems[7].Id then
				ns.ActionQueue.clearButton();
				return ns.OrderStates.CAST_ENCHANT;
			end
		end,
		TRADE_CANCELLED = tradeCancelledAfterOrderReadyForDelivery,
	}),

	CAST_ENCHANT = baseOrderState:new({
		Name = "CAST_ENCHANT",

		ENTER_STATE = function(customer)
			ns.ActionQueue.castEnchant(customer.CurrentOrder.Recipes[1].Name);
		end,
		SPELLCAST_CHANGED = function(customer, cancelledCast)
			if IsCurrentSpell(customer.CurrentOrder.Recipes[1].Id) then
				ns.ActionQueue.clearButton();
				return ns.OrderStates.APPLY_ENCHANT;
			else
				ns.ActionQueue.castEnchant(customer.CurrentOrder.Recipes[1].Name);
			end
		end,
		TRADE_ITEM_CHANGED = function(customer, enteredItems)
			if ns.isEmpty(enteredItems[7]) then
				ns.ActionQueue.clearButton();
				return ns.OrderStates.WAIT_FOR_ENCHANTABLE;
			end
		end,
		TRADE_CANCELLED = tradeCancelledAfterOrderReadyForDelivery,
	}),

	APPLY_ENCHANT = baseOrderState:new({
		Name = "APPLY_ENCHANT",

		ENTER_STATE = function(customer)
			ns.ActionQueue.applyEnchant();
		end,
		TRADE_ITEM_CHANGED = function(customer, enteredItems)
			if ns.isEmpty(enteredItems[7]) then
				ns.ActionQueue.clearButton();
				return ns.OrderStates.WAIT_FOR_ENCHANTABLE;
			else
				local givenEnchant = select(6, GetTradeTargetItemInfo(7));

				if givenEnchant == customer.CurrentOrder.Recipes[1].Name then
					ns.ActionQueue.clearButton();
					return ns.OrderStates.AWAIT_PAYMENT;
				end
			end
		end,
		SPELLCAST_FAILED = function(customer, spellId)
			if spellId == customer.CurrentOrder.Recipes[1].Id then
				ns.warningf(ns.LOG_INVALID_ENCHANTABLE, customer.CurrentOrder.Recipes[1].Link);
				customer:whisperf(ns.L.enUS.INVALID_ITEM, customer.CurrentOrder.Recipes[1].Link);
				ns.ActionQueue.clearButton();
				return ns.OrderStates.WAIT_FOR_ENCHANTABLE;
			else
				ns.ActionQueue.clearButton();
				return ns.OrderStates.CAST_ENCHANT;
			end
		end,
		REPLACE_ENCHANT = function(customer, currentEnchant, newEnchant)
			ReplaceTradeEnchant();
			customer:whisperf(ns.L.enUS.REPLACE_ENCHANT, currentEnchant, newEnchant);
		end,
		TRADE_CANCELLED = tradeCancelledAfterOrderReadyForDelivery,
	}),

	AWAIT_PAYMENT = baseOrderState:new({
		Name = "AWAIT_PAYMENT",

		ENTER_STATE = function(customer)
			local balance = customer.CurrentOrder.RequiredMoney - customer.CurrentOrder.ReceivedMoney;

			if balance > 0 then
				customer:whisperf(ns.L.enUS.MONEY_REQUIRED, ns.moneyToString(balance));
			else
				ns.ActionQueue.clearButton();
				return ns.OrderStates.ACCEPT_DELIVERY;
			end
		end,
		TRADE_MONEY_CHANGED = function(customer)
			local targetMoney = tonumber(GetTargetTradeMoney());
			local balance = customer.CurrentOrder.RequiredMoney - customer.CurrentOrder.ReceivedMoney - targetMoney;

			if balance <= 0 then
				ns.ActionQueue.clearButton();
				return ns.OrderStates.ACCEPT_DELIVERY
			end
		end,
		TRADE_ITEM_CHANGED = function(customer, enteredItems)
			if ns.isEmpty(enteredItems[7]) then
				ns.ActionQueue.clearButton();
				return ns.OrderStates.WAIT_FOR_ENCHANTABLE;
			end
		end,
		TRADE_CANCELLED = tradeCancelledAfterOrderReadyForDelivery,
	}),

	ACCEPT_DELIVERY = baseOrderState:new({
		Name = "ACCEPT_DELIVERY",

		ENTER_STATE = function(customer)
			ns.ActionQueue.acceptTrade();
		end,

		TRADE_CANCELLED = tradeCancelledAfterOrderReadyForDelivery,
		TRADE_ITEM_CHANGED = function(customer, enteredItems)
			if ns.isEmpty(enteredItems[7]) then
				ns.ActionQueue.clearButton();
				return ns.OrderStates.WAIT_FOR_ENCHANTABLE;
			end
		end,
		-- ENCHANT_SUCCEEDED = function(customer, spellId) -- This is just an extra error checking tool. May not be needed.
		-- 	if spellId == customer.CurrentOrder.Recipes[1].Id then
		-- 		ns.ActionQueue.clearButton();
		-- 	end
		-- end,
		TRADE_COMPLETED = function(customer)
			customer.CurrentOrder:reconcile(customer.CurrentOrder.Recipes[1]);

			if ns.isEmpty(customer.CurrentOrder.ReceivedMats) then
				ns.ActionQueue.clearButton();
				return ns.OrderStates.TRANSACTION_COMPLETE;
			else
				ns.ActionQueue.clearButton();
				return ns.OrderStates.READY_FOR_DELIVERY;
			end
		end,
	}),

	TRANSACTION_COMPLETE = baseOrderState:new({
		Name = "TRANSACTION_COMPLETE",

		ENTER_STATE = function(customer)
			customer:whisper(ns.L.enUS.TRANSACTION_COMPLETE);
			customer.CurrentOrder = nil;
			ns.CurrentOrder = nil;
		end
	})
}
