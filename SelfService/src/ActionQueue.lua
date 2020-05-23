local _, ns = ...;

ns.ActionQueue = {
	clearButton = function()
		SelfService_SecureButton:SetAttribute("type", nil);
		print("New Button State: No Action");
	end,
	castEnchant = function(enchantName)
		SelfService_SecureButton:SetAttribute("type", "spell");
		SelfService_SecureButton:SetAttribute("spell", enchantName);
		print("New Button State: Cast Enchant: "..enchantName);
	end,
	acceptTrade = function()
		SelfService_SecureButton:SetAttribute("type", "script");
		SelfService_SecureButton:SetAttribute("_script", function() AcceptTrade() end);
		print("New Button State: Accept Trade");
	end,
	applyEnchant = function()
		SelfService_SecureButton:SetAttribute("type", "script");
		SelfService_SecureButton:SetAttribute("_script", function() ClickTargetTradeButton(7) end);
		print("New Button State: Click the Will Not Be Traded");
	end,
	openTrade = function(player)
		SelfService_SecureButton:SetAttribute("type", "script");
		SelfService_SecureButton:SetAttribute("_script", function() InitiateTrade(player) end);
		print("New Button State: Opening a trade");
	end,
};
