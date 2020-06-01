local _, ns = ...;

local itemActionQueue = {};
local stackResults = {};
local brokenStacks = {};
local lockedSlots = {};
local eventFrame = CreateFrame("Frame");

local nextFreeSlot = function()
	for i=0,11 do
		if GetContainerNumFreeSlots(i) > 0 then
			for j=1,GetContainerNumSlots(i) do
				if GetContainerItemID(i, j) == nil then
					-- TODO: Remove in release, for debugging only
					ns.debug("Free slot at "..i..", "..j);
					return {container = i, containerSlot = j};
				end
			end
		end
	end
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

		for _, stack in ipairs(matches) do
			table.insert(stackResults, stack);
		end
		table.insert(itemActionQueue, {action = "BREAK_STACK", itemId = returnable.itemId, count = returnable.count});
	end
	table.insert(itemActionQueue, {action = "RETURN_STACKS"});
end

local breakStack = function(itemId, count)
	local matches = searchBags(itemId);
	local total = GetItemCount(itemId);

	if total < count then
		-- TODO: Localize
		ns.error("Inventory does not contain "..count.." of ["..itemId.."].");
	elseif total == count then
		for i=1,#matches do
			table.insert(brokenStacks, matches[i])
		end
	else
		while count ~= 0 do
			if matches[#matches].count <= count then
				count = count - matches[#matches].count;
				table.insert(brokenStacks, table.remove(matches));
			else
				local freeSlot = nextFreeSlot();

				if ns.isEmpty(freeSlot) then
					-- TODO: Localize
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

local getKey = function(container, slot)
	return container..":"..slot;
end

local isSafe = function(action)
	if not action or CursorHasItem() then
		return false;
	else
		if action.action == "MOVE_STACK" then
			local toKey, fromKey = getKey(action.toBag, action.toSlot), getKey(action.fromBag, action.fromSlot);

			if lockedSlots[toKey] or lockedSlots[fromKey] then
				return false;
			end
		elseif action.action == "BREAK_STACK" then
			for _, stack in ipairs(stackResults) do
				local key = getKey(stack.container, stack.containerSlot);

				if lockedSlots[key] then
					return false;
				end
			end
		elseif action.action == "RETURN_STACKS" then
			for _, stack in ipairs(brokenStacks) do
				local key = getKey(stack.container, stack.containerSlot);

				if lockedSlots[key] then
					return false;
				end
			end
		end
	end

	-- Desired action is safe, return true and clear the lockedSlots table
	lockedSlots = {};
	return true;
end

local doAction = function(action)
	if not action then
		-- TODO: For debugging only. Remove after testing.
		ns.debug("doAction in Inventory.lua called with nil action");
		return;
	elseif action.action == "RETURN_STACKS" then
		eventFrame:UnregisterEvent("ITEM_UNLOCKED");
		eventFrame:UnregisterEvent("ITEM_LOCKED");
		ns.CurrentTrade.Customer.CurrentOrder:handleEvent("CALLED_BACK", brokenStacks);
	elseif action.count then
		breakStack(action.itemId, action.count);
	else
		PickupContainerItem(action.fromBag, action.fromSlot);
		if CursorHasItem() then
			PickupContainerItem(action.toBag, action.toSlot);
		else
			ClearCursor();
			-- TODO: For debugging only. Remove after testing.
			ns.debug("Failed to pick up a stack.");
		end
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

	if isSafe(itemActionQueue[1]) then
		doAction(table.remove(itemActionQueue, 1));
	else
		ns.debug("Unable to perform first action in list.");
	end
	-- if itemActionQueue[1].action == "MOVE_STACK" then
	-- 	if isSafeToDoNextMove() then
	-- 		doNextMove();
	-- 	end
	-- elseif itemActionQueue[1].action == "BREAK_STACK" then
	-- 	if isSafeToBreak() then
	-- 		breakStack(itemActionQueue[1].itemId, itemActionQueue[1].count);
	-- 		table.remove(itemActionQueue, 1);
	-- 	end
	-- end
end

local eventHandlers = {
	ITEM_LOCKED = function(container, containerSlot)
		local key = getKey(container, containerSlot);
		lockedSlots[key] = "locked";
	end,
	ITEM_UNLOCKED = function(container, containerSlot)
		local key = getKey(container, containerSlot);
		lockedSlots[key] = nil;

		if isSafe(itemActionQueue[1]) then
			doAction(table.remove(itemActionQueue, 1));
		end
	end,
};

eventFrame:SetScript("OnEvent", function(_, event, ...)
	eventHandlers[event](...);
end);
