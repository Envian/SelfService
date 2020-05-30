local _, ns = ...;

local itemActionQueue = {};
local stackResults = {};
local brokenStacks = {};
local lockedSlots = {};
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

local makeItemActionQueue = function(returnables)
	itemActionQueue = {};
	stackResults = {};

	for _, returnable in ipairs(returnables) do
		local matches = searchBags(returnable.itemId);
		local maxStack = select(8, GetItemInfo(returnable.itemId));

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
		table.insert(itemActionQueue, {action = "BREAK_STACK", itemId = returnable.itemId, count = returnable.count});
	end
	table.insert(itemActionQueue, {action = "RETURN_STACKS"});
end

local breakStack = function(itemId, count)
	local matches = searchBags(itemId);
	local total = GetItemCount(itemId);

	if total < count then
		ns.error("Inventory does not contain "..count.." of ["..itemId.."].");
	elseif total == count then
		table.insert(brokenStacks, matches[1]);
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
	if ns.isEmpty(itemActionQueue) or itemActionQueue[1].action ~= "BREAK_STACK" or CursorHasItem() then
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

local isSafeToReturn = function()
	if ns.isEmpty(itemActionQueue) or itemActionQueue[1].action ~= "RETURN_STACKS" or CursorHasItem() then
		return false;
	else
		for _, match in ipairs(brokenStacks) do
			local key = match.container..match.containerSlot;

			if lockedSlots[key] then
				return false;
			end
		end
	end

	return true;
end

local isSafeToDoNextMove = function()
	if ns.isEmpty(itemActionQueue) or itemActionQueue[1].action ~= "MOVE_STACK" or CursorHasItem() then
		return false;
	else
		local nextMove = itemActionQueue[1];
		local toKey, fromKey = nextMove.toBag..nextMove.toSlot, nextMove.fromBag..nextMove.fromSlot;

		return not lockedSlots[toKey] and not lockedSlots[fromKey];
	end
end

ns.findInInventory = function(returnables)
	if not returnables then
		ns.error("Nil parameter supplied to findInInventory()");
		return;
	end

	lockedSlots = {};
	brokenStacks = {};
	makeItemActionQueue(returnables);

	eventFrame:RegisterEvent("ITEM_UNLOCKED");
	eventFrame:RegisterEvent("ITEM_LOCKED");

	if itemActionQueue[1].action == "MOVE_STACK" then
		if isSafeToDoNextMove() then
			doNextMove();
		end
	elseif itemActionQueue[1].action == "BREAK_STACK" then
		if isSafeToBreak() then
			breakStack(itemActionQueue[1].itemId, itemActionQueue[1].count);
			table.remove(itemActionQueue, 1);
		end
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
			breakStack(itemActionQueue[1].itemId, itemActionQueue[1].count);
			table.remove(itemActionQueue, 1);
		elseif isSafeToReturn() then
			eventFrame:UnregisterEvent("ITEM_UNLOCKED");
			eventFrame:UnregisterEvent("ITEM_LOCKED");
			ns.CurrentTrade.Customer.CurrentOrder:handleEvent("CALLED_BACK", brokenStacks);
		end
	end,
};

eventFrame:SetScript("OnEvent", function(_, event, ...)
	eventHandlers[event](...);
end);
