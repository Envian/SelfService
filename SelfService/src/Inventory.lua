local _, ns = ...;

local itemActionQueue = {};
local stackResults = {};
local brokenStacks = {};
local lockedSlots = {};
local desiredItem = 0;
local desiredAmt = 0;
local eventFrame = CreateFrame("Frame");

local doNextMove = function()
	local currentMove = itemActionQueue[1];

	PickupContainerItem(currentMove.fromBag, currentMove.fromSlot);
	if CursorHasItem() then
		PickupContainerItem(currentMove.toBag, currentMove.toSlot);
		table.remove(itemActionQueue, 1);
	else
		ClearCursor();
		ns.debug("Failed to pick up a stack.");
	end
end

local nextFreeBagSlot = function()
	for i=0,11 do
		if GetContainerNumFreeSlots(i) == 0 then
			break;
		else
			for j=1,GetContainerNumSlots(i) do
				if GetContainerItemID(i, j) == nil then
					ns.debug("Free slot at "..i..", "..j);
					return {container = i, containerSlot = j};
				end
			end
		end
	end

	ns.error("No free bag slots available.");
end

local searchBags = function(itemId)
	local matches = {}

	for i=0,11 do
		for j=1,GetContainerNumSlots(i) do
			if GetContainerItemID(i, j) == itemId then
				local count = select(2, GetContainerItemInfo(i, j));
				table.insert(matches, {itemId = itemId, container = i, containerSlot = j, count = count});
			end
		end
	end

	return matches;
end

local makeItemActionQueue = function(itemId)
	itemActionQueue = {};
	stackResults = {};

	local matches = searchBags(itemId);
	local maxStack = select(8, GetItemInfo(itemId));

	local i, j = 1, #matches;

	while i < j do
		if matches[i].count == maxStack then
			i = i + 1;
		else
			table.insert(itemActionQueue, {action = "MOVE_STACK", fromBag = matches[j].container, fromSlot = matches[j].containerSlot, toBag = matches[i].container, toSlot = matches[i].containerSlot});

			if matches[i].count + matches[j].count > maxStack then
				matches[j].count = matches[j].count - (maxStack - matches[i].count);
				matches[i].count = maxStack;
				i = i + 1;
			else
				matches[i].count = matches[i].count + matches[j].count;
				table.remove(matches, j);
				j = j - 1;
			end
		end
	end

	stackResults = matches;
	table.insert(itemActionQueue, {action = "BREAK_STACK"});
end

local breakStack = function(itemId, count)
	eventFrame:UnregisterEvent("ITEM_UNLOCKED");
	eventFrame:UnregisterEvent("ITEM_LOCKED");
	brokenStacks = {};

	local matches = searchBags(itemId);
	local total = GetItemCount(itemId);

	if total < count then
		ns.error("Inventory does not contain "..count.." of ["..itemId.."].");
	elseif total == count then
		brokenStacks = matches;
	else
		while count ~= 0 do
			if matches[#matches].count <= count then
				count = count - matches[#matches].count;
				table.insert(brokenStacks, table.remove(matches));
			else
				local freeSlot = nextFreeBagSlot();

				if ns.isEmpty(freeSlot) then
					ns.error("Unable to break an appropriate stack size. Inventory is full.");
					return;
				end

				SplitContainerItem(matches[#matches].container, matches[#matches].containerSlot, count);
				if CursorHasItem() then
					PickupContainerItem(freeSlot.container, freeSlot.containerSlot);
					result = {itemId = itemId, container = freeSlot.container, containerSlot = freeSlot.containerSlot, count = count};
					count = 0;
					table.insert(brokenStacks, result);
				end
			end
		end
	end
end

local isSafeToBreak = function()
	if ns.isEmpty(itemActionQueue) or itemActionQueue[1].action ~= "BREAK_STACK" then
		return false;
	else
		for _, match in ipairs(stackResults) do
			local key = match.container..match.containerSlot;

			if lockedSlots[key] then
				return false;
			end
		end
	end

	return true;
end

local isSafeToDoNextMove = function()
	if ns.isEmpty(itemActionQueue) or itemActionQueue[1].action ~= "MOVE_STACK" then
		return false;
	else
		local nextMove = itemActionQueue[1];
		local toKey, fromKey = nextMove.toBag..nextMove.toSlot, nextMove.fromBag..nextMove.fromSlot;

		return not lockedSlots[toKey] and not lockedSlots[fromKey];
	end
end

ns.findInInventory = function(itemId, count)
	if not itemId or type(count) ~= "number" or count < 0 then
		ns.error("Invalid parameters supplied to findInInventory()");
		return;
	end

	lockedSlots = {};
	desiredItem = itemId;
	desiredAmt = count;
	makeItemActionQueue(itemId);

	if itemActionQueue[1].action == "MOVE_STACK" then
		eventFrame:RegisterEvent("ITEM_UNLOCKED");
		eventFrame:RegisterEvent("ITEM_LOCKED");

	-- Do first move.
		if isSafeToDoNextMove() then
			doNextMove();
		end
	elseif itemActionQueue[1].action == "BREAK_STACK" then
		table.remove(itemActionQueue, 1);
		breakStack(itemId, count);
	end
end

local eventHandlers = {
	ITEM_LOCKED = function(container, containerSlot)
		local key = container..containerSlot;
		lockedSlots[key] = "locked";
	end,
	ITEM_UNLOCKED = function(container, containerSlot)
		local key = container..containerSlot;
		lockedSlots[key] = nil;

		if isSafeToDoNextMove() then
			doNextMove();
		elseif isSafeToBreak() then
			breakStack(desiredItem, desiredAmt);
		end
	end,
};

eventFrame:SetScript("OnEvent", function(_, event, ...)
	eventHandlers[event](...);
end);
