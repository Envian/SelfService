local _, ns = ...;

local noAction = function() end
local tradeCancelledAfterOrderReadyForDelivery = function(customer)
	customer:whisper(ns.L.enUS.TRADE_CANCELLED);
	ns.ActionQueue.clearTradeAction();
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
	SPELLCAST_FAILED = noAction,
	INVENTORY_CHANGED = noAction,
	CALLED_BACK = noAction
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
			ns.ActionQueue.clearTradeAction();
			return ns.OrderStates.WAIT_FOR_MATS;
		end
	}),

	WAIT_FOR_MATS = baseOrderState:new({
		Name = "WAIT_FOR_MATS",

		TRADE_ITEM_CHANGED = function(customer, enteredItems)
			if customer.CurrentOrder:isTradeAcceptable(enteredItems) then
				ns.ActionQueue.clearTradeAction();
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
			ns.ActionQueue.clearTradeAction();
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
				ns.ActionQueue.clearTradeAction();
				return ns.OrderStates.WAIT_FOR_MATS;
			end
		end,
		TRADE_CANCELLED = function(customer)
			customer:whisper(ns.L.enUS.TRADE_CANCELLED);
			ns.ActionQueue.clearTradeAction();
			return ns.OrderStates.ORDER_PLACED;
		end,
		TRADE_COMPLETED = function(customer)
			customer:whisper(ns.L.enUS.CRAFTING_ORDER);
			ns.ActionQueue.clearTradeAction();
			return ns.OrderStates.CRAFT_ORDER;
		end
	}),

	CRAFT_ORDER = baseOrderState:new({
		Name = "CRAFT_ORDER",

		ENTER_STATE = function(customer)
			if customer.CurrentOrder:isDeliverable() then
				customer:whisper(ns.L.enUS.ORDER_READY);
				ns.ActionQueue.clearTradeAction();
				return ns.OrderStates.READY_FOR_DELIVERY;
			end
		end,
		INVENTORY_CHANGED = function(customer, containerId)
			if customer.CurrentOrder:isDeliverable() then
				customer:whisper(ns.L.enUS.ORDER_READY);
				ns.ActionQueue.clearTradeAction();
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
			if customer.CurrentOrder.Enchants[customer.CurrentOrder.EnchantIndex] then
				customer:whisperf(ns.L.enUS.ADD_ENCHANTABLE_ITEM, customer.CurrentOrder.Enchants[customer.CurrentOrder.EnchantIndex].Link);
			end

			return ns.OrderStates.DELIVER_ORDER;
		end
	}),

	DELIVER_ORDER = baseOrderState:new({
		Name = "DELIVER_ORDER",
		ENTER_STATE = function(customer)
			local returnables = {};
			ns.debug(ns.LOG_ORDER_PREPARING_RETURNABLES);
			for id, count in pairs(customer.CurrentOrder.ItemBalance) do
				if count < 0 then
					returnables[id] = -count;
				end
			end

			if not ns.isEmpty(returnables) then
				ns.breakStacksForReturn(returnables);
			else
				if customer.CurrentOrder.Enchants[customer.CurrentOrder.EnchantIndex] then
					return ns.OrderStates.WAIT_FOR_ENCHANTABLE;
				else
					return ns.OrderStates.AWAIT_PAYMENT;
				end
			end
		end,
		CALLED_BACK = function(customer, returnables)
			for _, returnable in ipairs(returnables) do
				ns.debugf(ns.LOG_RETURNABLES, returnable.id, returnable.container, returnable.slot);
				UseContainerItem(returnable.container, returnable.slot);
			end

			if customer.CurrentOrder.Enchants[customer.CurrentOrder.EnchantIndex] then
				return ns.OrderStates.WAIT_FOR_ENCHANTABLE;
			else
				return ns.OrderStates.AWAIT_PAYMENT;
			end
		end,
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
				ns.ActionQueue.clearTradeAction();
				return ns.OrderStates.CAST_ENCHANT;
			end
		end,
		TRADE_CANCELLED = tradeCancelledAfterOrderReadyForDelivery,
	}),

	CAST_ENCHANT = baseOrderState:new({
		Name = "CAST_ENCHANT",

		ENTER_STATE = function(customer)
			ns.ActionQueue.castEnchant(customer.CurrentOrder.Enchants[customer.CurrentOrder.EnchantIndex].Name);
		end,
		SPELLCAST_CHANGED = function(customer, cancelledCast)
			if IsCurrentSpell(customer.CurrentOrder.Enchants[customer.CurrentOrder.EnchantIndex].Id) then
				ns.ActionQueue.clearTradeAction();
				return ns.OrderStates.APPLY_ENCHANT;
			else
				ns.ActionQueue.castEnchant(customer.CurrentOrder.Enchants[customer.CurrentOrder.EnchantIndex].Name);
			end
		end,
		TRADE_ITEM_CHANGED = function(customer, enteredItems)
			if ns.isEmpty(enteredItems[7]) then
				ns.ActionQueue.clearTradeAction();
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
				ns.ActionQueue.clearTradeAction();
				return ns.OrderStates.WAIT_FOR_ENCHANTABLE;
			else
				local givenEnchant = select(6, GetTradeTargetItemInfo(7));

				if givenEnchant == customer.CurrentOrder.Enchants[customer.CurrentOrder.EnchantIndex].Name then
					ns.ActionQueue.clearTradeAction();
					return ns.OrderStates.AWAIT_PAYMENT;
				end
			end
		end,
		SPELLCAST_FAILED = function(customer, spellId)

			if spellId == customer.CurrentOrder.Enchants[customer.CurrentOrder.EnchantIndex].Id then
				ns.warningf(ns.LOG_INVALID_ENCHANTABLE, customer.CurrentOrder.Enchants[customer.CurrentOrder.EnchantIndex].Link);
				customer:whisperf(ns.L.enUS.INVALID_ITEM, customer.CurrentOrder.Enchants[customer.CurrentOrder.EnchantIndex].Link);
				ns.ActionQueue.clearTradeAction();
				return ns.OrderStates.WAIT_FOR_ENCHANTABLE;
			else
				ns.ActionQueue.clearTradeAction();
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
			if customer.CurrentOrder.MoneyBalance > 0 then
				customer:whisperf(ns.L.enUS.MONEY_REQUIRED, ns.moneyToString(customer.CurrentOrder.MoneyBalance));
			else
				ns.ActionQueue.clearTradeAction();
				return ns.OrderStates.ACCEPT_DELIVERY;
			end
		end,
		TRADE_MONEY_CHANGED = function(customer)
			local targetMoney = tonumber(GetTargetTradeMoney());

			if customer.CurrentOrder.MoneyBalance - targetMoney < 0 then
				ns.ActionQueue.clearTradeAction();
				return ns.OrderStates.ACCEPT_DELIVERY
			end
		end,
		TRADE_ITEM_CHANGED = function(customer, enteredItems)
			if ns.isEmpty(enteredItems[7]) then
				ns.ActionQueue.clearTradeAction();
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
				ns.ActionQueue.clearTradeAction();
				return ns.OrderStates.WAIT_FOR_ENCHANTABLE;
			end
		end,
		-- ENCHANT_SUCCEEDED = function(customer, spellId) -- This is just an extra error checking tool. May not be needed.
		-- 	if spellId == customer.CurrentOrder.Enchants[customer.CurrentOrder.EnchantIndex].Id then
		-- 		ns.ActionQueue.clearTradeAction();
		-- 	end
		-- end,
		TRADE_COMPLETED = function(customer)
			customer.CurrentOrder.EnchantIndex = customer.CurrentOrder.EnchantIndex + 1;

			if not customer.CurrentOrder.Enchants[customer.CurrentOrder.EnchantIndex] and ns.isEmpty(customer.CurrentOrder.ItemBalance) then
				ns.ActionQueue.clearTradeAction();
				return ns.OrderStates.TRANSACTION_COMPLETE;
			else
				ns.ActionQueue.clearTradeAction();
				customer.CurrentOrder.TradeAttempted = false;
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
	}),

	DEBUG_STATES = {
		SKIP_TO_AWAIT_PAYMENT = baseOrderState:new({
			Name = "SKIP_TO_AWAIT_PAYMENT",
			ENTER_STATE = function(customer)
				ns.print(ns.DEBUG_SKIPPED_ENCHANT);
				customer.CurrentOrder:credit(customer.CurrentOrder.Enchants[customer.CurrentOrder.EnchantIndex].Mats);
				customer:whisper(ns.L.enUS.DEBUG_SKIPPED_ENCHANT);
				return ns.OrderStates.AWAIT_PAYMENT;
			end
		})
	}
}
