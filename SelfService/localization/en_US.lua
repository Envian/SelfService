local _, ns = ...;

ns.LOCALIZATION = "enUS";
ns.ADDON_NAME = "SelfService";

-- Logging
ns.LOG_ENABLED = "Has been enabled.";
ns.LOG_DISABLED = "Has been disabled.";
ns.LOG_RESET = "Order for %s has been reset.";
ns.LOG_LOADED = "Data for %s has been loaded.";

ns.LOG_CONFLICT = "Recipe conflict found. %s and %s share the same Id, and will not work as expected.";
ns.LOG_CONFLICT_HIDING = "The recipe %s will not be available.";
ns.LOG_NEW_CUSTOMER = "Serving a new customer: %s.";
ns.LOG_RETURNING_CUSTOMER = "Serving a returning customer: %s.";

-- Whispers
ns.L.enUS = {
	FIRST_TIME_CUSTOMER = "First time customer message",
	RETURNING_CUSTOMER = "Returning customer message",
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
