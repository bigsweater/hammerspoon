hs.loadSpoon('EmmyLua')

local dropbox = require('dropbox')
dropbox:new():start()

local mc = require('monitorcontrol')
mc:new():start()
