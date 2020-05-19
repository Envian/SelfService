local _, ns = ...;

-- Compile all global ns definitions here

-- List of Craft/Tradeskill data I assume? Should be just a bunch of fields.
-- Currently ns.Data.Enchanting field defined in data/Enchanting.lua
ns.Data = {};

-- Map<String:name, Customer> in Customer.lua
ns.Customers = {};

-- Array<Object<int:id, int:quantity>>[7] in Events.lua, Order.lua
ns.CurrentTrade = {};

-- OrderClass
ns.CurrentOrder = nil;
