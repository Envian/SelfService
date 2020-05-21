local _, ns = ...;

ns.ActionQueue = {
	castEnchant = function(enchantName)
		SelfService_Secure_Button:SetAttribute("type", "spell");
		SelfService_Secure_Button:SetAttribute("spell", enchantName);
	end,
	acceptTrade = function(enchantName)
		SelfService_Secure_Button:SetAttribute("type", "script");
		SelfService_Secure_Button:SetAttribute("_script", function() AcceptTrade() end);
	end,
	applyEnchant = function()
		SelfService_Secure_Button:SetAttribute("type", "script");
		SelfService_Secure_Button:SetAttribute("_script", function() TradeRecipientItem7ItemButton:Click() end);
	end,
	openTrade = function(player)
			SelfService_Secure_Button:SetAttribute("type", "script");
			SelfService_Secure_Button:SetAttribute("_script", function() InitiateTrade(player) end);
	end
};
