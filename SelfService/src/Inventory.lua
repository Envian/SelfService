local _, ns = ...;

local itemActionQueue = {};
local stackResults = {};
local brokenStacks = {};
local eventFrame = CreateFrame("Frame");

local nextFreeSlot = function()
	for i=0,11 do
		if GetContainerNumFreeSlots(i) > 0 then
			for j=1,GetContainerNumSlots(i) do
				if GetContainerItemID(i, j) == nil then
					-- TODO: Remove in release, for debugging only
					ns.debug("Free slot at "..i..", "..j);
					return {container = i, slot = j};
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
				table.insert(matches, {itemId = itemId, container = i, slot = j, count = count});
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
				table.insert(itemActionQueue, {action = "MOVE_STACK", fromBag = matches[j].container, fromSlot = matches[j].slot, toBag = matches[i].container, toSlot = matches[i].slot});

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

				SplitContainerItem(matches[#matches].container, matches[#matches].slot, count);
				if CursorHasItem() then
					PickupContainerItem(freeSlot.container, freeSlot.slot);
					result = {itemId = itemId, container = freeSlot.container, slot = freeSlot.slot, count = count};
					count = 0;
					table.insert(brokenStacks, result);
				end
			end
		end
	end
end

local isLocked = function(container, slot)
	return C_Item.IsLocked(ItemLocation:CreateFromBagAndSlot(container, slot));
end

local isSafe = function(action)
	if not action or CursorHasItem() then
		return false;
	else
		if action.action == "MOVE_STACK" then
			if isLocked(action.toBag, action.toSlot) or isLocked(action.fromBag, action.fromSlot) then
				return false;
			end
		elseif action.action == "BREAK_STACK" then
			for _, stack in ipairs(stackResults) do
				if isLocked(stack.container, stack.slot) then
					return false;
				end
			end
		elseif action.action == "RETURN_STACKS" then
			for _, stack in ipairs(brokenStacks) do
				if isLocked(stack.container, stack.slot) then
					return false;
				end
			end
		end
	end

	-- Desired action is safe, return true
	return true;
end

local doAction = function(action)
	if not action then
		-- TODO: For debugging only. Remove after testing.
		ns.debug("doAction in Inventory.lua called with nil action");
		return;
	elseif action.action == "RETURN_STACKS" then
		eventFrame:UnregisterEvent("ITEM_UNLOCKED");
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

	brokenStacks = {};
	makeItemActionQueue(returnables);
	eventFrame:RegisterEvent("ITEM_UNLOCKED");

	if isSafe(itemActionQueue[1]) then
		doAction(table.remove(itemActionQueue, 1));
	else
		-- TODO: Remove message later. Just for the case where this function is called and an item is already on the cursor. Self fixes on next ITEM_UNLOCKED event
		ns.debug("Unable to perform first action in list.");
	end
end

local eventHandlers = {
	ITEM_UNLOCKED = function(container, slot)
		if isSafe(itemActionQueue[1]) then
			doAction(table.remove(itemActionQueue, 1));
		end
	end,
};

eventFrame:SetScript("OnEvent", function(_, event, ...)
	eventHandlers[event](...);
end);
