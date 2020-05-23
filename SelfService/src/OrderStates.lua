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
	TRADE_CANCELLED = noAction,
	TRADE_COMPLETED = noAction,
	CURSOR_CHANGE = noAction,
	ENCHANT_FAILED = noAction,
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
			ns.debug(ns.LOG_PREFIX.."Trade Initiated.");
			customer:whisper("Place the exact materials for your order in the trade window.");
			return ns.OrderStates.WAIT_FOR_MATS;
		end
	}),

	WAIT_FOR_MATS = baseOrderState:new({
		Name = "WAIT_FOR_MATS",

		TRADE_ITEM_CHANGED = function(customer, enteredItems)
			if ns.CurrentOrder:isTradeAcceptable() then
				return ns.OrderStates.ACCEPT_MATS;
			end
		end,
		TRADE_ACCEPTED = function(customer, playerAccepted, customerAccepted)
			ns.debug("Trade accept button pressed: ");
			ns.debug("  - Player Accepted: "..playerAccepted);
			ns.debug("  - Customer Accepted: "..customerAccepted);

			if playerAccepted == 0 and customerAccepted == 1 then
				ns.debug("Trade not acceptable. Message customer");
				customer:whisper("I need to receive exact materials for your order.");
			end
		end,
		TRADE_CANCELLED = function(customer)
			ns.debug("Trade cancelled.");
			customer:whisper("The trade was cancelled before I received the materials.");
			return ns.OrderStates.ORDER_PLACED;
		end
	}),

	ACCEPT_MATS = baseOrderState:new({
		Name = "ACCEPT_MATS",

		ENTER_STATE = function(customer)
			ns.ActionQueue.clearButton();
		end,
		TRADE_ITEM_CHANGED = function(customer)
			ns.debug("Traded items changed during trade accept phase. Abort to WAIT_FOR_MATS");
			ns.ActionQueue.clearButton();
			return ns.OrderStates.WAIT_FOR_MATS;
		end,
		TRADE_CANCELLED = function(customer)
			ns.debug("Trade cancelled.");
			customer:whisper("The trade was cancelled before I received the materials.");
			ns.ActionQueue.clearButton();
			return ns.OrderStates.ORDER_PLACED;
		end,
		TRADE_COMPLETED = function(customer)
			ns.debug("Trade complete.");
			customer:whisper("Please wait while I craft your order.");
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
				customer:whisper("Your order is ready.");
				return ns.OrderStates.READY_FOR_DELIVERY;
			end
		end
	}),

	READY_FOR_DELIVERY = baseOrderState:new({
		Name = "READY_FOR_DELIVERY",

		TRADE_SHOW = function(customer)
			if customer.CurrentOrder.Recipes[1].Type == "Enchanting" then
				customer:whisper("Place the item you want enchanted in the \"Will Not Be Traded\" slot.");
				return ns.OrderStates.WAIT_FOR_ENCHANTABLE;
			else
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
		TRADE_CANCELLED = function(customer)
			ns.debug("Trade cancelled.");
			customer:whisper("The trade was cancelled before I completed your order.");
			return ns.OrderStates.READY_FOR_DELIVERY;
		end
	}),

	WAIT_FOR_ENCHANTABLE = baseOrderState:new({
		Name = "WAIT_FOR_ENCHANTABLE",

		TRADE_ITEM_CHANGED = function(customer, enteredItems)
			if enteredItems[7].Id then
				-- local itemName, _, quantity = GetTradeTargetItemInfo(slotChanged);
				-- local itemLink = GetTradeTargetItemLink(slotChanged);
				-- ns.CurrentTrade[slotChanged] = itemName ~= nil and { id = ns.getItemIdFromLink(itemLink), quantity = quantity } or nil;

				-- local itemSlot = {};
				--
				-- local item = Item:CreateFromItemID(getItemIdFromLink(itemLink));
				-- item:ContinueOnItemLoad(function()
				-- 	itemSlot = select(9, GetItemInfo(itemLink));
				-- end
				-- error code 374
				-- UNIT_SPELLCAST_FAILED arg1:"player" arg3: spell id
				return ns.OrderStates.CAST_ENCHANT;
			else
				ns.debug("Item was removed from slot 7.");
			end
		end,
		TRADE_CANCELLED = function(customer)
			customer:whisper("The trade was cancelled before I completed the enchant.");
			return ns.OrderStates.READY_FOR_DELIVERY;
		end
	}),

	CAST_ENCHANT = baseOrderState:new({
		Name = "CAST_ENCHANT",

		ENTER_STATE = function(customer)
			ns.ActionQueue.castEnchant(customer.CurrentOrder.Recipes[1].Name);
		end,
		CURSOR_CHANGE = function(customer, spellId)
			if IsCurrentSpell(customer.CurrentOrder.Recipes[1].Id) then
				ns.ActionQueue.clearButton();
				return ns.OrderStates.APPLY_ENCHANT;
			else
				ns.ActionQueue.castEnchant(customer.CurrentOrder.Recipes[1].Name);
			end
		end,
		TRADE_CANCELLED = function(customer)
			customer:whisper("The trade was cancelled before I completed the enchant.");
			ns.ActionQueue.clearButton();
			return ns.OrderStates.READY_FOR_DELIVERY;
		end
	}),

	APPLY_ENCHANT = baseOrderState:new({
		Name = "APPLY_ENCHANT",

		ENTER_STATE = function(customer)
			ns.ActionQueue.applyEnchant();
		end,
		TRADE_ITEM_CHANGED = function(customer)
			local givenEnchant = select(6, GetTradeTargetItemInfo(7));
			ns.debug("Listed Enchant: " .. (givenEnchant or "NONE"));
			if givenEnchant == customer.CurrentOrder.Recipes[1].Name then
				ns.ActionQueue.clearButton();
				return ns.OrderStates.AWAIT_PAYMENT;
			end
		end,
		ENCHANT_FAILED = function(customer, spellId)
			if spellId == customer.CurrentOrder.Recipes[1].Id then
				ns.debug("Spellcast Failed, do something.");
				ns.ActionQueue.clearButton();
				return ns.OrderStates.CAST_ENCHANT;
			end
		end,
		REPLACE_ENCHANT = function(customer, newEnchant, currentEnchant)
			ReplaceTradeEnchant();
			customer:whisper("I am replacing "..currentEnchant.." on your item.");
		end,
		TRADE_CANCELLED = function(customer)
			customer:whisper("The trade was cancelled before I completed the enchant.");
			ns.ActionQueue.clearButton();
			return ns.OrderStates.READY_FOR_DELIVERY;
		end,
	}),

	AWAIT_PAYMENT = baseOrderState:new({
		Name = "AWAIT_PAYMENT",

		ENTER_STATE = function(customer)
			-- TODO: check if money is needed to complete trade.
			if customer.CurrentOrder.ReceivedMoney >= customer.CurrentOrder.RequiredMoney then
				return ns.OrderStates.ACCEPT_DELIVERY;
			end
		end,
		TRADE_MONEY_CHANGED = function(customer)
			-- TODO: check if money is needed to complete trade.
		end,
		TRADE_CANCELLED = function(customer)
			customer:whisper("The trade was cancelled before I received payment.");
			return ns.OrderStates["READY_FOR_DELIVERY"];
		end
	}),

	ACCEPT_DELIVERY = baseOrderState:new({
		Name = "ACCEPT_DELIVERY",

		ENTER_STATE = function(customer)
			ns.ActionQueue.acceptTrade();
		end,

		TRADE_CANCELLED = function(customer)
			ns.ActionQueue.clearButton();
			return ns.OrderStates.READY_FOR_DELIVERY;
		end,
		ENCHANT_SUCCEEDED = function(customer, spellId)
			if spellId == customer.CurrentOrder.Recipes[1].id then
				ns.debug("Enchant succeeded!");
				ns.ActionQueue.clearButton();
			end
		end,
		TRADE_COMPLETED = function(customer)
			-- TODO: if we have more things to do, return to READY_FOR_DELIVERY
			ns.debug("Trade completed!");

			customer.CurrentOrder.reconcile(customer.CurrentOrder.Recipes[1]);

			if customer.CurrentOrder.ReceivedMats == {} then
				ns.debug("ReceivedMats currently empty. Order is complete.");
				return ns.OrderStates.TRANSACTION_COMPLETE;
			else
				ns.debug("ReceivedMats not empty, more things to do.");
			end

			ns.ActionQueue.clearButton();
			return ns.OrderStates.TRANSACTION_COMPLETE;
		end,
	}),

	TRANSACTION_COMPLETE = baseOrderState:new({
		Name = "TRANSACTION_COMPLETE",

		ENTER_STATE = function(customer)
			customer:whisper("Your transaction is complete.");
			customer.CurrentOrder = nil;
		end
	})
}
