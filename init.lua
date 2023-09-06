hs.loadSpoon('EmmyLua')
hs.loadSpoon('Lunette')
hs.loadSpoon('Hyper')

App = hs.application
Hyper = spoon.Hyper
Lunette = spoon.Lunette

Lunette:bindHotkeys(spoon.Lunette.defaultHotkeys)
Hyper:bindHotKeys({ hyperKey = { {}, 'F19' } })

local function setupModes(modes)
	for _, group in pairs(modes) do
		group.mode = Hyper:new()
		group.mode:bind({}, 'escape', function()
			group.mode:exit()
			hs.alert('Exited mode ' .. group.alias or group.key)
		end)

		for _, hotkey in pairs(group.hotkeys) do
			group.mode:bind(
				hotkey.mod, hotkey.key, hotkey.callback,
				function() group.mode:exit() end
			)
		end

		Hyper:bind(group.mod, group.key, function() group.mode:enter() end)
	end
end

local modes = {
	{
		-- Apps
		key = 'a',
		alias = 'Apps',
		mod = {},
		hotkeys = {
			{
				key = 't',
				mod = {},
				callback = function()
					hs.alert('Terminal'); App.launchOrFocus('kitty')
				end
			},
			{
				key = 'b',
				mod = {},
				callback = function()
					hs.alert('Browser'); App.launchOrFocus('Arc')
				end
			},
			{
				key = 'm',
				mod = {},
				callback = function()
					hs.alert('Mail'); App.launchOrFocus('Mail')
				end
			},
			{
				key = 'e',
				mod = {},
				callback = function()
					hs.alert('Messages'); App.launchOrFocus('Messages')
				end
			},
			{
				key = 's',
				mod = {},
				callback = function()
					hs.alert('Slack'); App.launchOrFocus('Slack')
				end
			},
			{
				key = 'f',
				mod = {},
				callback = function()
					hs.alert('Finder'); App.launchOrFocus('Finder')
				end
			},
			{
				key = 'd',
				mod = {},
				callback = function()
					hs.alert('Dashlane'); App.launchOrFocus('Dashlane')
				end
			},
		},
	},
	{
		-- Hammerspoon
		alias = 'Hammerspoon',
		key = 'h',
		mod = {},
		hotkeys = {
			{
				key = 'r',
				mod = {},
				callback = function()
					hs.reload()
				end
			},
			{
				key = 'c',
				mod = {},
				callback = function() hs.toggleConsole() end
			}
		}
	}
}

setupModes(modes)

local dropbox = require('dropbox')
dropbox:new():start()

local mc = require('monitorcontrol')
mc:new():start()
