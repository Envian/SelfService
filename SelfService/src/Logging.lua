local _, ns = ...;

local LOG_PREFIX = string.format("|ccccccc[%s]|r ", ns.ADDON_NAME);
local nolog = function() end;

local log = function(message)
	if type(message) ~= "string" then error("Invalid operand to log: "..tostring(message)) end;
	print(LOG_PREFIX..message);
end

local logf = function(message, ...)
	if type(message) ~= "string" then error("Invalid operand to logf: "..tostring(message)) end;

	local success, result = pcall(string.format, message, ...);
	if success then
		print(LOG_PREFIX..result);
	else
		error(result, 2);
	end
end

ns.Log = {
	debug = nolog,
	debugf = nolog,
	info = nolog,
	infof = nolog,
	warning = nolog,
	warningf = nolog,
	error = nolog,
	errorf = nolog,
	fatal = nolog,
	fatalf = nolog,
	setLogLevel = function(level)
		if type(level) ~= "number" or level < 1 or level > 5 then
			error("Invalid level. Expected a number between 1 and 5. Got: "..tostring(level or "nil"));
		end

		SelfServiceData.LogLevel = level;
		ns.Log.debug = level >= 5 and log or nolog;
		ns.Log.debugf = level >= 5 and logf or nolog;
		ns.Log.info = level >= 4 and log or nolog;
		ns.Log.infof = level >= 4 and logf or nolog;
		ns.Log.warning = level >= 3 and log or nolog;
		ns.Log.warningf = level >= 3 and logf or nolog;
		ns.Log.error = level >= 2 and log or nolog;
		ns.Log.errorf = level >= 2 and logf or nolog;
		ns.Log.fatal = level >= 1 and log or nolog;
		ns.Log.fatalf = level >= 1 and logf or nolog;
	end
}

ns.Log.setLogLevel(SelfServiceData.LogLevel);
