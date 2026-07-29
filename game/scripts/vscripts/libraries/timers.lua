TIMERS_VERSION = "2.00"

--[[

	-- A timer running every second that starts immediately on the next frame, respects pauses
	Timers:CreateTimer(function()
			print ("Hello. I'm running immediately and then every second thereafter.")
			return 1.0
		end
	)

	-- A timer which calls a function with a table context
	Timers:CreateTimer(GameMode.someFunction, GameMode)

	-- A timer running every second that starts 5 seconds in the future, respects pauses
	Timers:CreateTimer(5, function()
			print ("Hello. I'm running 5 seconds after you called me and then every second thereafter.")
			return 1.0
		end
	)

	-- 10 second delayed, run once using gametime (respect pauses)
	Timers:CreateTimer({
		endTime = 10, -- when this timer should first execute, you can omit this if you want it to run first on the next frame
		callback = function()
			print ("Hello. I'm running 10 seconds after when I was started.")
		end
	})

	-- 10 second delayed, run once regardless of pauses
	Timers:CreateTimer({
		useGameTime = false,
		endTime = 10, -- when this timer should first execute, you can omit this if you want it to run first on the next frame
		callback = function()
			print ("Hello. I'm running 10 seconds after I was started even if someone paused the game.")
		end
	})


	-- A timer running every second that starts after 2 minutes regardless of pauses
	Timers:CreateTimer("uniqueTimerString3", {
		useGameTime = false,
		endTime = 120,
		callback = function()
			print ("Hello. I'm running after 2 minutes and then every second thereafter.")
			return 1
		end
	})


	-- A timer using the old style to repeat every second starting 5 seconds ahead
	Timers:CreateTimer("uniqueTimerString3", {
		useOldStyle = true,
		endTime = GameRules:GetGameTime() + 5,
		callback = function()
			print ("Hello. I'm running after 5 seconds and then every second thereafter.")
			return GameRules:GetGameTime() + 1
		end
	})

]]
-- Compatibility floor for zero-delay and overdue repeating timers. Unlike the
-- legacy scheduler this is not a permanent polling interval: the thinker sleeps
-- until the next timer deadline.
TIMERS_THINK = 0.01

local TIMER_CONTEXT_NAME = "xhs_adaptive_timers"
local TIMER_GENERATION_KEY = "__xhs_timer_generation"

local function HeapSwap(heap, a, b)
	heap[a], heap[b] = heap[b], heap[a]
end

local function HeapPush(heap, entry)
	local index = #heap + 1
	heap[index] = entry

	while index > 1 do
		local parent = math.floor(index / 2)
		if heap[parent].endTime <= entry.endTime then break end
		HeapSwap(heap, parent, index)
		index = parent
	end
end

local function HeapPop(heap)
	local count = #heap
	if count == 0 then return nil end

	local root = heap[1]
	local tail = heap[count]
	heap[count] = nil
	count = count - 1

	if count > 0 then
		heap[1] = tail
		local index = 1
		while true do
			local left = index * 2
			if left > count then break end

			local right = left + 1
			local smallest = left
			if right <= count and heap[right].endTime < heap[left].endTime then
				smallest = right
			end
			if heap[index].endTime <= heap[smallest].endTime then break end

			HeapSwap(heap, index, smallest)
			index = smallest
		end
	end

	return root
end

if Timers == nil then
	--	print ( '[Timers] creating Timers' )
	Timers = {}
	Timers.__index = Timers
end

function Timers:new(o)
	o = o or {}
	setmetatable(o, Timers)
	return o
end

function Timers:_xpcall(f, ...)
	print(f)
	print({ ... })
	PrintTable({ ... })
	local result = xpcall(function() return f(unpack(arg)) end,
		function(msg)
			-- build the error message
			return msg .. '\n' .. debug.traceback() .. '\n'
		end)

	print(result)
	PrintTable(result)
	if not result[1] then
		-- throw an error
	end
	-- remove status code
	table.remove(result, 1)
	return unpack(result)
end

function Timers:start(existingTimers)
	Timers = self
	self.timers = existingTimers or {}
	self.gameTimeHeap = {}
	self.realTimeHeap = {}
	self.pendingEntries = {}
	self.timerGeneration = 0
	self.isThinking = false
	self.thinkArmed = false
	self.schedulerGeneration = (self.schedulerGeneration or 0) + 1
	local schedulerGeneration = self.schedulerGeneration

	self.thinker = Entities:CreateByClassname("info_target")
	self.thinkCallback = function()
		return Timers:Think(schedulerGeneration)
	end

	for name, timer in pairs(self.timers) do
		self:_QueueTimer(name, timer)
	end
	self:_ArmThinker()
end

function Timers:_UsesGameTime(timer)
	return timer.useGameTime ~= false
end

function Timers:_IsEntryCurrent(entry)
	local timer = self.timers[entry.name]
	return timer ~= nil
		and timer == entry.timer
		and timer[TIMER_GENERATION_KEY] == entry.generation
		and timer.endTime == entry.endTime
		and self:_UsesGameTime(timer) == entry.useGameTime
end

function Timers:_PeekCurrent(heap)
	while #heap > 0 do
		local entry = heap[1]
		if self:_IsEntryCurrent(entry) then
			return entry
		end
		HeapPop(heap)
	end
	return nil
end

function Timers:_PushEntry(entry)
	local heap = entry.useGameTime and self.gameTimeHeap or self.realTimeHeap
	HeapPush(heap, entry)
end

