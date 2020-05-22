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
				ns.CurrentTrade.Items[n].ItemId = 0;
				ns.CurrentTrade.Items[n].Count = 0;
			end
			ns.CurrentTrade.Gold = 0;
			ns.CurrentTrade.Customer = customer;

			ns.CurrentTrade.Customer.Order:handleEvent(ns.CurrentTrade.Customer, "tradeOpened");
		end
	end,
	tradeItemChanged = function(slot)
		local itemName, _, quantity = GetTradeTargetItemInfo(slot);

		ns.CurrentTrade.Items[slot].Id = itemName and ns.getItemIdFromLink(GetTradeTargetItemLink(slot), "item") or 0;
		ns.CurrentTrade.Items[slot].Quantity = itemName and quantity or 0;

		ns.dumpTable(ns.CurrentTrade.Items);
		ns.CurrentTrade.Customer.Order:handleEvent(ns.CurrentTrade.Customer, "tradeItemChanged");
	end,
	tradeGoldChanged = function(slot)

	end,
	tradeAccepted = function()

	end,
	tradeCanceled = function()

	end,
	tradeConfirmed = function()

	end
}
