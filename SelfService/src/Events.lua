local _, ns = ...;

local ns.

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
		ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", ns.Events.filterInbound);
		ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", ns.Events.filterOutbound);
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
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER", ns.Events.filterInbound);
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER_INFORM", ns.Events.filterOutbound);
		print(ns.LOG_DISABLED);
	end
end

ns.Events.Frame:SetScript("OnEvent", function(_, event, ...)
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
		-- allow trade request if there is an active record of the
		-- customer, otherwise immediately cancel and send whisper
		print("Trade Initiated");
		local name = TradeFrameRecipientNameText:GetText().."-"..GetRealmName();

		if ns.Customers[name]:getCart() then
			print("Customer active, continue trade.");
			-- Active customer, register trade events and configure window monitor
			frame:RegisterEvent("TRADE_TARGET_ITEM_CHANGED");
			frame:RegisterEvent("TRADE_MONEY_CHANGED"); -- May be TRADE_CURRENCY_CHANGED
			frame:RegisterEvent("TRADE_ACCEPT_UPDATE");
		else
			CancelTrade();
			customer:reply(ns.L.enUS.BUY_FIRST);
		end

	elseif event == "TRADE_TARGET_ITEM_CHANGED" then
		-- If we land here, customer is active and available to trade
		local slotChanged = ...;
		print("Trade Item Changed: "..slotChanged);
		local itemName, _, quantity = GetTradeTargetItemInfo(slotChanged);
		local itemLink = GetTradeTargetItemLink(slotChanged);

		if itemName == "" then -- If GetTradeTargetItemInfo returns empty strings, item was removed from window
			print("Item removed from slot "..slotChanged);
			ns.CurrentOrder:removeTradeWindowItem(slotChanged);
		else
			print(itemName.." added to slot "..slotChanged);
			ns.CurrentOrder:addTradeWindowItem(ns.getItemIdFromLink(itemLink), itemName, quantity, slotChanged);
		end

	elseif event == "TRADE_MONEY_CHANGED" then
		print("Customer has changed tip value.");

	elseif event == "TRADE_ACCEPT_UPDATE" then
		-- Customer has accepted the trade. Do we accept or reject?
		-- Minimize number of trades. Require customer to optimize trading of mats, compare to expected optimization
		-- Gathering: 1 trade, 1 enchant. Are exact mats present?
		-- Enchant: is slot 7 enchanted properly and does tip match price?
		-- If we accept the trade, register the TRADE_CLOSED event and listen for bag update/chat loot events to cross check traded items
		frame:RegisterEvent("CHAT_MSG_LOOT"); -- register event only if we accept trade
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
