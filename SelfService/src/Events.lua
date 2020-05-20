local _, ns = ...;

local COMMAND_REGEX = "^!%s*%a%a";
local SEARCH_REGEX = "^%?%s*([|%a%d]+)";

ns.Events = {
	Frame = CreateFrame("Frame"),
	filterInbound = function(_, event, message, sender)
		return ns.Enabled and (message:match(COMMAND_REGEX) or message:match(SEARCH_REGEX));
	end,
	filterOutbound = function(_, event, message, sender)
		return ns.Enabled and message:sub(1, #ns.REPLY_PREFIX) == ns.REPLY_PREFIX;
	end
}

ns.enableAddon = function()
	if not ns.Enabled then
		ns.Enabled = true;
		ns.Events.Frame:RegisterEvent("CRAFT_SHOW");
		ns.Events.Frame:RegisterEvent("CHAT_MSG_WHISPER");
		ns.Events.Frame:RegisterEvent("TRADE_SHOW");
		ns.Events.Frame:RegisterEvent("TRADE_TARGET_ITEM_CHANGED");
		ns.Events.Frame:RegisterEvent("TRADE_MONEY_CHANGED");
		ns.Events.Frame:RegisterEvent("TRADE_ACCEPT_UPDATE");
		ns.Events.Frame:RegisterEvent("TRADE_CLOSED");
		--ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", ns.Events.filterInbound);
		--ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", ns.Events.filterOutbound);
		print(ns.LOG_ENABLED);
	end
end

ns.disableAddon = function()
	if ns.Enabled then
		ns.Enabled = false;
		ns.Events.Frame:UnregisterEvent("CRAFT_SHOW");
		ns.Events.Frame:UnregisterEvent("CHAT_MSG_WHISPER");
		ns.Events.Frame:UnregisterEvent("TRADE_SHOW");
		ns.Events.Frame:UnregisterEvent("TRADE_TARGET_ITEM_CHANGED");
		ns.Events.Frame:UnregisterEvent("TRADE_MONEY_CHANGED");
		ns.Events.Frame:UnregisterEvent("TRADE_ACCEPT_UPDATE");
		ns.Events.Frame:UnregisterEvent("TRADE_CLOSED");
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER", ns.Events.filterInbound);
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER_INFORM", ns.Events.filterOutbound);
		print(ns.LOG_DISABLED);
	end
end

ns.Events.Frame:SetScript("OnEvent", function(_, event, ...)
	if event == "CRAFT_SHOW" then
		-- Only enchanting (and a couple irrelevant skills) use this event.
		if GetCraftName() == "Enchanting" and not ns.Loaded.Enchanting then
			for n = 1,GetNumCrafts(),1 do
				local id = ns.getItemIdFromLink(GetCraftItemLink(n), "enchant");

				local enchant = ns.Data.Enchanting[id];
				if enchant then
					enchant = ns.RecipeClass:newEnchant(id, enchant);
					enchant:loadFromIndex(n);
				end
			end

			-- Connects products (Wands, oils) with their "enchant"
			for itemId, recipe in pairs(ns.Data.Enchanting_Results) do
				ns.Recipes[itemId] = recipe;
			end
			ns.Loaded.Enchanting = true;
			print(ns.LOG_LOADED:format("Enchanting"));
		end

	elseif event == "CHAT_MSG_WHISPER" then
		local message, sender = ...;
		if not message or not sender then return end;

		-- allow ? queries by "translating" to !search
		message = message:gsub(SEARCH_REGEX, "!search %1");
		if message:match(COMMAND_REGEX) then
			local customer = ns.getCustomer(sender);

			-- Do we send a greeting?
			if customer.LastWhisper == 0 then
				print(string.format(ns.LOG_NEW_CUSTOMER, customer.Name));
				customer.MessagesAvailable = 1; -- Allows an extra message in this case.
				customer:reply(ns.L.enUS.FIRST_TIME_CUSTOMER);
			elseif GetTime() - customer.LastWhisper > 30 * 60 then
				print(string.format(ns.LOG_NEW_CUSTOMER, customer.Name));
				customer.MessagesAvailable = 1;
				customer:reply(ns.L.enUS.RETURNING_CUSTOMER);
			end

			customer.MessagesAvailable = 2; -- Safeguard against spam.

			local command, args = message:match("^%!(%S+)%s?(.*)$");
			local cmdFunction = ns.Commands[command:lower()];

			if cmdFunction == nil then
				customer:reply(ns.L.enUS.UNKNOWN_COMMAND);
			else
				cmdFunction(args, customer);
			end

			customer.LastWhisper = GetTime();
			customer.MessagesAvailable = 0;
		end

	elseif event == "TRADE_SHOW" then
		print("Trade Initiated");
		local customer = ns.getCustomer(TradeFrameRecipientNameText:GetText());

		if customer then
			local order = customer:getOrder();

			if order then
				print("Customer order is active, continue trade.");
				if order.Status == ns.OrderClass.STATUSES.ORDERED then
					print("Customer has ordered, waiting on mats.");
				elseif order.Status == ns.OrderClass.STATUSES.GATHERED then
					print("Customer has delivered mats, start enchanting");
				else
					print("This order is in an insofar unhandled state.");
				end
			else
				CancelTrade();
				customer:reply(ns.L.enUS.BUY_FIRST);
			end
		else
			CancelTrade();
		end

	elseif event == "TRADE_TARGET_ITEM_CHANGED" then
		local slotChanged = ...;
		local _, _, quantity = GetTradeTargetItemInfo(slotChanged);
		local itemLink = GetTradeTargetItemLink(slotChanged);
		ns.CurrentTrade[slotChanged] = itemName ~= "" and { id = ns.getItemIdFromLink(itemLink), quantity = quantity } or nil;

	elseif event == "TRADE_MONEY_CHANGED" then
		-- Money frame getText will be required to determine value
		print("Customer has changed tip value.");

	elseif event == "TRADE_ACCEPT_UPDATE" then
		local playerAccepted, customerAccepted = ...;

		print("Trade accept button pressed: ");
		print("  - Player Accepted: "..playerAccepted);
		print("  - Customer Accepted: "..customerAccepted);

		if playerAccepted == 0 and customerAccepted == 1 then
			if ns.CurrentOrder:isTradeAcceptable() then
				AcceptTrade();
			else
				CancelTrade();
			end
		end

		-- Minimize number of trades. Require customer to optimize trading of mats, compare to expected optimization
		-- Gathering: 1 trade, 1 enchant. Are exact mats present?
		-- Enchant: is slot 7 enchanted properly and does tip match price?
		-- If we accept the trade, register the TRADE_CLOSED event and listen for bag update/chat loot events to cross check traded items

	elseif event == "TRADE_CLOSED" then
		-- Fired when the window closes, not guarantee of successful trade
		-- May need to check a flag to see if trade was accepted or cancelled
		if ns.CurrentOrder then
			ns.CurrentOrder:closeTrade();
		else
			ns.CurrentTrade = {};
		end
		-- Listen for CHAT_MSG_LOOT events and look for expected mats
			-- ^ This method could cause issues
		-- Unregister all trade events
		-- Scan bags to ensure transfer of actual materials
		-- May be easier to record bag contents in pretrade and subtract that from bag contents posttrade
	end
end);
