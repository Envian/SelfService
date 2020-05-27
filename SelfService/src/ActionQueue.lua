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
	openTrade = function(player)
		SelfService_SecureButton:SetAttribute("type", "script");
		SelfService_SecureButton:SetAttribute("_script", function() InitiateTrade(player) end);
		SelfService_SecureButton:SetText("Open Trade");
		ns.debugf(ns.LOG_SECURE_BUTTON_TRADE_ACTION, ns.LOG_SECURE_BUTTON_TYPES.OPEN_TRADE);
	end,
	-- useContainerItem = function(bagId, slotId)
	-- 	SelfService_SecureButton:SetAttribute("type", "script");
	-- 	SelfService_SecureButton:SetAttribute("_script", function() UseContainerItem(bagId, slotId) end);
	-- 	SelfService_SecureButton:SetText("Add Returnable");
	-- 	ns.debug("Adding Returnable Item");
	-- end,
};
