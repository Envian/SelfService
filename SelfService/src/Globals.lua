local _, ns = ...;

-- Compile all global ns definitions here
ns.Customers = {};
ns.CurrentTrade = {};
ns.CurrentOrder = nil;

ns.OrderClass.STATUSES = {
	PENDING = 1,
	ORDERED = 2,
	GATHERED = 3,
	DELIVERED = 4,
	CANCELLED = 5
}
