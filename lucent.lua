-- lucent ui kit
-- one file, no dependencies. drop it in a modulescript and require it

local lucent = (function()

local utils = {}

local math_floor = math.floor
local math_abs = math.abs
local math_min = math.min
local math_max = math.max
local math_huge = math.huge
local math_sqrt = math.sqrt
local math_sin = math.sin
local math_cos = math.cos
local math_pi = math.pi
local math_rad = math.rad
local math_clamp = math.clamp

local function norm(key)
	return (string.gsub(string.lower(key), "[%s_%-%.]", ""))
end

local function kebab(key)
	return (string.gsub(string.gsub(key, "(%u)", "-%1"), "^%-", "")):lower()
end

local function copy(source)
	local out = {}
	for key, value in source do
		out[key] = value
	end
	return out
end

local function keys(source)
	local out = {}
	for key in source do
		table.insert(out, key)
	end
	return out
end

local function values(source)
	local out = {}
	for _, value in source do
		table.insert(out, value)
	end
	return out
end

local function count(source)
	local total = 0
	for _ in source do
		total += 1
	end
	return total
end

local function merge(...)
	local out = {}
	for index = 1, select("#", ...) do
		local source = select(index, ...)
		if source then
			for key, value in source do
				if value ~= nil then
					out[key] = value
				end
			end
		end
	end
	return out
end

local function is_instance(value)
	return typeof(value) == "Instance"
end

local function deep_merge(...)
	local out = {}
	for index = 1, select("#", ...) do
		local source = select(index, ...)
		if source then
			for key, value in source do
				local current = out[key]
				if type(value) == "table" and type(current) == "table" and not is_instance(value) then
					out[key] = deep_merge(current, value)
				elseif value ~= nil then
					out[key] = value
				end
			end
		end
	end
	return out
end

local function pick(source, ...)
	local out = {}
	for index = 1, select("#", ...) do
		local key = select(index, ...)
		if source[key] ~= nil then
			out[key] = source[key]
		end
	end
	return out
end

local function omit(source, ...)
	local skip = {}
	for index = 1, select("#", ...) do
		skip[select(index, ...)] = true
	end
	local out = {}
	for key, value in source do
		if not skip[key] then
			out[key] = value
		end
	end
	return out
end

local function map(source, fn)
	local out = {}
	for key, value in source do
		out[key] = fn(value, key)
	end
	return out
end

local function map_array(source, fn)
	local out = table.create(#source)
	for index, value in source do
		out[index] = fn(value, index)
	end
	return out
end

local function filter(source, fn)
	local out = {}
	for key, value in source do
		if fn(value, key) then
			out[key] = value
		end
	end
	return out
end

local function find(source, fn)
	for key, value in source do
		if fn(value, key) then
			return value, key
		end
	end
	return nil
end

local function reduce(source, initial, fn)
	local acc = initial
	for key, value in source do
		acc = fn(acc, value, key)
	end
	return acc
end

local function contains(source, wanted)
	for _, value in source do
		if value == wanted then
			return true
		end
	end
	return false
end

local function is_number(value)
	local kind = typeof(value)
	return kind == "number"
end

local function is_array(source)
	if type(source) ~= "table" then
		return false
	end
	return source[1] ~= nil or next(source) == nil
end

local function clamp(value, low, high)
	if value < low then
		return low
	end
	if value > high then
		return high
	end
	return value
end

local function clamp01(value)
	return clamp(value, 0, 1)
end

local function lerp(a, b, alpha)
	return a + (b - a) * alpha
end

local function inverse_lerp(a, b, value)
	if a == b then
		return 0
	end
	return (value - a) / (b - a)
end

local function remap(value, in_min, in_max, out_min, out_max)
	return lerp(out_min, out_max, inverse_lerp(in_min, in_max, value))
end

local function round(value, step)
	step = step or 1
	return math_floor(value / step + 0.5) * step
end

local function sign(value)
	if value > 0 then
		return 1
	elseif value < 0 then
		return -1
	end
	return 0
end

local function sum(list)
	local total = 0
	for _, value in list do
		total += value
	end
	return total
end

local function max_of(list)
	local best = -math_huge
	for _, value in list do
		if value > best then
			best = value
		end
	end
	return best
end

local function min_of(list)
	local best = math_huge
	for _, value in list do
		if value < best then
			best = value
		end
	end
	return best
end

local function average(list)
	if #list == 0 then
		return 0
	end
	return sum(list) / #list
end

local function normalize(list)
	local low = min_of(list)
	local high = max_of(list)
	local span = high - low
	if span == 0 then
		span = 1
	end
	local out = table.create(#list)
	for index, value in list do
		out[index] = (value - low) / span
	end
	return out, low, high
end

local function comma(value, digits)
	local text = string.format("%." .. (digits or 2) .. "f", value)
	local whole, fraction = string.match(text, "^(%-?%d+)%.(%d+)$")
	if not whole then
		return text
	end
	whole = string.reverse((string.gsub(string.reverse(whole), "(%d%d%d)", "%1,")))
	return whole .. "." .. fraction
end

local function compact(value, digits)
	digits = digits or 1
	local size = math_abs(value)
	local prefix = value < 0 and "-" or ""
	local units = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, unit in units do
		if size >= unit[1] then
			local text = string.format("%." .. digits .. "f", size / unit[1])
			text = string.gsub(text, "(%.%d*[1-9])0+$", "%1")
			text = string.gsub(text, "%.$", "")
			return prefix .. text .. unit[2]
		end
	end
	if size == math_floor(size) then
		return prefix .. string.format("%.0f", size)
	end
	return prefix .. string.format("%." .. digits .. "f", size)
end

local function percent(value, digits)
	return string.format("%." .. (digits or 0) .. "f", value * 100) .. "%"
end

local function pad(value, length, char)
	value = tostring(value)
	char = char or "0"
	while #value < length do
		value = char .. value
	end
	return value
end

local function split(text, separator)
	local out = {}
	for piece in string.gmatch(text, "([^" .. separator .. "]+)") do
		table.insert(out, piece)
	end
	return out
end

local function trim(text)
	return (string.gsub(text, "^%s*(.-)%s*$", "%1"))
end

local function starts_with(text, prefix)
	return string.sub(text, 1, #prefix) == prefix
end

local function ends_with(text, suffix)
	return suffix == "" or string.sub(text, -#suffix) == suffix
end

local function wrap_text(text, limit)
	local words = {}
	for word in string.gmatch(text .. " ", "%S+%s*") do
		table.insert(words, word)
	end
	local lines = {}
	local current = ""
	for _, word in words do
		if #current + #word > limit and #current > 0 then
			table.insert(lines, (string.gsub(current, "%s+$", "")))
			current = word
		else
			current ..= word
		end
	end
	if #current > 0 then
		table.insert(lines, (string.gsub(current, "%s+$", "")))
	end
	return table.concat(lines, "\n")
end

local function title_case(text)
	return (string.gsub(text, "(%a)([%w']*)", function(first, rest)
		return string.upper(first) .. string.lower(rest)
	end))
end

local function signed(value, digits)
	if value > 0 then
		return "+" .. string.format("%." .. (digits or 1) .. "f", value)
	end
	return string.format("%." .. (digits or 1) .. "f", value)
end

local function duration(seconds)
	if seconds < 1 then
		return string.format("%dms", math.floor(seconds * 1000))
	end
	if seconds < 60 then
		return string.format("%.1fs", seconds)
	end
	if seconds < 3600 then
		return string.format("%dm %ds", math_floor(seconds / 60), math_floor(seconds % 60))
	end
	return string.format("%dh %dm", math_floor(seconds / 3600), math_floor(seconds % 3600 / 60))
end

local function relative_time(timestamp)
	local delta = os.time() - timestamp
	if delta < 60 then
		return "now"
	end
	if delta < 3600 then
		return string.format("%dm ago", math_floor(delta / 60))
	end
	if delta < 86400 then
		return string.format("%dh ago", math_floor(delta / 3600))
	end
	if delta < 604800 then
		return string.format("%dd ago", math_floor(delta / 86400))
	end
	return os.date("%b %d", timestamp)
end

local function shard(list, size)
	local out = {}
	for index = 1, #list, size do
		local chunk = {}
		for inner = index, math.min(index + size - 1, #list) do
			table.insert(chunk, list[inner])
		end
		table.insert(out, chunk)
	end
	return out
end

local function zip(first, second)
	local out = {}
	for index = 1, math.max(#first, #second) do
		table.insert(out, { first[index], second[index] })
	end
	return out
end

local function noop() end

local function once(fn)
	local called = false
	local result
	return function(...)
		if called then
			return result
		end
		called = true
		result = fn(...)
		return result
	end
end

local function debounce(fn, wait)
	local token = 0
	return function(...)
		local args = table.pack(...)
		token += 1
		local current = token
		task.delay(wait, function()
			if current == token then
				fn(table.unpack(args, 1, args.n))
			end
		end)
	end
end

local function throttle(fn, interval)
	local last = 0
	return function(...)
		local now = os.clock()
		if now - last >= interval then
			last = now
			fn(...)
		end
	end
end

local function uuid()
	local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
	return (string.gsub(template, "[xy]", function(char)
		local value = char == "x" and math.random(0, 15) or math.random(8, 11)
		return string.format("%x", value)
	end))
end

local function hash(text)
	local value = 5381
	for index = 1, #text do
		value = (value * 33 + string.byte(text, index)) % 2147483647
	end
	return value
end

local function export(source)
	local out = {}
	for key, value in source do
		if type(value) ~= "function" then
			out[key] = value
		end
	end
	return out
end

local function px(value)
	return UDim.new(0, value)
end

local function size(x, y)
	return UDim2.fromOffset(x, y or x)
end

local function scale(x, y)
	return UDim2.fromScale(x, y or x)
end

local function vec2(x, y)
	return Vector2.new(x, y or x)
end

local function deg(radians)
	return radians * 180 / math_pi
end

local function rad(degrees)
	return math_rad(degrees)
end

local function pythagoras(x, y)
	return math_sqrt(x * x + y * y)
end

local function distance(a, b)
	return (a - b).Magnitude
end

local function rotate(point, radians)
	local cosine = math_cos(radians)
	local sine = math_sin(radians)
	return Vector2.new(point.X * cosine - point.Y * sine, point.X * sine + point.Y * cosine)
end

local function to_hex(color)
	return string.format("#%02X%02X%02X", math_floor(color.R * 255 + 0.5), math_floor(color.G * 255 + 0.5), math_floor(color.B * 255 + 0.5))
end

local function from_hex(value)
	local clean = string.gsub(value, "#", "")
	if #clean == 3 then
		clean = string.rep(string.sub(clean, 1, 1), 2) .. string.rep(string.sub(clean, 2, 2), 2) .. string.rep(string.sub(clean, 3, 3), 2)
	end
	return Color3.fromHex(clean)
end

local function serialize(color)
	return { math_floor(color.R * 255 + 0.5), math_floor(color.G * 255 + 0.5), math_floor(color.B * 255 + 0.5) }
end

local function json_encode(value)
	local kind = type(value)
	if kind == "number" or kind == "boolean" then
		return tostring(value)
	elseif kind == "string" then
		return string.format("%q", value)
	elseif kind == "table" then
		if is_array(value) then
			local parts = map_array(value, json_encode)
			return "[" .. table.concat(parts, ",") .. "]"
		end
		local parts = {}
		for key, entry in value do
			table.insert(parts, string.format("%q", tostring(key)) .. ":" .. json_encode(entry))
		end
		return "{" .. table.concat(parts, ",") .. "}"
	end
	return "null"
end

local function json_decode(text, position)
	position = position or 1
	local index = position
	while index <= #text and string.match(string.sub(text, index, index), "%s") do
		index += 1
	end
	local char = string.sub(text, index, index)
	if char == "{" then
		local out = {}
		index += 1
		while true do
			while index <= #text and string.match(string.sub(text, index, index), "%s") do
				index += 1
			end
			if string.sub(text, index, index) == "}" then
				return out, index + 1
			end
			local key, next_index = json_decode(text, index)
			index = next_index
			while index <= #text and string.match(string.sub(text, index, index), "[%s:]") do
				index += 1
			end
			local value
			value, index = json_decode(text, index)
			out[key] = value
			while index <= #text and string.match(string.sub(text, index, index), "[%s,]") do
				index += 1
			end
		end
	elseif char == "[" then
		local out = {}
		index += 1
		while true do
			while index <= #text and string.match(string.sub(text, index, index), "%s") do
				index += 1
			end
			if string.sub(text, index, index) == "]" then
				return out, index + 1
			end
			local value
			value, index = json_decode(text, index)
			table.insert(out, value)
			while index <= #text and string.match(string.sub(text, index, index), "[%s,]") do
				index += 1
			end
		end
	elseif char == '"' then
		local out = ""
		index += 1
		while index <= #text do
			local current = string.sub(text, index, index)
			if current == "\\" then
				local escape_character = string.sub(text, index + 1, index + 1)
				if escape_character == "n" then
					out ..= "\n"
				elseif escape_character == "t" then
					out ..= "\t"
				elseif escape_character == '"' or escape_character == "\\" then
					out ..= escape_character
				else
					out ..= escape_character
				end
				index += 2
			elseif current == '"' then
				return out, index + 1
			else
				out ..= current
				index += 1
			end
		end
		return out, index
	else
		local start_index = index
		while index <= #text and string.match(string.sub(text, index, index), "[%w%.%-%+]") do
			index += 1
		end
		local token = string.sub(text, start_index, index - 1)
		if token == "true" then
			return true, index
		elseif token == "false" then
			return false, index
		elseif token == "null" then
			return nil, index
		end
		return tonumber(token), index
	end
end

utils.norm = norm
utils.kebab = kebab
utils.copy = copy
utils.keys = keys
utils.values = values
utils.count = count
utils.merge = merge
utils.deep_merge = deep_merge
utils.pick = pick
utils.omit = omit
utils.map = map
utils.map_array = map_array
utils.filter = filter
utils.find = find
utils.reduce = reduce
utils.contains = contains
utils.is_number = is_number
utils.is_array = is_array
utils.clamp = clamp
utils.clamp01 = clamp01
utils.lerp = lerp
utils.inverse_lerp = inverse_lerp
utils.remap = remap
utils.round = round
utils.sign = sign
utils.sum = sum
utils.max_of = max_of
utils.min_of = min_of
utils.average = average
utils.normalize = normalize
utils.comma = comma
utils.compact = compact
utils.percent = percent
utils.pad = pad
utils.split = split
utils.trim = trim
utils.starts_with = starts_with
utils.ends_with = ends_with
utils.wrap_text = wrap_text
utils.title_case = title_case
utils.signed = signed
utils.duration = duration
utils.relative_time = relative_time
utils.shard = shard
utils.zip = zip
utils.noop = noop
utils.once = once
utils.debounce = debounce
utils.throttle = throttle
utils.uuid = uuid
utils.hash = hash
utils.px = px
utils.size = size
utils.scale = scale
utils.vec2 = vec2
utils.deg = deg
utils.rad = rad
utils.pythagoras = pythagoras
utils.distance = distance
utils.rotate = rotate
utils.to_hex = to_hex
utils.from_hex = from_hex
utils.json_encode = json_encode
utils.json_decode = json_decode

local signal = {}
signal.__index = signal

local connection = {}
connection.__index = connection

local function create_signal()
	return setmetatable({ _handlers = {} }, signal)
end

function connection:disconnect()
	if not self._connected then
		return
	end
	self._connected = false
	local handlers = self._owner._handlers
	for index, entry in handlers do
		if entry == self then
			table.remove(handlers, index)
			break
		end
	end
end

function connection:is_connected()
	return self._connected
end

function signal:connect(fn)
	local handle = setmetatable({ _owner = self, _fn = fn, _connected = true }, connection)
	table.insert(self._handlers, handle)
	return handle
end

function signal:once(fn)
	local handle
	handle = self:connect(function(...)
		handle:disconnect()
		fn(...)
	end)
	return handle
end

function signal:wait()
	local thread = coroutine.running()
	local handle
	handle = self:connect(function(...)
		handle:disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function signal:fire(...)
	for _, handle in table.clone(self._handlers) do
		if handle._connected then
			pcall(handle._fn, ...)
		end
	end
end

function signal:clear()
	for _, handle in self._handlers do
		handle._connected = false
	end
	self._handlers = {}
end

function signal:count()
	return #self._handlers
end

function signal:destroy()
	self:clear()
end

local trove = {}
trove.__index = trove

local function create_trove()
	return setmetatable({ _tasks = {} }, trove)
end

function trove:add(item)
	table.insert(self._tasks, item)
	return item
end

function trove:connect(target, fn)
	return self:add(target:connect(fn))
end

function trove:bind(instance, event, fn)
	return self:add(instance[event]:Connect(fn))
end

function trove:thread(fn, ...)
	local thread = task.spawn(fn, ...)
	self:add(thread)
	return thread
end

function trove:delay(seconds, fn)
	return self:add(task.delay(seconds, fn))
end

function trove:dispose(item)
	for index, entry in self._tasks do
		if entry == item then
			table.remove(self._tasks, index)
			break
		end
	end
	self:release(item)
end

function trove:release(item)
	if typeof(item) == "RBXScriptConnection" then
		item:Disconnect()
	elseif typeof(item) == "Instance" then
		item:Destroy()
	elseif typeof(item) == "thread" then
		pcall(task.cancel, item)
	elseif type(item) == "table" then
		if type(item.destroy) == "function" then
			item:destroy()
		elseif type(item.disconnect) == "function" then
			item:disconnect()
		end
	end
end

function trove:destroy()
	local tasks = self._tasks
	self._tasks = {}
	for index = #tasks, 1, -1 do
		pcall(self.release, self, tasks[index])
	end
end

local state = {}

local function create_state(initial)
	local self = setmetatable({
		_value = initial,
		_changed = create_signal(),
		_silent = false,
	}, state)
	return self
end

function state:get()
	return self._value
end

function state:set(next)
	if self._value == next then
		return self._value
	end
	local previous = self._value
	self._value = next
	self._changed:fire(next, previous)
	return next
end

function state:update(fn)
	return self:set(fn(self._value))
end

function state:observe(fn, immediate)
	if immediate then
		fn(self._value, self._value)
	end
	return self._changed:connect(fn)
end

function state:map(fn)
	local derived = create_state(fn(self._value))
	self:observe(function(value)
		derived:set(fn(value))
	end)
	return derived
end

function state:silent(next)
	self._value = next
	return next
end

local store = {}
store.__index = store

local function create_store(options)
	options = options or {}
	local self = setmetatable({
		_value = options.initial or {},
		_changed = create_signal(),
		_middleware = options.middleware or {},
	}, store)
	return self
end

function store:get(key)
	if key == nil then
		return self._value
	end
	return self._value[key]
end

function store:set(key, value)
	local previous = self._value
	local next_state = copy(previous)
	if type(key) == "table" then
		next_state = deep_merge(previous, key)
		for _, entry in self._middleware do
			next_state = entry(next_state, previous) or next_state
		end
	else
		next_state[key] = value
		for _, entry in self._middleware do
			next_state = entry(next_state, previous) or next_state
		end
	end
	self._value = next_state
	self._changed:fire(self._value, previous)
	return self._value
end

function store:reset(value)
	local previous = self._value
	self._value = value or {}
	self._changed:fire(self._value, previous)
end

function store:observe(fn, immediate)
	if immediate then
		fn(self._value, self._value)
	end
	return self._changed:connect(fn)
end

function store:select(keys_wanted, fn)
	local previous
	return self:observe(function(value)
		local sliced = pick(value, table.unpack(keys_wanted))
		local changed = previous == nil or json_encode(sliced) ~= json_encode(previous)
		if changed then
			previous = sliced
			fn(sliced, value)
		end
	end, true)
end

 local color = {}

function color.rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

function color.hex(value)
	local clean = string.gsub(value, "#", "")
	if #clean == 3 then
		clean = string.rep(string.sub(clean, 1, 1), 2) .. string.rep(string.sub(clean, 2, 2), 2) .. string.rep(string.sub(clean, 3, 3), 2)
	end
	return Color3.fromHex(clean)
end

function color.to_hex(target)
	return string.format("#%02X%02X%02X", math_floor(target.R * 255 + 0.5), math_floor(target.G * 255 + 0.5), math_floor(target.B * 255 + 0.5))
end

function color.luminance(target)
	return target.R * 0.2126 + target.G * 0.7152 + target.B * 0.0722
end

function color.is_light(target)
	return color.luminance(target) > 0.58
end

function color.lighten(target, amount)
	return target:Lerp(Color3.new(1, 1, 1), clamp01(amount))
end

function color.darken(target, amount)
	return target:Lerp(Color3.new(0, 0, 0), clamp01(amount))
end

function color.mix(first, second, amount)
	return first:Lerp(second, clamp01(amount))
end

function color.alpha(target, amount)
	return Color3.new(target.R * amount, target.G * amount, target.B * amount)
end

function color.readable(target)
	if color.is_light(target) then
		return Color3.fromRGB(14, 14, 18)
	end
	return Color3.fromRGB(250, 250, 252)
end

function color.contrast(first, second)
	local high = math.max(color.luminance(first), color.luminance(second))
	local low = math.min(color.luminance(first), color.luminance(second))
	return (high + 0.05) / (low + 0.05)
end

function color.hover(target, amount)
	if color.is_light(target) then
		return color.darken(target, amount or 0.1)
	end
	return color.lighten(target, amount or 0.12)
end

function color.pressed(target, amount)
	if color.is_light(target) then
		return color.darken(target, amount or 0.18)
	end
	return color.lighten(target, amount or 0.2)
end

function color.ramp(base, steps)
	local out = {}
	for index = 1, steps do
		local amount = (index - 1) / math.max(1, steps - 1)
		out[index] = color.mix(color.darken(base, 0.45), color.lighten(base, 0.35), amount)
	end
	return out
end

function color.saturate(target, amount)
	local grey = color.luminance(target)
	return Color3.new(
		clamp01(grey + (target.R - grey) * (1 + amount)),
		clamp01(grey + (target.G - grey) * (1 + amount)),
		clamp01(grey + (target.B - grey) * (1 + amount))
	)
end

function color.hue(target, shift)
	local hue_value, saturation, value = Color3.toHSV(target)
	return Color3.fromHSV((hue_value + shift) % 1, saturation, value)
end

function color.sequence(steps)
	if type(steps) == "string" then
		steps = { steps }
	end
	local keypoints = {}
	local total = #steps
	for index, value in steps do
		table.insert(keypoints, ColorSequenceKeypoint.new(total > 1 and (index - 1) / (total - 1) or 0, typeof(value) == "string" and color.hex(value) or value))
	end
	return ColorSequence.new(keypoints)
end

local theme = {}

theme.tokens = {
	radius = { none = 0, xs = 3, sm = 6, md = 8, lg = 12, xl = 16, xxl = 22, full = 999 },
	space = { none = 0, ["3xs"] = 2, ["2xs"] = 4, xs = 6, sm = 8, md = 12, lg = 16, xl = 22, ["2xl"] = 30, ["3xl"] = 40 },
	type = { ["2xs"] = 10, xs = 11, sm = 12, md = 13, lg = 15, xl = 18, ["2xl"] = 22, ["3xl"] = 28, ["4xl"] = 36 },
	font = { sans = Enum.Font.Gotham, medium = Enum.Font.GothamMedium, bold = Enum.Font.GothamBold, black = Enum.Font.GothamBlack, mono = Enum.Font.Code, display = Enum.Font.GothamBlack },
	control = { height = 34, height_sm = 26, height_lg = 42, icon = 16, icon_sm = 14, icon_lg = 20, gap = 8 },
	layer = { base = 1, content = 2, raised = 3, header = 4, chrome = 5, dropdown = 40, drawer = 50, overlay = 60, dialog = 61, toast = 80, tooltip = 90 },
	stroke = { none = 0, hairline = 1, base = 1, heavy = 2 },
	motion = { instant = 0.06, fast = 0.12, base = 0.22, slow = 0.34, slower = 0.5, preset = "snappy" },
}

theme.palettes = {
	dark = {
		mode = "dark",
		colors = {
			background = Color3.fromRGB(11, 11, 13),
			foreground = Color3.fromRGB(246, 246, 248),
			card = Color3.fromRGB(18, 18, 21),
			card_foreground = Color3.fromRGB(243, 243, 246),
			popover = Color3.fromRGB(22, 22, 26),
			popover_foreground = Color3.fromRGB(243, 243, 246),
			primary = Color3.fromRGB(139, 122, 246),
			primary_foreground = Color3.fromRGB(12, 10, 24),
			secondary = Color3.fromRGB(38, 38, 44),
			secondary_foreground = Color3.fromRGB(232, 232, 238),
			muted = Color3.fromRGB(30, 30, 35),
			muted_foreground = Color3.fromRGB(148, 148, 160),
			accent = Color3.fromRGB(45, 45, 54),
			accent_foreground = Color3.fromRGB(244, 244, 248),
			destructive = Color3.fromRGB(226, 84, 96),
			destructive_foreground = Color3.fromRGB(255, 245, 246),
			success = Color3.fromRGB(84, 196, 138),
			success_foreground = Color3.fromRGB(8, 26, 16),
			warning = Color3.fromRGB(232, 174, 84),
			warning_foreground = Color3.fromRGB(34, 22, 4),
			info = Color3.fromRGB(108, 168, 240),
			info_foreground = Color3.fromRGB(6, 20, 34),
			border = Color3.fromRGB(44, 44, 52),
			border_strong = Color3.fromRGB(68, 68, 80),
			input = Color3.fromRGB(26, 26, 31),
			ring = Color3.fromRGB(139, 122, 246),
			overlay = Color3.fromRGB(4, 4, 6),
			shadow = Color3.fromRGB(0, 0, 0),
			highlight = Color3.fromRGB(255, 255, 255),
			grid = Color3.fromRGB(36, 36, 43),
			sidebar = Color3.fromRGB(14, 14, 17),
			chart_1 = Color3.fromRGB(139, 122, 246),
			chart_2 = Color3.fromRGB(84, 196, 168),
			chart_3 = Color3.fromRGB(232, 174, 84),
			chart_4 = Color3.fromRGB(226, 108, 150),
			chart_5 = Color3.fromRGB(108, 168, 240),
			chart_6 = Color3.fromRGB(150, 150, 170),
		},
		alpha = { overlay = 0.68, shadow = 0.5, hover = 0.06, pressed = 0.12, disabled = 0.45, ghost = 0.03, border = 0.9, glass = 0.86, highlight = 0.06, area = 0.82 },
	},
	light = {
		mode = "light",
		colors = {
			background = Color3.fromRGB(250, 250, 251),
			foreground = Color3.fromRGB(16, 16, 20),
			card = Color3.fromRGB(255, 255, 255),
			card_foreground = Color3.fromRGB(20, 20, 26),
			popover = Color3.fromRGB(255, 255, 255),
			popover_foreground = Color3.fromRGB(20, 20, 26),
			primary = Color3.fromRGB(118, 98, 240),
			primary_foreground = Color3.fromRGB(253, 253, 255),
			secondary = Color3.fromRGB(238, 238, 242),
			secondary_foreground = Color3.fromRGB(38, 38, 48),
			muted = Color3.fromRGB(242, 242, 246),
			muted_foreground = Color3.fromRGB(110, 110, 126),
			accent = Color3.fromRGB(233, 233, 240),
			accent_foreground = Color3.fromRGB(24, 24, 32),
			destructive = Color3.fromRGB(214, 58, 70),
			destructive_foreground = Color3.fromRGB(255, 255, 255),
			success = Color3.fromRGB(34, 158, 94),
			success_foreground = Color3.fromRGB(255, 255, 255),
			warning = Color3.fromRGB(204, 138, 30),
			warning_foreground = Color3.fromRGB(255, 255, 255),
			info = Color3.fromRGB(46, 116, 212),
			info_foreground = Color3.fromRGB(255, 255, 255),
			border = Color3.fromRGB(224, 224, 232),
			border_strong = Color3.fromRGB(196, 196, 208),
			input = Color3.fromRGB(246, 246, 249),
			ring = Color3.fromRGB(118, 98, 240),
			overlay = Color3.fromRGB(24, 24, 32),
			shadow = Color3.fromRGB(110, 110, 130),
			highlight = Color3.fromRGB(255, 255, 255),
			grid = Color3.fromRGB(234, 234, 240),
			sidebar = Color3.fromRGB(248, 248, 250),
			chart_1 = Color3.fromRGB(118, 98, 240),
			chart_2 = Color3.fromRGB(34, 168, 148),
			chart_3 = Color3.fromRGB(214, 146, 34),
			chart_4 = Color3.fromRGB(216, 68, 108),
			chart_5 = Color3.fromRGB(46, 116, 212),
			chart_6 = Color3.fromRGB(140, 140, 155),
		},
		alpha = { overlay = 0.32, shadow = 0.12, hover = 0.05, pressed = 0.1, disabled = 0.4, ghost = 0.02, border = 0.85, glass = 0.9, highlight = 0.7, area = 0.85 },
	},
	midnight = {
		mode = "dark",
		colors = {
			background = Color3.fromRGB(8, 10, 18),
			card = Color3.fromRGB(14, 17, 28),
			popover = Color3.fromRGB(17, 21, 34),
			primary = Color3.fromRGB(96, 150, 255),
			primary_foreground = Color3.fromRGB(4, 10, 22),
			secondary = Color3.fromRGB(28, 34, 52),
			muted = Color3.fromRGB(22, 27, 42),
			accent = Color3.fromRGB(34, 42, 62),
			border = Color3.fromRGB(34, 40, 58),
			input = Color3.fromRGB(20, 25, 40),
			ring = Color3.fromRGB(96, 150, 255),
			grid = Color3.fromRGB(28, 34, 52),
		},
	},
	rose = {
		mode = "dark",
		colors = {
			background = Color3.fromRGB(16, 10, 13),
			card = Color3.fromRGB(24, 15, 20),
			popover = Color3.fromRGB(28, 18, 23),
			primary = Color3.fromRGB(238, 110, 150),
			primary_foreground = Color3.fromRGB(30, 6, 16),
			secondary = Color3.fromRGB(44, 26, 34),
			muted = Color3.fromRGB(36, 22, 29),
			accent = Color3.fromRGB(52, 32, 41),
			border = Color3.fromRGB(52, 33, 42),
			input = Color3.fromRGB(30, 19, 25),
			ring = Color3.fromRGB(238, 110, 150),
		},
	},
	emerald = {
		mode = "dark",
		colors = {
			background = Color3.fromRGB(8, 14, 12),
			card = Color3.fromRGB(13, 21, 18),
			popover = Color3.fromRGB(15, 25, 21),
			primary = Color3.fromRGB(74, 208, 148),
			primary_foreground = Color3.fromRGB(4, 24, 16),
			secondary = Color3.fromRGB(24, 38, 33),
			muted = Color3.fromRGB(19, 31, 27),
			accent = Color3.fromRGB(29, 46, 40),
			border = Color3.fromRGB(30, 47, 41),
			input = Color3.fromRGB(17, 28, 24),
			ring = Color3.fromRGB(74, 208, 148),
		},
	},
	nord = {
		mode = "dark",
		colors = {
			background = Color3.fromRGB(19, 23, 30),
			card = Color3.fromRGB(25, 30, 39),
			popover = Color3.fromRGB(28, 34, 44),
			primary = Color3.fromRGB(136, 192, 208),
			primary_foreground = Color3.fromRGB(12, 18, 24),
			secondary = Color3.fromRGB(38, 46, 59),
			muted = Color3.fromRGB(32, 39, 50),
			accent = Color3.fromRGB(43, 52, 66),
			border = Color3.fromRGB(45, 54, 68),
			input = Color3.fromRGB(29, 35, 45),
			ring = Color3.fromRGB(136, 192, 208),
		},
	},
	cyber = {
		mode = "dark",
		colors = {
			background = Color3.fromRGB(10, 11, 14),
			card = Color3.fromRGB(16, 18, 22),
			popover = Color3.fromRGB(19, 22, 27),
			primary = Color3.fromRGB(126, 231, 226),
			primary_foreground = Color3.fromRGB(4, 20, 22),
			secondary = Color3.fromRGB(30, 35, 42),
			muted = Color3.fromRGB(24, 28, 34),
			accent = Color3.fromRGB(36, 42, 50),
			border = Color3.fromRGB(38, 43, 52),
			input = Color3.fromRGB(21, 25, 30),
			ring = Color3.fromRGB(126, 231, 226),
			success = Color3.fromRGB(126, 231, 162),
		},
	},
	amber = {
		mode = "light",
		colors = {
			background = Color3.fromRGB(252, 249, 243),
			card = Color3.fromRGB(255, 253, 249),
			popover = Color3.fromRGB(255, 253, 249),
			primary = Color3.fromRGB(206, 122, 26),
			primary_foreground = Color3.fromRGB(255, 250, 242),
			secondary = Color3.fromRGB(244, 235, 222),
			muted = Color3.fromRGB(246, 239, 229),
			accent = Color3.fromRGB(238, 226, 208),
			border = Color3.fromRGB(230, 216, 196),
			input = Color3.fromRGB(248, 242, 233),
			ring = Color3.fromRGB(206, 122, 26),
		},
	},
}

theme.brand_defaults = {
	logo = nil,
	logo_size = 22,
	logo_radius = 6,
	logo_fit = "contain",
	logo_color = nil,
	wordmark = nil,
	show_wordmark = true,
	wordmark_size = 14,
	gap = 8,
	placement = {
		navbar = true,
		sidebar = true,
		dialog = false,
		command = true,
		drawer = false,
		toast = false,
		splash = true,
		card_header = false,
	},
}

local function resolve(source, key)
	if source == nil or key == nil then
		return nil
	end
	if type(key) ~= "string" then
		return key
	end
	if source[key] ~= nil then
		return source[key]
	end
	local current = source
	for _, piece in split(key, ".") do
		if type(current) ~= "table" then
			return nil
		end
		current = current[piece]
	end
	return current
end

local active_theme

local function build_theme(options)
	options = options or {}
	local palette = theme.palettes[options.palette or options.preset or "dark"] or theme.palettes.dark
	local fallback = theme.palettes[palette.mode] or theme.palettes.dark
	local merged = {
		name = options.name or options.preset or options.palette or palette.mode or "dark",
		mode = options.mode or palette.mode or "dark",
		colors = deep_merge(fallback.colors, palette.colors, options.colors or {}),
		alpha = deep_merge(fallback.alpha, palette.alpha, options.alpha or {}),
		radius = deep_merge(theme.tokens.radius, options.radius or {}),
		space = deep_merge(theme.tokens.space, options.space or {}),
		type = deep_merge(theme.tokens.type, options.type or {}),
		font = deep_merge(theme.tokens.font, options.font or {}),
		control = deep_merge(theme.tokens.control, options.control or {}),
		layer = deep_merge(theme.tokens.layer, options.layer or {}),
		stroke = deep_merge(theme.tokens.stroke, options.stroke or {}),
		motion = deep_merge(theme.tokens.motion, options.motion or {}),
		brand = deep_merge(theme.brand_defaults, options.brand or {}),
	}

	function merged.color(key)
		return resolve(merged.colors, key) or merged.colors.foreground
	end

	function merged.alpha_value(key)
		return resolve(merged.alpha, key) or 1
	end

	function merged.radius_of(key)
		return resolve(merged.radius, key) or merged.radius.md
	end

	function merged.space_of(key)
		return resolve(merged.space, key) or merged.space.sm
	end

	function merged.type_of(key)
		return resolve(merged.type, key) or merged.type.md
	end

	function merged.font_of(key)
		return resolve(merged.font, key) or merged.font.sans
	end

	function merged.layer_of(key)
		return resolve(merged.layer, key) or merged.layer.base
	end

	function merged.is_dark()
		return merged.mode == "dark"
	end

	function merged.blend(key, amount)
		return color.alpha(merged.color(key), amount)
	end

	function merged.surface(key)
		return merged.colors[key] or merged.colors.card
	end

	function merged.extend(overrides)
		return build_theme(deep_merge(merged, overrides or {}))
	end

	function merged.clone()
		local copy_theme = build_theme({
			name = merged.name,
			mode = merged.mode,
			colors = deep_merge(merged.colors, {}),
			alpha = deep_merge(merged.alpha, {}),
			brand = deep_merge(merged.brand, {}),
		})
		return copy_theme
	end

	function merged.blend_to(other, amount)
		local colors = {}
		for key, value in merged.colors do
			local target = other.colors[key]
			if typeof(value) == "Color3" and typeof(target) == "Color3" then
				colors[key] = value:Lerp(target, clamp01(amount))
			else
				colors[key] = target or value
			end
		end
		return build_theme({ name = merged.name, mode = merged.mode, colors = colors, alpha = merged.alpha, brand = merged.brand })
	end

	return merged
end

theme.build = build_theme
theme.resolve = resolve
theme.changed = create_signal()
theme.registry = {}

function theme.register(name, palette)
	theme.palettes[name] = deep_merge(theme.palettes.dark, palette)
	theme.registry[name] = theme.palettes[name]
	return theme.palettes[name]
end

function theme.set(options)
	local next_theme = typeof(options) == "string" and build_theme({ palette = options }) or (options and options.color and build_theme(options))
	if not next_theme then
		next_theme = build_theme(options)
	end
	if active_theme and active_theme.brand then
		next_theme.brand = deep_merge(active_theme.brand, (typeof(options) == "table" and options.brand) or {})
	end
	active_theme = next_theme
	theme.changed:fire(active_theme)
	return active_theme
end

function theme.get()
	if not active_theme then
		active_theme = build_theme({ palette = "dark" })
	end
	return active_theme
end

active_theme = build_theme({ palette = "dark" })

local brand = {}

function brand.configure(options)
	local current_theme = theme.get()
	current_theme.brand = deep_merge(current_theme.brand, options or {})
	return current_theme.brand
end

function brand.set_logo(logo)
	return brand.configure({ logo = logo })
end

function brand.set_wordmark(text)
	return brand.configure({ wordmark = text })
end

function brand.clear()
	return brand.configure({ logo = nil, wordmark = nil })
end

function brand.get()
	return theme.get().brand
end

function brand.has_logo()
	return theme.get().brand.logo ~= nil
end

function brand.enabled_for(slot)
	local config = theme.get().brand
	return config.logo ~= nil and config.placement[slot] ~= false
end

function brand.merge(options)
	return deep_merge(theme.get().brand, options or {})
end

function brand.measure(options)
	local config = brand.merge(options)
	if config.logo == nil then
		return 0, 0
	end
	local mark = config.logo_size or 22
	if config.wordmark and config.show_wordmark ~= false then
		local width = #tostring(config.wordmark) * (config.wordmark_size or 14) * 0.55 + mark + (config.gap or 8)
		return width, mark
	end
	return mark, mark
end

local tween_service = game:GetService("TweenService")
local run_service = game:GetService("RunService")

local spring = {}
spring.__index = spring

function spring.new(options, initial)
	local self
	self = setmetatable({
		value = initial or 0,
		target = initial or 0,
		velocity = 0,
		stiffness = (options and options.stiffness) or 260,
		damping = (options and options.damping) or 26,
		mass = (options and options.mass) or 1,
		precision = (options and options.precision) or 0.001,
	}, spring)
	return self
end

function spring:set_target(value)
	self.target = value
	return self
end

function spring:set(value)
	self.value = value
	self.target = value
	self.velocity = 0
	return self
end

function spring:impulse(force)
	self.velocity += force
	return self
end

function spring:step(dt)
	dt = math.min(dt, 1 / 30)
	local displacement = self.value - self.target
	local acceleration = (-self.stiffness * displacement - self.damping * self.velocity) / self.mass
	self.velocity += acceleration * dt
	self.value += self.velocity * dt
	if math_abs(self.velocity) < self.precision and math_abs(displacement) < self.precision then
		self.value = self.target
		self.velocity = 0
		return true
	end
	return false
end

function spring:settled()
	return math_abs(self.velocity) <= self.precision and math_abs(self.target - self.value) <= self.precision
end

local spring_presets = {
	snappy = { stiffness = 320, damping = 26, mass = 1 },
	smooth = { stiffness = 190, damping = 24, mass = 1 },
	gentle = { stiffness = 130, damping = 22, mass = 1 },
	bouncy = { stiffness = 420, damping = 18, mass = 1 },
	precise = { stiffness = 500, damping = 34, mass = 1 },
	heavy = { stiffness = 180, damping = 30, mass = 1.6 },
	lazy = { stiffness = 90, damping = 20, mass = 1 },
}

local easing_styles = {
	linear = Enum.EasingStyle.Linear,
	sine = Enum.EasingStyle.Sine,
	quad = Enum.EasingStyle.Quad,
	cubic = Enum.EasingStyle.Cubic,
	quart = Enum.EasingStyle.Quart,
	quint = Enum.EasingStyle.Quint,
	exponential = Enum.EasingStyle.Exponential,
	circular = Enum.EasingStyle.Circular,
	back = Enum.EasingStyle.Back,
	bounce = Enum.EasingStyle.Bounce,
	elastic = Enum.EasingStyle.Elastic,
}

local easing_directions = {
	["in"] = Enum.EasingDirection.In,
	out = Enum.EasingDirection.Out,
	["in-out"] = Enum.EasingDirection.InOut,
	inout = Enum.EasingDirection.InOut,
}

local animation = {}

local tracked = {}
local pump_connection

local function pump(dt)
	for index = #tracked, 1, -1 do
		local entry = tracked[index]
		if entry:step(dt) then
			table.remove(tracked, index)
		end
	end
	if #tracked == 0 and pump_connection then
		pump_connection:Disconnect()
		pump_connection = nil
	end
end

local function track(item)
	table.insert(tracked, item)
	if not pump_connection then
		pump_connection = run_service.Heartbeat:Connect(pump)
	end
end

local function untrack(item)
	for index, entry in tracked do
		if entry == item then
			table.remove(tracked, index)
			break
		end
	end
end

function animation.spring_preset(name)
	return copy(spring_presets[name or "snappy"] or spring_presets.snappy)
end

function animation.ease_style(name)
	return easing_styles[name or "quad"] or Enum.EasingStyle.Quad
end

function animation.ease_direction(name)
	return easing_directions[name or "out"] or Enum.EasingDirection.Out
end

function animation.info(options)
	options = options or {}
	return TweenInfo.new(
		options.duration or options.time or 0.25,
		animation.ease_style(options.ease),
		animation.ease_direction(options.direction),
		options.repeat_count or 0,
		options.reverses or false,
		options.delay or 0
	)
end

function animation.tween(instance, goals, options)
	local tween = tween_service:Create(instance, animation.info(options), goals)
	tween:Play()
	return tween
end

function animation.cancel(instance, property)
	local tweens = tween_service:GetTweens(instance)
	for _, tween in tweens do
		if not property then
			tween:Cancel()
		end
	end
	return instance
end

function animation.spring(options)
	options = options or {}
	local config = options.config or animation.spring_preset(options.preset)
	local from_value = options.from or 0
	local to_value = options.to or 0
	local on_step = options.on_step
	local on_done = options.on_done
	local engine = spring.new(config, 0)
	engine.target = 1

	local controller = { _stopped = false, _engine = engine, _from = from_value, _to = to_value, settled = create_signal() }

	function controller:step(dt)
		if self._stopped then
			return true
		end
		local done = self._engine:step(dt)
		local alpha = clamp01(self._engine.value)
		if on_step then
			on_step(lerp(self._from, self._to, alpha), alpha)
		end
		if done then
			if on_done then
				on_done()
			end
			self.settled:fire()
			return true
		end
		return false
	end

	function controller:stop()
		self._stopped = true
		untrack(self)
	end

	function controller:retarget(value)
		self._from = lerp(self._from, self._to, clamp01(self._engine.value))
		self._to = value
		self._engine.value = 0
		self._engine.velocity = 0
		self._engine.target = 1
		if not contains(tracked, self) then
			track(self)
		end
		return self
	end

	function controller:jump(value)
		self._stopped = true
		untrack(self)
		if on_step then
			on_step(value, 1)
		end
		if on_done then
			on_done()
		end
		return self
	end

	function controller:destroy()
		self:stop()
		self.settled:clear()
	end

	track(controller)
	return controller
end

function animation.tween_value(from, to, options, on_step)
	local controller = animation.spring(merge(options or {}, {
		from = from,
		to = to,
		on_step = on_step,
	}))
	return controller
end

function animation.next_frame(fn)
	return run_service.RenderStepped:Once(fn)
end

function animation.next_heartbeat(fn)
	return run_service.Heartbeat:Once(fn)
end

function animation.delay(seconds, fn)
	return task.delay(seconds, fn)
end

function animation.sequence(steps)
	local index = 1
	local function run_step()
		local step = steps[index]
		if not step then
			return
		end
		if step.wait then
			task.delay(step.wait, function()
				index += 1
				run_step()
			end)
			return
		end
		if step.set then
			step.set(0)
		end
		local controller = animation.spring({
			from = 0,
			to = 1,
			preset = step.preset,
			on_step = step.set,
			on_done = function()
				if step.done then
					step.done()
				end
				index += 1
				run_step()
			end,
		})
		return controller
	end
	return run_step()
end

function animation.shake(instance, options)
	options = options or {}
	local origin = instance.Position
	local magnitude = options.magnitude or 10
	local duration = options.duration or 0.45
	local frequency = options.frequency or 46
	local elapsed = 0
	local connection
	local finished = create_signal()
	connection = run_service.RenderStepped:Connect(function(dt)
		elapsed += dt
		local progress = clamp01(elapsed / duration)
		local falloff = (1 - progress) * (1 - progress)
		instance.Position = origin
			+ UDim2.fromOffset(math_sin(elapsed * frequency) * magnitude * falloff, math_cos(elapsed * frequency * 1.27) * magnitude * falloff * 0.6)
		if progress >= 1 then
			instance.Position = origin
			connection:Disconnect()
			finished:fire()
		end
	end)
	return {
		stop = function()
			if connection.Connected then
				connection:Disconnect()
				instance.Position = origin
			end
		end,
		settled = finished,
	}
end

function animation.pulse(instance, options)
	options = options or {}
	local base = instance.Size
	local peak = options.peak or 1.12
	local growing = true
	return animation.spring({
		from = 1,
		to = peak,
		preset = options.preset or "bouncy",
		on_step = function(value)
			instance.Size = UDim2.new(base.X.Scale * value, base.X.Offset * value, base.Y.Scale * value, base.Y.Offset * value)
		end,
		on_done = function()
			if growing then
				growing = false
				animation.spring({
					from = peak,
					to = 1,
					preset = options.preset or "bouncy",
					on_step = function(value)
						instance.Size = UDim2.new(base.X.Scale * value, base.X.Offset * value, base.Y.Scale * value, base.Y.Offset * value)
					end,
					on_done = options.on_done,
				})
			elseif options.on_done then
				options.on_done()
			end
		end,
	})
end

function animation.number(label, from, to, options)
	options = options or {}
	local formatter = options.format or function(value)
		return comma(value, options.digits or 0)
	end
	return animation.spring({
		from = from,
		to = to,
		preset = options.preset or "smooth",
		on_step = function(value)
			label.Text = formatter(value)
		end,
		on_done = function()
			label.Text = formatter(to)
		end,
	})
end

function animation.stop_all()
	for _, entry in copy(tracked) do
		entry:stop()
	end
	tracked = {}
end

local path = {}

local command_pattern = "([MmLlHhVvCcSsQqTtAaZz])%s*([^MmLlHhVvCcSsQqTtAaZz]*)"

local function parse_numbers(text)
	local out = {}
	for value in string.gmatch(text, "%-?%d*%.?%d+") do
		table.insert(out, tonumber(value))
	end
	return out
end

local function unit_clamp(value)
	if value < -1 then
		return -1
	elseif value > 1 then
		return 1
	end
	return value
end

local function signed_angle(ux, uy, vx, vy)
	local dot = ux * vx + uy * vy
	local lengths = math_sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy))
	local value = math.acos(unit_clamp(dot / lengths))
	if ux * vy - uy * vx < 0 then
		return -value
	end
	return value
end

local function append_cubic(out, x0, y0, x1, y1, x2, y2, x3, y3)
	local length = math_sqrt((x3 - x0) ^ 2 + (y3 - y0) ^ 2)
	local segments = math_clamp(math.ceil(length / 3), 3, 24)
	for index = 1, segments do
		local t = index / segments
		local inverse = 1 - t
		local a = inverse * inverse * inverse
		local b = 3 * inverse * inverse * t
		local c = 3 * inverse * t * t
		local d = t * t * t
		table.insert(out, vec2(a * x0 + b * x1 + c * x2 + d * x3, a * y0 + b * y1 + c * y2 + d * y3))
	end
end

local function append_arc(out, x0, y0, rx, ry, rotation, large, sweep, x1, y1)
	if rx == 0 or ry == 0 or (x0 == x1 and y0 == y1) then
		table.insert(out, vec2(x1, y1))
		return
	end

	local phi = rad(rotation)
	local cosine_phi = math_cos(phi)
	local sine_phi = math_sin(phi)
	local dx = (x0 - x1) / 2
	local dy = (y0 - y1) / 2
	local px = cosine_phi * dx + sine_phi * dy
	local py = -sine_phi * dx + cosine_phi * dy

	local rxs = rx * rx
	local rys = ry * ry
	local pxs = px * px
	local pys = py * py
	local denominator = rxs * pys + rys * pxs
	local coefficient = 0
	if denominator ~= 0 then
		coefficient = math_sqrt(math.max(0, (rxs * rys - rxs * pys - rys * pxs) / denominator))
	end
	if large == sweep then
		coefficient = -coefficient
	end

	local cxp = coefficient * rx * py / ry
	local cyp = -coefficient * ry * px / rx
	local center_x = cosine_phi * cxp - sine_phi * cyp + (x0 + x1) / 2
	local center_y = sine_phi * cxp + cosine_phi * cyp + (y0 + y1) / 2

	local ux = (px - cxp) / rx
	local uy = (py - cyp) / ry
	local vx = (-px - cxp) / rx
	local vy = (-py - cyp) / ry

	local theta = signed_angle(1, 0, ux, uy)
	local delta = signed_angle(ux, uy, vx, vy)
	if not sweep and delta > 0 then
		delta -= math_pi * 2
	elseif sweep and delta < 0 then
		delta += math_pi * 2
	end

	local steps = math_clamp(math.ceil(math_abs(delta) / (math_pi / 2)), 1, 8)
	local increment = delta / steps
	local function point(t)
		return vec2(center_x + cosine_phi * rx * math_cos(t) - sine_phi * ry * math_sin(t), center_y + sine_phi * rx * math_cos(t) + cosine_phi * ry * math_sin(t))
	end

	for index = 0, steps - 1 do
		local t1 = theta + index * increment
		local t2 = t1 + increment
		local alpha = 4 / 3 * math.tan((t2 - t1) / 4)
		local start_point = point(t1)
		local end_point = point(t2)
		local start_tangent = vec2(-math_sin(t1), math_cos(t1))
		local end_tangent = vec2(-math_sin(t2), math_cos(t2))
		append_cubic(
			out,
			start_point.X,
			start_point.Y,
			start_point.X + alpha * rx * (cosine_phi * start_tangent.X - sine_phi * start_tangent.Y),
			start_point.Y + alpha * ry * (sine_phi * start_tangent.X + cosine_phi * start_tangent.Y),
			end_point.X - alpha * rx * (cosine_phi * end_tangent.X - sine_phi * end_tangent.Y),
			end_point.Y - alpha * ry * (sine_phi * end_tangent.X + cosine_phi * end_tangent.Y),
			end_point.X,
			end_point.Y
		)
	end
end

function path.flatten(source)
	local polylines = {}
	local current
	local x, y = 0, 0
	local start_x, start_y = 0, 0
	local last_control
	local last_command

	local function ensure()
		if not current then
			current = { vec2(x, y) }
			table.insert(polylines, current)
		end
		return current
	end

	for command, body in string.gmatch(source, command_pattern) do
		local upper = string.upper(command)
		local relative = command ~= upper
		local values = parse_numbers(body)

		if upper == "M" then
			for index = 1, #values, 2 do
				x = values[index] + (relative and x or 0)
				y = values[index + 1] + (relative and y or 0)
				if index == 1 then
					current = { vec2(x, y) }
					table.insert(polylines, current)
					start_x, start_y = x, y
				else
					ensure()
					table.insert(current, vec2(x, y))
				end
			end
		elseif upper == "L" then
			for index = 1, #values, 2 do
				x = values[index] + (relative and x or 0)
				y = values[index + 1] + (relative and y or 0)
				ensure()
				table.insert(current, vec2(x, y))
			end
		elseif upper == "H" then
			for _, value in values do
				x = value + (relative and x or 0)
				ensure()
				table.insert(current, vec2(x, y))
			end
		elseif upper == "V" then
			for _, value in values do
				y = value + (relative and y or 0)
				ensure()
				table.insert(current, vec2(x, y))
			end
		elseif upper == "C" then
			for index = 1, #values, 6 do
				local c1x = values[index] + (relative and x or 0)
				local c1y = values[index + 1] + (relative and y or 0)
				local c2x = values[index + 2] + (relative and x or 0)
				local c2y = values[index + 3] + (relative and y or 0)
				local ex = values[index + 4] + (relative and x or 0)
				local ey = values[index + 5] + (relative and y or 0)
				ensure()
				append_cubic(current, x, y, c1x, c1y, c2x, c2y, ex, ey)
				last_control = vec2(c2x, c2y)
				x, y = ex, ey
			end
		elseif upper == "S" then
			for index = 1, #values, 4 do
				local c1x, c1y = x, y
				if (last_command == "C" or last_command == "S") and last_control then
					c1x = x * 2 - last_control.X
					c1y = y * 2 - last_control.Y
				end
				local c2x = values[index] + (relative and x or 0)
				local c2y = values[index + 1] + (relative and y or 0)
				local ex = values[index + 2] + (relative and x or 0)
				local ey = values[index + 3] + (relative and y or 0)
				ensure()
				append_cubic(current, x, y, c1x, c1y, c2x, c2y, ex, ey)
				last_control = vec2(c2x, c2y)
				x, y = ex, ey
			end
		elseif upper == "Q" then
			for index = 1, #values, 4 do
				local qx = values[index] + (relative and x or 0)
				local qy = values[index + 1] + (relative and y or 0)
				local ex = values[index + 2] + (relative and x or 0)
				local ey = values[index + 3] + (relative and y or 0)
				ensure()
				append_cubic(current, x, y, x + 2 / 3 * (qx - x), y + 2 / 3 * (qy - y), ex + 2 / 3 * (qx - ex), ey + 2 / 3 * (qy - ey), ex, ey)
				last_control = vec2(qx, qy)
				x, y = ex, ey
			end
		elseif upper == "T" then
			for index = 1, #values, 2 do
				local qx, qy = x, y
				if (last_command == "Q" or last_command == "T") and last_control then
					qx = x * 2 - last_control.X
					qy = y * 2 - last_control.Y
				end
				local ex = values[index] + (relative and x or 0)
				local ey = values[index + 1] + (relative and y or 0)
				ensure()
				append_cubic(current, x, y, x + 2 / 3 * (qx - x), y + 2 / 3 * (qy - y), ex + 2 / 3 * (qx - ex), ey + 2 / 3 * (qy - ey), ex, ey)
				last_control = vec2(qx, qy)
				x, y = ex, ey
			end
		elseif upper == "A" then
			for index = 1, #values, 7 do
				local rx = values[index]
				local ry = values[index + 1]
				local rotation = values[index + 2]
				local large = values[index + 3] ~= 0
				local sweep = values[index + 4] ~= 0
				local ex = values[index + 5] + (relative and x or 0)
				local ey = values[index + 6] + (relative and y or 0)
				ensure()
				append_arc(current, x, y, rx, ry, rotation, large, sweep, ex, ey)
				x, y = ex, ey
			end
		elseif upper == "Z" then
			if current then
				table.insert(current, vec2(start_x, start_y))
			end
			x, y = start_x, start_y
		end

		if upper ~= "C" and upper ~= "S" and upper ~= "Q" and upper ~= "T" then
			last_control = nil
		end
		last_command = upper
	end

	local cleaned = {}
	for _, polyline in polylines do
		if #polyline > 1 then
			table.insert(cleaned, polyline)
		end
	end
	return cleaned
end

function path.points(source)
	local values = parse_numbers(source)
	local out = {}
	for index = 1, #values, 2 do
		table.insert(out, vec2(values[index], values[index + 1]))
	end
	return out
end

function path.arc(center_x, center_y, radius, start_angle, end_angle, segments)
	local span = end_angle - start_angle
	segments = segments or math_clamp(math.ceil(math_abs(span) / 0.22), 4, 128)
	local out = {}
	for index = 0, segments do
		local angle = start_angle + span * (index / segments)
		table.insert(out, vec2(center_x + math_cos(angle) * radius, center_y + math_sin(angle) * radius))
	end
	return out
end

function path.circle(center_x, center_y, radius, segments)
	return path.arc(center_x, center_y, radius, 0, math_pi * 2, segments or math_clamp(math.ceil(radius * 4), 12, 96))
end

function path.rounded_rect(x, y, width, height, radius)
	local limit = math.min(radius, math.min(width, height) / 2)
	local points = {}
	local corners = {
		{ x + width - limit, y + limit, -math_pi / 2, 0 },
		{ x + width - limit, y + height - limit, 0, math_pi / 2 },
		{ x + limit, y + height - limit, math_pi / 2, math_pi },
		{ x + limit, y + limit, math_pi, math_pi * 1.5 },
	}
	for _, corner in corners do
		for _, point in path.arc(corner[1], corner[2], limit, corner[3], corner[4], 5) do
			table.insert(points, point)
		end
	end
	return points
end

function path.ellipse(center_x, center_y, radius_x, radius_y, segments)
	segments = segments or 32
	local out = {}
	for index = 0, segments - 1 do
		local angle = index / segments * math_pi * 2
		table.insert(out, vec2(center_x + math_cos(angle) * radius_x, center_y + math_sin(angle) * radius_y))
	end
	return out
end

function path.star(center_x, center_y, outer, inner, count_points)
	local out = {}
	local total = (count_points or 5) * 2
	for index = 0, total - 1 do
		local radius = index % 2 == 0 and outer or inner
		local angle = -math_pi / 2 + index / total * math_pi * 2
		table.insert(out, vec2(center_x + math_cos(angle) * radius, center_y + math_sin(angle) * radius))
	end
	return out
end

function path.line(x1, y1, x2, y2)
	return { vec2(x1, y1), vec2(x2, y2) }
end

function path.smooth(points, tension)
	if #points < 3 then
		return copy(points)
	end
	tension = tension or 0.2
	local out = { points[1] }
	for index = 1, #points - 1 do
		local previous = points[math.max(1, index - 1)]
		local current = points[index]
		local following = points[math.min(#points, index + 1)]
		local target = points[index + 1]
		local after = points[math.min(#points, index + 2)]
		local c1 = vec2(current.X + (following.X - previous.X) * tension, current.Y + (following.Y - previous.Y) * tension)
		local c2 = vec2(target.X - (after.X - current.X) * tension, target.Y - (after.Y - current.Y) * tension)
		append_cubic(out, current.X, current.Y, c1.X, c1.Y, c2.X, c2.Y, target.X, target.Y)
	end
	return out
end

function path.bounds(polylines)
	local min_x, min_y = math_huge, math_huge
	local max_x, max_y = -math_huge, -math_huge
	for _, polyline in polylines do
		for _, point in polyline do
			min_x = math.min(min_x, point.X)
			min_y = math.min(min_y, point.Y)
			max_x = math.max(max_x, point.X)
			max_y = math.max(max_y, point.Y)
		end
	end
	return min_x, min_y, max_x, max_y
end

function path.transform(polylines, scale_by, offset)
	scale_by = scale_by or 1
	offset = offset or Vector2.zero
	local out = {}
	for _, polyline in polylines do
		local copy_points = table.create(#polyline)
		for index, point in polyline do
			copy_points[index] = vec2(point.X * scale_by + offset.X, point.Y * scale_by + offset.Y)
		end
		table.insert(out, copy_points)
	end
	return out
end

function path.fit(polylines, size_value, padding_value)
	local min_x, min_y, max_x, max_y = path.bounds(polylines)
	local width = math.max(1e-4, max_x - min_x)
	local height = math.max(1e-4, max_y - min_y)
	local inner = size_value - (padding_value or 0) * 2
	local scale_by = math.min(inner / width, inner / height)
	local offset_x = (size_value - width * scale_by) / 2 - min_x * scale_by
	local offset_y = (size_value - height * scale_by) / 2 - min_y * scale_by
	return path.transform(polylines, scale_by, vec2(offset_x, offset_y)), scale_by
end

function path.length(polyline)
	local total = 0
	for index = 2, #polyline do
		total += (polyline[index] - polyline[index - 1]).Magnitude
	end
	return total
end

function path.sample(polyline, count_points)
	local total = path.length(polyline)
	if total == 0 then
		local out = {}
		for index = 1, count_points do
			out[index] = polyline[1]
		end
		return out
	end
	local step = total / (count_points - 1)
	local out = { polyline[1] }
	local travelled = 0
	local target_index = 1
	local current = polyline[1]
	for index = 2, #polyline do
		local segment_start = polyline[index - 1]
		local segment_end = polyline[index]
		local segment_length = (segment_end - segment_start).Magnitude
		if segment_length == 0 then
			continue
		end
		while travelled + segment_length >= target_index * step and #out < count_points do
			local remaining = target_index * step - travelled
			out[target_index + 1] = segment_start + (segment_end - segment_start).Unit * remaining
			target_index += 1
		end
		travelled += segment_length
		current = segment_end
	end
	while #out < count_points do
		table.insert(out, current)
	end
	return out
end

local polygon = {}

function polygon.when_parented(instance, fn)
	local done = false
	local connection
	local function attempt()
		if done or not instance.Parent then
			return
		end
		done = true
		if connection then
			connection:Disconnect()
		end
		fn()
	end
	connection = instance.AncestryChanged:Connect(attempt)
	task.defer(attempt)
	return instance
end

local function bounds_of(points)
	local min_x, min_y = math_huge, math_huge
	local max_x, max_y = -math_huge, -math_huge
	for _, point in points do
		min_x = math.min(min_x, point.X)
		min_y = math.min(min_y, point.Y)
		max_x = math.max(max_x, point.X)
		max_y = math.max(max_y, point.Y)
	end
	return min_x, min_y, max_x, max_y
end

local function make_canvas(parent, min_x, min_y, width, height, options)
	options = options or {}
	local group = Instance.new("CanvasGroup")
	group.Name = options.name or "shape"
	group.BackgroundTransparency = 1
	group.BorderSizePixel = 0
	group.ClipsDescendants = false
	group.Size = UDim2.fromOffset(math.max(2, math.ceil(width)), math.max(2, math.ceil(height)))
	group.CanvasSize = UDim2.fromOffset(math.max(2, math.ceil(width)), math.max(2, math.ceil(height)))
	group.Position = UDim2.fromOffset(math.floor(min_x), math.floor(min_y))
	group.ZIndex = options.zindex or 1
	if options.layout_order then
		group.LayoutOrder = options.layout_order
	end
	if options.anchor then
		group.AnchorPoint = options.anchor
	end
	if parent then
		group.Parent = parent
	end
	return group
end

function polygon.stroke(points, width, options)
	options = options or {}
	local half = width / 2
	local items = {}
	for index = 1, #points - 1 do
		local start_point = points[index]
		local end_point = points[index + 1]
		local direction = end_point - start_point
		if direction.Magnitude > 1e-4 then
			local normal = vec2(-direction.Y, direction.X).Unit * half
			table.insert(items, { start_point + normal, end_point + normal, end_point - normal, start_point - normal })
		end
	end
	if options.caps ~= false then
		for index, point in points do
			if index == 1 or index == #points or options.joints then
				local sides = 6
				local joint = {}
				for side = 0, sides - 1 do
					local angle = side / sides * math_pi * 2
					table.insert(joint, point + vec2(math_cos(angle), math_sin(angle)) * half)
				end
				table.insert(items, joint)
			end
		end
	end
	return items
end

function polygon.fill(parent, points, fill_color, options)
	options = options or {}
	if #points < 3 then
		return nil
	end
	local padding = options.padding or 0
	local min_x, min_y, max_x, max_y = bounds_of(points)
	local width = max_x - min_x + padding * 2
	local height = max_y - min_y + padding * 2
	local group = make_canvas(parent, min_x - padding, min_y - padding, width, height, options)
	local local_points = table.create(#points)
	for index, point in points do
		local_points[index] = vec2(point.X - min_x + padding, point.Y - min_y + padding)
	end
	polygon.when_parented(group, function()
		local region = { min = Vector2.zero, max = vec2(width, height) }
		local first = local_points[1]
		for index = 2, #local_points - 1 do
			group:DrawPolygon({ first, local_points[index], local_points[index + 1] }, region, fill_color)
		end
		if options.outline then
			group:DrawPolygon(local_points, region, options.outline)
		end
	end)
	return group
end

function polygon.wedge(parent, items, fill_color, options)
	options = options or {}
	if #items == 0 then
		return nil
	end
	local padding = options.padding or 0
	local min_x, min_y, max_x, max_y = math_huge, math_huge, -math_huge, -math_huge
	for _, item in items do
		for _, point in item do
			min_x = math.min(min_x, point.X)
			min_y = math.min(min_y, point.Y)
			max_x = math.max(max_x, point.X)
			max_y = math.max(max_y, point.Y)
		end
	end
	local width = max_x - min_x + padding * 2
	local height = max_y - min_y + padding * 2
	local group = make_canvas(parent, min_x - padding, min_y - padding, width, height, options)
	polygon.when_parented(group, function()
		local region = { min = Vector2.zero, max = vec2(width, height) }
		for _, item in items do
			local translated = table.create(#item)
			for index, point in item do
				translated[index] = vec2(point.X - min_x + padding, point.Y - min_y + padding)
			end
			group:DrawPolygon(translated, region, fill_color)
		end
	end)
	return group
end

function polygon.stroke_group(parent, polylines, width, stroke_color, options)
	options = options or {}
	local items = {}
	for _, polyline in polylines do
		for _, item in polygon.stroke(polyline, width, options) do
			table.insert(items, item)
		end
	end
	return polygon.wedge(parent, items, stroke_color, options)
end

function polygon.polyline(parent, points, width, stroke_color, options)
	if #points < 2 then
		return nil
	end
	return polygon.stroke_group(parent, { points }, width, stroke_color, options)
end

local icons = {}

icons.viewbox = 24

local function box(x, y, width, height, radius)
	radius = radius or 0
	if radius <= 0 then
		return string.format("M%d %d H%d V%d H%d Z", x, y, x + width, y + height, x)
	end
	return string.format(
		"M%d %d H%d A%d %d 0 0 1 %d %d V%d A%d %d 0 0 1 %d %d H%d A%d %d 0 0 1 %d %d V%d A%d %d 0 0 1 %d %d Z",
		x + radius,
		y,
		x + width - radius,
		radius,
		radius,
		x + width,
		y + radius,
		y + height - radius,
		radius,
		radius,
		x + width - radius,
		y + height,
		x + radius,
		radius,
		radius,
		x,
		y + height - radius,
		y + radius,
		radius,
		radius,
		x + radius,
		y
	)
end

local function circle(cx, cy, r)
	return string.format("M%d %d A%d %d 0 1 1 %d %d A%d %d 0 1 1 %d %d Z", cx - r, cy, r, r, cx + r, cy, r, r, cx - r, cy)
end

local function ring(cx, cy, outer, inner)
	return string.format(
		"M%d %d A%d %d 0 1 1 %d %d A%d %d 0 1 1 %d %d Z M%d %d A%d %d 0 1 0 %d %d A%d %d 0 1 0 %d %d Z",
		cx - outer,
		cy,
		outer,
		outer,
		cx + outer,
		cy,
		outer,
		outer,
		cx - outer,
		cy,
		cx - inner,
		cy,
		inner,
		inner,
		cx + inner,
		cy,
		inner,
		inner,
		cx - inner,
		cy
	)
end

icons.set = {
	check = "M4 12 L9 17 L20 6",
	chevron_down = "M6 9 L12 15 L18 9",
	chevron_up = "M6 15 L12 9 L18 15",
	chevron_left = "M15 6 L9 12 L15 18",
	chevron_right = "M9 6 L15 12 L9 18",
	arrow_right = "M4 12 H19 M13 6 L19 12 L13 18",
	arrow_left = "M20 12 H5 M11 6 L5 12 L11 18",
	arrow_up = "M12 20 V5 M6 11 L12 5 L18 11",
	arrow_down = "M12 4 V19 M6 13 L12 19 L18 13",
	arrow_up_right = "M7 17 L17 7 M8 7 H17 V16",
	plus = "M12 5 V19 M5 12 H19",
	minus = "M5 12 H19",
	close = "M6 6 L18 18 M18 6 L6 18",
	menu = "M4 7 H20 M4 12 H20 M4 17 H20",
	search = "M11 4 A7 7 0 1 1 11 18 A7 7 0 1 1 11 4 M16 16 L21 21",
	settings = "M12 9 A3 3 0 1 1 12 15 A3 3 0 1 1 12 9 M12 2 L14 4 L17 3 L18 6 L21 7 L20 10 L21 13 L18 14 L17 17 L14 16 L12 18 L10 16 L7 17 L6 14 L3 13 L4 10 L3 7 L6 6 L7 3 L10 4 Z",
	home = "M4 11 L12 4 L20 11 V20 H15 V14 H9 V20 H4 Z",
	user = "M12 4 A4 4 0 1 1 12 12 A4 4 0 1 1 12 4 M4 21 C4 17 8 15 12 15 C16 15 20 17 20 21",
	users = "M9 5 A3.5 3.5 0 1 1 9 12 A3.5 3.5 0 1 1 9 5 M2 20 C2 16.5 5.5 15 9 15 C12.5 15 16 16.5 16 20 M17 6 A3 3 0 1 1 17 12 A3 3 0 1 1 17 6 M18 15 C20.5 15.6 22 17 22 20",
	bell = "M6 16 V11 A6 6 0 0 1 18 11 V16 L20 18 H4 Z M10 18 A2 2 0 0 0 14 18",
	mail = "M3 6 H21 V18 H3 Z M3 7 L12 13 L21 7",
	lock = "M6 11 H18 V20 H6 Z M9 11 V8 A3 3 0 0 1 15 8 V11",
	unlock = "M6 11 H18 V20 H6 Z M9 11 V8 A3 3 0 0 1 15 7.5",
	eye = "M2 12 C5 6 9 5 12 5 C15 5 19 6 22 12 C19 18 15 19 12 19 C9 19 5 18 2 12 Z " .. circle(12, 12, 3),
	eye_off = "M4 4 L20 20 M10 6 C11 5.5 11.6 5.5 12 5.5 C15 5.5 19 7 22 12 C20.6 14.5 19 16.3 17 17.4 M12 19 C9 19 5 18 2 12 C3.7 8.7 5.6 7 7.6 6.3",
	heart = "M12 20 C6 16 3 13 3 9.5 A4.5 4.5 0 0 1 12 7 A4.5 4.5 0 0 1 21 9.5 C21 13 18 16 12 20 Z",
	star = "M12 3 L15 9 L21 10 L16.5 14.5 L18 21 L12 17.5 L6 21 L7.5 14.5 L3 10 L9 9 Z",
	clock = "M12 3 A9 9 0 1 1 12 21 A9 9 0 1 1 12 3 M12 7 V12 L16 14",
	calendar = "M4 6 H20 V20 H4 Z M4 10 H20 M9 3 V7 M15 3 V7",
	download = "M12 4 V15 M7 11 L12 16 L17 11 M5 20 H19",
	upload = "M12 16 V5 M7 9 L12 4 L17 9 M5 20 H19",
	trash = "M4 7 H20 M9 7 V4 H15 V7 M6 7 L7 20 H17 L18 7 M10 11 V17 M14 11 V17",
	edit = "M4 20 H8 L20 8 L16 4 L4 16 Z M14 6 L18 10",
	copy = "M9 9 H20 V20 H9 Z M5 15 H4 V4 H15 V5",
	link = "M9 15 L15 9 M11 6 L13 4 A4 4 0 0 1 19 10 L17 12 M13 18 L11 20 A4 4 0 0 1 5 14 L7 12",
	filter = "M4 5 H20 L14 13 V19 L10 17 V13 Z",
	refresh = "M20 12 A8 8 0 1 1 12 4 A8 8 0 0 1 19 8 M20 4 V9 H15",
	play = "M8 5 L19 12 L8 19 Z",
	pause = "M8 5 H11 V19 H8 Z M14 5 H17 V19 H14 Z",
	volume = "M4 9 H8 L13 5 V19 L8 15 H4 Z M17 8 A5 5 0 0 1 17 16",
	mute = "M4 9 H8 L13 5 V19 L8 15 H4 Z M17 9 L22 15 M22 9 L17 15",
	wifi = "M4 9 A12 12 0 0 1 20 9 M7 13 A8 8 0 0 1 17 13 " .. circle(12, 18, 1.4),
	battery = "M3 8 H18 V16 H3 Z M20 11 V13",
	zap = "M13 2 L5 14 H11 L10 22 L19 9 H13 Z",
	shield = "M12 3 L20 6 V12 C20 16 16 19 12 21 C8 19 4 16 4 12 V6 Z",
	shield_check = "M12 3 L20 6 V12 C20 16 16 19 12 21 C8 19 4 16 4 12 V6 Z M9 12 L11.5 14.5 L16 10",
	flame = "M12 3 C14 7 18 8 18 13 A6 6 0 0 1 6 13 C6 10 8 9 9 7 C10 9 10 8 12 3 Z",
	image = "M4 5 H20 V19 H4 Z M4 15 L9 11 L13 15 L16 12 L20 16 " .. circle(9, 9, 1.4),
	folder = "M3 6 H9 L11 8 H21 V19 H3 Z",
	file = "M6 3 H14 L18 7 V21 H6 Z M14 3 V7 H18",
	terminal = "M4 5 H20 V19 H4 Z M7 10 L10 12 L7 14 M12 15 H17",
	code = "M9 7 L4 12 L9 17 M15 7 L20 12 L15 17",
	database = "M12 5 C7 5 4 6.5 4 8 V16 C4 17.5 7 19 12 19 C17 19 20 17.5 20 16 V8 C20 6.5 17 5 12 5 Z M4 8 C4 9.5 7 11 12 11 C17 11 20 9.5 20 8 M4 12 C4 13.5 7 15 12 15 C17 15 20 13.5 20 12",
	server = "M4 5 H20 V10 H4 Z M4 14 H20 V19 H4 Z M8 7.5 H9 M8 16.5 H9",
	cloud = "M7 18 A4 4 0 0 1 7 10 A5 5 0 0 1 17 10.5 A3.5 3.5 0 0 1 17 18 Z",
	globe = "M12 3 A9 9 0 1 1 12 21 A9 9 0 1 1 12 3 M3 12 H21 M12 3 C15 7 15 17 12 21 M12 3 C9 7 9 17 12 21",
	chart = "M4 20 V4 M4 20 H20 M8 17 V13 M12 17 V8 M16 17 V11",
	trending_up = "M4 17 L10 11 L14 15 L20 7 M15 7 H20 V12",
	trending_down = "M4 7 L10 13 L14 9 L20 17 M15 17 H20 V12",
	activity = "M3 12 H7 L10 5 L14 19 L17 12 H21",
	grid = "M4 4 H10 V10 H4 Z M14 4 H20 V10 H14 Z M4 14 H10 V20 H4 Z M14 14 H20 V20 H14 Z",
	list = "M8 6 H20 M8 12 H20 M8 18 H20 M4 6 H5 M4 12 H5 M4 18 H5",
	layout = "M3 5 H21 V19 H3 Z M3 10 H21 M10 10 V19",
	sidebar = "M3 5 H21 V19 H3 Z M9 5 V19",
	sliders = "M4 8 H14 M18 8 H20 M4 16 H8 M12 16 H20 " .. circle(16, 8, 2) .. " " .. circle(10, 16, 2),
	toggle_left = "M8 6 H16 A6 6 0 0 1 16 18 H8 A6 6 0 0 1 8 6 Z " .. circle(10, 12, 2.5),
	toggle_right = "M8 6 H16 A6 6 0 0 1 16 18 H8 A6 6 0 0 1 8 6 Z " .. circle(14, 12, 2.5),
	info = "M12 3 A9 9 0 1 1 12 21 A9 9 0 1 1 12 3 M12 11 V17 M12 8 H12.01",
	warning = "M12 4 L21 20 H3 Z M12 10 V14 M12 17 H12.01",
	alert = "M12 3 A9 9 0 1 1 12 21 A9 9 0 1 1 12 3 M12 8 V13 M12 16 H12.01",
	help = "M12 3 A9 9 0 1 1 12 21 A9 9 0 1 1 12 3 M9.5 9.5 A2.5 2.5 0 1 1 14 11 C13 12 12 12.5 12 14 M12 17 H12.01",
	sparkles = "M12 4 L14 9 L19 11 L14 13 L12 18 L10 13 L5 11 L10 9 Z M18 15 L19 17 L21 18 L19 19 L18 21 L17 19 L15 18 L17 17 Z",
	crown = "M4 18 L6 8 L10 12 L12 6 L14 12 L18 8 L20 18 Z",
	gift = "M4 10 H20 V20 H4 Z M4 7 H20 V10 H4 Z M12 7 V20 M12 7 C10 7 8 6 8 4.5 C9.5 3.5 12 5 12 7 Z M12 7 C14 7 16 6 16 4.5 C14.5 3.5 12 5 12 7 Z",
	tag = "M4 12 L12 4 H20 V12 L12 20 Z " .. circle(16.5, 8, 1.3),
	pin = "M12 3 A4 4 0 0 1 16 7 C16 11 12 12 12 14 V21 M12 3 A4 4 0 0 0 8 7 C8 11 12 12 12 14",
	bell_ring = "M6 16 V11 A6 6 0 0 1 18 11 V16 L20 18 H4 Z M10 18 A2 2 0 0 0 14 18 M2 5 L5 8 M22 5 L19 8",
	send = "M3 12 L21 4 L14 21 L11 14 Z",
	message = "M4 5 H20 V16 H13 L8 20 V16 H4 Z",
	chat = "M4 6 H14 V15 H9 L5 18 V15 H4 Z M20 9 V18 H11",
	more = circle(5, 12, 1.5) .. " " .. circle(12, 12, 1.5) .. " " .. circle(19, 12, 1.5),
	more_vertical = circle(12, 5, 1.5) .. " " .. circle(12, 12, 1.5) .. " " .. circle(12, 19, 1.5),
	external = "M14 4 H20 V10 M20 4 L11 13 M18 14 V19 H5 V6 H10",
	expand = "M4 9 V4 H9 M20 15 V20 H15 M15 4 H20 V9 M9 20 H4 V15",
	minimize = "M9 4 V9 H4 M15 20 V15 H20 M20 9 H15 V4 M4 15 H9 V20",
	maximize = "M4 6 H20 V18 H4 Z",
	fullscreen = "M4 9 V4 H9 M20 15 V20 H15 M15 4 H20 V9 M9 20 H4 V15",
	loader = "M12 3 A9 9 0 1 1 3 12",
	sun = circle(12, 12, 4.2) .. " M12 2 V4 M12 20 V22 M2 12 H4 M20 12 H22 M5 5 L6.5 6.5 M17.5 17.5 L19 19 M19 5 L17.5 6.5 M6.5 17.5 L5 19",
	moon = "M20 14 A8.5 8.5 0 0 1 9 3 A8.5 8.5 0 1 0 20 14 Z",
	palette = "M12 3 A9 9 0 0 0 12 21 C13.5 21 14 19.5 14 18 C14 16.5 15 16 16.5 16 H18 C19.7 16 21 14.7 21 13 C21 7.5 17 3 12 3 Z " .. circle(8, 10, 1.2) .. " " .. circle(12, 7.5, 1.2) .. " " .. circle(16, 10, 1.2),
	brush = "M4 14 C4 11 9 8 13 6 C16 4.5 18 6 17 9 C16 12 12 15 8 16 Z M6 18 C7 20 9 21 11 20",
	cpu = "M8 8 H16 V16 H8 Z M4 10 H8 M16 10 H20 M4 14 H8 M16 14 H20 M10 4 V8 M10 16 V20 M14 4 V8 M14 16 V20",
	gpu = "M3 8 H21 V18 H3 Z M7 8 V5 H15 V8 " .. circle(9, 13, 1.6) .. " " .. circle(15, 13, 1.6),
	memory = "M4 8 H20 V16 H4 Z M8 8 V5 M12 8 V5 M16 8 V5 M8 16 V19 M12 16 V19 M16 16 V19",
	keyboard = "M3 7 H21 V17 H3 Z M7 11 H8 M11 11 H12 M15 11 H16 M7 14 H17",
	mouse = "M7 4 H17 A5 5 0 0 1 17 20 H7 A5 5 0 0 1 7 4 Z M12 7 V10",
	headphones = "M4 14 V11 A8 8 0 0 1 20 11 V14 M4 14 H7 V19 H4 Z M20 14 H17 V19 H17 Z M20 14 H17 V19 H20 Z",
	monitor = "M3 5 H21 V15 H3 Z M8 19 H16 M12 15 V19",
	smartphone = "M8 3 H16 V21 H8 Z M11 18 H13",
	tablet = "M5 4 H19 V20 H5 Z M10 18 H14",
	watch = "M8 8 H16 V16 H8 Z M9 8 L10 3 H14 L15 8 M9 16 L10 21 H14 L15 16",
	camera = "M4 8 H8 L10 6 H14 L16 8 H20 V19 H4 Z " .. circle(12, 13, 3.5),
	video = "M3 7 H13 V17 H3 Z M13 10 L21 6 V18 L13 14",
	mic = "M12 4 A3.5 3.5 0 0 1 12 11 A3.5 3.5 0 0 1 12 4 M6 11 A6 6 0 0 0 18 11 M12 17 V21 M8 21 H16",
	credit_card = "M3 6 H21 V18 H3 Z M3 10 H21",
	wallet = "M4 7 H18 V19 H4 Z M4 7 L16 4 V7 " .. circle(16, 13, 1.4),
	coins = "M9 6 A5 5 0 1 1 9 16 A5 5 0 1 1 9 6 M15 10 A5 5 0 1 1 15 20 A5 5 0 1 1 15 10",
	cart = "M3 5 H6 L8 16 H19 L21 8 H7 " .. circle(9, 20, 1.3) .. " " .. circle(18, 20, 1.3),
	package = "M12 3 L21 8 V16 L12 21 L3 16 V8 Z M3 8 L12 13 L21 8 M12 13 V21",
	truck = "M3 7 H14 V17 H3 Z M14 10 H18 L21 13 V17 H14 " .. circle(7, 19, 1.6) .. " " .. circle(17, 19, 1.6),
	map_pin_filled = "M12 3 A6 6 0 0 1 18 9 C18 14 12 21 12 21 C12 21 6 14 6 9 A6 6 0 0 1 12 3 Z " .. circle(12, 9, 2.2),
	rocket = "M12 3 C16 6 18 10 18 14 L15 17 H9 L6 14 C6 10 8 6 12 3 Z M9 17 L7 21 L11 19 M15 17 L17 21 L13 19 " .. circle(12, 10, 1.8),
	target = ring(12, 12, 9, 5.5) .. " " .. ring(12, 12, 3, 0.1),
	flag = "M6 4 V20 M6 5 H18 L15 9 L18 13 H6",
	bookmark = "M6 4 H18 V20 L12 16 L6 20 Z",
	scissors = circle(7, 7, 2.2) .. " " .. circle(7, 17, 2.2) .. " M9 9 L20 19 M20 9 L9 19",
	command = "M9 6 A3 3 0 1 0 9 12 H15 A3 3 0 1 0 15 6 V12 A3 3 0 1 0 15 18 V12 H9 A3 3 0 1 0 9 18 V12",
	option = "M4 9 H13 M17 9 H20 " .. circle(15, 9, 2) .. " M4 15 H7 M11 15 H20 " .. circle(9, 15, 2),
	shift = "M12 4 L20 12 H16 V20 H8 V12 H4 Z",
	undo = "M4 10 H13 A5 5 0 0 1 13 20 H11 M4 10 L8 6 M4 10 L8 14",
	redo = "M20 10 H11 A5 5 0 0 0 11 20 H13 M20 10 L16 6 M20 10 L16 14",
	rotate = "M20 12 A8 8 0 1 1 12 4 A8 8 0 0 1 18 6.5 M20 4 V9 H15",
	crop = "M7 3 V17 H21 M3 7 H17 V21",
	save = "M5 4 H15 L19 8 V20 H5 Z M9 4 V9 H15 V4 M8 20 V15 H16 V20",
	printer = "M7 8 V4 H17 V8 M6 8 H18 V15 H6 Z M8 14 H16 V20 H8 Z",
	cut = "M5 6 H19 M5 12 H19 M5 18 H19 M10 4 L8 20 M16 4 L14 20",
	columns = "M4 5 H20 V19 H4 Z M9.3 5 V19 M14.6 5 V19",
	rows = "M4 5 H20 V19 H4 Z M4 9.3 H20 M4 14.6 H20",
	align_left = "M4 6 H20 M4 11 H14 M4 16 H18",
	align_center = "M4 6 H20 M7 11 H17 M5 16 H19",
	align_right = "M4 6 H20 M10 11 H20 M6 16 H20",
	bold = "M7 4 H13 A4 4 0 0 1 13 12 H7 Z M7 12 H14 A4 4 0 0 1 14 20 H7 Z",
	italic = "M10 4 H20 M4 20 H14 M15 4 L9 20",
	underline = "M7 4 V11 A5 5 0 0 0 17 11 V4 M5 20 H19",
	type = "M5 6 V4 H19 V6 M12 4 V20 M9 20 H15",
	percent = "M6 18 L18 6 " .. circle(8, 8, 2) .. " " .. circle(16, 16, 2),
	hash = "M9 4 L7 20 M17 4 L15 20 M4 9 H20 M3 15 H19",
	at = ring(12, 12, 7, 3) .. " M19 12 V15 A3 3 0 0 1 16 18",
	key = "M15 8 A4 4 0 1 1 11 12 A4 4 0 0 1 15 8 M12 12 L4 20 M7 17 L9 19 M10 15 L12 17",
	eraser = "M8 20 L4 16 L14 6 L20 12 L14 18 H8 Z M9 20 H20",
	wand = "M6 18 L16 8 M14 4 L20 10 M4 12 L6 14 M18 16 H20 M3 6 H5",
	box = "M12 3 L20 7 V17 L12 21 L4 17 V7 Z M4 7 L12 11 L20 7 M12 11 V21",
	layers = "M12 3 L21 8 L12 13 L3 8 Z M3 12 L12 17 L21 12 M3 16 L12 21 L21 16",
	git_branch = "M7 4 V16 A3 3 0 0 0 7 20 M7 8 A3 3 0 1 0 7 8 M17 8 A3 3 0 1 0 17 8 M17 11 V14 A3 3 0 0 1 14 17 H10",
	bug = "M9 7 A3 3 0 0 1 15 7 M9 7 H7 V11 A5 5 0 0 0 8 15 M15 7 H17 V11 A5 5 0 0 1 16 15 M8 15 H16 M9 11 H15 M6 12 H8 M16 12 H18 M9 19 L8 21 M15 19 L16 21 M8 15 L6 17 M16 15 L18 17",
	locate = "M12 3 V6 M12 18 V21 M3 12 H6 M18 12 H21 " .. ring(12, 12, 6, 2.5),
	compass = ring(12, 12, 9, 0.1) .. " M15.5 8.5 L13.5 13.5 L8.5 15.5 L10.5 10.5 Z",
	wind = "M4 8 H13 A3 3 0 1 0 13 14 H9 M4 12 H16 A3 3 0 0 1 16 18 H12 M4 16 H8",
	droplet = "M12 3 C12 3 6 9.5 6 14 A6 6 0 0 0 18 14 C18 9.5 12 3 12 3 Z",
	snowflake = "M12 3 V21 M4 7.5 L20 16.5 M4 16.5 L20 7.5 M9 5 L12 7 L15 5 M9 19 L12 17 L15 19",
}

icons.aliases = {
	x = "close",
	times = "close",
	cross = "close",
	["chevron-down"] = "chevron_down",
	["chevron-up"] = "chevron_up",
	["chevron-left"] = "chevron_left",
	["chevron-right"] = "chevron_right",
	["arrow-right"] = "arrow_right",
	["arrow-left"] = "arrow_left",
	["arrow-up"] = "arrow_up",
	["arrow-down"] = "arrow_down",
	["trending-up"] = "trending_up",
	["trending-down"] = "trending_down",
	["eye-off"] = "eye_off",
	["toggle-left"] = "toggle_left",
	["toggle-right"] = "toggle_right",
	["bell-ring"] = "bell_ring",
	["shield-check"] = "shield_check",
	["map-pin"] = "map_pin_filled",
	["git-branch"] = "git_branch",
	["check-circle"] = "check_circle",
	["alert-circle"] = "alert",
	["alert-triangle"] = "warning",
	["dots"] = "more",
	["ellipsis"] = "more",
	["ellipsis-vertical"] = "more_vertical",
	["horizontal-menu"] = "more",
	["vertical-menu"] = "more_vertical",
}

icons.set.check_circle = ring(12, 12, 9, 0.1) .. " M8 12.5 L11 15.5 L16.5 9.5"
icons.set.x_circle = ring(12, 12, 9, 0.1) .. " M9 9 L15 15 M15 9 L9 15"
icons.set.loader_ring = ring(12, 12, 9, 6.4)
icons.set.spinner = "M12 3 A9 9 0 1 1 4.5 16.5"

function icons.normalize(name)
	if type(name) ~= "string" then
		return nil
	end
	local key = norm(string.gsub(name, "[/\\ ]+", "-"))
	return icons.aliases[key] or icons.aliases[name] or key
end

function icons.get(name)
	local key = icons.normalize(name)
	return icons.set[key]
end

function icons.has(name)
	return icons.get(name) ~= nil
end

function icons.register(name, data)
	icons.set[icons.normalize(name)] = data
	return icons.set[icons.normalize(name)]
end

function icons.register_alias(name, target)
	icons.aliases[icons.normalize(name)] = icons.normalize(target)
	return icons.aliases[icons.normalize(name)]
end

function icons.list()
	local out = {}
	for key in icons.set do
		table.insert(out, key)
	end
	table.sort(out)
	return out
end

function icons.strokes(name, size, width)
	local source = icons.get(name)
	if not source then
		return nil
	end
	local viewbox = icons.viewbox
	local scale_by = size / viewbox
	local polylines = path.flatten(source)
	local scaled = path.transform(polylines, scale_by)
	return scaled, width / viewbox * size / size
end

local run_service = game:GetService("RunService")
local input_service = game:GetService("UserInputService")
local players = game:GetService("Players")

local dom = {}

local mount_root
local layers = {}
local screen_gui

function dom.frame(props, children)
	local instance = Instance.new(props.class or "Frame")
	instance.Name = props.name or "frame"
	instance.BackgroundColor3 = props.color or Color3.fromRGB(20, 20, 24)
	instance.BackgroundTransparency = props.transparency or (props.transparent and 1 or 0)
	instance.BorderSizePixel = 0
	instance.Size = props.size or size(100, 100)
	instance.Position = props.position or UDim2.new()
	instance.AnchorPoint = props.anchor or Vector2.zero
	instance.ZIndex = props.zindex or 1
	instance.Visible = props.visible ~= false
	instance.ClipsDescendants = props.clip or false
	instance.Active = props.active or false
	instance.AutomaticSize = props.auto_size or Enum.AutomaticSize.None
	instance.LayoutOrder = props.layout_order or 0
	instance.Rotation = props.rotation or 0
	if props.parent then
		instance.Parent = props.parent
	end
	if children then
		for _, child in children do
			if child then
				child.Parent = instance
			end
		end
	end
	return instance
end

function dom.text(props)
	local label = Instance.new(props.class or "TextLabel")
	label.Name = props.name or "text"
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = props.text or ""
	label.FontFace = props.font or Font.new("rbxasset://fonts/families/GothamSSm.json", props.weight, Enum.FontStyle.Normal)
	label.TextSize = props.size or 13
	label.TextColor3 = props.color or Color3.fromRGB(240, 240, 245)
	label.TextTransparency = props.transparency or 0
	label.TextXAlignment = props.align_x or Enum.TextXAlignment.Left
	label.TextYAlignment = props.align_y or Enum.TextYAlignment.Center
	label.TextWrapped = props.wrap ~= false
	label.TextTruncate = props.truncate or Enum.TextTruncate.None
	label.Size = props.size_of or UDim2.fromScale(1, 1)
	label.Position = props.position or UDim2.new()
	label.AnchorPoint = props.anchor or Vector2.zero
	label.ZIndex = props.zindex or 2
	label.RichText = props.rich or false
	label.AutomaticSize = props.auto_size or Enum.AutomaticSize.None
	label.LineHeight = props.line_height or 1.25
	label.TextScaled = props.scaled or false
	label.LayoutOrder = props.layout_order or 0
	label.MaxVisibleGraphemes = props.graphemes or -1
	if props.parent then
		label.Parent = props.parent
	end
	return label
end

function dom.image(props)
	local image = Instance.new(props.class or "ImageLabel")
	image.Name = props.name or "image"
	image.BackgroundTransparency = props.transparency or 1
	image.BorderSizePixel = 0
	image.Image = props.image or ""
	image.ImageColor3 = props.color or Color3.new(1, 1, 1)
	image.ImageTransparency = props.image_transparency or 0
	image.ScaleType = props.scale_type or Enum.ScaleType.Stretch
	image.Size = props.size_of or UDim2.fromScale(1, 1)
	image.Position = props.position or UDim2.new()
	image.AnchorPoint = props.anchor or Vector2.zero
	image.ZIndex = props.zindex or 2
	image.LayoutOrder = props.layout_order or 0
	image.SliceCenter = props.slice or Rect.new(0, 0, 0, 0)
	image.SliceScale = props.slice_scale or 1
	if props.parent then
		image.Parent = props.parent
	end
	return image
end

function dom.corner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = px(radius or 8)
	corner.Parent = parent
	return corner
end

function dom.stroke(parent, props)
	props = props or {}
	local stroke = Instance.new("UIStroke")
	stroke.Color = props.color or Color3.fromRGB(60, 60, 70)
	stroke.Transparency = props.transparency or 0
	stroke.Thickness = props.thickness or 1
	stroke.ApplyStrokeMode = props.mode or Enum.ApplyStrokeMode.Border
	stroke.LineJoinMode = props.join or Enum.LineJoinMode.Round
	stroke.Parent = parent
	return stroke
end

function dom.padding(parent, top, right, bottom, left)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = px(top or 0)
	padding.PaddingRight = px(right ~= nil and right or top)
	padding.PaddingBottom = px(bottom ~= nil and bottom or top)
	padding.PaddingLeft = px(left ~= nil and left or right or top)
	padding.Parent = parent
	return padding
end

function dom.list(parent, props)
	props = props or {}
	local list = Instance.new("UIListLayout")
	list.FillDirection = props.direction or Enum.FillDirection.Vertical
	list.HorizontalAlignment = props.horizontal or Enum.HorizontalAlignment.Left
	list.VerticalAlignment = props.vertical or Enum.VerticalAlignment.Top
	list.Padding = px(props.gap or 8)
	list.SortOrder = props.sort or Enum.SortOrder.LayoutOrder
	list.Wraps = props.wrap or false
	list.Parent = parent
	return list
end

function dom.grid(parent, props)
	props = props or {}
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = props.cell or size(80, 80)
	grid.CellPadding = props.gap or size(8, 8)
	grid.FillDirection = props.direction or Enum.FillDirection.Horizontal
	grid.HorizontalAlignment = props.horizontal or Enum.HorizontalAlignment.Left
	grid.VerticalAlignment = props.vertical or Enum.VerticalAlignment.Top
	grid.FillDirectionMaxCells = props.max_cells or 0
	grid.SortOrder = props.sort or Enum.SortOrder.LayoutOrder
	grid.Parent = parent
	return grid
end

function dom.page(parent, props)
	props = props or {}
	local page = Instance.new("UIPageLayout")
	page.FillDirection = props.direction or Enum.FillDirection.Horizontal
	page.Padding = px(props.gap or 12)
	page.HorizontalAlignment = props.horizontal or Enum.HorizontalAlignment.Center
	page.VerticalAlignment = props.vertical or Enum.VerticalAlignment.Center
	page.SortOrder = props.sort or Enum.SortOrder.LayoutOrder
	page.EasingStyle = animation.ease_style(props.ease or "quint")
	page.EasingDirection = animation.ease_direction(props.direction_ease or "in-out")
	page.TweenTime = props.time or 0.42
	page.Parent = parent
	return page
end

function dom.gradient(parent, props)
	props = props or {}
	local gradient = Instance.new("UIGradient")
	gradient.Color = props.color or color.sequence({ "#8B7AF6", "#6C5CE7" })
	gradient.Rotation = props.rotation or 90
	gradient.Transparency = props.transparency or NumberSequence.new(0)
	gradient.Offset = props.offset or Vector2.zero
	gradient.Parent = parent
	return gradient
end

function dom.shadow(parent, props)
	props = props or {}
	local holder = dom.frame({
		name = "shadow",
		parent = parent,
		size_of = size(props.width or 240, props.height or 240),
		color = props.color or Color3.fromRGB(0, 0, 0),
		transparency = 0.9,
		zindex = (parent and parent.ZIndex or 1) - 1,
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.5),
	})
	dom.image({
		name = "shadow_image",
		parent = holder,
		image = "rbxassetid://6015897843",
		scale_type = Enum.ScaleType.Slice,
		slice = Rect.new(Vector2.new(128, 128), Vector2.new(128, 128)),
		image_transparency = props.transparency or 0.72,
		color = props.color or Color3.fromRGB(0, 0, 0),
		size_of = UDim2.fromScale(1, 1),
	})
	return holder
end

function dom.aspect(parent, ratio)
	local constraint = Instance.new("UIAspectRatioConstraint")
	constraint.AspectRatio = ratio or 1
	constraint.AspectType = Enum.AspectType.FitWithinMaxSize
	constraint.Parent = parent
	return constraint
end

function dom.constrain(parent, props)
	props = props or {}
	local constraint = Instance.new("UISizeConstraint")
	constraint.MinSize = props.min or Vector2.zero
	constraint.MaxSize = props.max or Vector2.new(math_huge, math_huge)
	constraint.Parent = parent
	return constraint
end

function dom.scale(parent, factor)
	local ui_scale = Instance.new("UIScale")
	ui_scale.Scale = factor or 1
	ui_scale.Parent = parent
	return ui_scale
end

function dom.drag(instance, options)
	options = options or {}
	local handle = options.handle or instance
	local dragging = false
	local origin
	local start_position
	local moved = create_signal()

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if options.condition and not options.condition() then
				return
			end
			dragging = true
			origin = Vector2.new(input.Position.X, input.Position.Y)
			start_position = instance.Position
			moved:fire(true)
		end
	end)

	input_service.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local current = Vector2.new(input.Position.X, input.Position.Y)
			local delta = current - origin
			instance.Position = UDim2.new(start_position.X.Scale, start_position.X.Offset + delta.X, start_position.Y.Scale, start_position.Y.Offset + delta.Y)
		end
	end)

	input_service.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			moved:fire(false)
			if options.released then
				options.released(instance.Position)
			end
		end
	end)

	return moved
end

local interaction = {}

function interaction.hover(instance, options)
	options = options or {}
	local hovered = create_state(false)
	local pressed = create_state(false)
	local enabled = create_state(options.enabled ~= false)

	instance.Active = true
	instance.AutoButtonColor = false

	instance.InputBegan:Connect(function(input)
		if not enabled:get() then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			hovered:set(true)
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			pressed:set(true)
		end
	end)

	instance.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			hovered:set(false)
			pressed:set(false)
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			pressed:set(false)
		end
	end)

	instance.MouseEnter:Connect(function()
		if enabled:get() then
			hovered:set(true)
		end
	end)

	instance.MouseLeave:Connect(function()
		hovered:set(false)
		pressed:set(false)
	end)

	if options.block == nil and instance:IsA("TextButton") or instance:IsA("ImageButton") then
		instance.AutoButtonColor = false
	end

	return { hovered = hovered, pressed = pressed, enabled = enabled }
end

function interaction.clickable(instance, options)
	options = options or {}
	local states = interaction.hover(instance, options)
	local activated = create_signal()
	local right_clicked = create_signal()
	local middle_clicked = create_signal()

	if instance:IsA("GuiButton") then
		instance.MouseButton1Click:Connect(function()
			if states.enabled:get() then
				activated:fire()
			end
		end)
		instance.MouseButton2Click:Connect(function()
			if states.enabled:get() then
				right_clicked:fire()
			end
		end)
		instance.MouseButton3Click:Connect(function()
			if states.enabled:get() then
				middle_clicked:fire()
			end
		end)
	else
		instance.InputBegan:Connect(function(input)
			if not states.enabled:get() then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				activated:fire()
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
				right_clicked:fire()
			elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
				middle_clicked:fire()
			end
		end)
	end

	states.activated = activated
	states.right_clicked = right_clicked
	states.middle_clicked = middle_clicked

	function states:set_enabled(value)
		states.enabled:set(value)
		instance.Active = value
		if instance:IsA("GuiButton") then
			instance.AutoButtonColor = false
		end
	end

	return states
end

function interaction.focus_ring(instance, options)
	options = options or {}
	local theme_value = options.theme or theme.get()
	local ring = dom.stroke(instance, {
		color = theme_value.color("ring"),
		transparency = 1,
		thickness = options.thickness or 2,
	})
	ring.Name = "focus_ring"
	return ring
end

function interaction.keybind(key, fn, options)
	options = options or {}
	local connection
	connection = input_service.InputBegan:Connect(function(input, processed)
		if options.ignore_processed and processed then
			return
		end
		if input.KeyCode == key then
			fn()
		end
	end)
	return connection
end

function interaction.combo(keys, fn)
	local held = {}
	local connection
	connection = input_service.InputBegan:Connect(function(input)
		held[input.KeyCode] = true
		local ready = true
		for _, key in keys do
			if not held[key] then
				ready = false
			end
		end
		if ready then
			fn()
		end
	end)
	input_service.InputEnded:Connect(function(input)
		held[input.KeyCode] = nil
	end)
	return connection
end

local shell = {}

function shell.ensure_root(parent)
	if screen_gui and screen_gui.Parent then
		return screen_gui
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "lucent"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 100
	gui.Parent = parent
	screen_gui = gui
	mount_root = gui
	layers = {}
	return gui
end

function shell.layer(name, zindex)
	if not screen_gui then
		shell.ensure_root(players.LocalPlayer and players.LocalPlayer:WaitForChild("PlayerGui") or game:GetService("CoreGui"))
	end
	if layers[name] and layers[name].Parent then
		return layers[name]
	end
	local frame = dom.frame({
		name = name,
		parent = screen_gui,
		size_of = UDim2.fromScale(1, 1),
		transparent = true,
		zindex = zindex or 1,
		visible = true,
	})
	layers[name] = frame
	return frame
end

function shell.gui()
	if not screen_gui then
		shell.ensure_root(players.LocalPlayer and players.LocalPlayer:WaitForChild("PlayerGui") or game:GetService("CoreGui"))
	end
	return screen_gui
end

function shell.root(parent)
	if parent then
		return shell.ensure_root(parent)
	end
	return shell.gui()
end

local component = {}
component.__index = component

local function create_component(instance, extra)
	local self = setmetatable(merge({
		instance = instance,
		_children = {},
		_connections = {},
		_trove = create_trove(),
		_destroyed = create_signal(),
	}, extra or {}), component)
	return self
end

function component:child(name, object)
	self._children[name] = object
	return object
end

function component:on(signal_target, fn)
	local handle
	if signal_target.Connect then
		handle = signal_target:Connect(fn)
	else
		handle = signal_target:connect(fn)
	end
	table.insert(self._connections, handle)
	self._trove:add(handle)
	return handle
end

function component:own(item)
	self._trove:add(item)
	return item
end

function component:set_visible(value)
	self.instance.Visible = value
	return self
end

function component:show()
	self.instance.Visible = true
	return self
end

function component:hide()
	self.instance.Visible = false
	return self
end

function component:destroyed(fn)
	return self._destroyed:connect(fn)
end

function component:destroy()
	self._destroyed:fire()
	self._destroyed:clear()
	self._trove:destroy()
	if self.instance then
		self.instance:Destroy()
	end
	self.instance = nil
end

local brand_render = {}

local function logo_instance(config, parent)
	local mark = config.logo
	if typeof(mark) == "Instance" then
		local clone = mark:Clone()
		clone.Parent = parent
		if clone:IsA("ImageLabel") then
			clone.BackgroundTransparency = 1
			if config.logo_color then
				clone.ImageColor3 = config.logo_color
			end
			clone.ScaleType = Enum.ScaleType[title_case(config.logo_fit or "contain")]
		end
		return clone
	end
	if typeof(mark) == "function" then
		return mark(parent, config)
	end
	local image = dom.image({
		name = "logo",
		parent = parent,
		image = tostring(mark),
		size_of = UDim2.fromScale(1, 1),
		scale_type = Enum.ScaleType[title_case(config.logo_fit or "contain")],
		color = config.logo_color or Color3.new(1, 1, 1),
	})
	if config.logo_radius and config.logo_radius > 0 then
		dom.corner(image, config.logo_radius)
	end
	return image
end

function brand_render.mark(parent, options)
	local config = brand.merge(options)
	if config.logo == nil then
		return nil
	end
	local holder = dom.frame({
		name = "brand_mark",
		parent = parent,
		size_of = size(config.logo_size or 22, config.logo_size or 22),
		transparent = true,
		zindex = (parent and parent.ZIndex or 1) + 1,
		layout_order = -100,
	})
	logo_instance(config, holder)
	return holder
end

function brand_render.wordmark(parent, options)
	local config = brand.merge(options)
	local text_value = config.wordmark
	if text_value == nil or config.show_wordmark == false then
		return nil
	end
	if typeof(text_value) == "function" then
		return text_value(parent, config)
	end
	local theme_value = theme.get()
	return dom.text({
		name = "brand_wordmark",
		parent = parent,
		text = tostring(text_value),
		font = theme_value.font_of("bold"),
		size = config.wordmark_size or 14,
		color = config.wordmark_color or theme_value.color("foreground"),
		auto_size = Enum.AutomaticSize.X,
		size_of = UDim2.new(0, 0, 0, config.wordmark_size or 14),
		zindex = (parent and parent.ZIndex or 1) + 1,
		layout_order = -99,
	})
end

function brand_render.group(parent, options)
	if not brand.has_logo() then
		return nil
	end
	local config = brand.merge(options)
	local holder = dom.frame({
		name = "brand",
		parent = parent,
		size_of = UDim2.new(0, 0, 0, config.logo_size or 22),
		transparent = true,
		auto_size = Enum.AutomaticSize.X,
		zindex = (parent and parent.ZIndex or 1) + 1,
	})
	dom.list(holder, { direction = Enum.FillDirection.Horizontal, gap = config.gap or 8, vertical = Enum.VerticalAlignment.Center })
	brand_render.mark(holder, options)
	brand_render.wordmark(holder, options)
	return holder
end

local lucent_primitives = {}

function lucent_primitives.container(props, children)
	props = props or {}
	local theme_current = theme.get()
	local instance = dom.frame({
		name = props.name or "container",
		parent = props.parent,
		size_of = props.size_of or UDim2.fromScale(1, 1),
		position = props.position,
		anchor = props.anchor,
		color = props.color or (props.surface and theme_current.color(props.surface) or nil),
		transparency = props.transparency or (props.transparent and 1 or ((props.color or props.surface) and 0 or 1)),
		zindex = props.zindex or theme_current.layer_of("base"),
		clip = props.clip,
		auto_size = props.auto_size,
		layout_order = props.layout_order,
		visible = props.visible,
		rotation = props.rotation,
	})
	if props.radius then
		dom.corner(instance, theme_current.radius_of(props.radius))
	end
	if props.stroke then
		dom.stroke(instance, { color = theme_current.color(props.stroke_color or "border"), transparency = props.stroke_transparency or 0, thickness = props.stroke_thickness or theme_current.stroke.base })
	end
	if props.padding then
		dom.padding(instance, props.padding, props.padding_right, props.padding_bottom, props.padding_left)
	end
	if props.list then
		dom.list(instance, props.list)
	end
	if props.shadow then
		dom.shadow(instance, { transparency = props.shadow == true and theme_current.alpha_value("shadow") or props.shadow })
	end
	if children then
		for _, child in children do
			if child then
				child.Parent = instance
			end
		end
	end
	return instance
end

function lucent_primitives.text(props)
	props = props or {}
	local theme_current = theme.get()
	return dom.text({
		name = props.name,
		parent = props.parent,
		text = props.text or "",
		font = theme_current.font_of(props.font or (props.weight == Enum.FontWeight.Bold and "bold" or props.weight == Enum.FontWeight.Medium and "medium" or "sans")),
		weight = props.weight,
		size = props.size or theme_current.type_of(props.variant or "md"),
		color = props.color or (props.tone and theme_current.color(props.tone .. "_foreground") or nil) or theme_current.color("foreground"),
		transparency = props.transparency,
		align_x = props.align_x,
		align_y = props.align_y,
		wrap = props.wrap,
		truncate = props.truncate,
		size_of = props.size_of,
		position = props.position,
		anchor = props.anchor,
		zindex = props.zindex,
		auto_size = props.auto_size,
		rich = props.rich,
		layout_order = props.layout_order,
		line_height = props.line_height,
	})
end

function lucent_primitives.icon(props)
	props = props or {}
	local theme_current = theme.get()
	local name_value = props.name or props.icon
	if not name_value then
		return nil
	end
	if icons.has(name_value) then
		local icon_size = props.size or theme_current.control.icon
		local stroke_width = props.stroke_width or 1.8
		local holder = dom.frame({
			name = "icon_" .. tostring(icons.normalize(name_value)),
			parent = props.parent,
			size_of = size(icon_size, icon_size),
			position = props.position,
			anchor = props.anchor,
			transparent = true,
			zindex = props.zindex or 3,
			layout_order = props.layout_order,
		})
		local polylines = path.fit(path.flatten(icons.get(name_value)), icon_size, props.padding or 1)
		local stroke_scale = icon_size / icons.viewbox
		polygon.stroke_group(holder, polylines, stroke_width * stroke_scale, props.color or theme_current.color("foreground"), {
			zindex = props.zindex or 3,
			name = "icon_strokes",
			padding = 1,
		})
		return holder
	end
	if starts_with(tostring(name_value), "rbxassetid") or string.match(tostring(name_value), "^http") then
		return dom.image({
			name = "icon",
			parent = props.parent,
			image = name_value,
			size_of = size(props.size or theme_current.control.icon, props.size or theme_current.control.icon),
			position = props.position,
			anchor = props.anchor,
			color = props.color,
			zindex = props.zindex,
			layout_order = props.layout_order,
		})
	end
	return nil
end

function lucent_primitives.badge(props, children)
	props = props or {}
	local theme_current = theme.get()
	local variants = {
		default = { surface = "primary", ink = "primary_foreground" },
		secondary = { surface = "secondary", ink = "secondary_foreground" },
		destructive = { surface = "destructive", ink = "destructive_foreground" },
		success = { surface = "success", ink = "success_foreground" },
		warning = { surface = "warning", ink = "warning_foreground" },
		info = { surface = "info", ink = "info_foreground" },
		outline = { surface = nil, ink = "foreground" },
		muted = { surface = "muted", ink = "muted_foreground" },
	}
	local variant = variants[props.variant or "default"] or variants.default
	local instance = dom.frame({
		name = props.name or "badge",
		parent = props.parent,
		size_of = UDim2.new(0, 0, 0, props.height or 20),
		position = props.position,
		anchor = props.anchor,
		auto_size = Enum.AutomaticSize.X,
		color = variant.surface and theme_current.color(variant.surface) or nil,
		transparency = variant.surface and (props.transparency or 0) or 1,
		zindex = props.zindex or 2,
		layout_order = props.layout_order,
	})
	dom.corner(instance, theme_current.radius_of(props.radius or "full"))
	dom.padding(instance, 0, props.padding_x or 8, 0, props.padding_x or 8)
	dom.list(instance, { direction = Enum.FillDirection.Horizontal, gap = 5, vertical = Enum.VerticalAlignment.Center, horizontal = Enum.HorizontalAlignment.Center })
	if props.variant == "outline" then
		dom.stroke(instance, { color = theme_current.color("border_strong") })
	end
	if props.icon then
		lucent_primitives.icon({ name = props.icon, size = 12, parent = instance, color = theme_current.color(variant.ink), stroke_width = 2 })
	end
	if props.text then
		lucent_primitives.text({
			parent = instance,
			text = props.text,
			size = props.text_size or theme_current.type_of("2xs"),
			color = theme_current.color(variant.ink),
			font = "medium",
			auto_size = Enum.AutomaticSize.X,
			size_of = UDim2.new(0, 0, 0, props.text_size or theme_current.type_of("2xs")),
			zindex = props.zindex or 3,
		})
	end
	if props.dot then
		local dot = dom.frame({
			name = "dot",
			parent = instance,
			size_of = size(props.dot_size or 6, props.dot_size or 6),
			color = theme_current.color(props.dot_color or "success"),
			zindex = 4,
		})
		dom.corner(dot, 999)
	end
	if props.on_close then
		local close = dom.frame({ name = "close", parent = instance, size_of = size(12, 12), transparent = true, zindex = 4 })
		lucent_primitives.icon({ name = "close", size = 11, parent = close, color = theme_current.color(variant.ink), stroke_width = 2.2 })
		interaction.clickable(close).activated:connect(props.on_close)
	end
	if children then
		for _, child in children do
			if child then
				child.Parent = instance
			end
		end
	end
	return instance
end

function lucent_primitives.separator(props)
	props = props or {}
	local theme_current = theme.get()
	local instance = dom.frame({
		name = props.name or "separator",
		parent = props.parent,
		size_of = props.size_of or (props.direction == "vertical" and UDim2.new(0, 1, 1, 0) or UDim2.new(1, 0, 0, 1)),
		position = props.position,
		anchor = props.anchor,
		color = theme_current.color(props.color or "border"),
		transparency = props.transparency or 0,
		zindex = props.zindex or 2,
		layout_order = props.layout_order,
	})
	dom.corner(instance, 999)
	if props.label then
		local holder = dom.frame({
			name = "separator_holder",
			parent = props.parent,
			size_of = props.size_of or UDim2.new(1, 0, 0, 16),
			position = props.position,
			transparent = true,
			zindex = props.zindex or 2,
			layout_order = props.layout_order,
		})
		dom.list(holder, { direction = Enum.FillDirection.Horizontal, gap = 10, vertical = Enum.VerticalAlignment.Center })
		local line_left = dom.frame({ name = "line", parent = holder, size_of = UDim2.new(1, -20, 0, 1), color = theme_current.color("border"), zindex = 1 })
		lucent_primitives.text({ parent = holder, text = props.label, size = theme_current.type_of("2xs"), color_name = "muted_foreground", color = theme_current.color("muted_foreground"), auto_size = Enum.AutomaticSize.X, size_of = UDim2.new(0, 0, 0, 12), zindex = 2 })
		local line_right = dom.frame({ name = "line", parent = holder, size_of = UDim2.new(1, -20, 0, 1), color = theme_current.color("border"), zindex = 1 })
		instance:Destroy()
		return holder
	end
	return instance
end

function lucent_primitives.avatar(props)
	props = props or {}
	local theme_current = theme.get()
	local instance = dom.frame({
		name = props.name or "avatar",
		parent = props.parent,
		size_of = size(props.size or 36, props.size or 36),
		position = props.position,
		anchor = props.anchor,
		color = theme_current.color(props.color or "muted"),
		zindex = props.zindex or 2,
		clip = true,
		layout_order = props.layout_order,
	})
	dom.corner(instance, theme_current.radius_of(props.radius or "full"))
	if props.src then
		dom.image({
			parent = instance,
			image = props.src,
			size_of = UDim2.fromScale(1, 1),
			zindex = 1,
			scale_type = Enum.ScaleType.Crop,
		})
	elseif props.text then
		lucent_primitives.text({
			parent = instance,
			text = props.text,
			size = (props.size or 36) * 0.38,
			color = theme_current.color("foreground"),
			font = "medium",
			align_x = Enum.TextXAlignment.Center,
			size_of = UDim2.fromScale(1, 1),
			zindex = 2,
		})
	end
	if props.status then
		local status_colors = { online = "success", offline = "muted_foreground", busy = "destructive", away = "warning" }
		local dot = dom.frame({
			name = "status",
			parent = instance.Parent,
			size_of = size(9, 9),
			position = UDim2.new(1, -9, 1, -9),
			color = theme_current.color(status_colors[props.status] or "success"),
			zindex = (props.zindex or 2) + 2,
		})
		dom.corner(dot, 999)
		dom.stroke(dot, { color = theme_current.color("card"), thickness = 2 })
	end
	if props.ring then
		dom.stroke(instance, { color = theme_current.color(props.ring), thickness = 2 })
	end
	return instance
end

function lucent_primitives.spinner(props)
	props = props or {}
	local theme_current = theme.get()
	local instance = dom.frame({
		name = props.name or "spinner",
		parent = props.parent,
		size_of = size(props.size or 18, props.size or 18),
		position = props.position,
		anchor = props.anchor,
		transparent = true,
		zindex = props.zindex or 2,
	})
	local holder = dom.frame({
		name = "spin",
		parent = instance,
		size_of = UDim2.fromScale(1, 1),
		transparent = true,
		zindex = 1,
	})
	local radius = (props.size or 18) / 2
	local polylines = path.transform({ path.arc(radius, radius, radius - 1.6, 0.6, math_pi * 1.72, 24) }, 1)
	polygon.stroke_group(holder, polylines, props.thickness or 2, props.color or theme_current.color("primary"), { zindex = 1, padding = 1, caps = false })
	local spin_connection
	spin_connection = run_service.RenderStepped:Connect(function(dt)
		holder.Rotation += (props.speed or 320) * dt
	end)
	instance.Destroying:Connect(function()
		spin_connection:Disconnect()
	end)
	return instance
end

function lucent_primitives.skeleton(props)
	props = props or {}
	local theme_current = theme.get()
	local instance = dom.frame({
		name = props.name or "skeleton",
		parent = props.parent,
		size_of = props.size_of or UDim2.new(1, 0, 0, 12),
		position = props.position,
		anchor = props.anchor,
		color = theme_current.color(props.color or "muted"),
		zindex = props.zindex or 1,
		layout_order = props.layout_order,
	})
	dom.corner(instance, theme_current.radius_of(props.radius or "sm"))
	local pulse
	pulse = animation.spring({
		from = 0.25,
		to = 0.6,
		preset = "gentle",
		on_step = function(value)
			instance.BackgroundTransparency = value
		end,
		on_done = function()
			animation.spring({
				from = 0.6,
				to = 0.25,
				preset = "gentle",
				on_step = function(value)
					instance.BackgroundTransparency = value
				end,
				on_done = function()
					if instance.Parent then
						pulse = nil
					end
				end,
			})
		end,
	})
	return instance
end

function lucent_primitives.kbd(props)
	props = props or {}
	local theme_current = theme.get()
	local instance = dom.frame({
		name = props.name or "kbd",
		parent = props.parent,
		size_of = UDim2.new(0, 0, 0, props.height or 20),
		auto_size = Enum.AutomaticSize.X,
		color = theme_current.color(props.color or "muted"),
		zindex = props.zindex or 2,
		position = props.position,
	})
	dom.corner(instance, theme_current.radius_of("sm"))
	dom.stroke(instance, { color = theme_current.color("border_strong") })
	dom.padding(instance, 0, 6, 0, 6)
	lucent_primitives.text({
		parent = instance,
		text = props.text or "",
		size = theme_current.type_of("2xs"),
		color = theme_current.color("muted_foreground"),
		font = "medium",
		auto_size = Enum.AutomaticSize.X,
		size_of = UDim2.new(0, 0, 0, 12),
		zindex = 3,
	})
	return instance
end

function lucent_primitives.stacked(props, children)
	props = props or {}
	local holder = lucent_primitives.container(merge(props, { name = props.name or "stack", list = {
		direction = props.direction or Enum.FillDirection.Vertical,
		gap = props.gap or theme.get().space_of("sm"),
		horizontal = props.horizontal,
		vertical = props.vertical,
		wrap = props.wrap,
	} }), children)
	return holder
end

function lucent_primitives.scroll(props, children)
	props = props or {}
	local theme_current = theme.get()
	local instance = Instance.new("ScrollingFrame")
	instance.Name = props.name or "scroll"
	instance.BackgroundTransparency = props.transparency or 1
	instance.BackgroundColor3 = props.color or theme_current.color("card")
	instance.BorderSizePixel = 0
	instance.Size = props.size_of or UDim2.fromScale(1, 1)
	instance.Position = props.position or UDim2.new()
	instance.AnchorPoint = props.anchor or Vector2.zero
	instance.ZIndex = props.zindex or 1
	instance.CanvasSize = props.canvas or UDim2.new()
	instance.AutomaticCanvasSize = props.auto_canvas or Enum.AutomaticSize.Y
	instance.ScrollBarThickness = props.thickness or (props.hide_bar and 0 or 6)
	instance.ScrollBarImageTransparency = props.bar_transparency or 0.7
	instance.ScrollBarImageColor3 = props.bar_color or theme_current.color("border_strong")
	instance.ScrollingDirection = props.direction or Enum.ScrollingDirection.Y
	instance.ElasticBehavior = props.elastic or Enum.ElasticBehavior.WhenScrollable
	instance.VerticalScrollBarInset = props.inset or Enum.ScrollBarInset.None
	instance.ScrollingEnabled = props.enabled ~= false
	instance.ClipsDescendants = props.clip ~= false
	instance.LayoutOrder = props.layout_order or 0
	instance.ScrollBarCornerRadius = px(999)
	if props.parent then
		instance.Parent = props.parent
	end
	if props.padding then
		dom.padding(instance, props.padding, props.padding_right, props.padding_bottom, props.padding_left)
	end
	if props.list then
		dom.list(instance, props.list)
	end
	if props.grid then
		dom.grid(instance, props.grid)
	end
	if children then
		for _, child in children do
			if child then
				child.Parent = instance
			end
		end
	end
	return instance
end

function lucent_primitives.image(props)
	props = props or {}
	local theme_current = theme.get()
	local holder = dom.frame({
		name = props.name or "image_holder",
		parent = props.parent,
		size_of = props.size_of or size(120, 120),
		position = props.position,
		anchor = props.anchor,
		color = theme_current.color("muted"),
		zindex = props.zindex or 1,
		clip = props.clip ~= false,
		layout_order = props.layout_order,
	})
	dom.corner(holder, theme_current.radius_of(props.radius or "md"))
	dom.image({
		name = "image",
		parent = holder,
		image = props.src or "",
		size_of = UDim2.fromScale(1, 1),
		scale_type = props.scale_type or Enum.ScaleType.Crop,
		image_transparency = props.transparency,
		zindex = 1,
	})
	if props.fallback and (not props.src or props.src == "") then
		lucent_primitives.icon({ name = props.fallback or "image", size = (props.size_of or size(120, 120)).X.Offset * 0.3, parent = holder, color = theme_current.color("muted_foreground") })
	end
	if props.caption then
		lucent_primitives.text({ parent = holder, text = props.caption, size = theme_current.type_of("2xs"), color = theme_current.color("muted_foreground"), position = UDim2.new(0, 8, 1, -18), size_of = UDim2.new(1, -16, 0, 12), zindex = 3 })
	end
	return holder
end

local controls = {}

local button_variants = {
	default = { surface = "primary", ink = "primary_foreground", stroke = nil },
	secondary = { surface = "secondary", ink = "secondary_foreground", stroke = nil },
	outline = { surface = nil, ink = "foreground", stroke = "border_strong" },
	ghost = { surface = nil, ink = "foreground", stroke = nil },
	destructive = { surface = "destructive", ink = "destructive_foreground", stroke = nil },
	success = { surface = "success", ink = "success_foreground", stroke = nil },
	warning = { surface = "warning", ink = "warning_foreground", stroke = nil },
	info = { surface = "info", ink = "info_foreground", stroke = nil },
	link = { surface = nil, ink = "primary", stroke = nil },
	glass = { surface = "card", ink = "foreground", stroke = "border" },
}

local button_sizes = {
	sm = { height = 26, pad = 10, text = 12, icon = 14 },
	md = { height = 34, pad = 14, text = 13, icon = 16 },
	lg = { height = 42, pad = 18, text = 15, icon = 20 },
	icon = { height = 34, pad = 0, text = 13, icon = 16 },
}

function controls.button(props, children)
	props = props or {}
	local theme_current = theme.get()
	local variant = button_variants[props.variant or "default"] or button_variants.default
	local sizing = button_sizes[props.size or "md"] or button_sizes.md
	local height = props.height or sizing.height
	local instance = Instance.new("TextButton")
	instance.Name = props.name or "button"
	instance.AutoButtonColor = false
	instance.BackgroundColor3 = variant.surface and theme_current.color(variant.surface) or theme_current.color("card")
	instance.BackgroundTransparency = props.transparency or (variant.surface and 0 or 1)
	instance.BorderSizePixel = 0
	instance.Size = props.size_of or UDim2.new(0, 0, 0, height)
	instance.AutomaticSize = props.auto_size or Enum.AutomaticSize.X
	instance.Position = props.position or UDim2.new()
	instance.AnchorPoint = props.anchor or Vector2.zero
	instance.ZIndex = props.zindex or theme_current.layer_of("content")
	instance.Visible = props.visible ~= false
	instance.LayoutOrder = props.layout_order or 0
	instance.Text = ""
	instance.Active = true
	instance.ClipsDescendants = false
	if props.parent then
		instance.Parent = props.parent
	end
	dom.corner(instance, theme_current.radius_of(props.radius or "md"))
	if variant.stroke then
		dom.stroke(instance, { color = theme_current.color(variant.stroke), transparency = props.stroke_transparency or 0 })
	end
	local pad_x = props.padding_x or (props.icon_only and 0 or sizing.pad)
	dom.padding(instance, 0, height > 30 and pad_x or pad_x * 0.8, 0, height > 30 and pad_x or pad_x * 0.8)
	dom.list(instance, { direction = Enum.FillDirection.Horizontal, gap = props.gap or 7, vertical = Enum.VerticalAlignment.Center, horizontal = Enum.HorizontalAlignment.Center })

	local base_color = instance.BackgroundColor3
	local base_transparency = instance.BackgroundTransparency
	local foreground_color = theme_current.color(variant.ink)
	local states = interaction.clickable(instance, { enabled = props.enabled ~= false })

	local label
	if props.text then
		label = dom.text({
			name = "label",
			parent = instance,
			text = props.text,
			font = theme_current.font_of("medium"),
			size = props.text_size or sizing.text,
			color = foreground_color,
			auto_size = Enum.AutomaticSize.X,
			size_of = UDim2.new(0, 0, 0, props.text_size or sizing.text),
			zindex = instance.ZIndex + 1,
			truncate = props.truncate,
		})
	end
	if props.icon then
		controls._icon(instance, props.icon, sizing.icon, foreground_color, props.icon_position, instance.ZIndex + 1)
	end
	if props.loading then
		local spinner = lucent_primitives.spinner({ parent = instance, size = sizing.icon, color = foreground_color })
		spinner.LayoutOrder = -1
	end

	local hover_color = color.hover(instance.BackgroundColor3, 0.1)
	local pressed_color = color.pressed(instance.BackgroundColor3, 0.16)
	local hover_alpha = theme_current.alpha_value("hover")
	local pressed_alpha = theme_current.alpha_value("pressed")

	local function apply_transparency(value, alpha)
		if variant.surface then
			instance.BackgroundTransparency = lerp(base_transparency, 1, alpha or 0)
			instance.BackgroundColor3 = value
		else
			instance.BackgroundTransparency = lerp(1 - (alpha or 0), 1, 0)
			instance.BackgroundColor3 = value
		end
	end

	states.hovered:observe(function(hovering)
		if props.disabled then
			return
		end
		apply_transparency(hovering and hover_color or base_color, hovering and hover_alpha or 0)
	end)

	states.pressed:observe(function(is_pressed)
		if props.disabled then
			return
		end
		apply_transparency(is_pressed and pressed_color or (states.hovered:get() and hover_color or base_color), is_pressed and pressed_alpha or (states.hovered:get() and hover_alpha or 0))
	end)

	if props.disabled then
		instance.BackgroundTransparency = theme_current.alpha_value("disabled")
		if label then
			label.TextTransparency = theme_current.alpha_value("disabled")
		end
		states:set_enabled(false)
	end

	if props.on_click then
		states.activated:connect(function()
			if props.haptic then
				animation.pulse(instance, { peak = 0.96, preset = "snappy" })
			end
			props.on_click(instance)
		end)
	end

	if props.on_right_click then
		states.right_clicked:connect(function()
			props.on_right_click(instance)
		end)
	end

	if children then
		for _, child in children do
			if child then
				child.Parent = instance
			end
		end
	end

	return instance, states, label
end

function controls._icon(parent, name_value, icon_size, icon_color, position_value, zindex)
	local holder = lucent_primitives.icon({
		name = name_value,
		size = icon_size,
		parent = parent,
		color = icon_color,
		zindex = zindex,
		layout_order = position_value == "right" and 100 or -100,
	})
	return holder
end

function controls.icon_button(props)
	props = props or {}
	return controls.button(merge(props, { icon_only = not props.text, size_of = props.size_of or UDim2.new(0, 0, 0, props.height or 34), padding_x = 0 }))
end

function controls.toggle_group(props)
	props = props or {}
	local theme_current = theme.get()
	local selected = create_state(props.default or nil)
	local holder = lucent_primitives.container(merge(props, {
		name = props.name or "toggle_group",
		list = { direction = Enum.FillDirection.Horizontal, gap = props.gap or 4 },
		radius = props.radius or "md",
		color = theme_current.color("muted"),
		transparency = 0,
		padding = 3,
		auto_size = Enum.AutomaticSize.X,
	}))
	local buttons = {}
	local function refresh()
		for _, entry in buttons do
			local is_active = entry.value == selected:get()
			animation.spring({
				from = entry.button.BackgroundTransparency,
				to = is_active and 0 or 1,
				preset = "snappy",
				on_step = function(value)
					entry.button.BackgroundTransparency = value
					entry.label.TextTransparency = is_active and 0 or lerp(0, theme_current.alpha_value("disabled"), value)
				end,
			})
		end
	end
	for _, option in props.options or {} do
		local button = dom.frame({
			name = "option",
			parent = holder,
			size_of = UDim2.new(0, 0, 0, props.height or 28),
			auto_size = Enum.AutomaticSize.X,
			color = theme_current.color("card"),
			transparency = 1,
			zindex = 2,
		})
		dom.corner(button, theme_current.radius_of("sm"))
		dom.padding(button, 0, 10, 0, 10)
		local label = dom.text({
			parent = button,
			text = option.label or tostring(option.value),
			size = theme_current.type_of("xs"),
			color = theme_current.color("foreground"),
			font = "medium",
			auto_size = Enum.AutomaticSize.X,
			size_of = UDim2.new(0, 0, 0, 12),
			zindex = 3,
		})
		local entry = { value = option.value, button = button, label = label }
		table.insert(buttons, entry)
		interaction.clickable(button).activated:connect(function()
			selected:set(option.value)
			refresh()
			if props.on_change then
				props.on_change(option.value)
			end
		end)
		if option.icon then
			lucent_primitives.icon({ name = option.icon, size = 13, parent = button, color = theme_current.color("foreground"), layout_order = -1 })
		end
	end
	refresh()
	return holder, selected
end

function controls.card(props, children)
	props = props or {}
	local theme_current = theme.get()
	local instance = lucent_primitives.container({
		name = props.name or "card",
		parent = props.parent,
		size_of = props.size_of or UDim2.new(1, 0, 0, 0),
		position = props.position,
		anchor = props.anchor,
		auto_size = props.auto_size or Enum.AutomaticSize.Y,
		surface = props.surface or "card",
		transparency = props.transparency or 0,
		color = props.color,
		radius = props.radius or "lg",
		stroke = props.stroke ~= false,
		stroke_color = props.stroke_color,
		stroke_transparency = props.stroke_transparency,
		zindex = props.zindex or 1,
		clip = props.clip,
		layout_order = props.layout_order,
		list = { direction = Enum.FillDirection.Vertical, gap = 0 },
		shadow = props.shadow,
		padding = props.padding,
	})
	if props.interactive then
		instance.Active = true
		local states = interaction.clickable(instance)
		local base = instance.BackgroundColor3
		states.hovered:observe(function(hovering)
			instance.BackgroundColor3 = hovering and color.hover(base, 0.05) or base
		end)
		if props.on_click then
			states.activated:connect(function()
				props.on_click()
			end)
		end
	end
	if props.title or props.description or props.logo ~= false then
		local header = dom.frame({
			name = "header",
			parent = instance,
			size_of = UDim2.new(1, 0, 0, 0),
			auto_size = Enum.AutomaticSize.Y,
			transparent = true,
			zindex = 2,
		})
		dom.padding(header, props.header_padding or 16, props.header_padding or 16, props.title and (props.header_padding or 16) or 0, props.header_padding or 16)
		dom.list(header, { direction = Enum.FillDirection.Vertical, gap = 4 })
		local row = dom.frame({ name = "row", parent = header, size_of = UDim2.new(1, 0, 0, 0), auto_size = Enum.AutomaticSize.Y, transparent = true, zindex = 2 })
		dom.list(row, { direction = Enum.FillDirection.Horizontal, gap = 10, vertical = Enum.VerticalAlignment.Center })
		if brand.enabled_for("card_header") then
			brand_render.mark(row, { logo_size = props.logo_size or 20 })
		end
		if props.title then
			lucent_primitives.text({ parent = row, text = props.title, size = theme_current.type_of("lg"), font = "medium", color = theme_current.color("card_foreground"), auto_size = Enum.AutomaticSize.XY, size_of = UDim2.new(0, 0, 0, 0), zindex = 3 })
		end
		if props.badge then
			lucent_primitives.badge({ parent = row, text = props.badge, variant = props.badge_variant or "secondary" })
		end
		if props.description then
			lucent_primitives.text({ parent = header, text = props.description, size = theme_current.type_of("sm"), color = theme_current.color("muted_foreground"), auto_size = Enum.AutomaticSize.Y, size_of = UDim2.new(1, 0, 0, 0), zindex = 3, wrap = true })
		end
		if props.action then
			local action_holder = dom.frame({ name = "action", parent = header, size_of = UDim2.new(1, 0, 0, 0), auto_size = Enum.AutomaticSize.Y, transparent = true, zindex = 2 })
			dom.list(action_holder, { direction = Enum.FillDirection.Horizontal, gap = 8 })
			if type(props.action) == "table" then
				for _, item in props.action do
					if item then
						item.Parent = action_holder
					end
				end
			elseif props.action then
				props.action.Parent = action_holder
			end
		end
	end
	local body = dom.frame({
		name = "body",
		parent = instance,
		size_of = props.body_size or UDim2.new(1, 0, 0, 0),
		auto_size = props.body_auto or Enum.AutomaticSize.Y,
		transparent = true,
		zindex = 2,
	})
	if props.body_padding ~= 0 then
		dom.padding(body, props.body_padding or (props.title or props.description) and 16 or 16, props.body_padding or 16, props.body_padding or 16, props.body_padding or 16)
	end
	if props.body_list then
		dom.list(body, props.body_list)
	elseif props.body_padding ~= 0 or props.title then
		dom.list(body, { direction = Enum.FillDirection.Vertical, gap = props.body_gap or 12 })
	end
	if children then
		for _, child in children do
			if child then
				child.Parent = body
			end
		end
	end
	if props.footer then
		local footer = dom.frame({
			name = "footer",
			parent = instance,
			size_of = UDim2.new(1, 0, 0, 0),
			auto_size = Enum.AutomaticSize.Y,
			transparent = true,
			zindex = 2,
		})
		dom.padding(footer, 0, 16, 16, 16)
		dom.list(footer, { direction = Enum.FillDirection.Horizontal, gap = 8, horizontal = props.footer_align or Enum.HorizontalAlignment.Left, vertical = Enum.VerticalAlignment.Center })
		for _, item in props.footer do
			if item then
				item.Parent = footer
			end
		end
	end
	return instance, body
end

function controls.input(props)
	props = props or {}
	local theme_current = theme.get()
	local value = create_state(props.value or props.default or "")
	local focused = create_state(false)
	local height = props.height or theme_current.control.height

	local holder = dom.frame({
		name = props.name or "input_holder",
		parent = props.parent,
		size_of = props.size_of or UDim2.new(1, 0, 0, height),
		position = props.position,
		anchor = props.anchor,
		auto_size = props.auto_size,
		transparent = true,
		zindex = props.zindex or 2,
		layout_order = props.layout_order,
	})

	local field = dom.frame({
		name = "field",
		parent = holder,
		size_of = UDim2.new(1, 0, 1, 0),
		color = props.variant == "filled" and theme_current.color("muted") or theme_current.color("input"),
		transparency = props.transparency or 0,
		zindex = 1,
		clip = true,
	})
	dom.corner(field, theme_current.radius_of(props.radius or "md"))
	local stroke = dom.stroke(field, { color = theme_current.color("border"), transparency = props.variant == "ghost" and 1 or 0 })

	dom.padding(field, 0, props.padding_x or 10, 0, props.padding_x or 10)
	dom.list(field, { direction = Enum.FillDirection.Horizontal, gap = 8, vertical = Enum.VerticalAlignment.Center })

	if props.icon then
		lucent_primitives.icon({ name = props.icon, size = theme_current.control.icon, parent = field, color = theme_current.color("muted_foreground") })
	end

	local box = Instance.new("TextBox")
	box.Name = "box"
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	box.PlaceholderText = props.placeholder or ""
	box.PlaceholderColor3 = theme_current.color("muted_foreground")
	box.Text = value:get()
	box.TextColor3 = props.disabled and theme_current.color("muted_foreground") or theme_current.color("foreground")
	box.TextSize = props.text_size or theme_current.type_of("sm")
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.TextYAlignment = Enum.TextYAlignment.Center
	box.Size = UDim2.new(1, 0, 1, 0)
	box.ZIndex = 3
	box.MultiLine = false
	box.TextEditable = props.disabled ~= true
	box.SelectionImageObject = nil
	box.RichText = false
	box.Parent = field

	if props.password then
		box.Text = string.rep("•", #value:get())
	end

	if props.suffix or props.prefix then
		lucent_primitives.text({ parent = field, text = props.suffix or props.prefix, size = theme_current.type_of("xs"), color = theme_current.color("muted_foreground"), auto_size = Enum.AutomaticSize.X, size_of = UDim2.new(0, 0, 0, 12), zindex = 3 })
	end

	if props.clearable then
		local clear = dom.frame({ name = "clear", parent = field, size_of = size(14, 14), transparent = true, zindex = 5 })
		lucent_primitives.icon({ name = "close", size = 12, parent = clear, color = theme_current.color("muted_foreground"), stroke_width = 2.2 })
		interaction.clickable(clear).activated:connect(function()
			value:set("")
			box.Text = ""
		end)
	end

	box.Focused:Connect(function()
		focused:set(true)
		animation.spring({
			from = stroke.Transparency,
			to = 0,
			preset = "snappy",
			on_step = function(alpha)
				stroke.Color = color.mix(theme_current.color("border"), theme_current.color("ring"), alpha)
				stroke.Thickness = lerp(1, 2, alpha)
			end,
		})
	end)

	box.FocusLost:Connect(function(enter_pressed)
		focused:set(false)
		animation.spring({
			from = 1,
			to = 0,
			preset = "snappy",
			on_step = function(alpha)
				stroke.Color = color.mix(theme_current.color("ring"), theme_current.color("border"), alpha)
				stroke.Thickness = lerp(2, 1, alpha)
			end,
		})
		if props.on_submit and enter_pressed then
			props.on_submit(value:get())
		end
	end)

	box:GetPropertyChangedSignal("Text"):Connect(function()
		if props.password then
			local raw = string.gsub(box.Text, "•", "")
			value:set(raw)
			if props.on_change then
				props.on_change(raw)
			end
		else
			value:set(box.Text)
			if props.on_change then
				props.on_change(box.Text)
			end
		end
	end)

	if props.label then
		local label = lucent_primitives.text({
			parent = holder,
			text = props.label,
			size = theme_current.type_of("xs"),
			color = theme_current.color("foreground"),
			font = "medium",
			position = UDim2.new(0, 2, 0, -15),
			size_of = UDim2.new(1, 0, 0, 12),
			zindex = 3,
		})
	end
	if props.hint then
		lucent_primitives.text({
			parent = holder,
			text = props.hint,
			size = theme_current.type_of("2xs"),
			color = theme_current.color("muted_foreground"),
			position = UDim2.new(0, 2, 1, 2),
			size_of = UDim2.new(1, 0, 0, 12),
			zindex = 3,
		})
	end

	return holder, value, box, field, stroke
end

function controls.textarea(props)
	props = props or {}
	local theme_current = theme.get()
	local height = props.height or 90
	local holder = dom.frame({
		name = props.name or "textarea_holder",
		parent = props.parent,
		size_of = props.size_of or UDim2.new(1, 0, 0, height),
		position = props.position,
		transparent = true,
		zindex = props.zindex or 2,
		layout_order = props.layout_order,
	})
	local field = dom.frame({
		name = "field",
		parent = holder,
		size_of = UDim2.new(1, 0, 1, 0),
		color = theme_current.color("input"),
		zindex = 1,
		clip = true,
	})
	dom.corner(field, theme_current.radius_of(props.radius or "md"))
	local stroke = dom.stroke(field, { color = theme_current.color("border") })
	dom.padding(field, 9, 10, 9, 10)
	local box = Instance.new("TextBox")
	box.Name = "box"
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	box.PlaceholderText = props.placeholder or ""
	box.PlaceholderColor3 = theme_current.color("muted_foreground")
	box.Text = props.value or props.default or ""
	box.TextColor3 = theme_current.color("foreground")
	box.TextSize = props.text_size or theme_current.type_of("sm")
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.TextYAlignment = Enum.TextYAlignment.Top
	box.MultiLine = true
	box.TextWrapped = true
	box.Size = UDim2.new(1, 0, 1, 0)
	box.ZIndex = 3
	box.Parent = field
	local value = create_state(box.Text)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		value:set(box.Text)
		if props.on_change then
			props.on_change(box.Text)
		end
	end)
	box.Focused:Connect(function()
		stroke.Color = theme_current.color("ring")
		stroke.Thickness = 2
	end)
	box.FocusLost:Connect(function()
		stroke.Color = theme_current.color("border")
		stroke.Thickness = 1
	end)
	return holder, value, box
end

function controls.switch(props)
	props = props or {}
	local theme_current = theme.get()
	local value = create_state(props.default or false)
	local width = props.width or 42
	local height = props.height or 24
	local instance = dom.frame({
		name = props.name or "switch",
		parent = props.parent,
		size_of = size(width, height),
		position = props.position,
		anchor = props.anchor,
		color = theme_current.color(value:get() and (props.active_color or "primary") or "muted"),
		zindex = props.zindex or 2,
		layout_order = props.layout_order,
	})
	dom.corner(instance, 999)
	local knob = dom.frame({
		name = "knob",
		parent = instance,
		size_of = size(height - 6, height - 6),
		position = UDim2.new(0, 3, 0.5, 0),
		anchor = Vector2.new(0, 0.5),
		color = theme_current.color(props.knob_color or "foreground"),
		zindex = instance.ZIndex + 1,
	})
	dom.corner(knob, 999)
	if props.disabled then
		instance.BackgroundTransparency = theme_current.alpha_value("disabled")
	end

	local function refresh(animate)
		local active = value:get()
		local target_position = active and (width - height + 3) or 3
		local target_color = theme_current.color(active and (props.active_color or "primary") or "muted")
		if animate then
			animation.spring({
				from = knob.Position.X.Offset,
				to = target_position,
				preset = props.preset or "snappy",
				on_step = function(alpha)
					knob.Position = UDim2.new(0, alpha, 0.5, 0)
				end,
			})
			local from_color = instance.BackgroundColor3
			animation.spring({
				from = 0,
				to = 1,
				preset = "snappy",
				on_step = function(alpha)
					instance.BackgroundColor3 = from_color:Lerp(target_color, alpha)
				end,
			})
		else
			knob.Position = UDim2.new(0, target_position, 0.5, 0)
			instance.BackgroundColor3 = target_color
		end
	end
	refresh(false)

	if not props.disabled then
		interaction.clickable(instance).activated:connect(function()
			value:set(not value:get())
			refresh(true)
			if props.on_change then
				props.on_change(value:get())
			end
		end)
	end

	if props.label then
		local holder = dom.frame({ name = "switch_row", parent = props.parent, size_of = UDim2.new(1, 0, 0, height), transparent = true, zindex = props.zindex or 2 })
		dom.list(holder, { direction = Enum.FillDirection.Horizontal, gap = 10, vertical = Enum.VerticalAlignment.Center })
		instance.Parent = holder
		instance.LayoutOrder = 100
		lucent_primitives.text({ parent = holder, text = props.label, size = theme_current.type_of("sm"), color = theme_current.color("foreground"), auto_size = Enum.AutomaticSize.X, size_of = UDim2.new(0, 0, 0, 14), zindex = 3 })
		return holder, value
	end

	return instance, value
end

function controls.checkbox(props)
	props = props or {}
	local theme_current = theme.get()
	local value = create_state(props.default or false)
	local size_value = props.size or 18
	local instance = dom.frame({
		name = props.name or "checkbox",
		parent = props.parent,
		size_of = size(size_value, size_value),
		position = props.position,
		anchor = props.anchor,
		color = theme_current.color(props.color or "card"),
		zindex = props.zindex or 2,
		clip = true,
		layout_order = props.layout_order,
	})
	dom.corner(instance, theme_current.radius_of(props.radius or "xs"))
	dom.stroke(instance, { color = theme_current.color(value:get() and (props.active_color or "primary") or "border_strong") })
	local check = lucent_primitives.icon({
		name = props.indeterminate and "minus" or "check",
		size = size_value - 6,
		parent = instance,
		color = theme_current.color((props.active_color == "primary" and "primary_foreground") or "primary_foreground"),
		stroke_width = 2.6,
		zindex = 3,
	})
	check.Position = UDim2.fromScale(0.5, 0.5)
	check.AnchorPoint = Vector2.new(0.5, 0.5)
	check.GroupTransparency = value:get() and 0 or 1

	local function refresh()
		local active = value:get()
		animation.spring({
			from = instance.BackgroundTransparency,
			to = active and 0 or 1,
			preset = "snappy",
			on_step = function(alpha)
				instance.BackgroundColor3 = color.mix(theme_current.color("card"), theme_current.color(props.active_color or "primary"), alpha)
				check.GroupTransparency = 1 - alpha
			end,
		})
	end
	refresh()

	if not props.disabled then
		interaction.clickable(instance).activated:connect(function()
			value:set(not value:get())
			refresh()
			animation.pulse(check, { peak = 1.2, preset = "bouncy" })
			if props.on_change then
				props.on_change(value:get())
			end
		end)
	end

	if props.label or props.description then
		local holder = dom.frame({ name = "checkbox_row", parent = props.parent, size_of = UDim2.new(1, 0, 0, size_value), auto_size = Enum.AutomaticSize.Y, transparent = true, zindex = props.zindex or 2, layout_order = props.layout_order })
		dom.list(holder, { direction = Enum.FillDirection.Horizontal, gap = 10, vertical = Enum.VerticalAlignment.Top })
		instance.Parent = holder
		local text_holder = dom.frame({ name = "text", parent = holder, size_of = UDim2.new(1, -size_value - 10, 0, 0), auto_size = Enum.AutomaticSize.Y, transparent = true, zindex = 2 })
		dom.list(text_holder, { direction = Enum.FillDirection.Vertical, gap = 2 })
		lucent_primitives.text({ parent = text_holder, text = props.label or "", size = theme_current.type_of("sm"), color = theme_current.color("foreground"), auto_size = Enum.AutomaticSize.Y, size_of = UDim2.new(1, 0, 0, 0), zindex = 3, wrap = true })
		if props.description then
			lucent_primitives.text({ parent = text_holder, text = props.description, size = theme_current.type_of("2xs"), color = theme_current.color("muted_foreground"), auto_size = Enum.AutomaticSize.Y, size_of = UDim2.new(1, 0, 0, 0), zindex = 3, wrap = true })
		end
		return holder, value
	end
	return instance, value
end

function controls.radio_group(props)
	props = props or {}
	local theme_current = theme.get()
	local value = create_state(props.default or nil)
	local holder = lucent_primitives.container(merge(props, {
		name = props.name or "radio_group",
		list = { direction = props.direction or Enum.FillDirection.Vertical, gap = props.gap or 10 },
		transparent = true,
	}))
	local entries = {}
	for _, option in props.options or {} do
		local row = dom.frame({ name = "option", parent = holder, size_of = UDim2.new(1, 0, 0, 20), transparent = true, zindex = 2 })
		dom.list(row, { direction = Enum.FillDirection.Horizontal, gap = 9, vertical = Enum.VerticalAlignment.Center })
		local circle = dom.frame({ name = "circle", parent = row, size_of = size(18, 18), color = theme_current.color("card"), zindex = 2 })
		dom.corner(circle, 999)
		local ring_stroke = dom.stroke(circle, { color = theme_current.color("border_strong") })
		local dot = dom.frame({ name = "dot", parent = circle, size_of = size(9, 9), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), color = theme_current.color("primary"), zindex = 3 })
		dom.corner(dot, 999)
		dot.BackgroundTransparency = 1
		dot.Size = UDim2.fromOffset(2, 2)
		lucent_primitives.text({ parent = row, text = option.label or tostring(option.value), size = theme_current.type_of("sm"), color = theme_current.color("foreground"), auto_size = Enum.AutomaticSize.X, size_of = UDim2.new(0, 0, 0, 14), zindex = 3 })
		table.insert(entries, { option = option, circle = circle, dot = dot, ring = ring_stroke })
		interaction.clickable(row).activated:connect(function()
			value:set(option.value)
			for _, entry in entries do
				local active = entry.option.value == value:get()
				animation.spring({
					from = entry.dot.Size.X.Offset,
					to = active and 9 or 2,
					preset = "bouncy",
					on_step = function(alpha)
						entry.dot.Size = UDim2.fromOffset(alpha, alpha)
						entry.dot.BackgroundTransparency = 1 - clamp01((alpha - 2) / 7)
					end,
				})
			end
			if props.on_change then
				props.on_change(option.value)
			end
		end)
	end
	return holder, value
end

function controls.slider(props)
	props = props or {}
	local theme_current = theme.get()
	local min_value = props.min or 0
	local max_value = props.max or 100
	local step_value = props.step or 1
	local value = create_state(clamp(props.default or min_value, min_value, max_value))
	local height = props.height or 20
	local holder = dom.frame({
		name = props.name or "slider_holder",
		parent = props.parent,
		size_of = props.size_of or UDim2.new(1, 0, 0, height),
		position = props.position,
		transparent = true,
		zindex = props.zindex or 2,
		layout_order = props.layout_order,
	})
	local track = dom.frame({
		name = "track",
		parent = holder,
		size_of = UDim2.new(1, 0, 0, props.track_height or 5),
		position = UDim2.fromScale(0, 0.5),
		anchor = Vector2.new(0, 0.5),
		color = theme_current.color("muted"),
		zindex = 1,
	})
	dom.corner(track, 999)
	local fill = dom.frame({
		name = "fill",
		parent = track,
		size_of = UDim2.new(0, 0, 1, 0),
		color = theme_current.color(props.color or "primary"),
		zindex = 2,
	})
	dom.corner(fill, 999)
	local knob = dom.frame({
		name = "knob",
		parent = holder,
		size_of = size(props.knob_size or 15, props.knob_size or 15),
		position = UDim2.new(0, 0, 0.5, 0),
		anchor = Vector2.new(0.5, 0.5),
		color = theme_current.color(props.knob_color or "foreground"),
		zindex = 4,
	})
	dom.corner(knob, 999)
	dom.stroke(knob, { color = theme_current.color(props.color or "primary"), thickness = 2, transparency = 0.4 })

	local function ratio_of(current)
		return clamp01(inverse_lerp(min_value, max_value, current))
	end

	local function paint(current, animate)
		local ratio = ratio_of(current)
		if animate then
			animation.spring({
				from = fill.Size.X.Scale,
				to = ratio,
				preset = "precise",
				on_step = function(alpha)
					fill.Size = UDim2.fromScale(alpha, 1)
					knob.Position = UDim2.new(alpha, 0, 0.5, 0)
				end,
			})
		else
			fill.Size = UDim2.fromScale(ratio, 1)
			knob.Position = UDim2.new(ratio, 0, 0.5, 0)
		end
	end
	paint(value:get(), false)

	local dragging = false
	local function update_from_x(x)
		local ratio = clamp01((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X))
		local raw = lerp(min_value, max_value, ratio)
		local snapped = round(raw / step_value) * step_value
		local next_value = clamp(snapped, min_value, max_value)
		if next_value ~= value:get() then
			value:set(next_value)
			paint(next_value, true)
			if props.on_change then
				props.on_change(next_value)
			end
		end
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			update_from_x(input.Position.X)
			animation.spring({ from = knob.Size.X.Offset, to = (props.knob_size or 15) * 1.25, preset = "snappy", on_step = function(alpha)
				knob.Size = UDim2.fromOffset(alpha, alpha)
			end })
		end
	end)
	input_service.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update_from_x(input.Position.X)
		end
	end)
	input_service.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			animation.spring({ from = knob.Size.X.Offset, to = props.knob_size or 15, preset = "snappy", on_step = function(alpha)
				knob.Size = UDim2.fromOffset(alpha, alpha)
			end })
			if props.on_done then
				props.on_done(value:get())
			end
		end
	end)

	if props.label or props.show_value then
		local head = dom.frame({ name = "head", parent = holder, size_of = UDim2.new(1, 0, 0, 16), position = UDim2.new(0, 0, 0, -18), transparent = true, zindex = 2 })
		if props.label then
			lucent_primitives.text({ parent = head, text = props.label, size = theme_current.type_of("xs"), color = theme_current.color("foreground"), font = "medium", size_of = UDim2.new(0.5, 0, 1, 0), zindex = 3 })
		end
		if props.show_value ~= false then
			local readout = lucent_primitives.text({
				parent = head,
				text = (props.format and props.format(value:get())) or comma(value:get(), props.digits or 0),
				size = theme_current.type_of("xs"),
				color = theme_current.color("muted_foreground"),
				align_x = Enum.TextXAlignment.Right,
				size_of = UDim2.new(0.5, 0, 1, 0),
				position = UDim2.fromScale(0.5, 0),
				zindex = 3,
			})
			value:observe(function(current)
				readout.Text = (props.format and props.format(current)) or comma(current, props.digits or 0)
			end)
		end
	end

	return holder, value
end

local overlays = {}

local function scrim(parent, options)
	options = options or {}
	local theme_current = theme.get()
	local blocker = dom.frame({
		name = "scrim",
		parent = parent,
		size_of = UDim2.fromScale(1, 1),
		color = type(options.color) == "string" and theme_current.color(options.color) or (options.color or theme_current.color("overlay")),
		transparency = 1,
		zindex = options.zindex or theme_current.layer_of("overlay"),
		active = true,
		visible = false,
	})
	if options.blur then
		local blur = Instance.new("ImageLabel")
		blur.Name = "blur"
		blur.BackgroundTransparency = 1
		blur.Image = "rbxassetid://8992230677"
		blur.ScaleType = Enum.ScaleType.Stretch
		blur.Size = UDim2.fromScale(1, 1)
		blur.ImageTransparency = 1
		blur.ZIndex = blocker.ZIndex
		blur.Parent = blocker
	end
	return blocker
end

function overlays.create(kind, props)
	props = props or {}
	local theme_current = theme.get()
	local layer_name = kind == "toast" and "toast" or kind == "tooltip" and "tooltip" or "dialog"
	local root = shell.layer(layer_name, theme_current.layer_of(layer_name))
	local instance = dom.frame({
		name = props.name or kind,
		parent = root,
		size_of = UDim2.fromScale(1, 1),
		transparent = true,
		zindex = theme_current.layer_of(layer_name),
		visible = false,
	})
	local blocker = scrim(instance, { color = props.scrim_color, zindex = 1, blur = props.blur })
	local surface = dom.frame({
		name = "surface",
		parent = instance,
		size_of = props.size_of or UDim2.fromOffset(400, 260),
		position = props.position or UDim2.fromScale(0.5, 0.5),
		anchor = props.anchor or Vector2.new(0.5, 0.5),
		color = theme_current.color(props.surface or (kind == "tooltip" and "popover" or "popover")),
		transparency = 0,
		zindex = 3,
		clip = props.clip ~= false,
		auto_size = props.auto_size,
	})
	dom.corner(surface, theme_current.radius_of(props.radius or (kind == "tooltip" and "sm" or "xl")))
	if props.stroke ~= false then
		dom.stroke(surface, { color = theme_current.color("border") })
	end
	if props.shadow ~= false then
		dom.shadow(surface, { width = (props.size_of and props.size_of.X.Offset or 400) + 60, height = (props.size_of and props.size_of.Y.Offset or 260) + 60, transparency = theme_current.alpha_value("shadow") })
	end
	local content = dom.frame({
		name = "content",
		parent = surface,
		size_of = UDim2.fromScale(1, 1),
		transparent = true,
		zindex = 4,
	})
	if props.padding ~= 0 then
		dom.padding(content, props.padding or 18)
	end
	dom.list(content, { direction = Enum.FillDirection.Vertical, gap = props.gap or 14 })

	local api = {
		kind = kind,
		root = instance,
		surface = surface,
		content = content,
		scrim = blocker,
		open = create_state(false),
		closed = create_signal(),
		opened = create_signal(),
		_trove = create_trove(),
	}

	local close_animation
	function api:show()
		if api.open:get() then
			return api
		end
		api.open:set(true)
		instance.Visible = true
		blocker.Visible = true
		blocker.BackgroundTransparency = 1
		local enter = kind == "dialog" and { from = 0.86, to = 1, from_t = 0.35, to_t = 0 } or { from = 0.94, to = 1, from_t = 0.4, to_t = 0 }
		local base_size = surface.Size
		animation.tween(blocker, { BackgroundTransparency = props.scrim_transparency or theme_current.alpha_value("overlay") }, { duration = theme_current.motion.base, ease = "quad" })
		surface.Size = UDim2.new(base_size.X.Scale, base_size.X.Offset * enter.from, base_size.Y.Scale, base_size.Y.Offset * enter.from)
		surface.BackgroundTransparency = enter.from_t
		surface.UIScale = nil
		local scale = dom.scale(surface, enter.from)
		animation.spring({
			from = enter.from,
			to = 1,
			preset = props.preset or "snappy",
			on_step = function(alpha)
				scale.Scale = alpha
				surface.BackgroundTransparency = lerp(enter.from_t, 0, clamp01((alpha - enter.from) / math.max(0.001, 1 - enter.from)))
			end,
			on_done = function()
				scale.Scale = 1
				surface.BackgroundTransparency = 0
				api.opened:fire()
			end,
		})
		return api
	end

	function api:hide()
		if not api.open:get() then
			return api
		end
		api.open:set(false)
		local scale = surface:FindFirstChildOfClass("UIScale") or dom.scale(surface, 1)
		animation.tween(blocker, { BackgroundTransparency = 1 }, { duration = theme_current.motion.fast, ease = "quad" })
		animation.spring({
			from = scale.Scale,
			to = 0.9,
			preset = "precise",
			on_step = function(alpha)
				scale.Scale = alpha
				surface.BackgroundTransparency = clamp01((1 - alpha) * 2)
			end,
			on_done = function()
				instance.Visible = false
				blocker.Visible = false
				scale.Scale = 1
				surface.BackgroundTransparency = 0
				api.closed:fire()
			end,
		})
		return api
	end

	function api:toggle()
		if api.open:get() then
			api:hide()
		else
			api:show()
		end
		return api
	end

	function api:set_title(title, description)
		local header = surface:FindFirstChild("header") or dom.frame({ name = "header", parent = content, size_of = UDim2.new(1, 0, 0, 0), auto_size = Enum.AutomaticSize.Y, transparent = true, zindex = 5 })
		dom.list(header, { direction = Enum.FillDirection.Vertical, gap = 5 })
		local row = header:FindFirstChild("row") or dom.frame({ name = "row", parent = header, size_of = UDim2.new(1, 0, 0, 0), auto_size = Enum.AutomaticSize.Y, transparent = true, zindex = 5 })
		dom.list(row, { direction = Enum.FillDirection.Horizontal, gap = 10, vertical = Enum.VerticalAlignment.Center })
		if brand.enabled_for("dialog") then
			brand_render.mark(row, { logo_size = props.logo_size or 20 })
		end
		local title_label = row:FindFirstChild("title") or lucent_primitives.text({ name = "title", parent = row, text = title or "", size = theme_current.type_of("xl"), font = "medium", color = theme_current.color("popover_foreground"), auto_size = Enum.AutomaticSize.XY, size_of = UDim2.new(0, 0, 0, 0), zindex = 6 })
		title_label.Text = title or ""
		if description then
			local description_label = header:FindFirstChild("description") or lucent_primitives.text({ name = "description", parent = header, text = description, size = theme_current.type_of("sm"), color = theme_current.color("muted_foreground"), auto_size = Enum.AutomaticSize.Y, size_of = UDim2.new(1, 0, 0, 0), zindex = 6, wrap = true })
			description_label.Text = description
		end
		return header
	end

	function api:set_footer(children)
		local footer = surface:FindFirstChild("footer") or dom.frame({ name = "footer", parent = content, size_of = UDim2.new(1, 0, 0, 0), auto_size = Enum.AutomaticSize.Y, transparent = true, zindex = 5 })
		dom.list(footer, { direction = Enum.FillDirection.Horizontal, gap = 8, horizontal = Enum.HorizontalAlignment.Right, vertical = Enum.VerticalAlignment.Center })
		for _, child in children or {} do
			if child then
				child.Parent = footer
			end
		end
		return footer
	end

	function api:destroy()
		api._trove:destroy()
		instance:Destroy()
	end

	blocker.InputBegan:Connect(function(input)
		if props.dismissible ~= false and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			api:hide()
		end
	end)

	interaction.keybind(Enum.KeyCode.Escape, function()
		if api.open:get() and props.close_on_escape ~= false then
			api:hide()
		end
	end)

	return api
end

function overlays.dialog(props)
	props = props or {}
	local api = overlays.create("dialog", merge(props, { size_of = props.size_of or UDim2.fromOffset(props.width or 420, props.height or 0), auto_size = props.height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y }))
	if props.title or props.description then
		api:set_title(props.title, props.description)
	end
	if props.body then
		for _, child in props.body do
			if child then
				child.Parent = api.content
			end
		end
	end
	local buttons = {}
	if props.cancel_text then
		table.insert(buttons, (controls.button({ text = props.cancel_text, variant = props.cancel_variant or "outline", size = props.button_size or "md", on_click = function()
			api:hide()
			if props.on_cancel then
				props.on_cancel()
			end
		end })))
	end
	if props.confirm_text then
		table.insert(buttons, (controls.button({ text = props.confirm_text, variant = props.confirm_variant or "default", size = props.button_size or "md", on_click = function()
			if props.on_confirm then
				props.on_confirm()
			end
			if props.close_on_confirm ~= false then
				api:hide()
			end
		end })))
	end
	if #buttons > 0 then
		api:set_footer(buttons)
	end
	if props.open then
		api:show()
	end
	return api
end

function overlays.drawer(props)
	props = props or {}
	local theme_current = theme.get()
	local side = props.side or "right"
	local width = props.width or 320
	local api = overlays.create("dialog", merge(props, {
		size_of = UDim2.new(0, width, 1, 0),
		position = side == "right" and UDim2.fromScale(1, 0) or side == "left" and UDim2.fromScale(0, 0) or side == "bottom" and UDim2.fromScale(0, 1) or UDim2.fromScale(0, 0),
		anchor = side == "right" and Vector2.new(1, 0) or side == "left" and Vector2.new(0, 0) or side == "bottom" and Vector2.new(0, 1) or Vector2.new(0, 0),
		radius = props.radius or "none",
	}))
	if side == "bottom" then
		api.surface.Size = UDim2.new(1, 0, 0, props.height or 300)
	end

	local origin = api.surface.Position
	local function offset_position(progress)
		if side == "right" then
			return UDim2.new(1, width * progress, 0, 0)
		elseif side == "left" then
			return UDim2.new(0, -width * progress, 0, 0)
		elseif side == "bottom" then
			return UDim2.new(0, 0, 1, (props.height or 300) * progress)
		end
		return UDim2.new(0, 0, 0, -width * progress)
	end

	local original_show = api.show
	function api:show()
		if api.open:get() then
			return api
		end
		api.open:set(true)
		api.root.Visible = true
		api.scrim.Visible = true
		api.scrim.BackgroundTransparency = 1
		animation.tween(api.scrim, { BackgroundTransparency = theme_current.alpha_value("overlay") }, { duration = theme_current.motion.base, ease = "quad" })
		api.surface.Position = offset_position(1)
		animation.spring({
			from = 1,
			to = 0,
			preset = props.preset or "smooth",
			on_step = function(alpha)
				api.surface.Position = offset_position(alpha)
			end,
			on_done = function()
				api.opened:fire()
			end,
		})
		return api
	end

	local original_hide = api.hide
	function api:hide()
		if not api.open:get() then
			return api
		end
		api.open:set(false)
		animation.tween(api.scrim, { BackgroundTransparency = 1 }, { duration = theme_current.motion.fast, ease = "quad" })
		animation.spring({
			from = 0,
			to = 1,
			preset = "precise",
			on_step = function(alpha)
				api.surface.Position = offset_position(alpha)
			end,
			on_done = function()
				api.root.Visible = false
				api.scrim.Visible = false
				api.closed:fire()
			end,
		})
		return api
	end

	if props.title or props.description then
		api:set_title(props.title, props.description)
	end
	if brand.enabled_for("drawer") then
		brand_render.mark(api.content, { logo_size = props.logo_size or 24 })
	end
	if props.body then
		for _, child in props.body do
			if child then
				child.Parent = api.content
			end
		end
	end
	if props.open then
		api:show()
	end
	return api
end

function overlays.menu(props)
	props = props or {}
	local theme_current = theme.get()
	local root = shell.layer("dropdown", theme_current.layer_of("dropdown"))
	local instance = dom.frame({
		name = props.name or "menu",
		parent = root,
		size_of = UDim2.new(0, props.width or 200, 0, 0),
		position = props.position or UDim2.new(),
		auto_size = Enum.AutomaticSize.Y,
		color = theme_current.color("popover"),
		zindex = theme_current.layer_of("dropdown"),
		visible = false,
		clip = false,
	})
	dom.corner(instance, theme_current.radius_of(props.radius or "md"))
	dom.stroke(instance, { color = theme_current.color("border") })
	dom.shadow(instance, { width = (props.width or 200) + 50, height = 260, transparency = theme_current.alpha_value("shadow") })
	dom.padding(instance, 5, 5, 5, 5)
	local list = dom.list(instance, { direction = Enum.FillDirection.Vertical, gap = 1 })

	local api = { root = instance, open = create_state(false), items = {}, selected = create_signal() }
	local scale = dom.scale(instance, 1)

	function api:item(item_props)
		local row = dom.frame({
			name = "item",
			parent = instance,
			size_of = UDim2.new(1, 0, 0, item_props.height or 32),
			color = theme_current.color("accent"),
			transparency = 1,
			zindex = instance.ZIndex + 1,
			layout_order = #api.items,
		})
		dom.corner(row, theme_current.radius_of("sm"))
		dom.padding(row, 0, 8, 0, 8)
		dom.list(row, { direction = Enum.FillDirection.Horizontal, gap = 8, vertical = Enum.VerticalAlignment.Center })
		if item_props.icon then
			lucent_primitives.icon({ name = item_props.icon, size = 15, parent = row, color = theme_current.color(item_props.danger and "destructive" or "foreground") })
		end
		lucent_primitives.text({
			parent = row,
			text = item_props.label or "",
			size = theme_current.type_of("sm"),
			color = theme_current.color(item_props.danger and "destructive" or "foreground"),
			size_of = UDim2.new(1, item_props.shortcut and -50 or 0, 1, 0),
			zindex = row.ZIndex + 1,
			font = "medium",
		})
		if item_props.shortcut then
			lucent_primitives.kbd({ parent = row, text = item_props.shortcut })
		end
		local states = interaction.clickable(row)
		states.hovered:observe(function(hovering)
			animation.tween(row, { BackgroundTransparency = hovering and 0 or 1 }, { duration = theme_current.motion.fast, ease = "quad" })
		end)
		states.activated:connect(function()
			api.selected:fire(item_props.value or item_props.label)
			if item_props.on_select then
				item_props.on_select()
			end
			if props.close_on_select ~= false then
				api:close()
			end
		end)
		table.insert(api.items, row)
		return row
	end

	function api:separator()
		return lucent_primitives.separator({ parent = instance, size_of = UDim2.new(1, 0, 0, 1), color = "border", layout_order = #api.items })
	end

	function api:label(text)
		return lucent_primitives.text({ parent = instance, text = text, size = theme_current.type_of("2xs"), color = theme_current.color("muted_foreground"), font = "medium", size_of = UDim2.new(1, -6, 0, 12), zindex = instance.ZIndex + 1, layout_order = #api.items })
	end

	function api:open_at(position_value)
		instance.Position = position_value
		instance.Visible = true
		api.open:set(true)
		scale.Scale = 0.94
		instance.BackgroundTransparency = 0.3
		animation.spring({
			from = 0.94,
			to = 1,
			preset = "snappy",
			on_step = function(alpha)
				scale.Scale = alpha
				instance.BackgroundTransparency = lerp(0.3, 0, clamp01((alpha - 0.94) / 0.06))
			end,
		})
	end

	function api:close()
		if not api.open:get() then
			return
		end
		api.open:set(false)
		animation.spring({
			from = scale.Scale,
			to = 0.94,
			preset = "precise",
			on_step = function(alpha)
				scale.Scale = alpha
				instance.BackgroundTransparency = clamp01((1 - alpha) * 4)
			end,
			on_done = function()
				instance.Visible = false
			end,
		})
	end

	for _, item in props.items or {} do
		if item.separator then
			api:separator()
		elseif item.label_only then
			api:label(item.label)
		else
			api:item(item)
		end
	end

	return api
end

function overlays.dropdown(props)
	props = props or {}
	local theme_current = theme.get()
	local value = create_state(props.default or nil)
	local selected_label = create_state(props.placeholder or "select")
	local trigger = dom.frame({
		name = props.name or "dropdown_trigger",
		parent = props.parent,
		size_of = props.size_of or UDim2.new(1, 0, 0, theme_current.control.height),
		position = props.position,
		auto_size = props.auto_size,
		color = theme_current.color("input"),
		zindex = props.zindex or 2,
		layout_order = props.layout_order,
	})
	dom.corner(trigger, theme_current.radius_of(props.radius or "md"))
	dom.stroke(trigger, { color = theme_current.color("border") })
	dom.padding(trigger, 0, 10, 0, 10)
	dom.list(trigger, { direction = Enum.FillDirection.Horizontal, gap = 8, vertical = Enum.VerticalAlignment.Center })
	if props.icon then
		lucent_primitives.icon({ name = props.icon, size = 15, parent = trigger, color = theme_current.color("muted_foreground") })
	end
	local label = dom.text({
		parent = trigger,
		text = selected_label:get(),
		size = theme_current.type_of("sm"),
		color = theme_current.color(value:get() and "foreground" or "muted_foreground"),
		size_of = UDim2.new(1, -30, 1, 0),
		zindex = trigger.ZIndex + 1,
	})
	local chevron = lucent_primitives.icon({ name = "chevron_down", size = 14, parent = trigger, color = theme_current.color("muted_foreground"), zindex = trigger.ZIndex + 1 })

	local menu = overlays.menu({
		width = props.menu_width or (props.size_of and props.size_of.X.Offset or 200),
		items = map_array(props.options or {}, function(option)
			return {
				label = option.label or tostring(option.value),
				icon = option.icon,
				value = option.value,
				on_select = function()
					value:set(option.value)
					label.Text = option.label or tostring(option.value)
					label.TextColor3 = theme_current.color("foreground")
					if props.on_change then
						props.on_change(option.value)
					end
				end,
			}
		end),
	})

	local function place()
		local absolute = trigger.AbsolutePosition
		local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
		local menu_width = props.menu_width or (props.size_of and props.size_of.X.Offset or 220)
		local x = math.min(absolute.X, viewport.X - menu_width - 12)
		local y = absolute.Y + trigger.AbsoluteSize.Y + 6
		menu.root.Position = UDim2.fromOffset(x, y)
	end

	interaction.clickable(trigger).activated:connect(function()
		if menu.open:get() then
			menu:close()
		else
			place()
			menu:open_at(menu.root.Position)
		end
	end)

	return trigger, value, menu
end

function overlays.tooltip(props)
	props = props or {}
	local theme_current = theme.get()
	local root = shell.layer("tooltip", theme_current.layer_of("tooltip"))
	local tip = dom.frame({
		name = "tooltip",
		parent = root,
		size_of = UDim2.new(0, 0, 0, 0),
		auto_size = Enum.AutomaticSize.XY,
		color = theme_current.color(props.color or "popover"),
		zindex = theme_current.layer_of("tooltip"),
		visible = false,
	})
	dom.corner(tip, theme_current.radius_of("sm"))
	dom.stroke(tip, { color = theme_current.color("border") })
	dom.padding(tip, 6, 9, 6, 9)
	local label = dom.text({
		parent = tip,
		text = props.text or "",
		size = theme_current.type_of("xs"),
		color = theme_current.color("popover_foreground"),
		auto_size = Enum.AutomaticSize.XY,
		size_of = UDim2.new(0, 0, 0, 0),
		zindex = tip.ZIndex + 1,
		wrap = false,
	})
	local fade = dom.scale(tip, 0.9)
	local function show(x, y)
		tip.Visible = true
		tip.Position = UDim2.fromOffset(x, y)
		animation.spring({ from = fade.Scale, to = 1, preset = "snappy", on_step = function(alpha)
			fade.Scale = alpha
			tip.BackgroundTransparency = 1 - clamp01(alpha)
			label.TextTransparency = 1 - clamp01(alpha)
		end })
	end
	local function hide()
		animation.spring({ from = fade.Scale, to = 0.9, preset = "precise", on_step = function(alpha)
			fade.Scale = alpha
		end, on_done = function()
			tip.Visible = false
		end })
	end
	local target = props.target
	if target then
		target.MouseEnter:Connect(function()
			local position_value = target.AbsolutePosition
			show(position_value.X, position_value.Y - 30)
		end)
		target.MouseLeave:Connect(hide)
	end
	return { root = tip, show = show, hide = hide, set_text = function(text)
		label.Text = text
	end }
end

function overlays.toast_container(props)
	props = props or {}
	local theme_current = theme.get()
	local position_value = props.position or "bottom-right"
	local root = shell.layer("toast", theme_current.layer_of("toast"))
	local holder = dom.frame({
		name = "toast_holder",
		parent = root,
		size_of = UDim2.new(0, props.width or 320, 1, -32),
		position = position_value == "top-right" and UDim2.new(1, -16, 0, 16) or position_value == "top-left" and UDim2.new(0, 16, 0, 16) or position_value == "bottom-left" and UDim2.new(0, 16, 0, 0) or UDim2.new(1, -16, 0, 0),
		anchor = position_value == "top-right" and Vector2.new(1, 0) or position_value == "top-left" and Vector2.new(0, 0) or position_value == "bottom-left" and Vector2.new(0, 0) or Vector2.new(1, 0),
		transparent = true,
		zindex = theme_current.layer_of("toast"),
	})
	dom.list(holder, {
		direction = Enum.FillDirection.Vertical,
		gap = 10,
		horizontal = Enum.HorizontalAlignment.Right,
		vertical = starts_with(position_value, "top") and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom,
	})
	return holder
end

local toast_holder

function overlays.toast(props)
	props = props or {}
	local theme_current = theme.get()
	if not toast_holder or not toast_holder.Parent then
		toast_holder = overlays.toast_container({ position = props.position })
	end
	local tones = {
		default = "popover",
		success = "success",
		destructive = "destructive",
		warning = "warning",
		info = "info",
	}
	local tone = props.variant or "default"
	local close_toast
	local card = dom.frame({
		name = "toast",
		parent = toast_holder,
		size_of = UDim2.new(1, 0, 0, 0),
		auto_size = Enum.AutomaticSize.Y,
		color = tone == "default" and theme_current.color("popover") or theme_current.color("card"),
		zindex = theme_current.layer_of("toast"),
		clip = true,
	})
	dom.corner(card, theme_current.radius_of("lg"))
	dom.stroke(card, { color = theme_current.color("border") })
	dom.shadow(card, { width = 380, height = 120, transparency = theme_current.alpha_value("shadow") })
	dom.padding(card, 12, 12, 12, 12)
	local row = dom.frame({ name = "row", parent = card, size_of = UDim2.new(1, 0, 0, 0), auto_size = Enum.AutomaticSize.Y, transparent = true, zindex = card.ZIndex + 1 })
	dom.list(row, { direction = Enum.FillDirection.Horizontal, gap = 10, vertical = Enum.VerticalAlignment.Top })
	if brand.enabled_for("toast") then
		brand_render.mark(row, { logo_size = 18 })
	end
	local icon_color = tone == "default" and theme_current.color("primary") or theme_current.color(tone)
	if props.icon then
		lucent_primitives.icon({ name = props.icon, size = 17, parent = row, color = icon_color, stroke_width = 2 })
	end
	local text_holder = dom.frame({ name = "text", parent = row, size_of = UDim2.new(1, props.icon and -30 or 0, 0, 0), auto_size = Enum.AutomaticSize.Y, transparent = true, zindex = row.ZIndex })
	dom.list(text_holder, { direction = Enum.FillDirection.Vertical, gap = 3 })
	lucent_primitives.text({ parent = text_holder, text = props.title or "", size = theme_current.type_of("sm"), font = "medium", color = theme_current.color("popover_foreground"), auto_size = Enum.AutomaticSize.Y, size_of = UDim2.new(1, 0, 0, 0), zindex = text_holder.ZIndex + 1, wrap = true })
	if props.description then
		lucent_primitives.text({ parent = text_holder, text = props.description, size = theme_current.type_of("xs"), color = theme_current.color("muted_foreground"), auto_size = Enum.AutomaticSize.Y, size_of = UDim2.new(1, 0, 0, 0), zindex = text_holder.ZIndex + 1, wrap = true })
	end
	if props.action then
		controls.button({ parent = text_holder, text = props.action, variant = props.action_variant or "outline", size = "sm", on_click = function()
			if props.on_action then
				props.on_action()
			end
			if close_toast then
				close_toast()
			end
		end })
	end
	if tone ~= "default" then
		local accent = dom.frame({ name = "accent", parent = card, size_of = UDim2.new(0, 3, 1, 0), color = theme_current.color(tone), zindex = card.ZIndex + 2 })
	end

	local scale = dom.scale(card, 0.9)
	card.BackgroundTransparency = 0.4
	animation.spring({ from = 0.9, to = 1, preset = "bouncy", on_step = function(alpha)
		scale.Scale = alpha
		card.BackgroundTransparency = lerp(0.4, 0, clamp01((alpha - 0.9) / 0.1))
	end })

	if props.progress then
		local bar = dom.frame({ name = "bar", parent = card, size_of = UDim2.new(1, 0, 0, 2), position = UDim2.new(0, 0, 1, -2), color = icon_color, zindex = card.ZIndex + 2 })
		animation.spring({ from = 1, to = 0, preset = "lazy", on_step = function(alpha)
			bar.Size = UDim2.new(alpha, 0, 0, 2)
		end })
	end

	local closed = false
	close_toast = function()
		if closed then
			return
		end
		closed = true
		animation.spring({ from = scale.Scale, to = 0.9, preset = "precise", on_step = function(alpha)
			scale.Scale = alpha
			card.BackgroundTransparency = clamp01((1 - alpha) * 5)
		end, on_done = function()
			card:Destroy()
		end })
	end

	card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			close_toast()
		end
	end)

	task.delay(props.duration or 4, close_toast)
	return card, close_toast
end

local navigation = {}

function navigation.navbar(props)
	props = props or {}
	local theme_current = theme.get()
	local height = props.height or 56
	local theme_current_layer = theme_current.layer_of("chrome")
	local instance = dom.frame({
		name = props.name or "navbar",
		parent = props.parent,
		size_of = props.size_of or UDim2.new(1, 0, 0, height),
		position = props.position,
		anchor = props.anchor,
		color = theme_current.color(props.surface or "background"),
		transparency = props.transparency or (props.glass and 0.35 or 0),
		zindex = props.zindex or theme_current_layer,
		clip = false,
	})
	dom.padding(instance, 0, props.padding_x or 16, 0, props.padding_x or 16)
	dom.list(instance, { direction = Enum.FillDirection.Horizontal, gap = 14, vertical = Enum.VerticalAlignment.Center })
	if props.stroke ~= false then
		local underline = dom.frame({ name = "underline", parent = instance, size_of = UDim2.new(1, 0, 0, 1), position = UDim2.new(0, 0, 1, 0), color = theme_current.color("border"), zindex = instance.ZIndex + 1 })
	end
	local left = dom.frame({ name = "left", parent = instance, size_of = UDim2.new(0, 0, 1, 0), auto_size = Enum.AutomaticSize.X, transparent = true, zindex = instance.ZIndex + 1 })
	dom.list(left, { direction = Enum.FillDirection.Horizontal, gap = 10, vertical = Enum.VerticalAlignment.Center })
	brand_render.group(left, { logo_size = props.logo_size or 24, gap = props.logo_gap or 9 })
	if props.title then
		lucent_primitives.text({ parent = left, text = props.title, size = theme_current.type_of("md"), font = "medium", color = theme_current.color("foreground"), auto_size = Enum.AutomaticSize.X, size_of = UDim2.new(0, 0, 1, 0), zindex = left.ZIndex + 1 })
	end
	local center = dom.frame({ name = "center", parent = instance, size_of = UDim2.new(1, -((props.left_width or 0) + (props.right_width or 0)), 1, 0), auto_size = Enum.AutomaticSize.X, transparent = true, zindex = instance.ZIndex + 1 })
	dom.list(center, { direction = Enum.FillDirection.Horizontal, gap = 4, vertical = Enum.VerticalAlignment.Center, horizontal = props.center_align or Enum.HorizontalAlignment.Left })
	local right = dom.frame({ name = "right", parent = instance, size_of = UDim2.new(0, 0, 1, 0), auto_size = Enum.AutomaticSize.X, transparent = true, zindex = instance.ZIndex + 1 })
	dom.list(right, { direction = Enum.FillDirection.Horizontal, gap = 8, vertical = Enum.VerticalAlignment.Center, horizontal = Enum.HorizontalAlignment.Right })
	return instance, { left = left, center = center, right = right }
end

function navigation.nav_link(props)
	props = props or {}
	local theme_current = theme.get()
	local state = create_state(props.active or false)
	local instance = dom.frame({
		name = props.name or "nav_link",
		parent = props.parent,
		size_of = props.size_of or UDim2.new(0, 0, 0, props.height or 30),
		auto_size = Enum.AutomaticSize.X,
		color = theme_current.color("accent"),
		transparency = 1,
		zindex = props.zindex or 4,
		layout_order = props.layout_order,
	})
	dom.corner(instance, theme_current.radius_of(props.radius or "md"))
	dom.padding(instance, 0, 10, 0, 10)
	dom.list(instance, { direction = Enum.FillDirection.Horizontal, gap = 7, vertical = Enum.VerticalAlignment.Center })
	if props.icon then
		lucent_primitives.icon({ name = props.icon, size = 15, parent = instance, color = theme_current.color("muted_foreground"), zindex = instance.ZIndex + 1 })
	end
	local label = lucent_primitives.text({ parent = instance, text = props.text or "", size = theme_current.type_of(props.text_size or "sm"), font = "medium", color = theme_current.color("muted_foreground"), auto_size = Enum.AutomaticSize.X, size_of = UDim2.new(0, 0, 1, 0), zindex = instance.ZIndex + 1 })
	if props.badge then
		lucent_primitives.badge({ parent = instance, text = props.badge, variant = props.badge_variant or "default", size = "sm" })
	end

	local function paint(active)
		instance.BackgroundTransparency = active and 0 or 1
		label.TextColor3 = theme_current.color(active and "foreground" or "muted_foreground")
		for _, descendant in instance:GetDescendants() do
			if descendant:IsA("TextLabel") then
				descendant.TextColor3 = theme_current.color(active and "foreground" or "muted_foreground")
			end
		end
	end

	state:observe(paint)
	paint(state:get())

	local states = interaction.clickable(instance)
	states.hovered:observe(function(hovering)
		if not state:get() then
			animation.tween(instance, { BackgroundTransparency = hovering and 0.55 or 1 }, { duration = theme_current.motion.fast, ease = "quad" })
			label.TextColor3 = theme_current.color(hovering and "foreground" or "muted_foreground")
		end
	end)
	states.activated:connect(function()
		state:set(true)
		if props.on_click then
			props.on_click()
		end
	end)

	local api = {
		root = instance,
		state = state,
		set_active = function(value)
			state:set(value)
		end,
	}
	return api
end

function navigation.sidebar(props)
	props = props or {}
	local theme_current = theme.get()
	local width = props.width or 236
	local collapsed = create_state(props.collapsed or false)
	local instance = dom.frame({
		name = props.name or "sidebar",
		parent = props.parent,
		size_of = UDim2.new(0, width, props.height or 1, props.height and 0 or 0),
		position = props.position,
		anchor = props.anchor,
		color = theme_current.color(props.surface or "sidebar"),
		zindex = props.zindex or theme_current.layer_of("chrome"),
		clip = true,
	})
	if props.stroke ~= false then
		local edge = dom.frame({ name = "edge", parent = instance, size_of = UDim2.new(0, 1, 1, 0), position = UDim2.fromScale(props.edge_side or 1, 0), anchor = Vector2.new(props.edge_side or 1, 0), color = theme_current.color("border"), zindex = instance.ZIndex + 1 })
	end
	local content = dom.frame({ name = "content", parent = instance, size_of = UDim2.new(1, 0, 1, 0), transparent = true, zindex = instance.ZIndex + 1 })
	dom.padding(content, 12, 10, 12, 10)
	dom.list(content, { direction = Enum.FillDirection.Vertical, gap = 14 })

	local header = dom.frame({ name = "header", parent = content, size_of = UDim2.new(1, 0, 0, props.header_height or 34), transparent = true, zindex = content.ZIndex + 1 })
	dom.list(header, { direction = Enum.FillDirection.Horizontal, gap = 8, vertical = Enum.VerticalAlignment.Center })
	brand_render.group(header, { logo_size = props.logo_size or 26, gap = props.logo_gap or 10 })
	if props.title then
		lucent_primitives.text({ parent = header, text = props.title, size = theme_current.type_of("md"), font = "bold", color = theme_current.color("foreground"), auto_size = Enum.AutomaticSize.X, size_of = UDim2.new(0, 0, 1, 0), zindex = header.ZIndex + 1 })
	end

	local scroll = lucent_primitives.scroll({ parent = content, size_of = UDim2.new(1, 0, 1, -(props.header_height or 34) - 14), fill = Enum.ScrollingDirection.Y, zindex = content.ZIndex + 1 })
	local groups = dom.frame({ name = "groups", parent = scroll, size_of = UDim2.new(1, 0, 0, 0), auto_size = Enum.AutomaticSize.Y, transparent = true, zindex = scroll.ZIndex + 1 })
	dom.list(groups, { direction = Enum.FillDirection.Vertical, gap = 18 })

	local api = { root = instance, content = content, groups = groups, collapsed = collapsed, links = {} }

	function api:group(group_props)
		local holder = dom.frame({ name = "group", parent = groups, size_of = UDim2.new(1, 0, 0, 0), auto_size = Enum.AutomaticSize.Y, transparent = true, zindex = groups.ZIndex + 1 })
		dom.list(holder, { direction = Enum.FillDirection.Vertical, gap = 4 })
		if group_props.label then
			lucent_primitives.text({ parent = holder, text = group_props.label, size = theme_current.type_of("2xs"), font = "medium", color = theme_current.color("muted_foreground"), size_of = UDim2.new(1, 0, 0, 12), zindex = holder.ZIndex + 1 })
		end
		local links_holder = dom.frame({ name = "links", parent = holder, size_of = UDim2.new(1, 0, 0, 0), auto_size = Enum.AutomaticSize.Y, transparent = true, zindex = holder.ZIndex + 1 })
		dom.list(links_holder, { direction = Enum.FillDirection.Vertical, gap = 2 })
		for _, item in group_props.items or {} do
			local link = navigation.nav_link(merge(item, { parent = links_holder, zindex = links_holder.ZIndex + 1 }))
			table.insert(api.links, link)
		end
		return holder, links_holder
	end

	function api:footer(children)
		local footer = dom.frame({ name = "footer", parent = content, size_of = UDim2.new(1, 0, 0, 0), auto_size = Enum.AutomaticSize.Y, transparent = true, zindex = content.ZIndex + 1 })
		dom.list(footer, { direction = Enum.FillDirection.Vertical, gap = 8 })
		for _, child in children or {} do
			if child then
				child.Parent = footer
			end
		end
		return footer
	end

	function api:set_collapsed(value)
		collapsed:set(value)
		local target = value and (props.collapsed_width or 62) or width
		animation.spring({ from = instance.AbsoluteSize.X, to = target, preset = "smooth", on_step = function(alpha)
			instance.Size = UDim2.new(0, alpha, instance.Size.Y.Scale, 0)
		end })
		return api
	end

	function api:toggle()
		return api:set_collapsed(not collapsed:get())
	end

	return api
end

function navigation.tabs(props)
	props = props or {}
	local theme_current = theme.get()
	local value = create_state(props.default or (props.tabs and props.tabs[1] and props.tabs[1].value) or nil)
	local variant = props.variant or "underline"
	local instance = dom.frame({
		name = props.name or "tabs",
		parent = props.parent,
		size_of = props.size_of or UDim2.new(1, 0, 0, 0),
		auto_size = Enum.AutomaticSize.Y,
		transparent = true,
		zindex = props.zindex or 2,
		layout_order = props.layout_order,
	})
	dom.list(instance, { direction = Enum.FillDirection.Vertical, gap = props.gap or 14 })
	local strip = dom.frame({
		name = "strip",
		parent = instance,
		size_of = props.strip_size or UDim2.new(props.full ~= false and 1 or 0, 0, 0, props.height or 36),
		auto_size = (props.full ~= false or props.auto_width) and Enum.AutomaticSize.None or Enum.AutomaticSize.X,
		transparent = true,
		zindex = instance.ZIndex + 1,
	})
	dom.list(strip, { direction = Enum.FillDirection.Horizontal, gap = props.item_gap or 4, vertical = Enum.VerticalAlignment.Center })
	if variant == "pills" or variant == "segmented" then
		strip.BackgroundColor3 = theme_current.color(variant == "segmented" and "secondary" or "muted")
		strip.BackgroundTransparency = variant == "segmented" and 0 or 0.4
		dom.corner(strip, theme_current.radius_of(props.strip_radius or "lg"))
		dom.padding(strip, 4, 4, 4, 4)
	end

	local pages = dom.frame({ name = "pages", parent = instance, size_of = UDim2.new(1, 0, 0, 0), auto_size = Enum.AutomaticSize.Y, transparent = true, zindex = instance.ZIndex + 1 })
	local api = { root = instance, strip = strip, pages = pages, value = value, buttons = {}, changed = create_signal() }
	local indicator

	local function move_indicator(button)
		if variant ~= "underline" then
			return
		end
		if not indicator then
			indicator = dom.frame({ name = "indicator", parent = strip, size_of = UDim2.new(0, button.AbsoluteSize.X, 0, 2), position = UDim2.new(0, button.AbsolutePosition.X - strip.AbsolutePosition.X, 1, 0), anchor = Vector2.new(0, 0), color = theme_current.color(props.indicator_color or "primary"), zindex = strip.ZIndex + 2, layout_order = -1 })
			dom.corner(indicator, theme_current.radius_of("full"))
			return
		end
		animation.spring({
			from = indicator.AbsolutePosition.X,
			to = button.AbsolutePosition.X,
			preset = "snappy",
			on_step = function(alpha)
				indicator.Position = UDim2.fromOffset(alpha - strip.AbsolutePosition.X, indicator.Position.Y.Offset)
			end,
		})
		animation.spring({
			from = indicator.AbsoluteSize.X,
			to = button.AbsoluteSize.X,
			preset = "snappy",
			on_step = function(alpha)
				indicator.Size = UDim2.fromOffset(alpha, 2)
			end,
		})
	end

	local function select(tab, silent)
		value:set(tab.value)
		for _, entry in api.buttons do
			local active = entry.value == tab.value
			if variant == "underline" then
				animation.tween(entry.button, { BackgroundTransparency = active and 0.9 or 1 }, { duration = theme_current.motion.fast, ease = "quad" })
				entry.label.TextColor3 = theme_current.color(active and "foreground" or "muted_foreground")
			else
				entry.button.BackgroundColor3 = theme_current.color(active and (variant == "segmented" and "background" or "background") or "muted")
				entry.button.BackgroundTransparency = active and 0 or 1
				entry.label.TextColor3 = theme_current.color(active and "foreground" or "muted_foreground")
			end
			if entry.page then
				entry.page.Visible = active
				if active then
					entry.page.BackgroundTransparency = 0
				end
			end
			if active then
				move_indicator(entry.button)
			end
		end
		if not silent then
			api.changed:fire(tab.value)
			if tab.on_select then
				tab.on_select()
			end
			if props.on_change then
				props.on_change(tab.value)
			end
		end
	end

	for _, tab in props.tabs or {} do
		local button = dom.frame({
			name = "tab",
			parent = strip,
			size_of = UDim2.new(0, 0, 0, (props.height or 36) - 8),
			auto_size = Enum.AutomaticSize.X,
			color = theme_current.color("accent"),
			transparency = 1,
			zindex = strip.ZIndex + 1,
		})
		dom.corner(button, theme_current.radius_of(props.radius or "md"))
		dom.padding(button, 0, 12, 0, 12)
		dom.list(button, { direction = Enum.FillDirection.Horizontal, gap = 7, vertical = Enum.VerticalAlignment.Center })
		if tab.icon then
			lucent_primitives.icon({ name = tab.icon, size = 15, parent = button, color = theme_current.color("muted_foreground"), zindex = button.ZIndex + 1 })
		end
		local label = lucent_primitives.text({ parent = button, text = tab.label or tostring(tab.value), size = theme_current.type_of("sm"), font = "medium", color = theme_current.color("muted_foreground"), auto_size = Enum.AutomaticSize.X, size_of = UDim2.new(0, 0, 1, 0), zindex = button.ZIndex + 1 })
		if tab.badge then
			lucent_primitives.badge({ parent = button, text = tab.badge, variant = "secondary", size = "sm" })
		end
		local page = dom.frame({ name = "page_" .. tostring(tab.value), parent = pages, size_of = UDim2.new(1, 0, 0, 0), auto_size = Enum.AutomaticSize.Y, transparent = true, zindex = pages.ZIndex + 1, visible = false })
		if tab.content then
			dom.list(page, tab.list or { direction = Enum.FillDirection.Vertical, gap = 12 })
			for _, child in tab.content do
				if child then
					child.Parent = page
				end
			end
		end
		table.insert(api.buttons, { value = tab.value, button = button, label = label, page = page, tab = tab })
		interaction.clickable(button).activated:connect(function()
			select(tab)
		end)
	end

	function api:select(value_value)
		for _, entry in api.buttons do
			if entry.value == value_value then
				select(entry.tab)
				break
			end
		end
		return api
	end

	function api:page_of(value_value)
		for _, entry in api.buttons do
			if entry.value == value_value then
				return entry.page
			end
		end
		return nil
	end

	if props.tabs and #props.tabs > 0 then
		select(props.tabs[1], true)
	end

	return api
end

function navigation.accordion(props)
	props = props or {}
	local theme_current = theme.get()
	local instance = dom.frame({
		name = props.name or "accordion",
		parent = props.parent,
		size_of = props.size_of or UDim2.new(1, 0, 0, 0),
		auto_size = Enum.AutomaticSize.Y,
		transparent = true,
		zindex = props.zindex or 2,
		layout_order = props.layout_order,
	})
	dom.list(instance, { direction = Enum.FillDirection.Vertical, gap = props.gap or 6 })
	local api = { root = instance, items = {}, open = create_state(nil) }

	for index, item in props.items or {} do
		local holder = dom.frame({ name = "item", parent = instance, size_of = UDim2.new(1, 0, 0, 0), auto_size = Enum.AutomaticSize.Y, color = theme_current.color("card"), zindex = instance.ZIndex + 1, clip = true })
		dom.corner(holder, theme_current.radius_of(props.radius or "md"))
		dom.stroke(holder, { color = theme_current.color("border") })
		dom.list(holder, { direction = Enum.FillDirection.Vertical, gap = 0 })
		local trigger = dom.frame({ name = "trigger", parent = holder, size_of = UDim2.new(1, 0, 0, props.item_height or 42), color = theme_current.color("accent"), transparency = 1, zindex = holder.ZIndex + 1 })
		dom.padding(trigger, 0, 14, 0, 14)
		dom.list(trigger, { direction = Enum.FillDirection.Horizontal, gap = 10, vertical = Enum.VerticalAlignment.Center })
		local label = lucent_primitives.text({ parent = trigger, text = item.title or "", size = theme_current.type_of("sm"), font = "medium", color = theme_current.color("foreground"), size_of = UDim2.new(1, -30, 1, 0), zindex = trigger.ZIndex + 1 })
		local chevron_holder = dom.frame({ name = "chevron", parent = trigger, size_of = size(16, 16), transparent = true, zindex = trigger.ZIndex + 1 })
		local chevrons = path.fit(path.flatten(icons.get("chevron_down")), 14, 1)
		polygon.stroke_group(chevron_holder, chevrons, 1.8 * (14 / icons.viewbox), theme_current.color("muted_foreground"), { zindex = trigger.ZIndex + 2, padding = 1 })
		local panel = dom.frame({ name = "panel", parent = holder, size_of = UDim2.new(1, 0, 0, 0), transparent = true, zindex = holder.ZIndex + 1 })
		dom.padding(panel, 0, 14, 14, 14)
		local panel_content = dom.frame({ name = "content", parent = panel, size_of = UDim2.new(1, 0, 0, 0), auto_size = Enum.AutomaticSize.Y, transparent = true, zindex = panel.ZIndex + 1 })
		dom.list(panel_content, { direction = Enum.FillDirection.Vertical, gap = 8 })
		if type(item.content) == "string" then
			lucent_primitives.text({ parent = panel_content, text = item.content, size = theme_current.type_of("sm"), color = theme_current.color("muted_foreground"), auto_size = Enum.AutomaticSize.Y, size_of = UDim2.new(1, 0, 0, 0), wrap = true, zindex = panel_content.ZIndex + 1 })
		else
			for _, child in item.content or {} do
				if child then
					child.Parent = panel_content
				end
			end
		end
		panel.ClipsDescendants = true
		panel.Size = UDim2.new(1, 0, 0, 0)

		local entry = { holder = holder, panel = panel, content = panel_content, chevron = chevron_holder, open = create_state(item.open or false) }

		local function apply(open_value, instant)
			local target_height = open_value and panel_content.AbsoluteSize.Y + 28 or 0
			if instant then
				panel.Size = UDim2.new(1, 0, 0, target_height)
				chevron_holder.Rotation = open_value and 180 or 0
				return
			end
			animation.spring({ from = panel.AbsoluteSize.Y, to = target_height, preset = "smooth", on_step = function(alpha)
				panel.Size = UDim2.new(1, 0, 0, alpha)
			end })
			animation.spring({ from = chevron_holder.Rotation, to = open_value and 180 or 0, preset = "snappy", on_step = function(alpha)
				chevron_holder.Rotation = alpha
			end })
		end

		entry.apply = apply
		interaction.clickable(trigger).activated:connect(function()
			local next_value = not entry.open:get()
			if props.single then
				for _, other in api.items do
					if other ~= entry and other.open:get() then
						other.open:set(false)
						other.apply(false)
					end
				end
			end
			entry.open:set(next_value)
			apply(next_value)
			if next_value and item.on_open then
				item.on_open()
			end
		end)
		interaction.hover(trigger).hovered:observe(function(hovering)
			animation.tween(trigger, { BackgroundTransparency = hovering and 0.7 or 1 }, { duration = theme_current.motion.fast, ease = "quad" })
		end)
		apply(entry.open:get(), true)
		table.insert(api.items, entry)
	end

	return api
end

function navigation.breadcrumb(props)
	props = props or {}
	local theme_current = theme.get()
	local instance = dom.frame({
		name = props.name or "breadcrumb",
		parent = props.parent,
		size_of = props.size_of or UDim2.new(0, 0, 0, 20),
		auto_size = Enum.AutomaticSize.X,
		transparent = true,
		zindex = props.zindex or 2,
		layout_order = props.layout_order,
	})
	dom.list(instance, { direction = Enum.FillDirection.Horizontal, gap = props.gap or 6, vertical = Enum.VerticalAlignment.Center })
	for index, item in props.items or {} do
		if index > 1 then
			lucent_primitives.icon({ name = props.separator_icon or "chevron_right", size = 13, parent = instance, color = theme_current.color("muted_foreground"), zindex = instance.ZIndex + 1 })
		end
		local last = index == #props.items
		local label = dom.text({
			parent = instance,
			text = item.label or "",
			size = theme_current.type_of("sm"),
			font = theme_current.font_of("medium"),
			color = theme_current.color(last and "foreground" or "muted_foreground"),
			auto_size = Enum.AutomaticSize.XY,
			size_of = UDim2.new(0, 0, 0, 18),
			zindex = instance.ZIndex + 1,
		})
		if item.on_click then
			local states = interaction.clickable(label)
			states.hovered:observe(function(hovering)
				label.TextColor3 = theme_current.color(hovering and "foreground" or (last and "foreground" or "muted_foreground"))
			end)
			states.activated:connect(item.on_click)
		end
	end
	return instance
end

function navigation.pagination(props)
	props = props or {}
	local theme_current = theme.get()
	local page = create_state(props.page or 1)
	local total = math.max(1, math.ceil((props.total or 0) / (props.per_page or 10)))
	local instance = dom.frame({ name = props.name or "pagination", parent = props.parent, size_of = UDim2.new(0, 0, 0, 32), auto_size = Enum.AutomaticSize.X, transparent = true, zindex = props.zindex or 2, layout_order = props.layout_order })
	dom.list(instance, { direction = Enum.FillDirection.Horizontal, gap = 6, vertical = Enum.VerticalAlignment.Center })
	local changed = create_signal()

	local function page_button(label_value, value, is_active, enabled)
		local button = controls.button({ parent = instance, text = label_value, size = props.size or "sm", variant = is_active and "default" or "outline", enabled = enabled ~= false, on_click = function()
			if not enabled then
				return
			end
			page:set(value)
			changed:fire(value)
			if props.on_change then
				props.on_change(value)
			end
			if props.rebuild then
				props.rebuild(value)
			end
		end })
		button.Size = UDim2.new(0, 32, 0, 28)
		button.AutomaticSize = Enum.AutomaticSize.None
		return button
	end

	local function rebuild()
		for _, child in instance:GetChildren() do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		page_button("‹", math.max(1, page:get() - 1), false, page:get() > 1)
		local window_value = props.window or 2
		for index = 1, total do
			if index == 1 or index == total or math.abs(index - page:get()) <= window_value then
				page_button(tostring(index), index, index == page:get(), true)
			elseif math.abs(index - page:get()) == window_value + 1 then
				lucent_primitives.text({ parent = instance, text = "...", size = theme_current.type_of("sm"), color = theme_current.color("muted_foreground"), auto_size = Enum.AutomaticSize.XY, size_of = UDim2.new(0, 0, 0, 12), zindex = instance.ZIndex + 1 })
			end
		end
		page_button("›", math.min(total, page:get() + 1), false, page:get() < total)
	end

	rebuild()
	changed:connect(function()
		rebuild()
	end)

	return instance, page, changed
end

function navigation.progress(props)
	props = props or {}
	local theme_current = theme.get()
	local value = create_state(clamp(props.value or 0, 0, 100))
	local instance = dom.frame({
		name = props.name or "progress",
		parent = props.parent,
		size_of = props.size_of or UDim2.new(1, 0, 0, props.thickness or 6),
		color = theme_current.color(props.track or "muted"),
		zindex = props.zindex or 2,
		layout_order = props.layout_order,
	})
	dom.corner(instance, theme_current.radius_of("full"))
	local fill_instance = dom.frame({ name = "fill", parent = instance, size_of = UDim2.new(0, 0, 1, 0), color = theme_current.color(props.tone or "primary"), zindex = instance.ZIndex + 1 })
	dom.corner(fill_instance, theme_current.radius_of("full"))
	if props.gradient then
		dom.gradient(fill_instance, { color = props.gradient, rotation = 0 })
	end
	if props.stripes then
		local stripes = dom.image({ name = "stripes", parent = fill_instance, image = "rbxassetid://8985439975", scale_type = Enum.ScaleType.Tile, size_of = UDim2.fromScale(1, 1), image_transparency = 0.85, color = Color3.new(1, 1, 1), zindex = fill_instance.ZIndex + 1 })
	end

	local function apply(target, instant)
		local ratio = clamp(target / 100, 0, 1)
		if instant then
			fill_instance.Size = UDim2.new(ratio, 0, 1, 0)
			return
		end
		animation.spring({ from = fill_instance.Size.X.Scale, to = ratio, preset = props.preset or "smooth", on_step = function(alpha)
			fill_instance.Size = UDim2.new(alpha, 0, 1, 0)
		end })
	end

	apply(value:get(), true)
	return instance, {
		set = function(target)
			value:set(clamp(target, 0, 100))
			apply(value:get())
		end,
		add = function(amount)
			value:set(clamp(value:get() + amount, 0, 100))
			apply(value:get())
		end,
		get = function()
			return value:get()
		end,
		value = value,
	}
end

function navigation.alert(props)
	props = props or {}
	local theme_current = theme.get()
	local tones = {
		default = { ink = "foreground", icon = "info" },
		info = { ink = "info", icon = "info" },
		success = { ink = "success", icon = "check_circle" },
		warning = { ink = "warning", icon = "warning" },
		destructive = { ink = "destructive", icon = "alert" },
	}
	local tone = tones[props.variant or "default"] or tones.default
	local instance = dom.frame({
		name = props.name or "alert",
		parent = props.parent,
		size_of = props.size_of or UDim2.new(1, 0, 0, 0),
		auto_size = Enum.AutomaticSize.Y,
		color = theme_current.color(props.surface or "card"),
		zindex = props.zindex or 2,
		layout_order = props.layout_order,
	})
	dom.corner(instance, theme_current.radius_of(props.radius or "lg"))
	dom.stroke(instance, { color = theme_current.color("border") })
	dom.padding(instance, 14, 14, 14, 14)
	dom.list(instance, { direction = Enum.FillDirection.Horizontal, gap = 11, vertical = Enum.VerticalAlignment.Top })
	if props.icon ~= false then
		lucent_primitives.icon({ name = props.icon or tone.icon, size = 17, parent = instance, color = theme_current.color(tone.ink), zindex = instance.ZIndex + 1 })
	end
	local holder = dom.frame({ name = "text", parent = instance, size_of = UDim2.new(1, props.icon == false and 0 or -28, 0, 0), auto_size = Enum.AutomaticSize.Y, transparent = true, zindex = instance.ZIndex + 1 })
	dom.list(holder, { direction = Enum.FillDirection.Vertical, gap = 3 })
	if props.title then
		lucent_primitives.text({ parent = holder, text = props.title, size = theme_current.type_of("sm"), font = "medium", color = theme_current.color("foreground"), auto_size = Enum.AutomaticSize.Y, size_of = UDim2.new(1, 0, 0, 0), zindex = holder.ZIndex + 1, wrap = true })
	end
	if props.description then
		lucent_primitives.text({ parent = holder, text = props.description, size = theme_current.type_of("sm"), color = theme_current.color("muted_foreground"), auto_size = Enum.AutomaticSize.Y, size_of = UDim2.new(1, 0, 0, 0), zindex = holder.ZIndex + 1, wrap = true })
	end
	if props.action then
		dom.padding(holder, 0, 0, 8, 0)
		props.action.Parent = holder
	end
	if props.dismissible then
		local close_button = controls.icon_button({ name = "alert_close", icon = "close", size = "sm", variant = "ghost", parent = instance, on_click = function()
			animation.spring({ from = 1, to = 0, preset = "precise", on_step = function(alpha)
				dom.scale(instance, alpha)
				instance.BackgroundTransparency = clamp01(1 - alpha)
			end, on_done = function()
				instance:Destroy()
			end })
		end })
	end
	return instance
end

function navigation.stat(props)
	props = props or {}
	local theme_current = theme.get()
	local instance = dom.frame({
		name = props.name or "stat",
		parent = props.parent,
		size_of = props.size_of or UDim2.new(1, 0, 0, props.height or 96),
		position = props.position,
		auto_size = props.auto_size,
		color = theme_current.color(props.surface or "card"),
		zindex = props.zindex or 2,
		layout_order = props.layout_order,
		clip = true,
	})
	dom.corner(instance, theme_current.radius_of(props.radius or "lg"))
	dom.stroke(instance, { color = theme_current.color("border") })
	dom.padding(instance, 14, 14, 14, 14)
	dom.list(instance, { direction = Enum.FillDirection.Vertical, gap = 6 })
	local top = dom.frame({ name = "top", parent = instance, size_of = UDim2.new(1, 0, 0, 20), transparent = true, zindex = instance.ZIndex + 1 })
	dom.list(top, { direction = Enum.FillDirection.Horizontal, gap = 8, vertical = Enum.VerticalAlignment.Center, horizontal = Enum.HorizontalAlignment.Left })
	lucent_primitives.text({ parent = top, text = props.label or "", size = theme_current.type_of("xs"), color = theme_current.color("muted_foreground"), font = "medium", size_of = UDim2.new(1, -40, 1, 0), zindex = top.ZIndex + 1 })
	if props.icon then
		lucent_primitives.icon({ name = props.icon, size = 16, parent = top, color = theme_current.color(props.icon_color or "muted_foreground"), zindex = top.ZIndex + 1 })
	end
	local value_label = lucent_primitives.text({ parent = instance, text = props.format == "number" and comma(tonumber(props.value) or 0) or tostring(props.value or ""), size = props.value_size or 26, color = theme_current.color("foreground"), font = "bold", size_of = UDim2.new(1, 0, 0, 30), zindex = instance.ZIndex + 1 })
	if props.animate then
		animation.number(value_label, 0, tonumber(props.value) or 0, { duration = 1.1, format = props.format == "number" and comma or function(raw)
			return tostring(round(raw, props.decimals or 0)) .. (props.suffix or "")
		end })
	end
	local bottom = dom.frame({ name = "bottom", parent = instance, size_of = UDim2.new(1, 0, 0, 16), transparent = true, zindex = instance.ZIndex + 1 })
	dom.list(bottom, { direction = Enum.FillDirection.Horizontal, gap = 5, vertical = Enum.VerticalAlignment.Center })
	if props.delta then
		local positive = tonumber(props.delta) or 0
		lucent_primitives.icon({ name = positive >= 0 and "trending_up" or "trending_down", size = 13, parent = bottom, color = theme_current.color(positive >= 0 and "success" or "destructive"), zindex = bottom.ZIndex + 1 })
		lucent_primitives.text({ parent = bottom, text = signed(props.delta) .. (props.delta_suffix or "%"), size = theme_current.type_of("xs"), color = theme_current.color(positive >= 0 and "success" or "destructive"), font = "medium", auto_size = Enum.AutomaticSize.X, size_of = UDim2.new(0, 0, 1, 0), zindex = bottom.ZIndex + 1 })
	end
	if props.hint then
		lucent_primitives.text({ parent = bottom, text = props.hint, size = theme_current.type_of("xs"), color = theme_current.color("muted_foreground"), size_of = UDim2.new(1, -60, 1, 0), zindex = bottom.ZIndex + 1 })
	end
	return instance, value_label
end

function navigation.table(props)
	props = props or {}
	local theme_current = theme.get()
	local columns = props.columns or {}
	local rows = create_state(props.rows or {})
	local instance = dom.frame({
		name = props.name or "table",
		parent = props.parent,
		size_of = props.size_of or UDim2.new(1, 0, 0, 0),
		auto_size = Enum.AutomaticSize.Y,
		color = theme_current.color(props.surface or "card"),
		zindex = props.zindex or 2,
		layout_order = props.layout_order,
		clip = true,
	})
	dom.corner(instance, theme_current.radius_of(props.radius or "lg"))
	dom.stroke(instance, { color = theme_current.color("border") })
	local holder = dom.frame({ name = "holder", parent = instance, size_of = UDim2.new(1, 0, 0, 0), auto_size = Enum.AutomaticSize.Y, transparent = true, zindex = instance.ZIndex + 1 })
	dom.list(holder, { direction = Enum.FillDirection.Vertical, gap = 0 })

	local head = dom.frame({ name = "head", parent = holder, size_of = UDim2.new(1, 0, 0, props.head_height or 38), color = theme_current.color("muted"), transparency = 0.55, zindex = holder.ZIndex + 1 })
	dom.padding(head, 0, 14, 0, 14)
	dom.list(head, { direction = Enum.FillDirection.Horizontal, gap = 10, vertical = Enum.VerticalAlignment.Center })
	for _, column in columns do
		local cell = dom.text({ parent = head, text = column.label or "", size = theme_current.type_of("xs"), font = theme_current.font_of("medium"), color = theme_current.color("muted_foreground"), size_of = UDim2.new(column.width or 1 / math.max(1, #columns), 0, 1, 0), zindex = head.ZIndex + 1 })
		if column.sortable then
			local states = interaction.clickable(cell)
			states.activated:connect(function()
				if props.on_sort then
					props.on_sort(column.key)
				end
			end)
		end
	end

	local body = dom.frame({ name = "body", parent = holder, size_of = UDim2.new(1, 0, 0, 0), auto_size = Enum.AutomaticSize.Y, transparent = true, zindex = holder.ZIndex + 1 })
	dom.list(body, { direction = Enum.FillDirection.Vertical, gap = 0 })

	local api = { root = instance, body = body, rows = rows, selected = create_state(nil), row_instances = {} }

	local function clear_body()
		for _, child in body:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		api.row_instances = {}
	end

	function api:render(data)
		clear_body()
		for index, row in data or rows:get() do
			local row_instance = dom.frame({ name = "row", parent = body, size_of = UDim2.new(1, 0, 0, props.row_height or 42), transparent = true, zindex = body.ZIndex + 1 })
			dom.padding(row_instance, 0, 14, 0, 14)
			dom.list(row_instance, { direction = Enum.FillDirection.Horizontal, gap = 10, vertical = Enum.VerticalAlignment.Center })
			if index % 2 == 0 then
				row_instance.BackgroundColor3 = theme_current.color("muted")
				row_instance.BackgroundTransparency = 0.75
			end
			if index < (data and #data or #rows:get()) then
				local line = dom.frame({ name = "line", parent = row_instance, size_of = UDim2.new(1, 0, 0, 1), position = UDim2.fromScale(0, 1), color = theme_current.color("border"), zindex = row_instance.ZIndex + 1 })
			end
			for _, column in columns do
				local raw = row[column.key]
				local cell = dom.frame({ name = "cell", parent = row_instance, size_of = UDim2.new(column.width or 1 / math.max(1, #columns), 0, 1, 0), transparent = true, zindex = row_instance.ZIndex + 1 })
				dom.list(cell, { direction = Enum.FillDirection.Horizontal, gap = 7, vertical = Enum.VerticalAlignment.Center })
				if column.render then
					local rendered = column.render(raw, row, cell)
					if rendered and rendered.Parent == nil then
						rendered.Parent = cell
					end
				else
					lucent_primitives.text({ parent = cell, text = tostring(raw or ""), size = theme_current.type_of("sm"), color = theme_current.color("foreground"), size_of = UDim2.new(1, 0, 1, 0), zindex = cell.ZIndex + 1, truncate = Enum.TextTruncate.AtEnd })
				end
			end
			if props.on_row_click then
				local states = interaction.clickable(row_instance)
				states.hovered:observe(function(hovering)
					row_instance.BackgroundTransparency = hovering and 0.5 or (index % 2 == 0 and 0.75 or 1)
					row_instance.BackgroundColor3 = hovering and theme_current.color("accent") or theme_current.color("muted")
				end)
				states.activated:connect(function()
					api.selected:set(row)
					props.on_row_click(row, index)
				end)
			end
			table.insert(api.row_instances, row_instance)
		end
		return api
	end

	api:render(rows:get())
	return api
end

function navigation.chart(props)
	props = props or {}
	local theme_current = theme.get()
	local kind = props.kind or "line"
	local instance = dom.frame({
		name = props.name or "chart",
		parent = props.parent,
		size_of = props.size_of or UDim2.new(1, 0, 0, props.height or 180),
		color = theme_current.color(props.surface or "card"),
		zindex = props.zindex or 2,
		layout_order = props.layout_order,
		clip = true,
	})
	dom.corner(instance, theme_current.radius_of(props.radius or "lg"))
	dom.stroke(instance, { color = theme_current.color("border") })
	dom.padding(instance, 12, 12, 12, 12)
	local canvas = dom.frame({ name = "canvas", parent = instance, size_of = UDim2.new(1, 0, 1, 0), transparent = true, zindex = instance.ZIndex + 1 })
	local data = props.data or {}
	local accent = theme_current.color(props.accent or "primary")
	local accent_secondary = theme_current.color(props.accent_secondary or "chart_2")

	local function points_from(series, width_value, height_value)
		local max_value = 0
		for _, entry in series do
			max_value = math.max(max_value, tonumber(entry) or 0)
		end
		max_value = math.max(max_value, 1)
		local step = #series > 1 and width_value / (#series - 1) or 0
		local result = {}
		for index, entry in series do
			local value = tonumber(entry) or 0
			table.insert(result, Vector2.new(step * (index - 1), height_value - (value / max_value) * height_value))
		end
		return result, max_value
	end

	local function draw()
		for _, child in canvas:GetChildren() do
			child:Destroy()
		end
		local size_value = canvas.AbsoluteSize
		if size_value.X <= 0 then
			size_value = Vector2.new(300, props.height or 180)
		end
		local grid_color = theme_current.color("border")
		for index = 0, props.grid_lines or 4 do
			local y = (size_value.Y / (props.grid_lines or 4)) * index
			local line = dom.frame({ name = "grid", parent = canvas, size_of = UDim2.new(1, 0, 0, 1), position = UDim2.fromOffset(0, y), color = grid_color, transparency = 0.6, zindex = canvas.ZIndex })
		end
		if kind == "line" or kind == "area" then
			local series = props.series or data
			local points, max_value = points_from(series, size_value.X, size_value.Y)
			local smoothed = path.smooth(points, props.tension or 0.4, props.samples or 12)
			if kind == "area" then
				local closed = {}
				for _, point in smoothed do
					table.insert(closed, point)
				end
				table.insert(closed, Vector2.new(size_value.X, size_value.Y))
				table.insert(closed, Vector2.new(0, size_value.Y))
				local fill = Instance.new("CanvasGroup")
				fill.Name = "area"
				fill.BackgroundTransparency = 1
				fill.Size = UDim2.new(1, 0, 1, 0)
				fill.ZIndex = canvas.ZIndex + 1
				fill.Parent = canvas
				polygon.when_parented(fill, function()
					polygon.fill(fill, closed, accent, theme_current.alpha_value("area") or 0.82, canvas.ZIndex + 2)
				end)
			end
			local stroke_holder = dom.frame({ name = "line", parent = canvas, size_of = UDim2.new(1, 0, 1, 0), transparent = true, zindex = canvas.ZIndex + 3 })
			polygon.when_parented(stroke_holder, function()
				polygon.stroke_group(stroke_holder, { smoothed }, props.stroke_width or 2.2, accent, { zindex = canvas.ZIndex + 3 })
			end)
			if props.dots then
				for _, point in points do
					local dot = dom.frame({ name = "dot", parent = canvas, size_of = UDim2.fromOffset(props.dot_size or 6, props.dot_size or 6), position = UDim2.fromOffset(point.X - (props.dot_size or 6) / 2, point.Y - (props.dot_size or 6) / 2), color = accent, zindex = canvas.ZIndex + 4 })
					dom.corner(dot, (props.dot_size or 6) / 2)
				end
			end
		elseif kind == "bar" then
			local series = props.series or data
			local max_value = 1
			for _, entry in series do
				max_value = math.max(max_value, tonumber(entry) or 0)
			end
			local gap = props.gap or 6
			local bar_width = (size_value.X - gap * (#series - 1)) / math.max(1, #series)
			for index, entry in series do
				local value = tonumber(entry) or 0
				local height_value = (value / max_value) * size_value.Y
				local bar = dom.frame({ name = "bar", parent = canvas, size_of = UDim2.fromOffset(bar_width, 0), position = UDim2.fromOffset((bar_width + gap) * (index - 1), size_value.Y), anchor = Vector2.new(0, 1), color = index % 2 == 0 and accent_secondary or accent, zindex = canvas.ZIndex + 2 })
				dom.corner(bar, theme_current.radius_of(props.bar_radius or "sm"))
				animation.spring({ from = 0, to = height_value, preset = "smooth", delay = (index - 1) * 0.03, on_step = function(alpha)
					bar.Size = UDim2.fromOffset(bar_width, alpha)
				end })
			end
		elseif kind == "donut" then
			local total_value = 0
			for _, entry in data do
				total_value = total_value + (tonumber(entry.value) or 0)
			end
			total_value = math.max(total_value, 1)
			local radius = math.min(size_value.X, size_value.Y) / 2
			local thickness = props.thickness or 16
			local center = Vector2.new(size_value.X / 2, size_value.Y / 2)
			local start_angle = -90
			local holder = dom.frame({ name = "donut", parent = canvas, size_of = UDim2.new(1, 0, 1, 0), transparent = true, zindex = canvas.ZIndex + 2 })
			polygon.when_parented(holder, function()
				for index, entry in data do
					local sweep = (tonumber(entry.value) or 0) / total_value * 360
					local color_value = entry.color and theme_current.color(entry.color) or theme_current.color("chart_" .. tostring(((index - 1) % 6) + 1))
					polygon.stroke(holder, center, radius - thickness / 2, thickness, start_angle, start_angle + sweep, color_value, canvas.ZIndex + 2)
					start_angle = start_angle + sweep
				end
			end)
			if props.center_label then
				lucent_primitives.text({ parent = canvas, text = props.center_label, size = theme_current.type_of("lg"), font = "bold", color = theme_current.color("foreground"), size_of = UDim2.new(1, 0, 0, 20), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), align_x = Enum.TextXAlignment.Center, zindex = canvas.ZIndex + 3 })
			end
		end
		if props.labels then
			local label_holder = dom.frame({ name = "labels", parent = instance, size_of = UDim2.new(1, -24, 0, 14), position = UDim2.new(0, 12, 1, -18), transparent = true, zindex = instance.ZIndex + 2 })
			dom.list(label_holder, { direction = Enum.FillDirection.Horizontal })
			for _, label_text in props.labels do
				lucent_primitives.text({ parent = label_holder, text = label_text, size = theme_current.type_of("2xs"), color = theme_current.color("muted_foreground"), size_of = UDim2.new(1 / math.max(1, #props.labels), 0, 1, 0), align_x = Enum.TextXAlignment.Center, zindex = label_holder.ZIndex + 1 })
			end
		end
	end

	draw()

	local api = { root = instance, canvas = canvas }
	function api:set_data(new_data)
		data = new_data
		props.data = new_data
		draw()
		return api
	end
	function api:set_series(new_series)
		props.series = new_series
		draw()
		return api
	end
	return api
end

function navigation.command(props)
	props = props or {}
	local theme_current = theme.get()
	local api = overlays.create("dialog", merge(props, {
		size_of = UDim2.fromOffset(props.width or 520, 0),
		auto_size = Enum.AutomaticSize.Y,
		position = UDim2.new(0.5, 0, 0, 0.16),
		anchor = Vector2.new(0.5, 0),
		padding = 0,
		gap = 0,
	}))
	local head = dom.frame({ name = "head", parent = api.content, size_of = UDim2.new(1, 0, 0, 48), transparent = true, zindex = api.content.ZIndex + 1 })
	dom.padding(head, 0, 14, 0, 14)
	dom.list(head, { direction = Enum.FillDirection.Horizontal, gap = 10, vertical = Enum.VerticalAlignment.Center })
	lucent_primitives.icon({ name = props.icon or "search", size = 16, parent = head, color = theme_current.color("muted_foreground"), zindex = head.ZIndex + 1 })
	local entry = dom.frame({ name = "entry", parent = head, size_of = UDim2.new(1, -40, 1, 0), transparent = true, zindex = head.ZIndex + 1 })
	local box = Instance.new("TextBox")
	box.Name = "query"
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Size = UDim2.fromScale(1, 1)
	box.PlaceholderText = props.placeholder or "type a command or search..."
	box.PlaceholderColor3 = theme_current.color("muted_foreground")
	box.TextColor3 = theme_current.color("foreground")
	box.FontFace = theme_current.font_of("sans")
	box.TextSize = theme_current.type_of("md")
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.ClearTextOnFocus = false
	box.Text = ""
	box.ZIndex = head.ZIndex + 2
	box.Parent = entry
	local results = dom.frame({ name = "results", parent = api.content, size_of = UDim2.new(1, 0, 0, 0), auto_size = Enum.AutomaticSize.Y, transparent = true, zindex = api.content.ZIndex + 1 })
	dom.padding(results, 6, 6, 6, 6)
	dom.list(results, { direction = Enum.FillDirection.Vertical, gap = 2 })
	local footer = dom.frame({ name = "footer", parent = api.content, size_of = UDim2.new(1, 0, 0, 34), transparent = true, zindex = api.content.ZIndex + 1 })
	dom.padding(footer, 0, 12, 0, 12)
	dom.list(footer, { direction = Enum.FillDirection.Horizontal, gap = 12, vertical = Enum.VerticalAlignment.Center })
	if brand.enabled_for("command") then
		brand_render.mark(footer, { logo_size = 14 })
	end
	lucent_primitives.text({ parent = footer, text = props.footer_text or "esc to close", size = theme_current.type_of("2xs"), color = theme_current.color("muted_foreground"), auto_size = Enum.AutomaticSize.X, size_of = UDim2.new(0, 0, 1, 0), zindex = footer.ZIndex + 1 })

	local items = props.items or {}
	local filtered = {}
	local cursor = 1

	local function score(label_value, query)
		if query == "" then
			return 1
		end
		local lower = string.lower(label_value)
		local position_value = string.find(lower, string.lower(query), 1, true)
		if not position_value then
			return 0
		end
		return 1 - (position_value - 1) / math.max(1, #lower)
	end

	local function paint()
		for _, child in results:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		filtered = {}
		local query = box.Text
		for _, item in items do
			local weight = score(item.label or "", query)
			if weight > 0 then
				table.insert(filtered, { item = item, weight = weight })
			end
		end
		table.sort(filtered, function(a, b)
			return a.weight > b.weight
		end)
		if #filtered == 0 then
			lucent_primitives.text({ parent = results, text = props.empty_text or "no results", size = theme_current.type_of("sm"), color = theme_current.color("muted_foreground"), size_of = UDim2.new(1, 0, 0, 44), align_x = Enum.TextXAlignment.Center, zindex = results.ZIndex + 1 })
			return
		end
		cursor = clamp(cursor, 1, #filtered)
		for index, entry_value in filtered do
			local row = dom.frame({ name = "row", parent = results, size_of = UDim2.new(1, 0, 0, props.item_height or 36), color = theme_current.color("accent"), transparency = index == cursor and 0 or 1, zindex = results.ZIndex + 1 })
			dom.corner(row, theme_current.radius_of("sm"))
			dom.padding(row, 0, 10, 0, 10)
			dom.list(row, { direction = Enum.FillDirection.Horizontal, gap = 9, vertical = Enum.VerticalAlignment.Center })
			if entry_value.item.icon then
				lucent_primitives.icon({ name = entry_value.item.icon, size = 15, parent = row, color = theme_current.color("foreground"), zindex = row.ZIndex + 1 })
			end
			lucent_primitives.text({ parent = row, text = entry_value.item.label or "", size = theme_current.type_of("sm"), color = theme_current.color("foreground"), size_of = UDim2.new(1, entry_value.item.shortcut and -60 or 0, 1, 0), zindex = row.ZIndex + 1, font = "medium" })
			if entry_value.item.group then
				lucent_primitives.badge({ parent = row, text = entry_value.item.group, variant = "outline", size = "sm" })
			end
			if entry_value.item.shortcut then
				lucent_primitives.kbd({ parent = row, text = entry_value.item.shortcut })
			end
			local states = interaction.clickable(row)
			states.hovered:observe(function(hovering)
				cursor = index
				row.BackgroundTransparency = hovering and 0 or (cursor == index and 0 or 1)
			end)
			states.activated:connect(function()
				api:hide()
				if entry_value.item.on_select then
					entry_value.item.on_select()
				end
			end)
		end
	end

	box:GetPropertyChangedSignal("Text"):Connect(paint)
	box.FocusLost:Connect(function(enter_pressed)
		if enter_pressed and filtered[cursor] then
			api:hide()
			if filtered[cursor].item.on_select then
				filtered[cursor].item.on_select()
			end
		end
	end)

	local function move(delta)
		cursor = clamp(cursor + delta, 1, math.max(1, #filtered))
		local index = 0
		for _, child in results:GetChildren() do
			if child:IsA("Frame") then
				index = index + 1
				animation.tween(child, { BackgroundTransparency = index == cursor and 0 or 1 }, { duration = theme_current.motion.fast, ease = "quad" })
			end
		end
	end

	api._trove:connect(box.FocusLost:Connect(function() end))
	interaction.keybind(Enum.KeyCode.Down, function()
		if api.open:get() then
			move(1)
		end
	end)
	interaction.keybind(Enum.KeyCode.Up, function()
		if api.open:get() then
			move(-1)
		end
	end)

	local original_show = api.show
	function api:show()
		original_show(api)
		box.Text = ""
		cursor = 1
		paint()
		task.delay(0.05, function()
			box:CaptureFocus()
		end)
		return api
	end

	function api:set_items(new_items)
		items = new_items
		paint()
		return api
	end

	interaction.combo({ Enum.KeyCode.LeftControl, Enum.KeyCode.K }, function()
		api:show()
	end)
	interaction.combo({ Enum.KeyCode.RightControl, Enum.KeyCode.K }, function()
		api:show()
	end)

	return api
end

local lucent = {}

lucent.version = "1.0.0"
lucent.library = "lucent"

function lucent.init(options)
	options = options or {}
	if options.parent then
		shell.root(options.parent)
	else
		shell.gui()
	end
	if options.theme then
		theme.set(options.theme)
	end
	if options.logo ~= nil or options.brand then
		brand.configure(options.brand or { logo = options.logo })
	end
	lucent.root = shell.gui()
	return lucent
end

function lucent.mount(parent, options)
	return lucent.init(merge(options or {}, { parent = parent }))
end

function lucent.theme(options)
	return theme.set(options)
end

function lucent.get_theme()
	return theme.get()
end

function lucent.on_theme(fn)
	return theme.changed:connect(fn)
end

function lucent.palette(name, palette)
	return theme.register(name, palette)
end

function lucent.set_logo(logo, options)
	brand.set_logo(logo)
	if options then
		brand.configure(options)
	end
	return lucent
end

function lucent.set_wordmark(text, options)
	brand.set_wordmark(text)
	if options then
		brand.configure(options)
	end
	return lucent
end

function lucent.brand(options)
	return brand.configure(options)
end

function lucent.no_logo()
	return brand.clear()
end

function lucent.notify(options)
	return overlays.toast(options)
end

function lucent.dialog(options)
	return overlays.dialog(options)
end

function lucent.drawer(options)
	return overlays.drawer(options)
end

function lucent.command(options)
	return navigation.command(options)
end

function lucent.menu(options)
	return overlays.menu(options)
end

function lucent.tooltip(options)
	return overlays.tooltip(options)
end

function lucent.util()
	return utils
end

function lucent.icons()
	return icons
end

function lucent.spring(options)
	return animation.spring(options)
end

function lucent.tween(instance, goals, options)
	return animation.tween(instance, goals, options)
end

function lucent.path()
	return path
end

function lucent.dom()
	return dom
end

lucent.container = lucent_primitives.container
lucent.text = lucent_primitives.text
lucent.icon = lucent_primitives.icon
lucent.badge = lucent_primitives.badge
lucent.separator = lucent_primitives.separator
lucent.avatar = lucent_primitives.avatar
lucent.spinner = lucent_primitives.spinner
lucent.skeleton = lucent_primitives.skeleton
lucent.kbd = lucent_primitives.kbd
lucent.stacked = lucent_primitives.stacked
lucent.scroll = lucent_primitives.scroll
lucent.image = lucent_primitives.image

lucent.button = controls.button
lucent.icon_button = controls.icon_button
lucent.toggle_group = controls.toggle_group
lucent.card = controls.card
lucent.input = controls.input
lucent.textarea = controls.textarea
lucent.switch = controls.switch
lucent.checkbox = controls.checkbox
lucent.radio_group = controls.radio_group
lucent.slider = controls.slider
lucent.dropdown = overlays.dropdown

lucent.navbar = navigation.navbar
lucent.nav_link = navigation.nav_link
lucent.sidebar = navigation.sidebar
lucent.tabs = navigation.tabs
lucent.accordion = navigation.accordion
lucent.breadcrumb = navigation.breadcrumb
lucent.pagination = navigation.pagination
lucent.progress = navigation.progress
lucent.alert = navigation.alert
lucent.stat = navigation.stat
lucent.table = navigation.table
lucent.chart = navigation.chart

lucent.signal = create_signal
lucent.state = create_state
lucent.store = create_store
lucent.trove = create_trove

return lucent
end)()

return lucent
