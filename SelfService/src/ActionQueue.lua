local _, ns = ...;

ns.ActionQueue = {
	clearTradeAction = function()
		SelfService_ActionQueueButton:SetAttribute("type", nil);
		SelfService_ActionQueueButton:SetText("No Action");
		ns.debugf(ns.LOG_SECURE_BUTTON_TRADE_ACTION, ns.LOG_SECURE_BUTTON_TYPES.CLEAR);
	end,
	castEnchant = function(enchantName)
		SelfService_ActionQueueButton:SetAttribute("type", "spell");
		SelfService_ActionQueueButton:SetAttribute("spell", enchantName);
		SelfService_ActionQueueButton:SetText("Cast "..enchantName);
		ns.debugf(ns.LOG_SECURE_BUTTON_TRADE_ACTION, ns.LOG_SECURE_BUTTON_TYPES.CAST_ENCHANT);
	end,
	acceptTrade = function()
		SelfService_ActionQueueButton:SetAttribute("type", "script");
		SelfService_ActionQueueButton:SetAttribute("_script", function() AcceptTrade() end);
		SelfService_ActionQueueButton:SetText("Accept Trade");
		ns.debugf(ns.LOG_SECURE_BUTTON_TRADE_ACTION, ns.LOG_SECURE_BUTTON_TYPES.ACCEPT_TRADE);
	end,
	applyEnchant = function()
		SelfService_ActionQueueButton:SetAttribute("type", "script");
		SelfService_ActionQueueButton:SetAttribute("_script", function() ClickTargetTradeButton(7) end);
		SelfService_ActionQueueButton:SetText("Apply Enchant");
		ns.debugf(ns.LOG_SECURE_BUTTON_TRADE_ACTION, ns.LOG_SECURE_BUTTON_TYPES.APPLY_ENCHANT);
	end,
	openTrade = function(playerName)
		-- Trading and targeting does not work with players who are not in your group. There is no way to open trade with someone random.

		-- SelfService_ActionQueueButton:SetAttribute("unit", "player "..string.sub(playerName, 1, string.find(playerName, "-")-1));
		-- SelfService_ActionQueueButton:HookScript("OnClick", function(frame)
		-- 	InitiateTrade("target");
		-- 	-- -- Clears Target
		-- 	-- SelfService_ActionQueueButton:SetAttribute("type", "target");
		-- 	-- SelfService_ActionQueueButton:SetAttribute("unit", nil);
		-- 	-- SelfService_ActionQueueButton:HookScript("OnClick", function() end);
		-- 	-- SelfService_ActionQueueButton:SetText("Clear Target");
		-- end);
		-- SelfService_ActionQueueButton:SetText("Open Trade");
		-- ns.debugf(ns.LOG_SECURE_BUTTON_TRADE_ACTION, ns.LOG_SECURE_BUTTON_TYPES.OPEN_TRADE);
	end,
	-- useContainerItem = function(bagId, slotId)
	-- 	SelfService_ActionQueueButton:SetAttribute("type", "script");
	-- 	SelfService_ActionQueueButton:SetAttribute("_script", function() UseContainerItem(bagId, slotId) end);
	-- 	SelfService_ActionQueueButton:SetText("Add Returnable");
	-- 	ns.debug("Adding Returnable Item");
	-- end,
};
