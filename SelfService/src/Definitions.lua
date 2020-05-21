local _, ns = ...;
local func = function() end; -- TODO: hard fail if this is ever called. Only used for placeholders.

-- Classes
ns.CustomerClass = nil; -- Customer.lua
ns.OrderClass = nil; -- Order.lua
ns.RecipeClass = nil; -- Recipe.lua
ns.OrderStates = nil; -- OrderStates.lua

-- Members
ns.Enabled = false; -- Controls whether or not the addon is enabled or not.
ns.Data = {}; -- Map<String, Map<Int, Recipe>> - Map of profession, to recipeId, to recipe. Initialized unloaded.
ns.Search = {}; -- Map<String, List<Recipe>> - Map of String to list of recipes that match that string.
ns.Recipes = {}; -- Map<Id, Recipe> Map of Item/EnchantId to Recipe.
ns.Loaded = {}; -- Map<String, Boolean> Map of profession name to whether its loaded or not.
ns.Customers = {}; -- Map<String, CustomerClass> - use getCustomer(name) instead.
ns.CurrentTrade = {}; -- Map<Int, ItemInfo>, where int is the trade slot (1-6) and itemInfo contains an id and quantity.
ns.CurrentOrder = nil; -- A reference to the current OrderClass.

ns.Commands = {}; -- Map<String, Function> - Key is a command, value is the function to execute that cmd
ns.Events = {}; -- Untyped data structure. Only used to store event information long term.

-- Helper Methods
ns.getCustomer = func(name); -- Gets a customer by their name.
ns.enableAddon = func(); -- Enables events.
ns.disableAddon = func(); -- Disables events.
ns.imap = func(list, callback); -- Passes each element in list to callback, and returns a new list with the results from callback.
ns.ifilter = func(list, callback); -- returns a new list with only the items that return true from callback.
ns.getItemIdFromLink = func(link); -- Gets the first itemId from the given string.
ns.getLinkedItemIds = func(text, type) -- Gets all linked item Ids. Type can be "item", "enchant", or nil for both.
ns.delink = func(text); -- Removes all links from a string, but leaves the text (including brackets)
ns.populateEnchantingData = func(enchants); -- Loads data about each enchant, and saves it back on the passed in list.
ns.populateEnchantExtraData = func(extra); -- Loads special enchant products (oils, wands) into the global map.
ns.populateGlobalData = func(crafts); -- Takes (loaded) data about a profession and stores it in the Recipes and Search tables.

-- Other
ns.L = {}; -- Whisper localization object.
ns.REPLY_PREFIX = "<BOT> "; -- Whispers are prefixed with this label. Hard coded since the logic to filter messages uses this.
