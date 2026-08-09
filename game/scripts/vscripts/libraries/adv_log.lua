-- Copyright (C) 2018  Frostrose Studio
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

--------------------------------------------------------------------------
-- Advanced Log and Debugging Library
--------------------------------------------------------------------------

if Log == nil then
	log = {
	}

	Log = {
		Levels = {
			DEBUG = 1,
			INFO = 2,
			WARN = 3,
			ERROR = 4,
			CRITICAL = 5
		},
		targets = {}
	}

	Log.config = {
		{
			matcher = ".*",
			level = Log.Levels.DEBUG,
			targets = {
				"api"
			}
		},
		{
			matcher = ".*",
			level = Log.Levels.INFO,
			targets = {
				"console"
			}
		}
	}


	---------------------------------------------
	-- Utility
	---------------------------------------------
	function Log:_LevelToString(lvl)
		if lvl == self.Levels.DEBUG then
			return "debug"
		elseif lvl == self.Levels.INFO then
			return "info"
		elseif lvl == self.Levels.WARN then
			return "warn"
		elseif lvl == self.Levels.ERROR then
			return "error"
		elseif lvl == self.Levels.CRITICAL then
			return "critical"
		else
			return "invalid"
		end
	end

	function Log:_LinesSplit(str)
		local t = {}
		local function helper(line)
			table.insert(t, line)
			return ""
		end
		helper((str:gsub("(.-)\r?\n", helper)))
		return t
	end

	function Log:_StringSplit(str, pat)
		local t = {} -- NOTE: use {n = 0} in Lua-5.0
		local fpat = "(.-)" .. pat
		local last_end = 1
		local s, e, cap = str:find(fpat, 1)
		while s do
			if s ~= 1 or cap ~= "" then
				table.insert(t, cap)
			end
			last_end = e + 1
			s, e, cap = str:find(fpat, last_end)
		end
		if last_end <= #str then
			cap = str:sub(last_end)
			table.insert(t, cap)
		end
		return t
	end

	function Log:_Trim(s)
		return (s:gsub("^%s*(.-)%s*$", "%1"))
	end

	function Log:_PrintTable(node)
		-- to make output beautiful
		local function tab(amt)
			local str = ""
			for i = 1, amt do
				str = str .. "\t"
			end
			return str
		end

		local cache, stack, output = {}, {}, {}
		local depth = 1
		local output_str = "{\n"

		while true do
			local size = 0
			for k, v in pairs(node) do
				size = size + 1
			end

			local cur_index = 1
			for k, v in pairs(node) do
				if (cache[node] == nil) or (cur_index >= cache[node]) then
					if (string.find(output_str, "}", output_str:len())) then
						output_str = output_str .. ",\n"
					elseif not (string.find(output_str, "\n", output_str:len())) then
						output_str = output_str .. "\n"
					end

					-- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
					table.insert(output, output_str)
					output_str = ""

					local key
					if (type(k) == "number" or type(k) == "boolean") then
						key = "[" .. tostring(k) .. "]"
					else
						key = "['" .. tostring(k) .. "']"
					end

					if (type(v) == "number" or type(v) == "boolean") then
						output_str = output_str .. tab(depth) .. key .. " = " .. tostring(v)
					elseif (type(v) == "table") then
						output_str = output_str .. tab(depth) .. key .. " = {\n"
						table.insert(stack, node)
						table.insert(stack, v)
						cache[node] = cur_index + 1
						break
					else
						output_str = output_str .. tab(depth) .. key .. " = '" .. tostring(v) .. "'"
					end

					if (cur_index == size) then
						output_str = output_str .. "\n" .. tab(depth - 1) .. "}"
					else
						output_str = output_str .. ","
					end
				else
					-- close the table
					if (cur_index == size) then
						output_str = output_str .. "\n" .. tab(depth - 1) .. "}"
					end
				end

				cur_index = cur_index + 1
			end

			if (size == 0) then
				output_str = output_str .. "\n" .. tab(depth - 1) .. "}"
			end

			if (#stack > 0) then
				node = stack[#stack]
				stack[#stack] = nil
				depth = cache[node] == nil and depth + 1 or depth - 1
			else
				break
			end
		end

		-- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
		table.insert(output, output_str)
		return table.concat(output)
	end

	function Log:_IsFiltered(target, level, file)
		-- go over each rule
		for i = 1, #self.config do
			local rule = self.config[i]

			-- check if matcher matches
			if string.match(file, rule.matcher) then
				-- check if level is high enough for rule
				if level >= rule.level then
					-- see if the rule defines this target
					for j = 1, #rule.targets do
						if rule.targets[j] == target then
							return false
						end
					end
				end
			end
		end

		return true
	end

	function Log:_GetStackTrace(ptr)
		local trace = {}
		if debug == nil or debug.getinfo == nil then return trace end

		-- gather info
		while true do
			local ok, i = pcall(debug.getinfo, ptr, "nSl")
			if not ok then break end
			if i == nil or ptr > 20 then
				break
			end
			table.insert(trace, i)
			ptr = ptr + 1
		end

		return trace
	end

	function Log:_GetFileFromTrace(trace)
		if #trace < 1 then
			return ""
		else
			return trace[1]["short_src"]
		end
	end

	---------------------------------------------
	-- Print function
	-- which actually just prepares data and passes them to the configured targets
	---------------------------------------------
	function Log:Print(obj, level, traceLevel)
		if traceLevel == nil then
			traceLevel = 4
		end

		-- prepare level
		local levelString = self:_LevelToString(level)

		local content = ""

		local contentOK, preparedContent = pcall(function()
			if type(obj) == "table" then return self:_PrintTable(obj) end
			return tostring(obj)
		end)
		if contentOK then
			content = preparedContent
		else
			content = "<adv_log serialization failed: " .. tostring(preparedContent) .. ">"
		end

		local trace = self:_GetStackTrace(traceLevel);
		local file = self:_GetFileFromTrace(trace)

		local delivered = false
		for i = 1, #self.targets do
			if not self:_IsFiltered(self.targets[i].name, level, file) then
				local targetOK, targetError = pcall(function()
					self.targets[i]:print(levelString, content, trace)
				end)
				delivered = delivered or targetOK
				if not targetOK and NativePrint ~= nil then
					pcall(NativePrint, "[error][adv_log] target=" .. tostring(self.targets[i].name)
						.. " failed: " .. tostring(targetError))
				end
			end
		end
		if not delivered and NativePrint ~= nil then
			pcall(NativePrint, "[" .. levelString .. "][adv_log fallback] " .. tostring(content))
		end
	end

	---------------------------------------------
	-- Runs code in safe context: Catches exceptions
	-- and logs errors
	---------------------------------------------
	function Log:ExecuteInSafeContext(fun, args, options)
		if args == nil then args = {} end
		options = type(options) == "table" and options or {}

		local status, err = xpcall(fun, function(err)
			if err == nil then
				err = "Unknown Error"
			end
			local errorText = tostring(err)
			local prefix = tostring(options.prefix or "")
			if prefix ~= "" then errorText = prefix .. " " .. errorText end

			if options.silent ~= true then
				-- Do not filter safe-context errors, but never let a broken log
				-- target replace the original exception.
				local levelString = self:_LevelToString(Log.Levels.ERROR)
				local trace = self:_GetStackTrace(4)
				local delivered = false

				for i = 1, #self.targets do
					local targetStatus = pcall(function()
						self.targets[i]:print(
							levelString,
							"Error occurred while executing in safe context: " .. errorText,
							trace
						)
					end)
					delivered = delivered or targetStatus
				end
				if not delivered and NativePrint ~= nil then
					NativePrint("[error][adv_log] " .. errorText)
				end
			end

			if options.notify ~= false
				and GameRules ~= nil
				and GameRules.SendCustomMessage ~= nil then
				pcall(function()
					GameRules:SendCustomMessage("Error: " .. errorText, 0, 0)
				end)
			end
			return errorText
		end, unpack(args))

		return status, err
	end

	---------------------------------------------
	-- Configure the logger with a given config
	---------------------------------------------
	function Log:Configure(config)
		self.config = config;
	end

	---------------------------------------------
	-- Load the logger config from api
	---------------------------------------------
	function Log:ConfigureFromApi()
		api:GetLoggingConfiguration(function(data)
			log.info("Loaded new Logging configuration from server")
			self.config = data.rules
		end)
	end

	---------------------------------------------
	-- Add a logging target
	---------------------------------------------
	function Log:AddTarget(target)
		table.insert(self.targets, target)
	end

	---------------------------------------------
	-- General purpose log shortcut functions
	---------------------------------------------
	function log.debug(obj)
		Log:Print(obj, Log.Levels.DEBUG)
	end

	function log.info(obj)
		Log:Print(obj, Log.Levels.INFO)
	end

	function log.warn(obj)
		Log:Print(obj, Log.Levels.WARN)
	end

	function log.warning(obj)
		Log:Print(obj, Log.Levels.WARN)
	end

	function log.critical(obj)
		Log:Print(obj, Log.Levels.CRITICAL)
	end

	function log.crit(obj)
		Log:Print(obj, Log.Levels.CRITICAL)
	end

	function log.error(obj)
		Log:Print(obj, Log.Levels.ERROR)
	end

	---------------------------------------------
	-- Safe shortcut
	---------------------------------------------
	function safe(fun)
		return Log:ExecuteInSafeContext(fun)
	end

	---------------------------------------------
	-- Logger Targets
	---------------------------------------------

	ApiLogTarget = {
		name = "api"
	}

	function ApiLogTarget:print(level, content, trace)
		local encodedTrace = {}
		for i = 1, math.min(#trace, 12) do
			local frame = trace[i] or {}
			table.insert(encodedTrace, {
				source = tostring(frame.short_src or frame.source or ""),
				line = tonumber(frame.currentline or frame.line) or 0,
				name = tostring(frame.name or ""),
			})
		end
		if api then
			api:Message({
				level = level,
				content = tostring(content),
				trace = encodedTrace
			}, 2)
		end
	end

	ConsoleLogTarget = {
		name = "console"
	}

	function ConsoleLogTarget:print(level, content, trace)
		local frame = type(trace) == "table" and trace[1] or nil
		if type(frame) ~= "table" then
			NativePrint("[" .. tostring(level) .. "][adv_log:no_trace] " .. tostring(content))
			return
		end
		local name = ""
		if frame["name"] ~= nil then
			name = "|" .. frame["name"]
		end
		NativePrint("[" ..
			level .. "][" .. tostring(frame["short_src"] or frame["source"] or "unknown")
			.. ":" .. tostring(frame["currentline"] or 0) .. name .. "] " .. tostring(content))
	end

	-----------------------------------------------------------------
	-- Overwrite the default print and redirect it to the custom
	-- Log implementation above
	-----------------------------------------------------------------
	NativePrint = print
	print = nil

	function print(...)
		local args = { ... }

		if #args == 1 then
			args = args[1]
		end

		Log:Print(args, Log.Levels.INFO)
	end

	-----------------------------------------------------------------
	-- A function to re-lookup a function by name every time.
	-- Taken from /game/core/scripts/vscripts/utils/vscriptinit.lua
	-----------------------------------------------------------------
	NativeDynamic_Wrap = nil
	if Dynamic_Wrap ~= nil then
		NativeDynamic_Wrap = Dynamic_Wrap
		Dynamic_Wrap = nil
	end

	function Dynamic_Wrap(mt, name)
		local function wrapper(...)
			local args = { ... }

			if mt == nil or name == nil then
				print("[adv_log] Dynamic_Wrap received invalid mt/name")
				return nil
			end

			local method = mt[name]
			if type(method) ~= "function" then
				print("[adv_log] Dynamic_Wrap target is not a function:", tostring(name), type(method))
				return nil
			end

			local status, v = safe(function()
				-- Keep native Dynamic_Wrap behavior: pass wrapped table as self.
				return method(mt, unpack(args))
			end)

			if status then
				return v
			else
				return nil
			end
		end

		return wrapper
	end

	-----------------------------------------------------------------
	-- AdvLogRegisterLuaModifier(modifier)
	-- This function proxies a given modifier to run in safe
	-- contexts. all functions starting with On* will be proxied
	-----------------------------------------------------------------
	local coveredByProxy = {
		"OnAbilityEndChannel",
		"OnAbilityExecuted",
		"OnAbilityFullyCast",
		"OnAbilityStart",
		"OnAttack",
		"OnAttackAllied",
		"OnAttacked",
		"OnAttackFail",
		"OnAttackFinished",
		"OnAttackLanded",
		"OnAttackRecord",
		"OnAttackStart",
		"OnBreakInvisibility",
		"OnBuildingKilled",
		"OnDeath",
		"OnDominated",
		"OnHealReceived",
		"OnHealthGained",
		"OnHeroKilled",
		"OnManaGained",
		"OnModelChanged",
		"OnModifierAdded",
		"OnOrder",
		"OnProjectileDodge",
		"OnRespawn",
		"OnSetLocation",
		"OnSpellTargetReady",
		"OnSpentMana",
		"OnStateChanged",
		"OnTakeDamage",
		"OnTakeDamageKillCredit",
		"OnTeleported",
		"OnTeleporting",
		"OnTooltip",
		"OnUnitMoved",
		"OnCreated",
		"OnDestroy",
		"OnIntervalThink",
		"OnRefresh",
		"OnRemoved",
		"OnStackCountChanged"
	}

	function AdvLogRegisterLuaModifier(modifier)
		-- check if a covered function is defined
		for _, name in pairs(coveredByProxy) do
			print("Checking modifier for " .. name)

			if modifier[name] ~= nil then
				print("Modifier defines method " .. name .. ": " .. tostring(modifier[name]))

				-- create proxy
				local original = modifier[name]
				local function proxy(...)
					print("Running Proxy")
					return Log:ExecuteInSafeContext(original, { ... })
				end
				modifier[name] = proxy
			end
		end
	end

	---------------------------------------------
	-- Initialization
	---------------------------------------------
	Log:AddTarget(ApiLogTarget)
	Log:AddTarget(ConsoleLogTarget)
end
