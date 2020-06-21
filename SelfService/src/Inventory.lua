-- This file is part of SelfService.
--
-- SelfService is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- SelfService is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with SelfService.  If not, see <https://www.gnu.org/licenses/>.
local ADDON_NAME, ns = ...;

local moveQueue = {};
local returnStacks = {};
local eventFrame = CreateFrame("Frame");

local getKey = function(container, slot)
	return container..":"..slot;
end

local scanBags = function(itemMap)
	local inventoryMap = {}
	local freeSlots = {}

	for i=0,11 do
		for j=1,GetContainerNumSlots(i) do
			local itemId = GetContainerItemID(i, j) or 0;
			if itemMap[itemId] then
				local count = select(2, GetContainerItemInfo(i, j));
				inventoryMap[itemId] = inventoryMap[itemId] or {};
				table.insert(inventoryMap[itemId], {id = itemId, count = count, container = i, slot = j});
			elseif itemId == 0 then
				table.insert(freeSlots, {container = i, slot = j});
			end
		end
	end
	return inventoryMap, freeSlots;
end

local makeMoveQueue = function(inventoryMap, freeSlots, itemMap)
	moveQueue = {};
	local sortedStacks = {};

	-- Container Sorting Algorithm
	for itemId, stacks in pairs(inventoryMap) do
		local maxStack = select(8, GetItemInfo(itemId));

		local i, j = 1, #stacks;

		while i < j do
			if stacks[i].count == maxStack then
				i = i + 1;
			else
				table.insert(moveQueue, {fromContainer = stacks[j].container, fromSlot = stacks[j].slot, toContainer = stacks[i].container, toSlot = stacks[i].slot});

				if stacks[i].count + stacks[j].count > maxStack then
					stacks[j].count = stacks[i].count + stacks[j].count - maxStack;
					stacks[i].count = maxStack;
					i = i + 1;
				else
					stacks[i].count = stacks[i].count + stacks[j].count;
					table.insert(freeSlots, {container = stacks[j].container, slot = stacks[j].slot});
					table.remove(stacks, j);
					j = j - 1;
				end
			end
		end

		sortedStacks[itemId] = stacks;
	end

	-- Stack Breaking Algorithm
	for itemId, count in pairs(itemMap) do
		local stackList = sortedStacks[itemId];
		local total = GetItemCount(itemId);

		if total < count then
			-- TODO: Localize
			ns.errorf(ns.LOG_RETURN_INSUFFICIENT_ITEMS, count, itemId);
		elseif total == count then
			for _, stack in ipairs(stackList) do
				-- No stack break necessary
				table.insert(returnStacks, stack);
			end
		else
			while count ~= 0 do
				if stackList[#stackList].count <= count then
					count = count - stackList[#stackList].count;
					table.insert(returnStacks, table.remove(stackList));
				else
					local freeSlot = table.remove(freeSlots, 1);

					if not freeSlot then
						-- TODO: Localize
						ns.error(ns.LOG_INVENTORY_FULL);
						return;
					end

					-- Only add moves to the queue.
					table.insert(moveQueue, {fromContainer = stackList[#stackList].container, fromSlot = stackList[#stackList].slot, toContainer = freeSlot.container, toSlot = freeSlot.slot, count = count});
					table.insert(returnStacks, {id = itemId, count = count, container = freeSlot.container, slot = freeSlot.slot});
					count = 0;
				end
			end
		end
	end
end

local isLocked = function(container, slot)
	return GetContainerItemID(container, slot) and C_Item.IsLocked(ItemLocation:CreateFromBagAndSlot(container, slot));
end

local isSafe = function(action)
	return not (CursorHasItem() or isLocked(action.toContainer, action.toSlot) or isLocked(action.fromContainer, action.fromSlot));
end

local doNextAction = function()
	if not moveQueue[1] then
		for _, stack in ipairs(returnStacks) do
			if isLocked(stack.container, stack.slot) then
				return;
			end
		end
		eventFrame:UnregisterEvent("ITEM_UNLOCKED");
		ns.CurrentTrade.Customer.CurrentOrder:handleEvent("CALLED_BACK", returnStacks);
	else
		if isSafe(moveQueue[1]) then
			local action = table.remove(moveQueue, 1);

			if action.count then
				SplitContainerItem(action.fromContainer, action.fromSlot, action.count);
			else
				PickupContainerItem(action.fromContainer, action.fromSlot);
			end

			if CursorHasItem() then
				PickupContainerItem(action.toContainer, action.toSlot);
			else
				ClearCursor();
				-- TODO: For debugging only. Remove after testing.
				ns.error("Failed to pick up a stack.");
			end
		end
	end
end

ns.breakStacksForReturn = function(itemMap)
	if not itemMap then
		ns.error("Nil parameter supplied to breakStacksForReturn()");
		return;
	else
		returnStacks = {};
		local inventoryMap, freeSlots = scanBags(itemMap);
		makeMoveQueue(inventoryMap, freeSlots, itemMap);
		eventFrame:RegisterEvent("ITEM_UNLOCKED");
		doNextAction();
	end
end

local eventHandlers = {
	ITEM_UNLOCKED = function(container, slot)
		doNextAction();
	end,
};

eventFrame:SetScript("OnEvent", function(_, event, ...)
	eventHandlers[event](...);
end);
