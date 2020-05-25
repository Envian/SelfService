local _, ns = ...;

ns.LOCALIZATION = "enUS";
ns.ADDON_NAME = "SelfService";

-- Logging
-- Level 5 Debug
ns.LOG_SECURE_BUTTON_TRADE_ACTION = "Secure Action Button's trade action is now %s.";
ns.LOG_SECURE_BUTTON_CRAFT_ACTION = "Secure Action Button's craft action is now %s.";
ns.LOG_SECURE_BUTTON_TYPES = {
	CLEAR = "CLEARED",
	CAST_ENCHANT = "CAST_ENCHANT",
	ACCEPT_TRADE = "ACCEPT_TRADE",
	APPLY_ENCHANT = "APPLY_ENCHANT",
	OPEN_TRADE = "OPEN_TRADE",
}

ns.LOG_ORDER_PLACED = "%s has placed an order for %i items.";
ns.LOG_ORDER_STATE_CHANGE = "Order for %s has transitioned to the %s state.";
ns.LOG_ORDER_ITEM_QUANTITY_MISMATCH = "Trade requires [%s]x%i however [%s]x%i was given.";
ns.LOG_ORDER_UNDESIRED_ITEM = "Received [%s]x%i from trade, but not required for the transaction.";
ns.LOG_ORDER_TRADE_ACCEPTABLE = "Received all mats required for trade!";

ns.LOG_TRADE_BLOCKED_NO_ORDER = "Cancelled trade with %s: No active order.";
ns.LOG_TRADE_SERVING_OTHER = "Canceled trade with %s: Currently serving %s.";
ns.LOG_TRADE_ACCEPTED = "Accepted trade with %s.";

-- Level 4 Info
ns.LOG_LOADED = "Data for %s has been loaded.";
ns.LOG_NEW_CUSTOMER = "Serving a new customer: %s";
ns.LOG_RETURNING_CUSTOMER = "Serving a returning customer: %s";

-- Level 3 Warning
ns.LOG_ENABLED = "has been enabled.";
ns.LOG_DISABLED = "has been disabled.";
ns.ALREADY_ENABLED = "is already enabled.";
ns.ALREADY_DISABLED = "is already disabled.";

-- Level 2 Error
ns.LOG_CONFLICT = "Recipe conflict found. %s and %s share the same Id, and will not work as expected.";
ns.LOG_CONFLICT_HIDING = "The recipe %s will not be available.";

-- Level 1 Fatal

-- Console Command Messages
ns.CMD_UNKNOWN_COMMAND = "Unknown command: %s";
ns.CMD_UNKNOWN_SUBCOMMAND = "%s is not a valid subcommand for %s.";
ns.CMD_MORE_COMMANDS_NEEDED = "%s requires more subcommands to run.";
ns.CMD_RESET_BAD_NAME = "Reset requires a customer name."
ns.CMD_RESET_ORDER = "Order for %s has been reset.";
ns.CMD_RESET_CURRENT_ORDER = "Current order for %s has been reset.";
ns.CMD_RESET_ORDER_BAD_NAME = "Unable to reset order for %s, Customer not found.";
ns.CMD_RESET_NO_ORDER = "No order to reset.";
ns.CMD_HELP_UNKNOWN = "No help found for %s.";

-- Console command help text
-- This is a map/array hybrid. The map part is used to get the command's help text. the list is printed as help text.
ns.HELP_TEXT = {
	"This is the help text for the entire project. Try /ss help command",
	"it can be multilined too!",
	help = {"This is the help text for help. you're so fucked."},
	enable = {"Enables the SelfService bot."},
	disable = {
		"Hard disables the SelfService bot.",
		" Warning: This may cause trades in progress to be stuck."
	},
	reset = {
		"Resets some aspect of the mod.",
		order = {"Resets the order for the passed in player."},
		currentorder = {"Resets the current order"}
	}
}

-- Whispers
ns.L.enUS = {
	FIRST_TIME_CUSTOMER = "Thank you for using SelfService. When you are ready, use !buy <item link> to place your order. I currently only support ordering one item at a time.",
	RETURNING_CUSTOMER = "Welcome back to SelfService. When you are ready, use !buy <item link> to place your order. I currently only support ordering one item at a time.",
	UNKNOWN_COMMAND = "Unknown command. Use !help to see a list of commands.",
	NO_RESULTS = "No results found. Maybe I don't have the recipe? Try searching by slot (wrist), stat (int), and/or value (7 int).",
	HELP = "haha get wrecked nerd. you're on your own.",
	RECIPES_OWNED = "I have %s.",
	RECIPES_UNAVAILABLE = "I do not have that recipe.",
	ORDER_READY = "Once you have obtained the mats for %s, open trade. Your total is: ",
	ORDER_LIMIT = "I only support ordering 1 item at a time. Try again",
	ORDER_IN_PROGRESS = "I only support ordering 1 item at a time. Finish your order before requesting another",
	BUY_FIRST = "Use command !buy before opening trade.",
	BUSY = "I am serving another player right now. Please try again later."
}
