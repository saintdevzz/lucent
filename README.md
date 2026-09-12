# lucent

a single file ui kit for roblox. one modulescript, no dependencies, everything animated and every color yours to change.

## install

running from an executor, grab it off the repo:

```lua
local lucent = loadstring(game:HttpGet("https://raw.githubusercontent.com/saintdevzz/lucent/main/lucent.lua?v=2"))()
```

`demo.lua` already does that by itself, so you can run it as-is. it tries `game:HttpGet` first and falls through `HttpService` and the executor `request` functions, and it looks for a local `lucent.lua` next to itself or in `ReplicatedStorage` before downloading anything. if it can't get the library it tells you the actual reason instead of just dying.

plain roblox has no `loadstring`, so download `lucent.lua`, drop it in `ReplicatedStorage` and:

```lua
local replicated = game:GetService("ReplicatedStorage")
local lucent = require(replicated:WaitForChild("lucent"))
```

## first thing you do

```lua
lucent.init({
	theme = {
		palette = "midnight",
		colors = {
			primary = Color3.fromRGB(138, 122, 255),
			ring = Color3.fromRGB(138, 122, 255),
		},
	},
})
```

`init` makes the screengui and sets the theme. after that `lucent.root` is where you parent your stuff.

## logo

there is no logo until you set one. that is the default.

```lua
lucent.set_logo("rbxassetid://123456789", {
	logo_size = 24,
	logo_radius = 6,
	placement = {
		navbar = true,
		sidebar = true,
		command = true,
		dialog = false,
		drawer = false,
		toast = false,
		card_header = false,
	},
})

lucent.set_wordmark("your app")
```

pass an asset id, or an actual `ImageLabel` instance, or a function that builds one. `lucent.no_logo()` takes it back out.

## palettes

eight ship with it: `dark`, `light`, `midnight`, `rose`, `emerald`, `nord`, `cyber`, `amber`.

```lua
lucent.theme({ palette = "cyber" })
lucent.palette("vapor", { mode = "dark", colors = { primary = Color3.fromRGB(255, 90, 200) } })
lucent.on_theme(function(theme) print_it(theme.color("primary")) end)
```

anything you pass in `colors` overrides the palette, so you can tune one key without owning the whole thing.

## components

`container` `text` `icon` `badge` `separator` `avatar` `spinner` `skeleton` `kbd` `stacked` `scroll` `image`

`button` `icon_button` `toggle_group` `card` `input` `textarea` `switch` `checkbox` `radio_group` `slider` `dropdown`

`navbar` `nav_link` `sidebar` `tabs` `accordion` `breadcrumb` `pagination` `progress` `alert` `stat` `table` `chart` `command`

overlays: `dialog` `drawer` `menu` `tooltip` `notify`

plumbing: `signal` `state` `store` `trove` `spring` `tween` `util` `icons` `path` `dom`

## quick look

```lua
local card = lucent.card({
	parent = lucent.root,
	title = "revenue",
	description = "last twelve months",
	size_of = UDim2.new(0, 420, 0, 260),
})

lucent.chart({
	parent = card,
	kind = "area",
	series = { 12, 18, 15, 24, 22, 31, 28, 36, 34, 42, 47, 52 },
	dots = true,
})

lucent.button({
	parent = card,
	text = "export",
	icon = "download",
	variant = "outline",
	on_click = function()
		lucent.notify({ title = "export started", variant = "success" })
	end,
})
```

## icons

around 200 vector icons are baked in and drawn at runtime, so there are no image assets to upload. `lucent.icons().list()` gives you the names. ones that do not exist fall back quietly instead of erroring.

## motion

everything sits on a spring integrator running off one heartbeat. presets are `snappy`, `smooth`, `gentle`, `bouncy`, `precise`, `heavy` and `lazy`.

```lua
local animation = lucent.spring({ from = 0, to = 1, preset = "bouncy", on_step = function(value)
	frame.Position = UDim2.fromScale(value, 0)
end })
```

## notes

buttons, links and rows all accept `on_click` / `on_change` / `on_done`. inputs accept `on_change`. tables accept a `render` function per column, so a cell can be a badge, a progress bar or anything else you build. `lucent.table` returns an api with `render`, `selected` and `row_instances`.
