local _, ns = ...;

SLASH_SELFSERVICE1 = "/selfservice";
SLASH_SELFSERVICE2 = "/service";
SLASH_SELFSERVICE3 = "/ss";

local slashCommands = {
	enable = ns.enableAddon,
	disable = ns.disableAddon,
	help = function() end,
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
	local target, arguments, stack = ns.pullFromCommandTable(slashCommands, message);

	if target == slashCommands then
		slashCommands.help();
		return;
	end

	if not target then
		ns.errorf(ns.LOG_UNKNOWN_COMMAND, strjoin(" ", unpack(stack)));
	else
		if type(target) == "function" then
			target(arguments);
		elseif type(target) == "nil" then
			-- Nil is the type when an unknown command or subcommand is sent
			if #stack == 1 then
				ns.errorf(ns.LOG_UNKNOWN_COMMAND, stack[1]);
			else
				local unknownSubcmd = table.remove(stack, #stack);
				ns.errorf(ns.LOG_UNKNOWN_SUBCOMMAND, unknownSubcmd, strjoin(" ", unpack(stack)));
			end
		elseif type(target) == "table" then
			-- table means that there are more commands needed.
			ns.errorf(ns.LOG_MORE_COMMANDS_NEEDED, strjoin(" ", unpack(stack)));
		end
	end
end
