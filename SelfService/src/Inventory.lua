local _, ns = ...;

local eventFrame = CreateFrame("Frame");

local eventHandlers = {
	BAG_UPDATE = function(container)
	end,
	ITEM_LOCKED = function(container, containerSlot)
	end,
	ITEM_LOCK_CHANGED = function(container, containerSlot)
	end
};

local registerEvents = function()
	for event, _ in pairs(eventHandlers) do
		eventFrame:RegisterEvent(event);
	end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
	eventHandlers[event](...);
end);

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

local breakStack = function(itemId, count)
	ns.combineItems(itemId);

	local matches = searchBags(itemId);
	local total = GetItemCount(itemId);

	if total < count then
		ns.error("Inventory does not contain "..count.." of ["..itemId.."].");
	elseif total == count then
		return matches;
	else
		local results = {};

		while count ~= 0 do
			if matches[#matches].count <= count then
				count = count - matches[#matches];
				table.insert(results, table.remove(matches));
			else
				local freeSlot = ns.nextFreeBagSlot();
				if ns.isEmpty(freeSlot) then
					ns.error("Unable to break an appropriate stack size. Inventory is full.");
					return;
				end

				SplitContainerItem(matches[#matches].container, matches[#matches].containerSlot, count);
				if CursorHasItem() then
					PickupContainerItem(freeSlot.container, freeSlot.containerSlot);
					count = 0;
					table.insert(results, freeSlot);
				end
			end
		end

		return results;
	end
end

ns.combineItems = function(itemId)
	--temporary call
	registerEvents();
	local moveQueue = {};

	local matches = searchBags(itemId);
	local maxStack = select(8, GetItemInfo(itemId));

	local i, j = 1, #matches;

	while i < j do
		if matches[i].count == maxStack then
			i = i + 1;
		else
			table.insert(moveQueue, {fromBag = matches[j].container, fromSlot = matches[j].container, toBag = matches[i].container, toSlot = matches[i].containerSlot});

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
	ns.debug("Move Queue:");
	ns.dumpTable(moveQueue);
	ns.debug("Resultant Table:");
	ns.dumpTable(matches);
end
