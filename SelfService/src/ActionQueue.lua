local _, ns = ...;

ns.ActionQueue = {
	clearTradeAction = function()
		SelfService_SecureButton:SetAttribute("type", nil);
		SelfService_SecureButton:SetText("No Action");
		ns.debugf(ns.LOG_SECURE_BUTTON_TRADE_ACTION, ns.LOG_SECURE_BUTTON_TYPES.CLEAR);
	end,
	castEnchant = function(enchantName)
		SelfService_SecureButton:SetAttribute("type", "spell");
		SelfService_SecureButton:SetAttribute("spell", enchantName);
		SelfService_SecureButton:SetText("Cast "..enchantName);
		ns.debugf(ns.LOG_SECURE_BUTTON_TRADE_ACTION, ns.LOG_SECURE_BUTTON_TYPES.CAST_ENCHANT);
	end,
	acceptTrade = function()
		SelfService_SecureButton:SetAttribute("type", "script");
		SelfService_SecureButton:SetAttribute("_script", function() AcceptTrade() end);
		SelfService_SecureButton:SetText("Accept Trade");
		ns.debugf(ns.LOG_SECURE_BUTTON_TRADE_ACTION, ns.LOG_SECURE_BUTTON_TYPES.ACCEPT_TRADE);
	end,
	applyEnchant = function()
		SelfService_SecureButton:SetAttribute("type", "script");
		SelfService_SecureButton:SetAttribute("_script", function() ClickTargetTradeButton(7) end);
		SelfService_SecureButton:SetText("Apply Enchant");
		ns.debugf(ns.LOG_SECURE_BUTTON_TRADE_ACTION, ns.LOG_SECURE_BUTTON_TYPES.APPLY_ENCHANT);
	end,
	openTrade = function(playerName)
		SelfService_SecureButton:SetAttribute("type", "target");
		SelfService_SecureButton:SetAttribute("unit", string.sub(playerName, 1, i-1));
		SelfService_SecureButton:HookScript("OnClick", function(frame)
			InitiateTrade("target");
			ns.ActionQueue.clearTarget();
		end);
		SelfService_SecureButton:SetText("Open Trade");
		ns.debugf(ns.LOG_SECURE_BUTTON_TRADE_ACTION, ns.LOG_SECURE_BUTTON_TYPES.OPEN_TRADE);
	end,
	clearTarget = function()
		SelfService_SecureButton:SetAttribute("type", "target");
		SelfService_SecureButton:SetAttribute("unit", nil);
		SelfService_SecureButton:HookScript("OnClick", nil);
		SelfService_SecureButton:SetText("Clear Target");
	end,
	-- useContainerItem = function(bagId, slotId)
	-- 	SelfService_SecureButton:SetAttribute("type", "script");
	-- 	SelfService_SecureButton:SetAttribute("_script", function() UseContainerItem(bagId, slotId) end);
	-- 	SelfService_SecureButton:SetText("Add Returnable");
	-- 	ns.debug("Adding Returnable Item");
	-- end,
};
