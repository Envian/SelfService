local _, ns = ...;

function SelfService_ActionQueueButton:handleOnClick(button)
	print("My text is: "..self:GetText());
	print("Dumping a table. She a ho");
	ns.dumpTable(button);
end
