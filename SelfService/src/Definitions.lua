local _, ns =

ss = ns;

-- Placeholder defintion for documenting function parameters
local func = function() end;

-- Classes
-- CustomerClass - Customer.lua
ns.OrderClass = nil; -- Order.lua
ns.RecipeClass = nil; -- Recipe.lua
ns.OrderStates = nil; -- OrderStates.lua

-- Namespaces
ns.Data = {}; -- Map<String, Map<Int, Recipe>> - Map of profession, to recipeId, to recipe. Initialized unloaded, not used directly.
ns.Recipes = {}; -- Map<Id, Recipe> Map of Item/EnchantId to Recipe.
ns.Search = {}; -- Map<String, List<Recipe>> - Map of String to list of recipes that match that string.
ns.Customers = {}; -- Map<String, CustomerClass> - use getCustomer(name) instead.
ns.CustomerCommands = {}; -- Map<String, Function> - Key is a command, value is the function to execute that cmd
ns.OrderStates = {}; -- Map<String, BaseOrderState> where the key is the state name.
ns.Enabled = false; -- Controls whether or not the addon is enabled or not.
ns.Loaded = {}; -- Map<String, Boolean> Map of profession name to whether its loaded or not.
ns.Trading = {} -- A helper method collection, use to handle and manage events fired by the wow api related to trading and ordering.
ns.CurrentTrade = {}; -- A complex object with information about the current trade. See Trading.lua
ns.CurrentOrder = nil; -- A reference to the current OrderClass.

-- Action Queue
ns.ActionQueue = {}; -- Helper namespace
ns.ActionQueue.clearTradeAction = func() -- Clears the current trade action
ns.ActionQueue.castEnchant = func(enchantName) -- Casts an enchant
ns.ActionQueue.acceptTrade = func() -- Accepts trade
ns.ActionQueue.applyEnchant = func() -- Applies an enchant
ns.ActionQueue.openTrade = func(player) -- Opens trade with the given player

-- Helper Methods
ns.getCustomer = func(name); -- Gets a customer by their name.
ns.normalizeName = func(name); -- Normalizes a name so that it can safely be used to access ns.Customers. Returns nil when the name couldn't be normalized.

ns.imap = func(list, callback); -- Passes each element in list to callback, and returns a new list with the results from callback.
ns.ifilter = func(list, callback); -- returns a new list with only the items that return true from callback.
ns.getItemIdFromLink = func(link, type); -- Gets the first itemId from the given string.
ns.getLinkedItemIds = func(text, type); -- Gets all linked item Ids. Type can be "item", "enchant", or nil for both.
ns.dumpTable = func(table, indent); -- Dumps a table to the console, for debugging
ns.printType = func(value); -- Converts a variable to a readable representation.
ns.delink = func(text); -- Removes all links from a string, but leaves the text (including brackets)
ns.pullFromCommandTable = func(commandTable, command); -- Parses the command string and returns the object requested by the command string.
ns.searchRecipes = func(searchStringOrList); -- Takes in a search string, or a list of search terms, and returns all recipes that match.

ns.enableAddon = func(); -- Enables bot event handling.
ns.disableAddon = func(); -- Disables bot event handling.

ns.breakStacksForReturn = func(itemMap);

-- Logging
ns.setLogLevel = func(level); -- Sets the log level to a specified value.
ns.debug = func(message); -- Prints a debug message to the console.
ns.debugf = func(message, ...); -- Prints a formatted debug message to the console.
ns.info = func(message); -- Prints a info message to the console.
ns.infof = func(message, ...); -- Prints a formatted info message to the console.
ns.warning = func(message); -- Prints a warning message to the console.
ns.warningf = func(message, ...); -- Prints a formatted warning message to the console.
ns.error = func(message); -- Prints a error message to the console.
ns.errorf = func(message, ...); -- Prints a formatted error message to the console.
ns.fatal = func(message); -- Prints a fatal message to the console.
ns.fatalf = func(message, ...); -- Prints a formatted fatal message to the console.
ns.print = func(message); -- Prints a message to the console, regardless of log settings.
ns.printf = func(message, ...); -- Prints a formatted message to the console, regardless of log settings.

-- Other
ns.L = {}; -- Whisper localization object.
ns.REPLY_PREFIX = "<BOT> "; -- Whispers are prefixed with this label. Hard coded since the logic to filter messages uses this.
