hs.loadSpoon("EmmyLua")
hs.loadSpoon("Lunette")
hs.loadSpoon("Hyper")

App = hs.application
Hyper = spoon.Hyper
Lunette = spoon.Lunette

Lunette:bindHotkeys(spoon.Lunette.defaultHotkeys)

local hyperKeyPressed = false

local function setupModes(modes)
	for _, group in pairs(modes) do
		group.mode = Hyper:new()
		group.mode:bind({}, "escape", function()
			hyperKeyPressed = true
			group.mode:exit()
			hs.alert("Exited mode " .. group.alias or group.key)
		end)

		for _, hotkey in pairs(group.hotkeys) do
			group.mode:bind(hotkey.mod, hotkey.key, nil, function()
				hotkey.callback()
				hyperKeyPressed = true
				group.mode:exit()
				Hyper:exit()
			end)
		end

		Hyper:bind(group.mod, group.key, nil, function()
			hyperKeyPressed = true
			group.mode:enter()
		end)
	end
end

local modes = {
	{
		-- Apps
		key = "a",
		alias = "Apps",
		mod = {},
		hotkeys = {
			{
				key = "b",
				label = "Browser",
				mod = {},
				callback = function()
					hs.alert("Browser")
					-- Get default browser name using AppleScript
					local script = [[
use framework "AppKit"
use AppleScript version "2.4"
use scripting additions

property NSWorkspace : a reference to current application's NSWorkspace
property NSURL : a reference to current application's NSURL

set wurl to NSURL's URLWithString:"https://www.apple.com"
set thisBrowser to (NSWorkspace's sharedWorkspace)'s URLForApplicationToOpenURL:wurl
set appname to (thisBrowser's absoluteString)'s lastPathComponent()'s stringByDeletingPathExtension() as text
return appname as text
]]
					local output, status = hs.execute("osascript -e '" .. script:gsub("'", "'\\''") .. "'")
					local browserName = output:gsub("%s+", "")

					if browserName and browserName ~= "" then
						App.launchOrFocus(browserName)
					else
						-- Fallback to Safari if we can't determine default
						App.launchOrFocus("Safari")
					end
				end,
			},
			{
				key = "c",
				label = "Calendar",
				appName = "Calendar",
				mod = {},
				callback = function()
					hs.alert("Calendar")
					App.launchOrFocus("Calendar")
				end,
			},
			{
				key = "d",
				label = "Dashlane",
				appName = "Dashlane",
				mod = {},
				callback = function()
					hs.alert("Dashlane")
					App.launchOrFocus("Dashlane")
				end,
			},
			{
				key = "e",
				label = "Messages",
				appName = "Messages",
				mod = {},
				callback = function()
					hs.alert("Messages")
					App.launchOrFocus("Messages")
				end,
			},
			{
				key = "f",
				label = "Finder",
				appName = "Finder",
				mod = {},
				callback = function()
					hs.alert("Finder")
					App.launchOrFocus("Finder")
				end,
			},
			{
				key = "m",
				label = "Mail",
				appName = "Mail",
				mod = {},
				callback = function()
					hs.alert("Mail")
					App.launchOrFocus("Mail")
				end,
			},
			{
				key = "n",
				label = "Notes",
				appName = "Notes",
				mod = {},
				callback = function()
					hs.alert("Notes")
					App.launchOrFocus("Notes")
				end,
			},
			{
				key = "s",
				label = "Slack",
				appName = "Slack",
				mod = {},
				callback = function()
					hs.alert("Slack")
					App.launchOrFocus("Slack")
				end,
			},
			{
				key = "t",
				label = "Terminal",
				appName = "Ghostty",
				mod = {},
				callback = function()
					hs.alert("Terminal")
					if not App.launchOrFocus("Ghostty") then
						if not App.launchOrFocus("kitty") then
							App.launchOrFocus("Terminal")
						end
					end
				end,
			},
		},
	},
	{
		-- Hammerspoon
		alias = "Hammerspoon",
		key = "h",
		mod = {},
		hotkeys = {
			{
				key = "c",
				label = "Toggle Console",
				mod = {},
				callback = function()
					hs.alert("Console")
					hs.toggleConsole()
				end,
			},
			{
				key = "r",
				label = "Reload Config",
				mod = {},
				callback = function()
					hs.alert("Reloading...")
					hs.reload()
				end,
			},
		},
	},
}

-- Pre-compute bundle IDs for all apps at startup
local function resolveBundleIDs()
	for _, mode in ipairs(modes) do
		for _, hotkey in ipairs(mode.hotkeys) do
			if hotkey.appName then
				local output, status = hs.execute(string.format("osascript -e 'id of app \"%s\"'", hotkey.appName))
				if status then
					hotkey.bundleID = output:gsub("%s+$", "")
				end
			end
		end
	end
end

-- Create the chooser function
local createHyperChooser = function()
	local choices = {}
	local callbacks = {}

	for _, mode in ipairs(modes) do
		for _, hotkey in ipairs(mode.hotkeys) do
			local choice = {
				text = hotkey.label or hotkey.key,
				subText = "F19 → " .. mode.key .. " → " .. hotkey.key,
			}

			-- Get app icon from pre-computed bundle ID
			if hotkey.bundleID then
				choice.image = hs.image.imageFromAppBundle(hotkey.bundleID)
			end

			table.insert(choices, choice)
			table.insert(callbacks, hotkey.callback)
		end
	end

	local chooser = hs.chooser.new(function(choice)
		if choice then
			-- Find the index of the selected choice and call its callback
			for i, c in ipairs(choices) do
				if c.text == choice.text and c.subText == choice.subText then
					callbacks[i]()
					break
				end
			end
		end
	end)

	chooser:choices(choices)
	chooser:rows(10)
	chooser:width(30)
	chooser:placeholderText("Search actions...")
	chooser:show()
end

resolveBundleIDs()
setupModes(modes)

hs.hotkey.bind({}, "F19", function()
	hyperKeyPressed = false
	Hyper:enter()
end, function()
	Hyper:exit()
	if not hyperKeyPressed then
		createHyperChooser()
	end
end)

local dropbox = require("dropbox")
dropbox:new():start()

local mc = require("monitorcontrol")
mc:new():start()

local linearmouse = require("linearmouse")
linearmouse:new():start()
