--- Closes MonitorControl.app if only a single monitor is detected; opens it otherwise.
---@class MonitorControl
---@field mc hs.application? Instance of MonitorControl.app (or nil if we stop it)
---@field watcher hs.screen.watcher? The Hammerspoon Screen Watcher.
local module = {}
module.mc = nil
module.watcher = nil

local logger = hs.logger.new('monitorcontrol', 'info')

function module:new()
	local instance = {}
	setmetatable(instance, self)
	self.__index = self

	return instance
end

function module:start()
	self.watcher = hs.screen.watcher.new(self.handler):start()
	self.handler()

	return self
end

function module.handler()
	local multipleMonitors = #hs.screen.allScreens() > 1

	if multipleMonitors then
		module:startMonitorControl()
	else
		module:stopMonitorControl()
	end
end

function module:startMonitorControl()
	logger.i('Starting MonitorControl...')

	self.mc = hs.application.open('MonitorControl', 0, true)
	self.mc:hide()

	logger.i('MonitorControl started.')

	return self
end

function module:stopMonitorControl()
	logger.i('Stopping MonitorControl...')

	local mc = self.mc or hs.application.get('MonitorControl')

	if not mc then
		logger.i('MonitorControl not running.')

		self.mc = nil
		return self
	end

	if mc.kill then
		mc:kill()
	end

	self.mc = nil

	logger.i('MonitorControl stopped.')

	return self
end

return module
