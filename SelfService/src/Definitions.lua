local _, ns = ...;

-- Placeholder defintion for documenting function parameters
local func = function() end;

-- Classes
ns.CustomerClass = nil; -- Customer.lua
ns.OrderClass = nil; -- Order.lua
ns.RecipeClass = nil; -- Recipe.lua
ns.OrderStates = nil; -- OrderStates.lua

-- Namespaces
ns.Data = {}; -- Map<String, Map<Int, Recipe>> - Map of profession, to recipeId, to recipe. Initialized unloaded, not used directly.
ns.Recipes = {}; -- Map<Id, Recipe> Map of Item/EnchantId to Recipe.
ns.Search = {}; -- Map<String, List<Recipe>> - Map of String to list of recipes that match that string.
ns.Customers = {}; -- Map<String, CustomerClass> - use getCustomer(name) instead.
ns.Commands = {}; -- Map<String, Function> - Key is a command, value is the function to execute that cmd
ns.Events = {}; -- Untyped data structure. Used exclusively by Events.lua to maintain event structure.

-- Members
ns.Enabled = false; -- Controls whether or not the addon is enabled or not.
ns.Loaded = {}; -- Map<String, Boolean> Map of profession name to whether its loaded or not.
ns.CurrentTrade = {}; -- Map<Int, ItemInfo>, where int is the trade slot (1-6) and itemInfo contains an id and quantity.
ns.CurrentOrder = nil; -- A reference to the current OrderClass.

-- Helper Methods
ns.getCustomer = func(name); -- Gets a customer by their name.
ns.normalizeName = func(name); -- Normalizes a name so that it can safely be used to access ns.Customers. Returns nil when the name couldn't be normalized.
ns.imap = func(list, callback); -- Passes each element in list to callback, and returns a new list with the results from callback.
ns.ifilter = func(list, callback); -- returns a new list with only the items that return true from callback.
ns.getItemIdFromLink = func(link, type); -- Gets the first itemId from the given string.
ns.getLinkedItemIds = func(text, type); -- Gets all linked item Ids. Type can be "item", "enchant", or nil for both.
ns.delink = func(text); -- Removes all links from a string, but leaves the text (including brackets)
ns.enableAddon = func(); -- Enables bot event handling.
ns.disableAddon = func() -- Disables bot event handling.

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

-- Specialized helpers
ns.processCommand = func(commandList, command); -- Parses the command string and calls the corresponding command from CommandList.
ns.populateEnchantingData = func(enchants); -- Loads data about each enchant, and saves it back on the passed in list.
ns.populateEnchantExtraData = func(extra); -- Loads special enchant products (oils, wands) into the global map.
ns.populateGlobalData = func(crafts); -- Takes (loaded) data about a profession and stores it in the Recipes and Search tables.

-- Other
ns.L = {}; -- Whisper localization object.
ns.REPLY_PREFIX = "<BOT> "; -- Whispers are prefixed with this label. Hard coded since the logic to filter messages uses this.
