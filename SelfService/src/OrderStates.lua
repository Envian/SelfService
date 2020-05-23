local _, ns = ...;

local noAction = function() end;
-- Base state - All events which are not defiend fall back here, and return self.
-- Note: these are not actual blizzard events.
local baseOrderState = {
	ENTER_STATE = noAction,
	TRADE_SHOW = noAction,
	TRADE_ITEM_CHANGED = noAction, -- Argument is a Map<ItemId, Count> of ItemId to Count
	TRADE_MONEY_CHANGED = noAction,
	TRADE_ACCEPTED = noAction,
	REPLACE_ENCHANT = noAction,
	TRADE_CANCELED = noAction,
	TRADE_COMPLETED = noAction,
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
			print(ns.LOG_PREFIX.."Trade Initiated.");
			return ns.OrderStates["WAIT_FOR_MATS"];
		end
	}),

	WAIT_FOR_MATS = baseOrderState:new({
		Name = "WAIT_FOR_MATS",

		TRADE_ITEM_CHANGED = function(customer, enteredItems)
			if ns.CurrentOrder:isTradeAcceptable() then
				return ns.OrderStates["ACCEPT_MATS"];
			end

			return nil;
		end,
		TRADE_ACCEPTED = function(customer, playerAccepted, customerAccepted)
			print("Trade accept button pressed: ");
			print("  - Player Accepted: "..playerAccepted);
			print("  - Customer Accepted: "..customerAccepted);

			if playerAccepted == 0 and customerAccepted == 1 then
				print("Trade not acceptable.");
				return ns.OrderStates["ORDER_PLACED"];
			end
		end,
		TRADE_CANCELED = function(customer)
			print("Trade cancelled.");
			return ns.OrderStates["ORDER_PLACED"];
		end
	}),

	ACCEPT_MATS = baseOrderState:new({
		Name = "ACCEPT_MATS",

		ENTER_STATE = function(customer)
			ns.ActionQueue.acceptTrade();
			return nil;
		end,
		TRADE_ITEM_CHANGED = function(customer, slotChanged)
			print("Traded items changed during trade accept phase. Abort to WAIT_FOR_MATS");
			return ns.OrderStates["WAIT_FOR_MATS"];
		end,
		TRADE_CANCELED = function(customer)
			print("Trade cancelled.");
			return ns.OrderStates["ORDER_PLACED"];
		end,
		TRADE_COMPLETED = function(customer)
			print("Trade complete.");
			customer.CurrentOrder:closeTrade();
			return ns.OrderStates["CRAFT_ORDER"];
		end
	}),

	CRAFT_ORDER = baseOrderState:new({
		Name = "CRAFT_ORDER",

		-- Ensure we have the tools in bag, e.g. Runed Copper Rod
		-- Compile list of all CraftFocus items required to complete order
		-- Search bags for each CraftFocus
		-- Search bank bags for each missing CraftFocus
		-- When all CraftFocus items are in inventory, update OrderState to READY_FOR_DELIVERY

		-- Temporary: TRADE_SHOW is a convenient event to put here to push forward
		TRADE_SHOW = function(customer)
			return ns.OrderStates["READY_FOR_DELIVERY"];
		end
	}),

	READY_FOR_DELIVERY = baseOrderState:new({
		Name = "READY_FOR_DELIVERY",

		TRADE_SHOW = function(customer)
			return ns.OrderStates["WAIT_FOR_ENCHANTABLE"];
			--return ns.OrderStates["DELIVER_ORDER"];
		end
	}),

	DELIVER_ORDER = baseOrderState:new({
		Name = "DELIVER_ORDER",

		TRADE_ITEM_CHANGED = function(customer, slotChanged)
			-- local itemName, _, quantity = GetTradeTargetItemInfo(slotChanged);
			-- local itemLink = GetTradeTargetItemLink(slotChanged);
			-- ns.CurrentTrade[slotChanged] = itemName ~= nil and { id = ns.getItemIdFromLink(itemLink), quantity = quantity } or nil;

			return nil;
		end,
		TRADE_CANCELED = function(customer)
			print("Trade cancelled.");
			return ns.OrderStates["READY_FOR_DELIVERY"];
		end
	}),

	WAIT_FOR_ENCHANTABLE = baseOrderState:new({
		Name = "WAIT_FOR_ENCHANTABLE",

		TRADE_ITEM_CHANGED = function(customer, slotChanged)
			if slotChanged == 7 then
				-- local itemName, _, quantity = GetTradeTargetItemInfo(slotChanged);
				-- local itemLink = GetTradeTargetItemLink(slotChanged);
				-- ns.CurrentTrade[slotChanged] = itemName ~= nil and { id = ns.getItemIdFromLink(itemLink), quantity = quantity } or nil;

				-- local itemSlot = {};
				--
				-- local item = Item:CreateFromItemID(getItemIdFromLink(itemLink));
				-- item:ContinueOnItemLoad(function()
				-- 	itemSlot = select(9, GetItemInfo(itemLink));
				-- end

				return ns.OrderStates["CAST_ENCHANT"];
			else
				return nil;
			end
		end,
		TRADE_CANCELED = function(customer)
			print("Trade cancelled.");
			return ns.OrderStates["READY_FOR_DELIVERY"];
		end
	}),

	CAST_ENCHANT = baseOrderState:new({
		Name = "CAST_ENCHANT",

		TRADE_ITEM_CHANGED = function(customer, slotChanged)
			if slotChanged == 7 then
				-- local itemName, _, quantity = GetTradeTargetItemInfo(slotChanged);
				-- local itemLink = GetTradeTargetItemLink(slotChanged);
				-- ns.CurrentTrade[slotChanged] = itemName ~= nil and { id = ns.getItemIdFromLink(itemLink), quantity = quantity } or nil;

				-- local itemSlot = {};
				--
				-- local item = Item:CreateFromItemID(getItemIdFromLink(itemLink));
				-- item:ContinueOnItemLoad(function()
				-- 	itemSlot = select(9, GetItemInfo(itemLink));
				-- end

				if itemName then
					return ns.OrderStates["AWAIT_PAYMENT"];
				else
					return ns.OrderStatus["WAIT_FOR_ENCHANTABLE"];
				end
			else
				return nil;
			end
		end,
		REPLACE_ENCHANT = function(newEnchant, currentEnchant)
			return ns.OrderStatus["OVERRIDE_ENCHANT"];
		end,
		TRADE_CANCELED = function(customer)
			print("Trade cancelled.");
			return ns.OrderStates["READY_FOR_DELIVERY"];
		end
	}),

	OVERRIDE_ENCHANT = baseOrderState:new({
		Name = "OVERRIDE_ENCHANT",

		TRADE_ITEM_CHANGED = function()
			return ns.OrderStates["AWAIT_PAYMENT"];
		end,
		TRADE_CANCELED = function(customer)
			print("Trade cancelled.");
			return ns.OrderStates["READY_FOR_DELIVERY"];
		end
	}),

	AWAIT_PAYMENT = baseOrderState:new({
		Name = "AWAIT_PAYMENT",

		TRADE_MONEY_CHANGED = function()
			-- return ns.OrderStates."ACCEPT_DELIVERY"; or
			-- return self;
		end,
		TRADE_CANCELED = function(customer)
			print("Trade cancelled.");
			return ns.OrderStates["READY_FOR_DELIVERY"];
		end
	}),

	ACCEPT_DELIVERY = baseOrderState:new({
		Name = "ACCEPT_DELIVERY",

		ENTER_STATE = function(customer)
			ns.ActionQueue.acceptTrade();
		end,

		TRADE_CANCELED = function(customer)
			return ns.OrderStates.READY_FOR_DELIVERY;
		end,

		TRADE_COMPLETED = function(customer)

		end,
	}),

	TRANSACTION_COMPLETE = baseOrderState:new({
		Name = "TRANSACTION_COMPLETE",

		ENTER_STATE = function(customer)
			customer.CurrentOrder = nil;
		end
	})
}
