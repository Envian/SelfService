local _, ns = ...;

SLASH_SELFSERVICE1 = "/selfservice";
SLASH_SELFSERVICE2 = "/service";
SLASH_SELFSERVICE3 = "/ss";

local SLASH_COMMANDS = {
	enable = ns.enableAddon,
	disable = ns.disableAddon,
	reset = {
		order = function(who)
			if not who or #who == 0 then
				ns.error(ns.LOG_RESET_BAD_NAME);
				return;
			end

			local customer = ns.Customers[ns.normalizeName(who)];
			if customer then
				if not customer.CurrentOrder then
					ns.error(ns.LOG_RESET_NO_ORDER);
					return;
				end
				customer.CurrentOrder = nil;
				if ns.CurrentOrder and ns.CurrentOrder.CustomerName == customer.Name then
					ns.CurrentOrder = nil;
				end
				ns.warningf(ns.LOG_RESET_ORDER, customer.Name);
			else
				ns.errorf(ns.LOG_RESET_ORDER_BAD_NAME, who);
			end
		end,
		currentorder = function()
			if ns.CurrentOrder then
				local customerName = ns.CurrentOrder.CustomerName
				ns.Customers[customerName].CurrentOrder = nil;
				ns.CurrentOrder = nil;
				ns.warningf(ns.LOG_RESET_CURRENT_ORDER, customerName);
			else
				ns.error(ns.LOG_RESET_NO_ORDER);
			end
		end
	}
}

SlashCmdList["SELFSERVICE"] = function(message, editbox)
	local success, stack, resultType = ns.processCommand(SLASH_COMMANDS, message);
	-- No commands passed, ignore for now.
	if not stack or #stack == 0 then return end;

	print(success, strjoin(" ", unpack(stack)), resultType);

	if not success then
		if resultType == "nil" then
			-- Nil is the type when an unknown command or subcommand is sent
			if #stack == 1 then
				ns.errorf(ns.LOG_UNKNOWN_COMMAND, stack[1]);
			else
				local unknownSubcmd = table.remove(stack, #stack);
				ns.errorf(ns.LOG_UNKNOWN_SUBCOMMAND, unknownSubcmd, strjoin(" ", unpack(stack)));
			end
		else
			-- All other types means that there are more commands needed.
			ns.errorf(ns.LOG_MORE_COMMANDS_NEEDED, strjoin(" ", unpack(stack)));
		end
	end
end
