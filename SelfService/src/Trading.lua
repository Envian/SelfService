local _, ns = ...;

ns.CurrentTrade = {
	TargetItems = {{},{},{},{},{},{},{}},
	PlayerItems = {{},{},{},{},{},{},{}},
	TargetMoney = 0,
	PlayerMoney = 0,
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
				wipe(ns.CurrentTrade.TargetItems[n]);
				wipe(ns.CurrentTrade.PlayerItems[n]);
			end
			ns.CurrentTrade.TargetMoney = 0;
			ns.CurrentTrade.PlayerMoney = 0;
			ns.CurrentTrade.Customer = customer;

			ns.CurrentTrade.Customer.CurrentOrder:handleEvent("TRADE_SHOW");
			ns.debugf(ns.LOG_TRADE_ACCEPTED, customer.Name);
		end
	end,
	tradeItemChanged = function(slot)
		if not ns.CurrentTrade.Customer or not ns.CurrentTrade.Customer.CurrentOrder then return end;

		local itemName, _, quantity = GetTradeTargetItemInfo(slot);

		ns.CurrentTrade.TargetItems[slot].Id = itemName and ns.getItemIdFromLink(GetTradeTargetItemLink(slot), "item") or nil;
		ns.CurrentTrade.TargetItems[slot].Count = itemName and quantity or nil;

		ns.CurrentTrade.Customer.CurrentOrder:handleEvent("TRADE_ITEM_CHANGED", ns.CurrentTrade.TargetItems);
	end,
	playerItemChanged = function(slot)
		if not ns.CurrentTrade.Customer or not ns.CurrentTrade.Customer.CurrentOrder then return end;

		local itemName, _, quantity = GetTradePlayerItemInfo(slot);

		ns.CurrentTrade.PlayerItems[slot].Id = itemName and ns.getItemIdFromLink(GetTradePlayerItemLink(slot), "item") or nil;
		ns.CurrentTrade.PlayerItems[slot].Count = itemName and quantity or nil;
	end,
	tradeItemUpdated = function()
		if not ns.CurrentTrade.Customer or not ns.CurrentTrade.Customer.CurrentOrder then return end;

		for i=1,7 do
			local itemName, _, quantity = GetTradeTargetItemInfo(i);

			ns.CurrentTrade.TargetItems[i].Id = itemName and ns.getItemIdFromLink(GetTradeTargetItemLink(i), "item") or nil;
			ns.CurrentTrade.TargetItems[i].Count = itemName and quantity or nil;
		end

		ns.CurrentTrade.Customer.CurrentOrder:handleEvent("TRADE_ITEM_CHANGED", ns.CurrentTrade.TargetItems);
	end,
	tradeGoldChanged = function()
		if not ns.CurrentTrade.Customer or not ns.CurrentTrade.Customer.CurrentOrder then return end;

		ns.CurrentTrade.Money = GetTargetTradeMoney();
		ns.CurrentTrade.Customer.CurrentOrder:handleEvent("TRADE_MONEY_CHANGED", ns.CurrentTrade.TargetMoney, ns.CurrentTrade.PlayerMoney);
	end,
	tradeAccepted = function(playerAccepted, CustomerAccepted)
		if not ns.CurrentTrade.Customer or not ns.CurrentTrade.Customer.CurrentOrder then return end;

		ns.dumpTable(ns.CurrentTrade.TargetItems);
		ns.dumpTable(ns.CurrentTrade.PlayerItems);

		ns.CurrentTrade.Customer.CurrentOrder:handleEvent("TRADE_ACCEPTED", playerAccepted, CustomerAccepted);
	end,
	overrideEnchant = function(currentEnchant, newEnchant)
		if not ns.CurrentTrade.Customer or not ns.CurrentTrade.Customer.CurrentOrder then return end;
		ns.CurrentTrade.Customer.CurrentOrder:handleEvent("REPLACE_ENCHANT", currentEnchant, newEnchant);
	end,
	tradeCancelled = function()
		if not ns.CurrentTrade.Customer or not ns.CurrentTrade.Customer.CurrentOrder then return end;

		ns.CurrentTrade.Customer.CurrentOrder:handleEvent("TRADE_CANCELLED");
		ns.CurrentTrade.Customer = nil;
	end,
	tradeCompleted = function()
		if not ns.CurrentTrade.Customer or not ns.CurrentTrade.Customer.CurrentOrder then return end;

		-------------------------------------------------------------------------------------------------------
		-- Reconcile trade items from both ns.CurrentTrade.PlayerItems and ns.CurrentTrade.TargetItems here. --
		-------------------------------------------------------------------------------------------------------
		ns.CurrentTrade.Customer.CurrentOrder:reconcile(ns.CurrentTrade.PlayerItems, false);
		ns.CurrentTrade.Customer.CurrentOrder:reconcile(ns.CurrentTrade.TargetItems, true);


		ns.CurrentTrade.Customer.CurrentOrder:handleEvent("TRADE_COMPLETED");
		ns.CurrentTrade.Customer = nil;
	end,
	totalTrade = function()
		local tradeMats = {};

		for i=1, 6 do
			local playerStack = ns.CurrentTrade.PlayerItems[i];
			local targetStack = ns.CurrentTrade.TargetItems[i];

			if playerStack.Id then
				tradeMats[playerStack.Id] = (tradeMats[playerStack.Id] or 0) - playerStack.Count;
			end

			if targetStack.Id then
				tradeMats[targetStack.Id] = (tradeMats[targetStack.Id] or 0) + targetStack.Count;
			end
		end

		return tradeMats;
	end
}
