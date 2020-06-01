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
ns.LOG_ORDER_INSUFFICIENT_ITEMS = "Trade requires [%s]x%i however [%s]x%i was given.";
ns.LOG_ORDER_UNDESIRED_ITEM = "Received [%s]x%i from trade, but not required for the transaction.";
ns.LOG_ORDER_TRADE_ACCEPTABLE = "Received all mats required for trade!";
ns.LOG_ORDER_PREPARING_RETURNABLES = "Preparing returnable materials.";
ns.LOG_RETURNABLES = "Return %s from Bag %s, Slot %s";

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
ns.LOG_ALREADY_ENABLED = "is already enabled.";
ns.LOG_ALREADY_DISABLED = "is already disabled.";
ns.LOG_INVALID_ENCHANTABLE = "%s cannot be applied to the requested item.";

-- Level 2 Error
ns.LOG_CONFLICT = "Recipe conflict found. %s and %s share the same Id, and will not work as expected.";
ns.LOG_CONFLICT_HIDING = "The recipe %s will not be available.";
ns.LOG_RECONCILE_UNRECEIVED_MATS = "ns.OrderClass:reconcile tried to remove materials we did not receive.";
ns.LOG_RECONCILE_NEGATIVE_MATS = "ns.OrderClass:reconcile resulted in a negative ReceivedMats balance.";

-- Level 1 Fatal

-- Console Command Messages
ns.CMD_UNKNOWN_COMMAND = "Unknown command: %s";
ns.CMD_UNKNOWN_SUBCOMMAND = "%s is not a valid subcommand for %s.";
ns.CMD_MORE_COMMANDS_NEEDED = "%s requires more subcommands to run.";
ns.CMD_HELP_UNKNOWN = "No help found for %s.";

ns.CMD_CONFIRM_WARNING = "Use /ss confirm to continue.";
ns.CMD_CONFIRM_NOTHING = "Nothing needed confirmation.";

ns.CMD_RESET_BAD_NAME = "Reset requires a customer name."
ns.CMD_RESET_ORDER = "Order for %s has been reset.";
ns.CMD_RESET_CURRENT_ORDER = "Current order for %s has been reset.";
ns.CMD_RESET_ORDER_BAD_NAME = "Unable to reset order for %s, Customer not found.";
ns.CMD_RESET_NO_ORDER = "No order to reset.";

ns.CMD_WIPE_ALL_WARNING = "WARNING: This will wipe all settings and reload the UI.";
ns.CMD_WIPE_CUSTOMERS_WARNING = "WARNING: This will wipe all customer data and current orders.";
ns.CMD_WIPE_CUSTOMERS = "All customers and orders have been reset.";

-- Debug mode messages
ns.DEBUG_MODE_RELOAD_MESSAGE = "Debug mode cannot be disabled without reloading the UI.";
ns.DEBUG_SKIP_ENCHANT_STATE = "Debug Mode Enabled - Enchants will no longer be cast.";
ns.DEBUG_SKIPPED_ENCHANT = "Debug Mode Enabled - Customer's item has not been enchanted.";

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
	},
	wipe = {
		"Wipes saved SelfService data, deleting it permanently.",
		all = {"Wipes all data and reloads the UI."},
		customers = {"Wipes all customer information and pending orders."}
	},
	debug = {
		"Various debug commands for testing this addon.",
		mockenchants = {"Skips enchanting an item but progresses the order as if it was done successfully."}
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
	ORDER_PLACED = "Once you have obtained the mats for %s, open trade. Your total is: ",
	ORDER_LIMIT = "I only support ordering 1 item at a time. Try again",
	ORDER_MULTIPLE_SEARCH_RESULTS = "I found %i recipes that match that description. Please be more specific.",
	ORDER_IN_PROGRESS = "I only support ordering 1 item at a time. Finish your order before requesting another",
	BUY_FIRST = "Use command !buy before opening trade.",
	BUSY = "I am serving another player right now. Please try again later.",
	INVALID_ITEM = "%s cannot be applied to that item.",
	REPLACE_ENCHANT = "I am replacing %s with %s on your item.",
	TRADE_CANCELLED = "The trade was cancelled. Open a trade window when you are ready to continue.",
	MONEY_REQUIRED = "I need %s more to complete your order.",
	TRANSACTION_COMPLETE = "Your transaction is complete. Come back again now, ya hear?",
	ADD_EXACT_MATERIALS = "Place the exact materials for your order in the trade window.",
	EXACT_MATERIALS_REQUIRED = "I need to receive exact materials for your order.",
	CRAFTING_ORDER = "Please wait while I craft your order",
	ORDER_READY = "Your order is ready.",
	ADD_ENCHANTABLE_ITEM = "Place the item you want enchanted in the \"Will Not Be Traded\" slot.",

	DEBUG_SKIPPED_ENCHANT = "Debug mode enabled. Enchant has not been applied.",
}
