local _, ns = ...;

SLASH_SELFSERVICE1 = "/selfservice";
SLASH_SELFSERVICE2 = "/service";
SLASH_SELFSERVICE3 = "/ss";

-- Callbacks for wipe commands. Goes through with the wipe
local doWipeAll = function()
	SelfServiceData = nil;
	ReloadUI();
end

local doWipeCustomers = function()
	SelfServiceData.Customers = {};
	ns.Customers = {};
	ns.CurrentOrder = nil;

	ns.print(ns.CMD_WIPE_CUSTOMERS);
end

-- Stores the current action that needs confirmation.
local confirmCallback = nil;

local confirmFromUser = function(message, callback)
	if type(message) ~= "string" then error("Invalid message passed into confirmFromUser.", 2) end;
	if type(callback) ~= "function" then error("Invalid callback passed into confirmFromUser.", 2) end;

	ns.print(message..ns.CMD_CONFIRM_WARNING);
	confirmCallback = callback;
end

local slashCommands = {
	enable = ns.enableAddon,
	disable = ns.disableAddon,
	help = function(helpTopic)
		helpList = ns.pullFromCommandTable(ns.HELP_TEXT, helpTopic);
		if type(helpList) == "nil" then
			ns.printf(ns.CMD_HELP_UNKNOWN, helpTopic);
		elseif type(helpList) == "string" then
			ns.print(helpList);
		else
			for _, line in ipairs(helpList) do ns.print(line) end;
		end
	end,
	confirm = function()
		if confirmCallback then
			confirmCallback();
			confirmCallback = nil;
		else
			ns.print(ns.CMD_CONFIRM_NOTHING);
		end
	end,
	reset = {
		order = function(who)
			if not who or #who == 0 then
				ns.print(ns.CMD_RESET_BAD_NAME);
				return;
			end

			local customerName = ns.normalizeName(who);
			-- Customers are always added to SelfServiceData on creation.
			if SelfServiceData.Customers[customerName] then
				local customer = ns.getCustomer(customerName);

				if not customer.CurrentOrder then
					ns.print(ns.CMD_RESET_NO_ORDER);
					return;
				end
				customer.CurrentOrder = nil;
				if ns.CurrentOrder and ns.CurrentOrder.CustomerName == customer.Name then
					ns.CurrentOrder = nil;
				end
				ns.printf(ns.CMD_RESET_ORDER, customer.Name);
			else
				ns.printf(ns.CMD_RESET_ORDER_BAD_NAME, who);
			end
		end,
		currentorder = function()
			if ns.CurrentOrder then
				local customerName = ns.CurrentOrder.CustomerName
				ns.Customers[customerName].CurrentOrder = nil;
				ns.CurrentOrder = nil;
				ns.printf(ns.CMD_RESET_CURRENT_ORDER, customerName);
			else
				ns.print(ns.CMD_RESET_NO_ORDER);
			end
		end,
	},
	wipe = {
		all = function()
			confirmFromUser(ns.CMD_WIPE_ALL_WARNING, doWipeAll);
		end,
		customers = function()
			confirmFromUser(ns.CMD_WIPE_CUSTOMERS_WARNING, doWipeCustomers);
		end,
	},
	debug = {
		mockenchants = function()
			ns.print(ns.DEBUG_SKIP_ENCHANT_STATE);
			ns.print(ns.DEBUG_MODE_RELOAD_MESSAGE);
			ns.OrderStates.CAST_ENCHANT = ns.OrderStates.DEBUG_STATES.SKIP_TO_AWAIT_PAYMENT;
		end
	},
	breakstack = function(params)
		local args = {};

		for i in string.gmatch(params, "%S+") do
			table.insert(args, i);
		end

		ns.breakStack(tonumber(args[1]), tonumber(args[2]));
	end,
}

SlashCmdList["SELFSERVICE"] = function(message, editbox)
	local target, arguments, stack = ns.pullFromCommandTable(slashCommands, message);

	if target == slashCommands then
		slashCommands.help();
		return;
	end

	if not target then
		ns.printf(ns.CMD_UNKNOWN_COMMAND, strjoin(" ", unpack(stack)));
	else
		if type(target) == "function" then
			target(arguments);
		elseif type(target) == "nil" then
			-- Nil is the type when an unknown command or subcommand is sent
			if #stack == 1 then
				ns.printf(ns.CMD_UNKNOWN_COMMAND, stack[1]);
			else
				local unknownSubcmd = table.remove(stack, #stack);
				ns.printf(ns.CMD_UNKNOWN_SUBCOMMAND, unknownSubcmd, strjoin(" ", unpack(stack)));
			end
		elseif type(target) == "table" then
			-- table means that there are more commands needed.
			ns.printf(ns.CMD_MORE_COMMANDS_NEEDED, strjoin(" ", unpack(stack)));
		end
	end
end
