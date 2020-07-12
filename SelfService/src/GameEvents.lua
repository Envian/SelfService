-- This file is part of SelfService.
--
-- SelfService is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- SelfService is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with SelfService.  If not, see <https://www.gnu.org/licenses/>.
local ADDON_NAME, ns = ...;

local COMMAND_REGEX = "^!%s*%a%a";
local SEARCH_REGEX = "^%?%s*([|%a%d]+)";

local filterInbound = function(_, event, message, sender)
	return ns.Enabled and (message:match(COMMAND_REGEX) or message:match(SEARCH_REGEX));
end

local filterOutbound = function(_, event, message, sender)
	return ns.Enabled and message:sub(1, #ns.REPLY_PREFIX) == ns.REPLY_PREFIX;
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
	BAG_UPDATE_DELAYED = function()
		-- Not necessary to have a trade window open to handle this event
		if ns.CurrentOrder then
			ns.CurrentOrder:handleEvent("INVENTORY_CHANGED");
		end
	end
	-- UNIT_SPELLCAST_SUCCEEDED = function(_, _, spellId)
	-- 	if ns.CurrentTrade.Customer and ns.CurrentTrade.Customer.CurrentOrder then
	-- 		ns.CurrentTrade.Customer.CurrentOrder:handleEvent("ENCHANT_SUCCEEDED", spellId);
	-- 	end
	-- end
};

-- Main event frame. Events only fire when the addon is enabled.
local eventFrame = CreateFrame("Frame");
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
			for productId, recipe in pairs(ns.Data.Enchanting_Results) do
				ns.Recipes[productId] = recipe;
				recipe.IsCrafted = true;
				recipe.ProductId = productId;
			end

			ns.Loaded.Enchanting = true;
			ns.infof(ns.LOG_LOADED, "Enchanting");
			ns.dataLoaded("Enchanting");
		end
	end
end);

-- Enable/Disable handlers.
ns.registerEvent(ns.EVENT.ENABLE, function()
	for event, _ in pairs(eventHandlers) do
		eventFrame:RegisterEvent(event);
	end
	-- Hides outgoing bot whispers, and incoming commands.
	-- ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", filterInbound);
	-- ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", filterOutbound);

	SelfService_ActionQueueButton:Show();

	-- Reloads customer information after log in or reload
	for name, data in pairs(SelfServiceData.Customers) do
		if data.CurrentOrder then
			ns.getCustomer(name);
			ns.CurrentOrder = ns.CurrentOrder or (SelfServiceData.CurrentCustomer and ns.Customers[name].CurrentOrder or nil);
		end
	end

	if ns.CurrentOrder then ns.CurrentOrder:handleEvent("ENTER_STATE") end
end);

ns.registerEvent(ns.EVENT.DISABLE, function()
	for event, _ in pairs(eventHandlers) do
		eventFrame:UnregisterEvent(event);
	end
	-- ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER", filterInbound);
	-- ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER_INFORM", filterOutbound);
	SelfService_ActionQueueButton:Hide();
end);
