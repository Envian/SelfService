local _, ns = ...;

local noAction = function() return self end;
-- Base state - All events which are not defiend fall back here, and return self.
local baseOrderState = {
    "EnterState" = noAction, -- basically a  "Custom Event"
    "TRADE_MONEY_CHANGED" = noAction,
    "TRADE_CLOSED" = noAction
}
baseOrderState.__index = baseOrderState;
function baseOrderState:new(state)
    setmetatable(state, baseOrderState);
    return state;
end

ns.OrderStates = {
	"ORDER_PLACED" = baseOrderState:new({
		"TRADE_SHOW" = function()
			-- return ns.OrderStates."WAIT_FOR_MATS";
		end
	}),

	"WAIT_FOR_MATS" = baseOrderState:new({
		"UI_INFO_MESSAGE" = function()
			-- return ns.OrderStates."ORDER_PLACED";
		end,
		"TRADE_TARGET_ITEM_CHANGED" = function()
			-- return self;
		end,
		"TRADE_ACCEPT_UPDATE" = function()
			-- return ns.OrderStates."ACCEPT_MATS"; or
			-- return self;
		end
	}),

	"ACCEPT_MATS" = baseOrderState:new({
		"TRADE_TARGET_ITEM_CHANGED" = function()
			-- return ns.OrderStates."ACCEPT_MATS";
		end,
		"UI_INFO_MESSAGE" = function()
			-- return ns.OrderStates."ORDER_PLACED"; or
			-- return ns.OrderStates."CRAFT_ORDER";
		end
	}),

	"CRAFT_ORDER" = baseOrderState:new({
		"SOME_EVENT_TRIGGERED" = function()
			-- return ns.OrderStates."ORDER_GATHERED";
		end
	}),

	"READY_FOR_DELIVERY" = baseOrderState:new({
		"TRADE_SHOW" = function()
			-- return ns.OrderStates."DELIVER_ORDER";
		end
	}),

	"DELIVER_ORDER" = baseOrderState:new({
		"TRADE_TARGET_ITEM_CHANGED" = function()
			-- return ns.OrderStates."WAIT_FOR_ENCHANTABLE"; or
			-- return ns.OrderStates."AWAIT_PAYMENT";
		end,
		"UI_INFO_MESSAGE" = function()
			-- return ns.OrderStates."READY_FOR_DELIVERY";
		end
	}),

	"WAIT_FOR_ENCHANTABLE" = baseOrderState:new({
		"TRADE_TARGET_ITEM_CHANGED" = function()
			-- return self; or
			-- return ns.OrderStates."CAST_ENCHANT";
		end,
		"UI_INFO_MESSAGE" = function()
			-- return ns.OrderStates."READY_FOR_DELIVERY";
		end
	}),

	"CAST_ENCHANT" = baseOrderState:new({
		"TRADE_TARGET_ITEM_CHANGED" = function()
			-- return ns.OrderStates."WAIT_FOR_ENCHANTABLE"; or
			-- return ns.OrderStates."AWAIT_PAYMENT";
		end,
		"TRADE_REPLACE_ENCHANT" = function()
			-- return ns.OrderStates."OVERRIDE_ENCHANT";
		end,
		"UI_INFO_MESSAGE" = function()
			-- return ns.OrderStates."READY_FOR_DELIVERY";
		end
	}),

	"OVERRIDE_ENCHANT" = baseOrderState:new({
		"TRADE_TARGET_ITEM_CHANGED" = function()
			-- return ns.OrderStates."AWAIT_PAYMENT";
		end,
		"UI_INFO_MESSAGE" = function()
			-- return ns.OrderStates."READY_FOR_DELIVERY";
		end
	}),

	"AWAIT_PAYMENT" = baseOrderState:new({
		"TRADE_MONEY_CHANGED" = function()
			-- return ns.OrderStates."ACCEPT_DELIVERY"; or
			-- return self;
		end,
		"UI_INFO_MESSAGE" = function()
			-- return ns.OrderStates."READY_FOR_DELIVERY";
		end
	}),

	"ACCEPT_DELIVERY" = baseOrderState:new({
		"UI_INFO_MESSAGE" = function()
			-- return ns.OrderStates."READY_FOR_DELIVERY"; or
			-- return ns.OrderStates."COMPLETE"
		end
	})
}
