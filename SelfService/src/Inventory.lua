ns.nextFreeBagSlot = function()
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

ns.combineItems = function(itemId)
	local matches = ns.searchBags(itemId);
	ns.dumpTable(matches);
	local maxStack = select(8, GetItemInfo(itemId));

	local n = 1;
	local i, j = 1, #matches;

	while n < 3 do
		ns.debug("i = "..i.."; j = "..j);
		ns.debug("Stacking "..matches[i].container..", "..matches[i].containerSlot);
		if matches[i].count == maxStack then
			ns.debug("Stack is full.");
			i = i + 1;
		else
			ns.debug("Grabbing stack at "..matches[j].container..", "..matches[j].containerSlot);
			PickupContainerItem(matches[j].container, matches[j].containerSlot);
			if CursorHasItem() then
				ns.debug("Got the stack.");
				PickupContainerItem(matches[i].container, matches[i].containerSlot);
				ns.debug("Dropped the stack.");

				if matches[i].count + matches[j].count > maxStack then
					matches[j].count = maxStack - matches[i].count;
					matches[i].count = maxStack;
					i = i + 1;
					ns.debug("Partial stack drop, do not remove matches[j]");
				else
					ns.debug("Full stack was moved. Remove matches[j].");
					matches[i].count = matches[i].count + matches[j].count;
					table.remove(matches, j);
					j = j - 1;
				end
			end
		end
		n = n + 1;
	end
end

ns.searchBags = function(itemId)
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

ns.breakStack = function(itemId, count)
	ns.combineItems(itemId);

	local matches = ns.searchBags(itemId);
	local total = 0;

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
	end
end
