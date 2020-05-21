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

		TRADE_SHOW = function(customer)
			print(ns.LOG_PREFIX.."Trade Initiated.");
			ns.CurrentTrade = {};
			return ns.OrderStates["WAIT_FOR_MATS"];
		end
	}),

	WAIT_FOR_MATS = baseOrderState:new({
		Name = "WAIT_FOR_MATS",

		UI_INFO_MESSAGE = function(customer, error)
			if error == 226 then
				print("Trade cancelled.");
				return ns.OrderStates["ORDER_PLACED"];
			else
				print("Unexpected UI_INFO_MESSAGE: "..message);
				error("Unexpected UI_INFO_MESSAGE: "..message);
			end
		end,
		TRADE_TARGET_ITEM_CHANGED = function(customer, slotChanged)
			local itemName, _, quantity = GetTradeTargetItemInfo(slotChanged);
			local itemLink = GetTradeTargetItemLink(slotChanged);
			ns.CurrentTrade[slotChanged] = itemName ~= nil and { id = ns.getItemIdFromLink(itemLink), quantity = quantity } or nil;

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
					return ns.OrderStates["ORDER_PLACED"];
				end
			end
		end
	}),

	ACCEPT_MATS = baseOrderState:new({
		Name = "ACCEPT_MATS",

		TRADE_TARGET_ITEM_CHANGED = function(customer, slotChanged)
			print("Traded items changed during trade accept phase. Abort to WAIT_FOR_MATS");
			return ns.OrderStates["WAIT_FOR_MATS"];
		end,
		UI_INFO_MESSAGE = function(customer, error)
			if error == 226 then
				print("Trade cancelled.");
				ns.CurrentTrade = {};
				return ns.OrderStates["ORDER_PLACED"];
			elseif error == 227 then
				print("Trade complete.");
				customer.CurrentOrder:closeTrade();
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

		-- Temporary: TRADE_SHOW is a convenient event to put here to push forward
		TRADE_SHOW = function(customer)
			return ns.OrderStates["READY_FOR_DELIVERY"];
		end
	}),

	READY_FOR_DELIVERY = baseOrderState:new({
		Name = "READY_FOR_DELIVERY",

		TRADE_SHOW = function(customer)
			ns.CurrentTrade = {};
			return ns.OrderStates["WAIT_FOR_ENCHANTABLE"];
			--return ns.OrderStates["DELIVER_ORDER"];
		end
	}),

	DELIVER_ORDER = baseOrderState:new({
		Name = "DELIVER_ORDER",

		TRADE_TARGET_ITEM_CHANGED = function(customer, slotChanged)
			local itemName, _, quantity = GetTradeTargetItemInfo(slotChanged);
			local itemLink = GetTradeTargetItemLink(slotChanged);
			ns.CurrentTrade[slotChanged] = itemName ~= nil and { id = ns.getItemIdFromLink(itemLink), quantity = quantity } or nil;

			return nil;
		end,
		UI_INFO_MESSAGE = function(customer, error)
			if error == 226 then
				print("Trade cancelled.");
				return ns.OrderStates["READY_FOR_DELIVERY"];
			else
				print("Unexpected UI_INFO_MESSAGE: "..message);
				error("Unexpected UI_INFO_MESSAGE: "..message);
			end
		end
	}),

	WAIT_FOR_ENCHANTABLE = baseOrderState:new({
		Name = "WAIT_FOR_ENCHANTABLE",

		TRADE_TARGET_ITEM_CHANGED = function(customer, slotChanged)
			if slotChanged == 7 then
				local itemName, _, quantity = GetTradeTargetItemInfo(slotChanged);
				local itemLink = GetTradeTargetItemLink(slotChanged);
				ns.CurrentTrade[slotChanged] = itemName ~= nil and { id = ns.getItemIdFromLink(itemLink), quantity = quantity } or nil;

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
		UI_INFO_MESSAGE = function(customer, error)
			if error == 226 then
				print("Trade cancelled.");
				return ns.OrderStates["READY_FOR_DELIVERY"];
			else
				print("Unexpected UI_INFO_MESSAGE: "..message);
				error("Unexpected UI_INFO_MESSAGE: "..message);
			end
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
