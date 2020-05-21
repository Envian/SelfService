local _, ns = ...;

local noAction = function() end;
-- Base state - All events which are not defiend fall back here, and return self.
local baseOrderState = {
	EnterState = noAction, -- basically a  "Custom Event"
	TRADE_SHOW = noAction,
	TRADE_TARGET_ITEM_CHANGED = noAction,
	TRADE_MONEY_CHANGED = noAction,
	TRADE_ACCEPT_UPDATE = noAction,
	TRADE_REPLACE_ENCHANT = noAction,
	UI_INFO_MESSAGE = noAction
}
baseOrderState.__index = baseOrderState;

function baseOrderState:new(state)
	setmetatable(state, baseOrderState);
	return state;
end

ns.OrderStates = {
	ORDER_PLACED = baseOrderState:new({
		Name = "ORDER_PLACED",

		TRADE_SHOW = function()
			print(ns.LOG_PREFIX.."Trade Initiated.");
			return ns.OrderStates["WAIT_FOR_MATS"];
		end
	}),

	WAIT_FOR_MATS = baseOrderState:new({
		Name = "WAIT_FOR_MATS",

		UI_INFO_MESSAGE = function(customer, message)
			if message == "Trade cancelled." then
				print("Trade cancelled.");
				return ns.OrderStates["ORDER_PLACED"];
			else
				print("Unexpected UI_INFO_MESSAGE: "..message);
				error("Unexpected UI_INFO_MESSAGE: "..message);
			end
		end,
		TRADE_TARGET_ITEM_CHANGED = function(customer, slotChanged)
			local _, _, quantity = GetTradeTargetItemInfo(slotChanged);
			local itemLink = GetTradeTargetItemLink(slotChanged);
			ns.CurrentTrade[slotChanged] = itemName ~= "" and { id = ns.getItemIdFromLink(itemLink), quantity = quantity } or nil;

			return nil;
		end,
		TRADE_ACCEPT_UPDATE = function(customer, playerAccepted, customerAccepted)
			print("Trade accept button pressed: ");
			print("  - Player Accepted: "..playerAccepted);
			print("  - Customer Accepted: "..customerAccepted);

			if playerAccepted == 0 and customerAccepted == 1 then
				if ns.CurrentOrder:isTradeAcceptable() then
					--AcceptTrade(); -- Blizzard UI Protected Function
					print("TRADE ACCEPTABLE, ACCEPT TRADE!");
					return ns.OrderStates["ACCEPT_MATS"]
				else
					CancelTrade();
				end
			end
			-- return ns.OrderStates."ACCEPT_MATS"; or
			-- return self;
		end
	}),

	ACCEPT_MATS = baseOrderState:new({
		Name = "ACCEPT_MATS",

		TRADE_TARGET_ITEM_CHANGED = function()
			print("Traded items changed during trade accept phase. Abort to WAIT_FOR_MATS");
			return ns.OrderStates["WAIT_FOR_MATS"];
		end,
		UI_INFO_MESSAGE = function(customer, message)
			if message == "Trade cancelled." then
				print("Trade cancelled.");
				return ns.OrderStates["ORDER_PLACED"];
			elseif message == "Trade complete." then
				print("Trade complete.");
				return ns.OrderStates["CRAFT_ORDER"];
			else
				print("Unexpected UI_INFO_MESSAGE: "..message);
				error("Unexpected UI_INFO_MESSAGE: "..message, 0);
			end
		end,
	}),

	CRAFT_ORDER = baseOrderState:new({
		Name = "CRAFT_ORDER",

		-- Ensure we have the tools in bag, e.g. Runed Copper Rod
		-- Compile list of all CraftFocus items required to complete order
		-- Search bags for each CraftFocus
		-- Search bank bags for each missing CraftFocus
		-- When all CraftFocus items are in inventory, update OrderState to READY_FOR_DELIVERY

		UNKNOWN_EVENT_TRIGGERED = function()
			return ns.OrderStates["READY_FOR_DELIVERY"];
		end
	}),

	READY_FOR_DELIVERY = baseOrderState:new({
		Name = "READY_FOR_DELIVERY",

		TRADE_SHOW = function()
			-- return ns.OrderStates."DELIVER_ORDER";
		end
	}),

	DELIVER_ORDER = baseOrderState:new({
		Name = "DELIVER_ORDER",

		TRADE_TARGET_ITEM_CHANGED = function()
			-- return ns.OrderStates."WAIT_FOR_ENCHANTABLE"; or
			-- return ns.OrderStates."AWAIT_PAYMENT";
		end,
		UI_INFO_MESSAGE = function()
			-- return ns.OrderStates."READY_FOR_DELIVERY";
		end
	}),

	WAIT_FOR_ENCHANTABLE = baseOrderState:new({
		Name = "WAIT_FOR_ENCHANTABLE",

		TRADE_TARGET_ITEM_CHANGED = function()
			-- return self; or
			-- return ns.OrderStates."CAST_ENCHANT";
		end,
		UI_INFO_MESSAGE = function()
			-- return ns.OrderStates."READY_FOR_DELIVERY";
		end
	}),

	CAST_ENCHANT = baseOrderState:new({
		Name = "CAST_ENCHANT",

		TRADE_TARGET_ITEM_CHANGED = function()
			-- return ns.OrderStates."WAIT_FOR_ENCHANTABLE"; or
			-- return ns.OrderStates."AWAIT_PAYMENT";
		end,
		TRADE_REPLACE_ENCHANT = function()
			-- return ns.OrderStates."OVERRIDE_ENCHANT";
		end,
		UI_INFO_MESSAGE = function()
			-- return ns.OrderStates."READY_FOR_DELIVERY";
		end
	}),

	OVERRIDE_ENCHANT = baseOrderState:new({
		Name = "OVERRIDE_ENCHANT",

		TRADE_TARGET_ITEM_CHANGED = function()
			-- return ns.OrderStates."AWAIT_PAYMENT";
		end,
		UI_INFO_MESSAGE = function()
			-- return ns.OrderStates."READY_FOR_DELIVERY";
		end
	}),

	AWAIT_PAYMENT = baseOrderState:new({
		Name = "AWAIT_PAYMENT",

		TRADE_MONEY_CHANGED = function()
			-- return ns.OrderStates."ACCEPT_DELIVERY"; or
			-- return self;
		end,
		UI_INFO_MESSAGE = function()
			-- return ns.OrderStates."READY_FOR_DELIVERY";
		end
	}),

	ACCEPT_DELIVERY = baseOrderState:new({
		Name = "ACCEPT_DELIVERY",

		UI_INFO_MESSAGE = function()
			-- return ns.OrderStates."READY_FOR_DELIVERY"; or
			-- return ns.OrderStates."COMPLETE"
		end
	})
}
