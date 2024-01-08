--- Opens LinearMouse.app if a Basilisk mouse is detected. Closes it if not.
--- @class LinearMouse
--- @field lm hs.application? Instance of LnearMouse.app
--- @field watcher hs.usb.watcher? The Hammerspoon USB watcher.

local module = {}
module.linearmouse = nil

function module:new()
	local instance = {}
	setmetatable(instance, self)
	self.__index = self

	return instance
end

function module:start()
	if (module:checkForBasilisk()) then
		self:startLinearMouse()
	else
		self:stopLinearMouse()
	end

	self.watcher = hs.usb.watcher.new(self.handler):start()
	return self
end

function module.handler(event)
	local name = event.productName
	local eventType = event.eventType

	if string.find(name, 'Basilisk') == nil then
		return
	end

	if (eventType == 'added') then
		module:startLinearMouse()
	end

	if (eventType == 'removed') then
		module:stopLinearMouse()
	end
end

function module:checkForBasilisk()
	local devices = hs.usb.attachedDevices()

	if not devices then
		return false
	end

	local attached = false

	for _, device in ipairs(devices) do
		if device.productName and string.find(device.productName, 'Basilisk') then
			attached = true
			break
		end
	end

	return attached
end

function module:startLinearMouse()
	self.linearmouse = hs.application.open('LinearMouse')
	self.linearmouse:hide()

	return self
end

function module:stopLinearMouse()
	local lm = self.linearmouse or hs.application.get('LinearMouse')

	if not lm then
		self.linearmouse = nil
		return self
	end

	if lm.kill then
		lm:kill()
	end

	self.linearmouse = nil

	return self
end

return module
