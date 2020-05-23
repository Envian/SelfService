local _, ns = ...;

ns.ActionQueue = {
	clearButton = function()
		SelfService_SecureButton:SetAttribute("type", nil);
		ns.debugf(ns.LOG_SECURE_BUTTON_TRADE_ACTION, ns.LOG_SECURE_BUTTON_TYPES.CLEAR);
	end,
	castEnchant = function(enchantName)
		SelfService_SecureButton:SetAttribute("type", "spell");
		SelfService_SecureButton:SetAttribute("spell", enchantName);
		ns.debugf(ns.LOG_SECURE_BUTTON_TRADE_ACTION, ns.LOG_SECURE_BUTTON_TYPES.CAST_ENCHANT);
	end,
	acceptTrade = function()
		SelfService_SecureButton:SetAttribute("type", "script");
		SelfService_SecureButton:SetAttribute("_script", function() AcceptTrade() end);
		ns.debugf(ns.LOG_SECURE_BUTTON_TRADE_ACTION, ns.LOG_SECURE_BUTTON_TYPES.ACCEPT_TRADE);
	end,
	applyEnchant = function()
		SelfService_SecureButton:SetAttribute("type", "script");
		SelfService_SecureButton:SetAttribute("_script", function() ClickTargetTradeButton(7) end);
		ns.debugf(ns.LOG_SECURE_BUTTON_TRADE_ACTION, ns.LOG_SECURE_BUTTON_TYPES.APPLY_ENCHANT);
	end,
	openTrade = function(player)
		SelfService_SecureButton:SetAttribute("type", "script");
		SelfService_SecureButton:SetAttribute("_script", function() InitiateTrade(player) end);
		ns.debugf(ns.LOG_SECURE_BUTTON_TRADE_ACTION, ns.LOG_SECURE_BUTTON_TYPES.OPEN_TRADE);
	end,
};
