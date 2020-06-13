local ADDON_NAME, ns = ...;

local LOG_PREFIX = string.format("|cffcccccc[%s]|r ", ADDON_NAME);
local nolog = function() end;

local log = function(message)
	if type(message) ~= "string" then error("Invalid operand to log: "..tostring(message), 2) end;
	print(LOG_PREFIX..message);
end

local logf = function(message, ...)
	if type(message) ~= "string" then error("Invalid operand to logf: "..tostring(message), 2) end;

	local success, result = pcall(string.format, message, ...);
	if success then
		print(LOG_PREFIX..result);
	else
		error(result, 2);
	end
end

ns.LogLevel = {
	["1"] = 1,
	[1] = 1,
	FATAL = 1,
	["2"] = 2,
	[2] = 2,
	ERROR = 1,
	["3"] = 3,
	[3] = 3,
	WARNING = 1,
	["4"] = 4,
	[4] = 4,
	INFO = 1,
	["5"] = 5,
	[5] = 5,
	DEBUG = 1,
};

ns.setLogLevel = function(level)
	if not ns.LogLevel[level] then
		error("Invalid level. Expected a number between 1 and 5, or a valid debug level. Got: "..tostring(level or "nil"), 2);
	end
	level = ns.LogLevel[level];

	SelfServiceData.LogLevel = level;
	ns.debug = level >= 5 and log or nolog;
	ns.debugf = level >= 5 and logf or nolog;
	ns.info = level >= 4 and log or nolog;
	ns.infof = level >= 4 and logf or nolog;
	ns.warning = level >= 3 and log or nolog;
	ns.warningf = level >= 3 and logf or nolog;
	ns.error = level >= 2 and log or nolog;
	ns.errorf = level >= 2 and logf or nolog;
	ns.fatal = level >= 1 and log or nolog;
	ns.fatalf = level >= 1 and logf or nolog;
end

ns.setLogLevel(SelfServiceData.LogLevel);

ns.print = log;
ns.printf = logf;
