local _, ns = ...;

SLASH_SELFSERVICE1 = "/selfservice";
SLASH_SELFSERVICE2 = "/service";
SLASH_SELFSERVICE3 = "/ss";

local SLASH_COMMANDS = {
	enable = ns.enableAddon,
	disable = ns.disableAddon,
	reset = function(args)
		local resetWhat, who = args:match("^(%S+)%s?(.*)$");
		if not resetWhat or not who then return end;

		local customer = ns.getCustomer(who);
		if resetWhat:lower() == "order" then
			customer.CurrentOrder = nil;
			print(ns.LOG_RESET:format(customer.Name));
		end
	end
}

SlashCmdList["SELFSERVICE"] = function(message, editbox)
	if not message or #message == 0 then return end;

	local command, args = message:match("^(%S+)%s?(.*)$");
	local cmdFunction = SLASH_COMMANDS[command:lower()];

	if cmdFunction then
		cmdFunction(args);
	else
		print("FUCK - "..command);
	end
end
