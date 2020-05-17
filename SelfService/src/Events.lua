local _, ns = ...;

local COMMAND_REGEX = "^!%s*%a%a";
local SEARCH_REGEX = "^%?%s*([|%a%d]+)";


local frame = CreateFrame("Frame");
frame:RegisterEvent("CRAFT_SHOW");
frame:RegisterEvent("CHAT_MSG_WHISPER");
frame:RegisterEvent("TRADE_SHOW");
-- Register event so we can disable addon in a BG

frame:SetScript("OnEvent", function(_, event, ...)
	if event == "CRAFT_SHOW" then
		-- Only enchanting (and a couple irrelevant skills) use this event.
		if GetCraftName() == "Enchanting" and not ns.Loaded.Enchanting then
			ns.populateEnchantingData(ns.Data.Enchanting);

			-- Connects products (Wands, oils) with their "enchant"
			ns.populateEnchantExtraData(ns.Data.Enchanting_Results);
			ns.populateGlobalData(ns.Data.Enchanting);
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
				customer:reply(ns.L.enUS.FIRST_TIME_CUSTOMER);
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
		-- allow trade request if there is an active record of the customer, otherwise immediately cancel and send whisper
		print("Trade Initiated");
		-- TODO: Detect Realm on load
		local name = TradeFrameRecipientNameText:GetText().."-Thunderfury";

		-- TODO: Update to use with cart active customers
		if ns.Customers[name] then
			print("Customer active, continue trade.");
			-- Active customer, register trade events
			frame:RegisterEvent("TRADE_TARGET_ITEM_CHANGED");
			frame:RegisterEvent("TRADE_ACCEPT_UPDATE");
			frame:RegisterEvent("CHAT_MSG_LOOT");
		else
			CancelTrade();
			customer:reply(ns.L.enUS.BUY_FIRST);
		end

	elseif event == "TRADE_TARGET_ITEM_CHANGED" then
		-- If we land here, customer is active and available to trade
		-- TODO: Detect Realm on load
		local name = TradeFrameRecipientNameText:GetText().."-Thunderfury";
		local slotChanged = ...;
		-- Slots 1-7, 7 will not be traded slot. Only care about 1-6 for accounting purposes
		print("Trade Item Changed: "..slotChanged);
		local itemName, _, quantity, _, _, _ = GetTradeTargetItemInfo(slotChanged);
		local itemLink = GetTradeTargetItemLink(slotChanged);
		-- Test to add item to TradedItems table. Only actually add items to TradedItems if trade is completed
		if(itemName) then -- If GetTradeTargetItemInfo returns empty, item was removed from window
			-- Track the state of each slot individually
			ns.Customers[name]:addTradedItem(itemName, quantity);
		else
			--ns.Customers[name]:removeTradedItem()
		end

	elseif event == "TRADE_ACCEPT_UPDATE" then
		-- Customer has accepted the trade. Do we accept or reject?
		-- Minimize number of trades. Require customer to optimize trading of mats, compare to expected optimization
		-- MVP: 1 trade, 1 enchant. Are exact mats present? Yes: accept, No: reject
		-- If we accept the trade, register the TRADE_CLOSED event and listen for bag update/chat loot events to cross check traded items
		frame:RegisterEvent("TRADE_CLOSED");

	elseif event == "TRADE_CLOSED" then
		-- Listen for CHAT_MSG_LOOT events and look for expected mats
			-- ^ This method could cause issues
		-- Unregister all trade events
		frame:UnregisterEvent("TRADE_TARGET_ITEM_CHANGED");
		frame:UnregisterEvent("TRADE_CLOSED");
		frame:UnregisterEvent("CHAT_MSG_LOOT");
		-- Scan bags to ensure transfer of actual materials
		-- May be easier to record bag contents in pretrade and subtract that from bag contents posttrade
	end
end);

ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", function(_, event, message, sender)
	return ns.Enabled and (message:match(COMMAND_REGEX) or message:match(SEARCH_REGEX));
end)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(_, event, message, sender)
	return ns.Enabled and message:sub(1, #ns.REPLY_PREFIX) == ns.REPLY_PREFIX;
end)
