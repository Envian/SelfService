local _, ns = ...;

local COMMAND_REGEX = "^!%s*%a%a";
local SEARCH_REGEX = "^%?%s*([|%a%d]+)";


local frame = CreateFrame("Frame");
frame:RegisterEvent("CRAFT_SHOW");
frame:RegisterEvent("CHAT_MSG_WHISPER");
frame:RegisterEvent("TRADE_SHOW");

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
			frame:RegisterEvent("TRADE_TARGET_ITEM_CHANGED");
		else
			CancelTrade();
			customer:reply(ns.L.enUS.BUY_FIRST);
		end
		
	elseif event == "TRADE_TARGET_ITEM_CHANGED" then
		local slotChanged = ...;
		-- Slots 1-7, 7 will not be traded slot
		print("Trade Item Changed: "..slotChanged);
		local name, _, quantity, _, _, _ = GetTradeTargetItemInfo(slotChanged);
		local itemLink = GetTradeTargetItemLink(slotChanged);
		
	end
end);

ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", function(_, event, message, sender)
	return ns.Enabled and (message:match(COMMAND_REGEX) or message:match(SEARCH_REGEX));
end)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(_, event, message, sender)
	return ns.Enabled and message:sub(1, #ns.REPLY_PREFIX) == ns.REPLY_PREFIX;
end)
