-- lucent demo
-- runs straight off the repo, or alongside a local lucent.lua

local replicated = game:GetService("ReplicatedStorage")
local source = "https://raw.githubusercontent.com/saintdevzz/lucent/main/lucent.lua"

local function local_copy()
	local places = { replicated }
	if script then
		table.insert(places, 1, script)
	end
	for _, parent in ipairs(places) do
		local found = parent:FindFirstChild("lucent")
		if found then
			return found
		end
	end
	return nil
end

local function fetchers()
	local http = game:GetService("HttpService")
	local attempts = {}

	table.insert(attempts, function()
		return game:HttpGet(source)
	end)
	table.insert(attempts, function()
		return http:HttpGet(source)
	end)
	table.insert(attempts, function()
		return http:GetAsync(source)
	end)

	local external = request or http_request
	if external then
		table.insert(attempts, function()
			local reply = external({ Url = source, Method = "GET" })
			return reply.Body or reply.body
		end)
	end

	if syn and syn.request then
		table.insert(attempts, function()
			local reply = syn.request({ Url = source, Method = "GET" })
			return reply.Body or reply.body
		end)
	end

	return attempts
end

local function download()
	local reason = "nothing to try"
	for _, attempt in ipairs(fetchers()) do
		local ok, body = pcall(attempt)
		if ok and type(body) == "string" and #body > 0 then
			return body
		end
		if not ok then
			reason = tostring(body)
		end
	end
	return nil, reason
end

local function acquire()
	local existing = local_copy()
	if existing then
		local ok, module = pcall(require, existing)
		if ok then
			return module
		end
	end

	local compile = loadstring or load
	if not compile then
		return nil, "this environment has no loadstring"
	end

	local body, download_error = download()
	if not body then
		return nil, "download failed, " .. tostring(download_error)
	end

	local chunk, compile_error = compile(body, "lucent")
	if not chunk then
		return nil, "compile failed, " .. tostring(compile_error)
	end

	local ok, loaded = pcall(chunk)
	if not ok then
		return nil, "lucent threw on load, " .. tostring(loaded)
	end
	return loaded
end

local lucent, failure = acquire()

if not lucent then
	error("lucent unavailable: " .. tostring(failure), 0)
end

local brand_logo = nil

if brand_logo then
	lucent.set_logo(brand_logo, {
		logo_size = 24,
		logo_radius = 6,
		placement = {
			navbar = true,
			sidebar = true,
			command = true,
			toast = true,
			dialog = true,
			drawer = true,
			card_header = false,
		},
	})
end

lucent.set_wordmark("lucent", { wordmark_size = 15 })

lucent.init({
	theme = {
		palette = "midnight",
		colors = {
			primary = Color3.fromRGB(138, 122, 255),
			ring = Color3.fromRGB(138, 122, 255),
			chart_2 = Color3.fromRGB(92, 214, 188),
		},
	},
})

local palette_names = { "midnight", "dark", "light", "rose", "emerald", "nord", "cyber", "amber" }
local palette_index = lucent.state(1)

