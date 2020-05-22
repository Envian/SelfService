local _, ns = ...;

ns.CurrentTrade = {
	Items = {},
	Gold = {},
	Customer = nil,
}

ns.Trading = {
	tradeOpened = function()
		local customer = ns.getCustomer(TradeFrameRecipientNameText:GetText());

		-- Temporary, single-order logic
		if not ns.CurrentOrder or ns.CurrentOrder.CustomerName ~= customer.Name then
			print("Canceling Trade - No Active Order or Incorrect Customer")
			CancelTrade();
			return;
		elseif not customer.Order then
			 -- Redundent, but "permanent"
			print("Canceling Trade - No Active Order")
 			CancelTrade();
 			return;
		else
			-- New trade, reset parameters
			for n = 1,7 do
				ns.CurrentTrade.Items[n].Id = 0;
				ns.CurrentTrade.Items[n].Count = 0;
			end
			ns.CurrentTrade.Copper = 0;
			ns.CurrentTrade.Customer = customer;

			ns.CurrentTrade.Customer.Order:handleEvent("TRADE_SHOW");
		end
	end,
	tradeItemChanged = function(slot)
		if not ns.CurrentTrade.Customer then return end;

		local itemName, _, quantity = GetTradeTargetItemInfo(slot);

		ns.CurrentTrade.Items[slot].Id = itemName and ns.getItemIdFromLink(GetTradeTargetItemLink(slot), "item") or 0;
		ns.CurrentTrade.Items[slot].Quantity = itemName and quantity or 0;

		ns.dumpTable(ns.CurrentTrade.Items);
		ns.CurrentTrade.Customer.Order:handleEvent("TRADE_ITEM_CHANGED", ns.Trading.CurrentTrade.Items);
	end,
	tradeGoldChanged = function()
		if not ns.CurrentTrade.Customer then return end;

		ns.CurrentTrade.Copper = GetTargetTradeMoney();
		ns.CurrentTrade.Customer.Order:handleEvent("TRADE_MONEY_CHANGED", ns.CurrentTrade.Copper);
	end,
	tradeAccepted = function(playerAccepted, CustomerAccepted)
		if not ns.CurrentTrade.Customer then return end;
		ns.CurrentTrade.Customer.Order:handleEvent("TRADE_ACCEPT_UPDATE", playerAccepted, CustomerAccepted);
	end,
	overrideEnchant = function()
		if not ns.CurrentTrade.Customer then return end;
		ns.CurrentTrade.Customer.Order:handleEvent("REPLACE_ENCHANT");
	end,
	tradeCanceled = function()
		if not ns.CurrentTrade.Customer then return end;

		ns.CurrentTrade.Customer = nil;
		ns.CurrentTrade.Customer.Order:handleEvent("TRADE_CANCELED");
	end,
	tradeCompleted = function()
		if not ns.CurrentTrade.Customer then return end;

		ns.CurrentTrade.Customer = nil;
		ns.CurrentTrade.Customer.Order:handleEvent("TRADE_COMPLETED");
	end,
}
