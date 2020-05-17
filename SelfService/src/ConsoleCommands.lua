local _, ns = ...;

SLASH_SELFSERVICE1 = "/selfservice";
SLASH_SELFSERVICE2 = "/service";
SLASH_SELFSERVICE3 = "/ss";

local SLASH_COMMANDS = {
	enable = ns.enableAddon,
	disable = ns.disableAddon
}

SlashCmdList["SELFSERVICE"] = function(message, editbox)
	if not message or #message == 0 then return end;

	local command, args = message:match("^(%S+)%s?(.*)$");
	local cmdFunction = SLASH_COMMANDS[command:lower()];

	if (cmdFunction) then
		cmdFunction(args);
	else
		print("FUCK")
	end
end
