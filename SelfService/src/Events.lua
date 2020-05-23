local _, ns = ...;

local COMMAND_REGEX = "^!%s*%a%a";
local SEARCH_REGEX = "^%?%s*([|%a%d]+)";

ns.Events = {
	EventFrame = CreateFrame("Frame"),
	filterInbound = function(_, event, message, sender)
		return ns.Enabled and (message:match(COMMAND_REGEX) or message:match(SEARCH_REGEX));
	end,
	filterOutbound = function(_, event, message, sender)
		return ns.Enabled and message:sub(1, #ns.REPLY_PREFIX) == ns.REPLY_PREFIX;
	end
}

ns.enableAddon = function()
	if not ns.Enabled then
		for event, _ in pairs(ns.Events.EventHandlers) do
			ns.Events.EventFrame:RegisterEvent(event);
		end
		-- Hides outgoing bot whispers, and incoming commands.
		-- ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", ns.Events.filterInbound);
		-- ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", ns.Events.filterOutbound);

		if not SelfService_SecureButton then
			local btn = CreateFrame("Button", "SelfService_SecureButton", UIParent, "SecureActionButtonTemplate");
			btn:SetSize(42, 42);
			btn:SetPoint("CENTER");

			local t = btn:CreateTexture(nil,"BACKGROUND")
			t:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Factions.blp")
			t:SetAllPoints(btn)
			btn.texture = t
		else
			SelfService_SecureButton:Show();
		end

		ns.Enabled = true;
		print(ns.LOG_ENABLED);
	end
end

ns.disableAddon = function()
	if ns.Enabled then
		for event, _ in pairs(ns.Events.EventHandlers) do
			ns.Events.EventFrame:UnregisterEvent(event);
		end
		--ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER", ns.Events.filterInbound);
		--ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER_INFORM", ns.Events.filterOutbound);
		SelfService_SecureButton:Hide();

		ns.Enabled = false;
		print(ns.LOG_DISABLED);
	end
end

ns.Events.EventHandlers = {
	CHAT_MSG_WHISPER = function(message, sender)
		-- Convert messages including "?term" to "!search term"
		message = message:gsub(SEARCH_REGEX, "!search %1");
		if message:match(COMMAND_REGEX) then
			print(message);
			local command, term = message:match("^%!(%S+)%s?(.*)$");
			ns.getCustomer(sender):handleCommand(command, term);
		end
	end,
	TRADE_SHOW = function() ns.Trading.tradeOpened() end,
	TRADE_TARGET_ITEM_CHANGED = function(slot) ns.Trading.tradeItemChanged(slot) end,
	TRADE_MONEY_CHANGED = function() ns.Trading.tradeGoldChanged() end,
	TRADE_ACCEPT_UPDATE = function(playerAccepted, CustomerAccepted) ns.Trading.tradeAccepted(playerAccepted, CustomerAccepted) end,
	TRADE_REPLACE_ENCHANT = function() ns.Trading.overrideEnchant() end,
	UI_INFO_MESSAGE = function(code)
		if     code == 226 then ns.Trading.tradeCanceled()
		elseif code == 227 then ns.Trading.tradeCompleted()
		end
	end,
	CURRENT_SPELL_CAST_CHANGED = function()
		if ns.CurrentTrade.Customer and ns.CurrentTrade.Customer.CurrentOrder then
			ns.CurrentTrade.Customer.CurrentOrder:handleEvent("CURSOR_CHANGE");
		end
	end,
	CURSOR_UPDATE = function()
		if ns.CurrentTrade.Customer and ns.CurrentTrade.Customer.CurrentOrder then
			ns.CurrentTrade.Customer.CurrentOrder:handleEvent("CURSOR_CHANGE");
		end
	end,
	-- UNIT_SPELLCAST_FAILED_QUIET = function(_, _, spellId)
	-- 	if ns.CurrentTrade.Customer and ns.CurrentTrade.Customer.CurrentOrder then
	-- 		ns.CurrentTrade.Customer.CurrentOrder:handleEvent("ENCHANT_FAILED", spellId);
	-- 	end
	-- end,
	UNIT_SPELLCAST_FAILED = function(_, _, spellId)
		if ns.CurrentTrade.Customer and ns.CurrentTrade.Customer.CurrentOrder then
			ns.CurrentTrade.Customer.CurrentOrder:handleEvent("ENCHANT_FAILED", spellId);
		end
	end,
};

-- UNIT_SPELLCAST_FAILED_QUIET 3rd param will be Enchant ID

ns.Events.EventFrame:SetScript("OnEvent", function(_, event, ...)
	ns.Events.EventHandlers[event](...);
end);
	-- else
	-- 	print("Another event fired. Checking currentOrder...");
	--
	-- 	if(ns.CurrentOrder) then
	-- 		print("CurrentOrder is active. Call process()");
	-- 		ns.CurrentOrder:process(event, ...);
	-- 	else
	-- 		print("CurrentOrder is inactive. Do nothing.");
	-- 	end
	-- end
	-- elseif event == "TRADE_SHOW" then
	-- 	print("Trade Initiated");
	-- 	local customer = ns.getCustomer(TradeFrameRecipientNameText:GetText());
	--
	-- 	if customer then
	-- 		local order = customer:getOrder();
	--
	-- 		if order then
	-- 			print("Customer order is active, continue trade.");
	-- 			if order.Status == ns.OrderClass.STATUSES.ORDERED then
	-- 				print("Customer has ordered, waiting on mats.");
	-- 			elseif order.Status == ns.OrderClass.STATUSES.GATHERED then
	-- 				print("Customer has delivered mats, start enchanting");
	-- 			else
	-- 				print("This order is in an insofar unhandled state.");
	-- 			end
	-- 		else
	-- 			CancelTrade();
	-- 			customer:reply(ns.L.enUS.BUY_FIRST);
	-- 		end
	-- 	else
	-- 		CancelTrade();
	-- 	end
	--
	-- elseif event == "TRADE_TARGET_ITEM_CHANGED" then
	-- 	local slotChanged = ...;
	-- 	local _, _, quantity = GetTradeTargetItemInfo(slotChanged);
	-- 	local itemLink = GetTradeTargetItemLink(slotChanged);
	-- 	ns.CurrentTrade[slotChanged] = itemName ~= "" and { id = ns.getItemIdFromLink(itemLink), quantity = quantity } or nil;
	--
	-- elseif event == "TRADE_MONEY_CHANGED" then
	-- 	-- Money frame getText will be required to determine value
	-- 	print("Customer has changed tip value.");
	--
	-- elseif event == "TRADE_ACCEPT_UPDATE" then
	-- 	local playerAccepted, customerAccepted = ...;
	--
	-- 	print("Trade accept button pressed: ");
	-- 	print("  - Player Accepted: "..playerAccepted);
	-- 	print("  - Customer Accepted: "..customerAccepted);
	--
	-- 	if playerAccepted == 0 and customerAccepted == 1 then
	-- 		if ns.CurrentOrder:isTradeAcceptable() then
	-- 			--AcceptTrade(); -- Blizzard UI Protected Function
	-- 			print("TRADE ACCEPTABLE, ACCEPT TRADE!");
	-- 		else
	-- 			CancelTrade();
	-- 		end
	-- 	end
	--
	-- 	-- Minimize number of trades. Require customer to optimize trading of mats, compare to expected optimization
	-- 	-- Gathering: 1 trade, 1 enchant. Are exact mats present?
	-- 	-- Enchant: is slot 7 enchanted properly and does tip match price?
	-- 	-- If we accept the trade, register the TRADE_CLOSED event and listen for bag update/chat loot events to cross check traded items
	--
	-- --UI_INFO_MESSAGE
	-- -- 227 "Trade complete."
	-- -- 226 "Trade cancelled."
	-- elseif event == "UI_INFO_MESSAGE" then
	-- 	local error, message = ...;
	-- 		-- Fired when the window closes, not guarantee of successful trade
	-- 		-- May need to check a flag to see if trade was accepted or cancelled
	-- 	if message == "Trade complete." then
	-- 		print("Trade complete.");
	-- 		if ns.CurrentOrder then
	-- 			ns.CurrentOrder:closeTrade();
	-- 		end
	-- 	elseif message == "Trade cancelled." then
	-- 		print("Trade cancelled.");
	-- 		if ns.CurrentOrder then
	-- 			print("Keep global CurrentOrder alive.");
	-- 		end
	-- 	else
	-- 		print("Something else happened.");
	-- 	end
	-- 		-- Listen for CHAT_MSG_LOOT events and look for expected mats
	-- 			-- ^ This method could cause issues
	-- 		-- Unregister all trade events
	-- 		-- Scan bags to ensure transfer of actual materials
	-- 		-- May be easier to record bag contents in pretrade and subtract that from bag contents posttrade
	-- end
-- end);

-- Loading events are always captured.
local loadingFrame = CreateFrame("Frame");
loadingFrame:RegisterEvent("CRAFT_SHOW");
loadingFrame:SetScript("OnEvent", function(_, event, ...)
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

			-- Connects products (Wands, oils) with their "enchant", so product IDs can be linked to their recipe.
			for itemId, recipe in pairs(ns.Data.Enchanting_Results) do
				ns.Recipes[itemId] = recipe;
			end
			ns.Loaded.Enchanting = true;
			print(ns.LOG_LOADED:format("Enchanting"));
		end
	end
end);
