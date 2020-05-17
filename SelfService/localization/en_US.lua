local _, ns = ...;

ns.LOCALIZATION = "enUS";
ns.ADDON_NAME = "SelfService";

-- Logging
ns.LOG_PREFIX = string.format("[%s] ", ns.ADDON_NAME);
ns.LOG_ENABLED = ns.LOG_PREFIX .. "Has been enabled.";
ns.LOG_DISABLED = ns.LOG_PREFIX .. "Has been disabled.";
ns.LOG_LOADED = ns.LOG_PREFIX .. "Data for %s has been loaded.";


ns.LOG_CONFLICT = ns.LOG_PREFIX .. "Recipe conflict found. %s and %s share the same Id, and will not work as expected.";
ns.LOG_CONFLICT_HIDING = ns.LOG_PREFIX .. "The recipe %s will not be available.";
ns.LOG_NEW_CUSTOMER = ns.LOG_PREFIX .. "Serving a new customer: %s.";
ns.LOG_RETURNING_CUSTOMER = ns.LOG_PREFIX .. "Serving a returning customer: %s.";

-- Whispers
ns.L = ns.L or {}
ns.L.enUS = {
	FIRST_TIME_CUSTOMER = "First time customer message",
	RETURNING_CUSTOMER = "Returning customer message",
	UNKNOWN_COMMAND = "Unknown command. Use !help to see a list of commands.",
	NO_RESULTS = "No results found. Maybe I don't have the recipe? Try searching by slot (wrist), stat (int), and/or value (7 int).",
	HELP = "haha get wrecked nerd. you're on your own.",
	RECIPES_OWNED = "I have %s.",
	RECIPES_UNAVAILABLE = "I do not have that recipe.",
}
