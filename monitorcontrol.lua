--- Closes MonitorControl.app if only a single monitor is detected; opens it otherwise.
---@class MonitorControl
---@field mc hs.application? Instance of MonitorControl.app (or nil if we stop it)
---@field watcher hs.screen.watcher? The Hammerspoon Screen Watcher.
local module = {}
module.mc = nil
module.watcher = nil

function module:new()
	local instance = {}
	setmetatable(instance, self)
	self.__index = self

	return instance
end

function module:start()
	self.handler()
	self.watcher = hs.screen.watcher.new(self.handler):start()
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
	self.mc = hs.application.open('MonitorControl', 0, true)
	self.mc:hide()

	return self
end

function module:stopMonitorControl()
	local mc = self.mc or hs.application.get('MonitorControl')

	if not mc then
		self.mc = nil
		return self
	end

	if mc.kill then
		mc:kill()
	end

	self.mc = nil

	return self
end

return module
