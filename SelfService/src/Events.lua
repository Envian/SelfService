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
		ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", ns.Events.filterInbound);
		ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", ns.Events.filterOutbound);
		print(ns.LOG_ENABLED);
	end
end

ns.disableAddon = function()
	if ns.Enabled then
		ns.Disable = false;
		ns.Events.Frame:UnregisterEvent("CRAFT_SHOW");
		ns.Events.Frame:UnregisterEvent("CHAT_MSG_WHISPER");
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER", ns.Events.filterInbound);
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER_INFORM", ns.Events.filterOutbound);
		print(ns.LOG_DISABLED);
	end
end

DEBUG = ns;

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
	end
end);
