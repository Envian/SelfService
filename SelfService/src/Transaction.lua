local _, ns = ...;

-- Transaction Definition
ns.TransactionClass = {};
ns.TransactionClass.__index = ns.TransactionClass;

DEBUG = ns.TransactionClass;

function ns.TransactionClass:new(data, customer)
  data = data or {
    Customer = customer,
    Active = false,
    ReceivedMats = {}
  }
  setmetatable(data, ns.TransactionClass);
  return data;
end

function ns.TransactionClass:addTradeWindowItem(itemName, quantity, slot)
  -- Define Trade variable if it's not defined already
  if not self.Trade then
    self.Trade = {};
    for i=1, 7 do
      self.Trade[i] = 0
    end
  end

  self.Trade[slot] = {itemName, quantity};
end

function ns.TransactionClass:removeTradeWindowItem(slot)
  self.Trade[slot] = 0;
end

function ns.TransactionClass:compareToCart()
  local requiredMats = self.Customer:getCart().Mats;

  for id, count in pairs(requiredMats) do
    local matchFound = false;
    for rid, rcount in pairs(self.ReceivedMats) do
      if id == rid and count ~= rcount then
        matchFound = true;
        local _, itemLink = GetItemInfo(id);
        print("Discrepancy between received and required mats!");
        print("Required: "..itemLink.."x"..count);
        print("Received: "..itemLink.."x"..rcount);
        return;
      end
    end

    if matchFound == false then
      local _, itemLink = GetItemInfo(id);
      print("Required material not received: "..itemLink);
      return;
    end
  end

  print("Got exact materials!");
end

function ns.TransactionClass:endTrade()

end

function ns.TransactionClass:isActive()
  return self.Active
end
