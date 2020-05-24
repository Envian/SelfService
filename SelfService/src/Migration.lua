local _, ns = ...;

if not SelfServiceData or not SelfServiceData.Version then
	SelfServiceData = {
		Version = 0,
		Customers = {},
		LogLevel = 5,
	};
end