local function cycle_palette()
	palette_index:set((palette_index:get() % #palette_names) + 1)
	local name = palette_names[palette_index:get()]
	lucent.theme({ palette = name })
	lucent.notify({ title = "theme", description = name, variant = "info", icon = "palette", duration = 2 })
end

local sidebar
local settings_drawer
local confirm_dialog
local project_table
local filter_rows

local shell = lucent.container({
	parent = lucent.root,
	name = "demo",
	size_of = UDim2.fromScale(1, 1),
	surface = "background",
	zindex = 1,
})

local nav, nav_slots = lucent.navbar({
	parent = shell,
	surface = "background",
	height = 56,
})

lucent.icon_button({
	parent = nav_slots.left,
	icon = "sidebar",
	variant = "ghost",
	height = 30,
	on_click = function()
		if sidebar then
			sidebar:toggle()
		end
	end,
})

lucent.text({
	parent = nav_slots.left,
	text = "lucent",
	size = 14,
	font = "bold",
	auto_size = Enum.AutomaticSize.X,
	size_of = UDim2.new(0, 0, 0, 18),
})

lucent.separator({ parent = nav_slots.left, direction = "vertical", size_of = UDim2.new(0, 1, 0, 22) })

for _, item in { "overview", "analytics", "reports", "team" } do
	lucent.nav_link({
		parent = nav_slots.center,
		text = item,
		active = item == "overview",
		on_click = function()
			lucent.notify({ title = "navigation", description = item, variant = "info", icon = "compass", duration = 2 })
		end,
	})
end

local command_palette = lucent.command({
	placeholder = "search or run a command...",
	items = {
		{ label = "go to overview", icon = "home", group = "nav", shortcut = "g o", on_select = function()
			lucent.notify({ title = "overview", variant = "info", icon = "home", duration = 2 })
		end },
		{ label = "go to analytics", icon = "chart", group = "nav", on_select = function()
			lucent.notify({ title = "analytics", variant = "info", icon = "chart", duration = 2 })
		end },
		{ label = "toggle sidebar", icon = "sidebar", group = "view", on_select = function()
			if sidebar then
				sidebar:toggle()
			end
		end },
		{ label = "switch theme", icon = "palette", group = "view", shortcut = "t", on_select = cycle_palette },
		{ label = "open settings", icon = "settings", group = "app", on_select = function()
			if settings_drawer then
				settings_drawer:show()
			end
		end },
		{ label = "export report", icon = "download", group = "app", on_select = function()
			lucent.notify({ title = "export started", variant = "info", icon = "download", duration = 2 })
		end },
		{ label = "lock workspace", icon = "lock", group = "app", on_select = function()
			lucent.notify({ title = "workspace locked", variant = "warning", icon = "lock", duration = 2 })
		end },
	},
})

lucent.button({
	parent = nav_slots.right,
	text = "theme",
	icon = "palette",
	variant = "outline",
	size = "sm",
	on_click = cycle_palette,
})

lucent.button({
	parent = nav_slots.right,
	text = "search",
	icon = "search",
	variant = "ghost",
	size = "sm",
	on_click = function()
		command_palette:show()
	end,
})

lucent.button({
	parent = nav_slots.right,
	text = "new",
	icon = "plus",
	size = "sm",
	on_click = function()
		lucent.notify({ title = "project created", description = "untitled project added", variant = "success", icon = "plus", duration = 3 })
	end,
})

lucent.button({
	parent = nav_slots.right,
	text = "delete",
	icon = "trash",
	variant = "ghost",
	size = "sm",
	on_click = function()
		if confirm_dialog then
			confirm_dialog:show()
		end
	end,
})

lucent.badge({ parent = nav_slots.right, text = "beta", variant = "outline" })
lucent.avatar({ parent = nav_slots.right, text = "LD", size = 30 })

local body = lucent.container({
	parent = shell,
	name = "body",
	size_of = UDim2.new(1, 0, 1, -56),
	position = UDim2.fromOffset(0, 56),
	transparent = true,
	zindex = 2,
})

sidebar = lucent.sidebar({
	parent = body,
	width = 232,
	title = "workspace",
	surface = "sidebar",
})

sidebar:group({
	label = "general",
	items = {
		{ text = "overview", icon = "home", active = true, on_click = function()
			lucent.notify({ title = "overview", variant = "info", icon = "home", duration = 2 })
		end },
		{ text = "analytics", icon = "chart", badge = "4", on_click = function()
			lucent.notify({ title = "analytics", variant = "info", icon = "chart", duration = 2 })
		end },
		{ text = "inbox", icon = "mail", badge = "12", on_click = function()
			lucent.notify({ title = "inbox", description = "12 unread threads", variant = "info", icon = "mail", duration = 2 })
		end },
		{ text = "members", icon = "users", on_click = function()
			lucent.notify({ title = "members", description = "18 in this workspace", variant = "info", icon = "users", duration = 2 })
		end },
	},
})

sidebar:group({
	label = "system",
	items = {
		{ text = "settings", icon = "settings", on_click = function()
			if settings_drawer then
				settings_drawer:show()
			end
		end },
		{ text = "security", icon = "shield", on_click = function()
			lucent.notify({ title = "security", description = "2fa enforced", variant = "success", icon = "shield_check", duration = 2 })
		end },
		{ text = "billing", icon = "credit_card", on_click = function()
			lucent.notify({ title = "billing", description = "pro plan, renews in 12 days", variant = "warning", icon = "wallet", duration = 2 })
		end },
	},
})

local sidebar_footer = sidebar:footer()

lucent.card({
	parent = sidebar_footer,
	surface = "card",
	padding = 10,
	title = "pro plan",
	description = "unlimited projects, priority support",
	body_padding = 0,
})

lucent.button({
	parent = sidebar_footer,
	text = "upgrade",
	icon = "sparkles",
	size = "sm",
	on_click = function()
		lucent.notify({ title = "upgrade", description = "billing opened", variant = "success", icon = "sparkles", duration = 2 })
	end,
})

local main = lucent.scroll({
	parent = body,
	name = "main",
	size_of = UDim2.new(1, -232, 1, 0),
	position = UDim2.fromOffset(232, 0),
	direction = Enum.ScrollingDirection.Y,
	auto_canvas = Enum.AutomaticSize.Y,
	padding = 20,
	thickness = 8,
	zindex = 2,
})

local page = lucent.container({
	parent = main,
	name = "page",
	size_of = UDim2.new(1, 0, 0, 0),
	auto_size = Enum.AutomaticSize.Y,
	transparent = true,
	list = { direction = Enum.FillDirection.Vertical, gap = 18 },
	zindex = 3,
})

local header = lucent.container({
	parent = page,
	name = "header",
	size_of = UDim2.new(1, 0, 0, 0),
	auto_size = Enum.AutomaticSize.Y,
	transparent = true,
	list = { direction = Enum.FillDirection.Vertical, gap = 10 },
	zindex = 4,
})

lucent.breadcrumb({
	parent = header,
	items = {
		{ label = "workspace", on_click = function() end },
		{ label = "projects", on_click = function() end },
		{ label = "overview" },
	},
})

local title_row = lucent.container({
	parent = header,
	name = "title_row",
	size_of = UDim2.new(1, 0, 0, 40),
	transparent = true,
	list = { direction = Enum.FillDirection.Horizontal, gap = 10, vertical = Enum.VerticalAlignment.Center },
	zindex = 5,
})

lucent.text({
	parent = title_row,
	text = "overview",
	size = 26,
	font = "bold",
	auto_size = Enum.AutomaticSize.X,
	size_of = UDim2.new(0, 0, 0, 34),
	layout_order = -10,
})

lucent.badge({ parent = title_row, text = "live", variant = "success", dot = true })
lucent.container({ parent = title_row, size_of = UDim2.new(1, -560, 0, 1), transparent = true })

lucent.input({
	parent = title_row,
	placeholder = "search projects...",
	icon = "search",
	size_of = UDim2.new(0, 210, 0, 34),
	on_change = function(text)
		if project_table and filter_rows then
			project_table:render(filter_rows(text))
		end
	end,
})

lucent.button({
	parent = title_row,
	text = "new project",
	icon = "plus",
	on_click = function()
		lucent.notify({ title = "project created", description = "untitled project added", variant = "success", icon = "plus", duration = 3 })
	end,
})

local stats_row = lucent.container({
	parent = page,
	name = "stats",
	size_of = UDim2.new(1, 0, 0, 96),
	transparent = true,
	list = { direction = Enum.FillDirection.Horizontal, gap = 14 },
	zindex = 5,
})

local stat_definitions = {
	{ label = "total revenue", value = 48231, format = "number", delta = 12.4, icon = "coins" },
	{ label = "active users", value = 8942, format = "number", delta = 4.1, icon = "users" },
	{ label = "conversion", value = 3.6, suffix = "%", delta = -0.8, icon = "target" },
	{ label = "sessions", value = 23104, format = "number", delta = 7.2, icon = "activity" },
}

for _, definition in stat_definitions do
	lucent.stat({
		parent = stats_row,
		label = definition.label,
		value = definition.value,
		format = definition.format,
		suffix = definition.suffix,
		delta = definition.delta,
		icon = definition.icon,
		animate = true,
		size_of = UDim2.new(0.25, -14, 0, 96),
	})
end

local mid_row = lucent.container({
	parent = page,
	name = "mid",
	size_of = UDim2.new(1, 0, 0, 268),
	transparent = true,
	list = { direction = Enum.FillDirection.Horizontal, gap = 14 },
	zindex = 5,
})

local revenue_card = lucent.card({
	parent = mid_row,
	title = "revenue",
	description = "last twelve months",
	size_of = UDim2.new(0.42, -14, 0, 268),
	badge = "monthly",
	body_gap = 10,
})

lucent.button({
	parent = revenue_card,
	text = "export",
	icon = "download",
	variant = "outline",
	size = "sm",
	on_click = function()
		lucent.notify({ title = "export started", variant = "info", icon = "download", duration = 2 })
	end,
})

lucent.chart({
	parent = revenue_card,
	kind = "area",
	series = { 12, 18, 15, 24, 22, 31, 28, 36, 34, 42, 47, 52 },
	labels = { "jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec" },
	size_of = UDim2.new(1, 0, 0, 172),
	dots = true,
	grid_lines = 4,
})

local traffic_card = lucent.card({
	parent = mid_row,
	title = "traffic",
	description = "source split",
	size_of = UDim2.new(0.29, -7, 0, 268),
})

lucent.chart({
	parent = traffic_card,
	kind = "donut",
	data = {
		{ value = 42 },
		{ value = 27 },
		{ value = 18 },
		{ value = 13 },
	},
	center_label = "42%",
	size_of = UDim2.new(1, 0, 0, 180),
	thickness = 18,
})

local sessions_card = lucent.card({
	parent = mid_row,
	title = "sessions",
	description = "per weekday",
	size_of = UDim2.new(0.29, -7, 0, 268),
})

lucent.chart({
	parent = sessions_card,
	kind = "bar",
	series = { 18, 26, 21, 34, 29, 41, 37 },
	size_of = UDim2.new(1, 0, 0, 180),
	grid_lines = 3,
})

local lower_row = lucent.container({
	parent = page,
	name = "lower",
	size_of = UDim2.new(1, 0, 0, 0),
	auto_size = Enum.AutomaticSize.Y,
	transparent = true,
	list = { direction = Enum.FillDirection.Horizontal, gap = 14 },
	zindex = 5,
})

local project_rows = {
	{ name = "orbit redesign", owner = "ava", status = "active", progress = 78, users = 1240 },
	{ name = "billing v2", owner = "noah", status = "review", progress = 46, users = 320 },
	{ name = "mobile shell", owner = "mila", status = "paused", progress = 21, users = 88 },
	{ name = "search ranking", owner = "kai", status = "active", progress = 64, users = 918 },
	{ name = "audit log", owner = "remy", status = "done", progress = 100, users = 410 },
	{ name = "onboarding flow", owner = "theo", status = "review", progress = 35, users = 204 },
}

local status_meta = {
	active = { variant = "success", icon = "activity" },
	review = { variant = "warning", icon = "eye" },
	paused = { variant = "muted", icon = "pause" },
	done = { variant = "default", icon = "check" },
}

local function status_cell(value)
	local meta = status_meta[value] or status_meta.paused
	return lucent.badge({ text = value, variant = meta.variant, icon = meta.icon })
end

local function progress_cell(value)
	local bar = lucent.progress({
		value = value,
		size_of = UDim2.new(1, 0, 0, 6),
		tone = value >= 75 and "success" or "primary",
	})
	return bar
end

filter_rows = function(query)
	if query == nil or query == "" then
		return project_rows
	end
	local out = {}
	for _, row in project_rows do
		if string.find(string.lower(row.name), string.lower(query), 1, true) then
			table.insert(out, row)
		end
	end
	return out
end

local table_card = lucent.card({
	parent = lower_row,
	title = "projects",
	description = "everything shipping this quarter",
	size_of = UDim2.new(0.62, -7, 0, 0),
	body_padding = 0,
})

project_table = lucent.table({
	parent = table_card,
	columns = {
		{ key = "name", label = "project", width = 0.28 },
		{ key = "owner", label = "owner", width = 0.16 },
		{ key = "status", label = "status", width = 0.2, render = function(raw)
			return status_cell(raw)
		end },
		{ key = "progress", label = "progress", width = 0.22, render = function(raw)
			return progress_cell(raw)
		end },
		{ key = "users", label = "users", width = 0.14 },
	},
	rows = project_rows,
	on_row_click = function(row)
		lucent.notify({ title = row.name, description = "owned by " .. tostring(row.owner), variant = "info", icon = "folder", duration = 2 })
	end,
})

local side_column = lucent.container({
	parent = lower_row,
	name = "side_column",
	size_of = UDim2.new(0.38, -7, 0, 0),
	auto_size = Enum.AutomaticSize.Y,
	transparent = true,
	list = { direction = Enum.FillDirection.Vertical, gap = 14 },
	zindex = 6,
})

local feed_entries = {
	{ icon = "git_branch", text = "ava pushed 3 commits to orbit", tone = "info" },
	{ icon = "check_circle", text = "billing v2 passed review", tone = "success" },
	{ icon = "warning", text = "search latency above threshold", tone = "warning" },
	{ icon = "trash", text = "old export job was removed", tone = "destructive" },
}

local function build_feed(kind)
	local holder = lucent.container({
		size_of = UDim2.new(1, 0, 0, 0),
		auto_size = Enum.AutomaticSize.Y,
		transparent = true,
		list = { direction = Enum.FillDirection.Vertical, gap = 10 },
	})
	for _, entry in feed_entries do
		local keep = kind == "all" or (kind == "alerts" and entry.tone ~= "info") or (kind == "notes" and entry.tone == "info")
		if keep then
			lucent.alert({
				parent = holder,
				variant = kind == "notes" and "default" or entry.tone,
				description = entry.text,
				icon = entry.icon,
			})
		end
	end
	lucent.skeleton({ parent = holder, size_of = UDim2.new(1, 0, 0, 12) })
	lucent.skeleton({ parent = holder, size_of = UDim2.new(0.68, 0, 0, 12) })
	return holder
end

local activity_card = lucent.card({
	parent = side_column,
	title = "activity",
	size_of = UDim2.new(1, 0, 0, 0),
	body_padding = 12,
	body_gap = 12,
})

lucent.tabs({
	parent = activity_card,
	variant = "segmented",
	tabs = {
		{ value = "all", label = "all", icon = "layers", content = { build_feed("all") } },
		{ value = "alerts", label = "alerts", icon = "bell", content = { build_feed("alerts") } },
		{ value = "notes", label = "notes", icon = "edit", content = { build_feed("notes") } },
	},
	on_change = function(value)
		lucent.notify({ title = "tab", description = tostring(value), variant = "info", duration = 2 })
	end,
})

local form_card = lucent.card({
	parent = side_column,
	title = "preferences",
	description = "changes land the moment you touch them",
	size_of = UDim2.new(1, 0, 0, 0),
	body_gap = 16,
})

lucent.switch({
	parent = form_card,
	label = "email notifications",
	default = true,
	on_change = function(value)
		lucent.notify({ title = "notifications", description = value and "on" or "off", variant = "info", icon = "bell", duration = 2 })
	end,
})

lucent.switch({
	parent = form_card,
	label = "weekly digest",
	default = false,
	on_change = function(value)
		lucent.notify({ title = "weekly digest", description = value and "on" or "off", variant = "info", icon = "mail", duration = 2 })
	end,
})

lucent.dropdown({
	parent = form_card,
	placeholder = "select a plan",
	options = {
		{ label = "starter", value = "starter", icon = "rocket" },
		{ label = "pro", value = "pro", icon = "zap" },
		{ label = "enterprise", value = "enterprise", icon = "crown" },
	},
	default = "pro",
	on_change = function(value)
		lucent.notify({ title = "plan", description = tostring(value), variant = "success", icon = "credit_card", duration = 2 })
	end,
})

lucent.container({ parent = form_card, size_of = UDim2.new(1, 0, 0, 22), transparent = true })

lucent.slider({
	parent = form_card,
	label = "alert volume",
	min = 0,
	max = 100,
	step = 5,
	default = 65,
	show_value = true,
	on_done = function(value)
		lucent.notify({ title = "volume", description = tostring(value) .. "%", variant = "info", icon = "volume", duration = 2 })
	end,
})

lucent.text({ parent = form_card, text = "region", size = 12, font = "medium", size_of = UDim2.new(1, 0, 0, 16) })

lucent.radio_group({
	parent = form_card,
	default = "eu",
	options = {
		{ label = "europe", value = "eu" },
		{ label = "north america", value = "na" },
		{ label = "asia pacific", value = "apac" },
	},
	on_change = function(value)
		lucent.notify({ title = "region", description = tostring(value), variant = "info", icon = "globe", duration = 2 })
	end,
})

lucent.textarea({
	parent = form_card,
	placeholder = "notes for the team...",
	height = 78,
})

local form_actions = lucent.container({
	parent = form_card,
	size_of = UDim2.new(1, 0, 0, 34),
	transparent = true,
	list = { direction = Enum.FillDirection.Horizontal, gap = 8 },
})

lucent.button({
	parent = form_actions,
	text = "save",
	icon = "save",
	on_click = function()
		lucent.notify({ title = "saved", description = "preferences updated", variant = "success", icon = "check_circle", duration = 2 })
	end,
})

lucent.button({
	parent = form_actions,
	text = "reset",
	variant = "ghost",
	on_click = function()
		lucent.notify({ title = "reset", description = "back to defaults", variant = "warning", icon = "refresh", duration = 2 })
	end,
})

local faq_card = lucent.card({
	parent = side_column,
	title = "faq",
	size_of = UDim2.new(1, 0, 0, 0),
	body_padding = 12,
	body_gap = 10,
})

lucent.accordion({
	parent = faq_card,
	single = true,
	items = {
		{ title = "how do i add my logo?", content = "call lucent.set_logo with an asset id or an instance, then pick the slots with lucent.brand. nothing renders until you do.", open = true },
		{ title = "can i change every color?", content = "yes. pass colors into lucent.theme, or register a whole palette with lucent.palette and switch by name." },
		{ title = "is everything animated?", content = "every control runs on a spring integrator with snappy, smooth, gentle, bouncy, precise, heavy and lazy presets." },
	},
})

local pagination_row = lucent.container({
	parent = page,
	size_of = UDim2.new(1, 0, 0, 40),
	transparent = true,
	list = { direction = Enum.FillDirection.Horizontal, gap = 10, vertical = Enum.VerticalAlignment.Center },
	zindex = 5,
})

lucent.text({
	parent = pagination_row,
	text = "showing 1-6 of 42",
	size = 12,
	color = lucent.get_theme().color("muted_foreground"),
	auto_size = Enum.AutomaticSize.X,
	size_of = UDim2.new(0, 0, 0, 16),
})

lucent.container({ parent = pagination_row, size_of = UDim2.new(1, -360, 0, 1), transparent = true })

lucent.pagination({
	parent = pagination_row,
	total = 42,
	per_page = 6,
	page = 1,
	window = 1,
	on_change = function(value)
		lucent.notify({ title = "page " .. tostring(value), variant = "info", icon = "rows", duration = 2 })
	end,
})

local settings_holder = lucent.container({
	size_of = UDim2.new(1, 0, 0, 0),
	auto_size = Enum.AutomaticSize.Y,
	transparent = true,
	list = { direction = Enum.FillDirection.Vertical, gap = 16 },
})

lucent.alert({
	parent = settings_holder,
	variant = "info",
	title = "branding",
	description = "set a logo with lucent.set_logo and it lands in the navbar, sidebar and command palette. leave it nil and nothing is drawn.",
})

lucent.switch({ parent = settings_holder, label = "compact mode", default = false, on_change = function(value)
	lucent.notify({ title = "compact", description = value and "on" or "off", variant = "info", duration = 2 })
end })

lucent.switch({ parent = settings_holder, label = "reduce motion", default = false, on_change = function(value)
	lucent.notify({ title = "reduce motion", description = value and "on" or "off", variant = "info", duration = 2 })
end })

lucent.container({ parent = settings_holder, size_of = UDim2.new(1, 0, 0, 22), transparent = true })

lucent.slider({ parent = settings_holder, label = "ui scale", min = 80, max = 130, step = 5, default = 100, show_value = true })

lucent.container({ parent = settings_holder, size_of = UDim2.new(1, 0, 0, 34), transparent = true })

lucent.input({ parent = settings_holder, placeholder = "workspace name", value = "acme inc", size_of = UDim2.new(1, 0, 0, 34) })

settings_drawer = lucent.drawer({
	side = "right",
	width = 344,
	title = "settings",
	description = "tune the workspace",
	body = { settings_holder },
	footer = {
		lucent.button({ text = "cancel", variant = "outline", on_click = function()
			settings_drawer:hide()
		end }),
		lucent.button({ text = "apply", on_click = function()
			settings_drawer:hide()
			lucent.notify({ title = "settings applied", variant = "success", icon = "check_circle", duration = 2 })
		end }),
	},
})

confirm_dialog = lucent.dialog({
	title = "delete project",
	description = "this removes the project and all of its history. there is no undo.",
	confirm_text = "delete",
	confirm_variant = "destructive",
	cancel_text = "keep it",
	body = {
		lucent.alert({ variant = "destructive", title = "careful", description = "three integrations depend on this project." }),
	},
	on_confirm = function()
		lucent.notify({ title = "deleted", variant = "destructive", icon = "trash", duration = 3 })
	end,
})

lucent.notify({
	title = "welcome back",
	description = "press ctrl+k to open the command palette",
	variant = "success",
	icon = "sparkles",
	duration = 5,
})

lucent.notify({
	title = "no logo by default",
	description = "set one with lucent.set_logo when you are ready",
	variant = "info",
	icon = "image",
	duration = 6,
})

return {
	root = shell,
	nav = nav,
	sidebar = sidebar,
	command = command_palette,
	drawer = settings_drawer,
	dialog = confirm_dialog,
	table = project_table,
}
