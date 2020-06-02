local _, ns = ...;

local COMMAND_REGEX = "^!%s*%a%a";
local SEARCH_REGEX = "^%?%s*([|%a%d]+)";

local eventFrame = CreateFrame("Frame");
local filterInbound = function(_, event, message, sender)
	return ns.Enabled and (message:match(COMMAND_REGEX) or message:match(SEARCH_REGEX));
end
local filterOutbound = function(_, event, message, sender)
	return ns.Enabled and message:sub(1, #ns.REPLY_PREFIX) == ns.REPLY_PREFIX;
end

local function ActionButton_OnEnter(self)
	GameTooltip_SetDefaultAnchor(GameTooltip, UIParent);
	GameTooltip:AddLine(self:GetText());
	GameTooltip:Show();
end

local function ActionButton_OnLeave(self)
	GameTooltip:Hide();
end

local eventHandlers = {
	CHAT_MSG_WHISPER = function(message, sender)
		-- Convert messages including "?term" to "!search term"
		message = message:gsub(SEARCH_REGEX, "!search %1");
		if message:match(COMMAND_REGEX) then
			local command, term = message:match("^%!%s*(%S+)%s?(.*)$");
			ns.getCustomer(sender):handleCommand(command, term);
		end
	end,
	TRADE_SHOW = function() ns.Trading.tradeOpened() end,
	TRADE_TARGET_ITEM_CHANGED = function(slot) ns.Trading.targetItemChanged(slot) end,
	TRADE_PLAYER_ITEM_CHANGED = function(slot) ns.Trading.playerItemChanged(slot) end,
	TRADE_UPDATE = function() ns.Trading.tradeItemUpdated() end,
	TRADE_MONEY_CHANGED = function() ns.Trading.tradeGoldChanged() end,
	TRADE_ACCEPT_UPDATE = function(playerAccepted, CustomerAccepted) ns.Trading.tradeAccepted(playerAccepted, CustomerAccepted) end,
	TRADE_REPLACE_ENCHANT = function(currentEnchant, newEnchant) ns.Trading.overrideEnchant(currentEnchant, newEnchant) end,
	UI_INFO_MESSAGE = function(code)
		if     code == 226 then ns.Trading.tradeCancelled()
		elseif code == 227 then ns.Trading.tradeCompleted()
		end
	end,
	CURRENT_SPELL_CAST_CHANGED = function(cancelledCast)
		if ns.CurrentTrade.Customer and ns.CurrentTrade.Customer.CurrentOrder then
			ns.CurrentTrade.Customer.CurrentOrder:handleEvent("SPELLCAST_CHANGED", cancelledCast);
		end
	end,
	UNIT_SPELLCAST_FAILED = function(_, _, spellId)
		if ns.CurrentTrade.Customer and ns.CurrentTrade.Customer.CurrentOrder then
			ns.CurrentTrade.Customer.CurrentOrder:handleEvent("SPELLCAST_FAILED", spellId);
		end
	end,
	-- UNIT_SPELLCAST_SUCCEEDED = function(_, _, spellId)
	-- 	if ns.CurrentTrade.Customer and ns.CurrentTrade.Customer.CurrentOrder then
	-- 		ns.CurrentTrade.Customer.CurrentOrder:handleEvent("ENCHANT_SUCCEEDED", spellId);
	-- 	end
	-- end
};

ns.enableAddon = function()
	if not ns.Enabled then
		for event, _ in pairs(eventHandlers) do
			eventFrame:RegisterEvent(event);
		end
		-- Hides outgoing bot whispers, and incoming commands.
		-- ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", filterInbound);
		-- ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", filterOutbound);

		if not SelfService_SecureButton then
			local btn = CreateFrame("Button", "SelfService_SecureButton", UIParent, "SecureActionButtonTemplate");
			btn:SetSize(42, 42);
			btn:SetPoint("CENTER");
			btn:SetText("No Action");
			btn:SetScript("OnEnter", ActionButton_OnEnter);
			btn:SetScript("OnLeave", ActionButton_OnLeave);

			local t = btn:CreateTexture(nil,"BACKGROUND")
			t:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Factions.blp")
			t:SetAllPoints(btn)
			btn.texture = t
		else
			SelfService_SecureButton:Show();
		end

		ns.Enabled = true;
		ns.warning(ns.LOG_ENABLED);
	else
		ns.warning(ns.LOG_ALREADY_ENABLED);
	end
end

ns.disableAddon = function()
	if ns.Enabled then
		for event, _ in pairs(eventHandlers) do
			eventFrame:UnregisterEvent(event);
		end
		--ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER", filterInbound);
		--ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER_INFORM", filterOutbound);
		SelfService_SecureButton:Hide();

		ns.Enabled = false;
		ns.warning(ns.LOG_DISABLED);
	else
		ns.warning(ns.LOG_ALREADY_DISABLED);
	end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
	eventHandlers[event](...);
end);

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
			ns.infof(ns.LOG_LOADED, "Enchanting");
		end
	end
end);
