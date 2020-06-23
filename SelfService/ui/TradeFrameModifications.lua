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


local tradeButtonDesiredState = false;

-- Hook into trade frame button enable/disable functionality to control it ourself.
local TradeFrameTradeButton_Enable_Original = TradeFrameTradeButton_Enable;
local TradeFrameTradeButton_Disable_Original = TradeFrameTradeButton_Disable;

TradeFrameTradeButton_Enable = function()
	TradeFrameTradeButton_Enable_Original();
	tradeButtonDesiredState = TradeFrameTradeButton:IsEnabled();
	if ns.Enabled then TradeFrameTradeButton:Disable() end;
end

TradeFrameTradeButton_Disable = function()
	TradeFrameTradeButton_Disable_Original();
	tradeButtonDesiredState = TradeFrameTradeButton:IsEnabled();
end

ns.registerEvent(ns.EVENT.ENABLE, function()
	SelfService_TradeFrameHelpText:Show();
	-- TODO: Keep track of what we want the button to look like and restore it here.
	TradeFrameTradeButton:Disable();
end);

ns.registerEvent(ns.EVENT.DISABLE, function()
	SelfService_TradeFrameHelpText:Hide();
	if tradeButtonDesiredState then TradeFrameTradeButton:Enable() else TradeFrameTradeButton:Disable() end;
end);