function Timers:_QueueTimer(name, timer)
	self.timerGeneration = self.timerGeneration + 1
	timer[TIMER_GENERATION_KEY] = self.timerGeneration

	local entry = {
		name = name,
		timer = timer,
		generation = self.timerGeneration,
		endTime = timer.endTime,
		useGameTime = self:_UsesGameTime(timer),
	}

	if self.isThinking then
		self.pendingEntries[#self.pendingEntries + 1] = entry
	else
		self:_PushEntry(entry)
	end
end

function Timers:_FlushPendingEntries()
	local pending = self.pendingEntries
	self.pendingEntries = {}

	for _, entry in ipairs(pending) do
		if self:_IsEntryCurrent(entry) then
			self:_PushEntry(entry)
		end
	end
end

function Timers:_GetNextDelay()
	local gameEntry = self:_PeekCurrent(self.gameTimeHeap)
	local realEntry = self:_PeekCurrent(self.realTimeHeap)
	local delay = nil

	if gameEntry ~= nil then
		delay = gameEntry.endTime - GameRules:GetGameTime()
	end
	if realEntry ~= nil then
		local realDelay = realEntry.endTime - Time()
		if delay == nil or realDelay < delay then
			delay = realDelay
		end
	end

	if delay == nil then return nil end
	return math.max(TIMERS_THINK, delay)
end

function Timers:_ArmThinker()
	if self.isThinking or self.thinker == nil or self.thinker:IsNull() then return end

	local delay = self:_GetNextDelay()
	if delay == nil then
		self.thinkArmed = false
		return
	end

	self.thinkArmed = true
	self.thinker:SetContextThink(TIMER_CONTEXT_NAME, self.thinkCallback, delay)
end

function Timers:_RunDueHeap(heap, now)
	while true do
		local entry = self:_PeekCurrent(heap)
		if entry == nil or entry.endTime > now then return end

		HeapPop(heap)
		if self:_IsEntryCurrent(entry) then
			local name = entry.name
			local timer = entry.timer
			self.timers[name] = nil

			local status, nextCall
			if timer.context then
				status, nextCall = xpcall(function() return timer.callback(timer.context, timer) end, function(msg)
					return msg .. '\n' .. debug.traceback() .. '\n'
				end)
			else
				status, nextCall = xpcall(function() return timer.callback(timer) end, function(msg)
					return msg .. '\n' .. debug.traceback() .. '\n'
				end)
			end

			if status then
				if nextCall then
					if timer.useOldStyle == true then
						timer.endTime = timer.endTime + nextCall - now
					else
						timer.endTime = timer.endTime + nextCall
					end

					-- Preserve the legacy behavior: a repeating named timer
					-- replaces a timer of the same name created by its callback.
					self.timers[name] = timer
					self:_QueueTimer(name, timer)
				end
			else
				self:HandleEventError("Timer", name, nextCall)
			end
		end
	end
end

function Timers:Think(schedulerGeneration)
	-- Stops a legacy or superseded thinker cleanly after a script reload.
	if schedulerGeneration ~= self.schedulerGeneration then return nil end

	self.thinkArmed = false
	if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then return nil end

	self.isThinking = true
	self:_RunDueHeap(self.gameTimeHeap, GameRules:GetGameTime())
	self:_RunDueHeap(self.realTimeHeap, Time())
	self.isThinking = false
	self:_FlushPendingEntries()

	local delay = self:_GetNextDelay()
	self.thinkArmed = delay ~= nil
	return delay
end

function Timers:HandleEventError(name, event, err)
	print(err)

	-- Ensure we have data
	name = tostring(name or 'unknown')
	event = tostring(event or 'unknown')
	err = tostring(err or 'unknown')

	-- Tell everyone there was an error
	--GameRules:SendCustomMessage(nil, name .. ' threw an error on event '..event, 0, 0)
	--GameRules:SendCustomMessage(err, 0, 0)

	-- Prevent loop arounds
	if not self.errorHandled then
		-- Store that we handled an error
		self.errorHandled = true
	end
end

function Timers:CreateTimer(name, args, context)
	if type(name) == "function" then
		if args ~= nil then
			context = args
		end
		args = { callback = name }
		name = DoUniqueString("timer")
	elseif type(name) == "table" then
		args = name
		name = DoUniqueString("timer")
	elseif type(name) == "number" then
		args = { endTime = name, callback = args }
		name = DoUniqueString("timer")
	end
	if not args.callback then
		print("Invalid timer created: " .. name)
		return
	end


	local now = GameRules:GetGameTime()
	if args.useGameTime ~= nil and args.useGameTime == false then
		now = Time()
	end

	if args.endTime == nil then
		args.endTime = now
	elseif args.useOldStyle == nil or args.useOldStyle == false then
		args.endTime = now + args.endTime
	end

	args.context = context

	Timers.timers[name] = args
	Timers:_QueueTimer(name, args)
	Timers:_ArmThinker()

	return name
end

function Timers:RemoveTimer(name)
	Timers.timers[name] = nil
end

function Timers:RemoveTimers(killAll)
	local timers = {}

	if not killAll then
		for k, v in pairs(Timers.timers) do
			if v.persist then
				timers[k] = v
			end
		end
	end

	Timers.timers = timers
	Timers.gameTimeHeap = {}
	Timers.realTimeHeap = {}
	Timers.pendingEntries = {}

	for name, timer in pairs(timers) do
		Timers:_QueueTimer(name, timer)
	end
	Timers:_ArmThinker()
end

-- Ability Lua files are also loaded in the client VM for prediction/tooltips.
-- Entity creation is server-only, so the automatic thinker must never start
-- from a client-side require().
if IsServer() and (Timers.timers == nil or Timers.gameTimeHeap == nil) then
	Timers:start(Timers.timers)
end
