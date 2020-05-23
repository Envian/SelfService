local _, ns = ...;

ns.CurrentTrade = {
	Items = {{},{},{},{},{},{},{}},
	Money = {},
	Customer = nil,
}

ns.Trading = {
	tradeOpened = function()
		local customer = ns.getCustomer(TradeFrameRecipientNameText:GetText());

		-- Temporary, single-order logic
		if not ns.CurrentOrder or ns.CurrentOrder.CustomerName ~= customer.Name then
			ns.warningf(ns.LOG_TRADE_SERVING_OTHER, customer.Name, ns.CurrentOrder and ns.CurrentOrder.CustomerName or "nobody");
			CancelTrade();
			return;
		elseif not customer.CurrentOrder then
			 -- Redundent, but "permanent"
			ns.warningf(ns.LOG_TRADE_BLOCKED_NO_ORDER, customer.Name);
 			CancelTrade();
 			return;
		else
			-- New trade, reset parameters
			for n = 1,7 do
				wipe(ns.CurrentTrade.Items[n]);
			end
			ns.CurrentTrade.Money = 0;
			ns.CurrentTrade.Customer = customer;

			ns.CurrentTrade.Customer.CurrentOrder:handleEvent("TRADE_SHOW");
			ns.debugf(ns.LOG_TRADE_ACCEPTED, customer.Name);
		end
	end,
	tradeItemChanged = function(slot)
		if not ns.CurrentTrade.Customer or not ns.CurrentTrade.Customer.CurrentOrder then return end;

		local itemName, _, quantity = GetTradeTargetItemInfo(slot);

		ns.CurrentTrade.Items[slot].Id = itemName and ns.getItemIdFromLink(GetTradeTargetItemLink(slot), "item") or nil;
		ns.CurrentTrade.Items[slot].Quantity = itemName and quantity or nil;

		ns.CurrentTrade.Customer.CurrentOrder:handleEvent("TRADE_ITEM_CHANGED", ns.CurrentTrade.Items);
	end,
	tradeGoldChanged = function()
		if not ns.CurrentTrade.Customer or not ns.CurrentTrade.Customer.CurrentOrder then return end;

		ns.CurrentTrade.Money = GetTargetTradeMoney();
		ns.CurrentTrade.Customer.CurrentOrder:handleEvent("TRADE_MONEY_CHANGED", ns.CurrentTrade.Copper);
	end,
	tradeAccepted = function(playerAccepted, CustomerAccepted)
		if not ns.CurrentTrade.Customer or not ns.CurrentTrade.Customer.CurrentOrder then return end;
		ns.CurrentTrade.Customer.CurrentOrder:handleEvent("TRADE_ACCEPTED", playerAccepted, CustomerAccepted);
	end,
	overrideEnchant = function()
		if not ns.CurrentTrade.Customer or not ns.CurrentTrade.Customer.CurrentOrder then return end;
		ns.CurrentTrade.Customer.CurrentOrder:handleEvent("REPLACE_ENCHANT");
	end,
	tradeCancelled = function()
		if not ns.CurrentTrade.Customer or not ns.CurrentTrade.Customer.CurrentOrder then return end;

		ns.CurrentTrade.Customer.CurrentOrder:handleEvent("TRADE_CANCELLED");
		ns.CurrentTrade.Customer = nil;
	end,
	tradeCompleted = function()
		if not ns.CurrentTrade.Customer or not ns.CurrentTrade.Customer.CurrentOrder then return end;

		ns.CurrentTrade.Customer.CurrentOrder:addTradedItems(ns.CurrentTrade.Items, ns.CurrentTrade.Money);
		ns.CurrentTrade.Customer.CurrentOrder:handleEvent("TRADE_COMPLETED");
		ns.CurrentTrade.Customer = nil;
	end,
	totalTrade = function()
		local tradeMats = {};

		for i=1, 6 do
			local stack = ns.CurrentTrade.Items[i];
			if stack.Id then
				tradeMats[stack.Id] = (tradeMats[stack.Id] or 0) + stack.Quantity;
			end
		end

		return tradeMats;
	end
}
