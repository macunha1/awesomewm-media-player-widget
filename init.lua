local awful       = require("awful")
local beautiful   = require("beautiful")
local helpers     = require("lain.helpers")
local proxy       = require("dbus_proxy")
local wibox       = require("wibox")

local MediaPlayer = {}

function MediaPlayer:new(args)
	return setmetatable({}, {__index = self}):init(args)
end

function MediaPlayer:init(args)
	self.icons  = args.icons      or {
		play    = args.play_icon  or beautiful.play,
		pause   = args.pause_icon or beautiful.pause
	}
	self.font   = args.font       or beautiful.font
	
	self.widget = wibox.widget {
		{
			id = "icon",
			widget = wibox.widget.imagebox,
		},
		{
			id = 'current_song',
			widget = wibox.widget.textbox,
			font = self.font
		},
		layout = wibox.layout.fixed.horizontal,
		set_status = function(self, image)
			self.icon.image = image
		end,
		set_text = function(self, text)
			self.current_song.markup = text
		end,
	}

	self.dbus = proxy.monitored.new({
		bus       = proxy.Bus.SESSION,
		name      = "org.mpris.MediaPlayer2." .. args.name or "spotify",
		path      = "/org/mpris/MediaPlayer2",
		interface = "org.mpris.MediaPlayer2.Player"
	})

	-- Higher refresh_rate == less CPU requirements
	-- Lower refresh_rate == better Widget response time
	self:watch(args.refresh_rate or 3)
	self:signal()

	return self
end

function MediaPlayer:escape_xml(str)
	str = string.gsub(str, "&", "&amp;")
	str = string.gsub(str, "<", "&lt;")
	str = string.gsub(str, ">", "&gt;")
	str = string.gsub(str, "'", "&apos;")
	str = string.gsub(str, '"', "&quot;")

	return str
end

function MediaPlayer:update_widget_icon(output)
	output = string.gsub(output, "\n", "")
	self.widget:set_status(
		(output == 'Playing') and self.icons.play or self.icons.pause
	)
end

function MediaPlayer:update_widget_text(output)
	self.widget:set_text(self:escape_xml(output))
	self.widget:set_visible(true)
end

function MediaPlayer:hide_widget()
	self.widget:set_text('Media Player | Offline')
	self.widget:set_visible(false)
end

function MediaPlayer:info()
  if not self.dbus.is_connected then
	return {}
  end

  local metadata = self.dbus:Get(self.dbus.interface, "Metadata")
  local status   = self.dbus:Get(self.dbus.interface, "PlaybackStatus")

  local artists = metadata["xesam:artist"]
  if type(artists) == "table" then
	artists = table.concat(artists, ", ")
  end

  local info = {
	album = metadata["xesam:album"],
	title = metadata["xesam:title"],
	artists = artists,
	status = status
  }

  return info
end

function MediaPlayer:watch(refresh_rate)
	local update_widget = function()
		local info = self:info()
		if not info["status"] then
			self:hide_widget()
		else
			self:update_widget_icon(info["status"])
			self:update_widget_text(
				string.format(
					"%s | %s",
					info.artists,
					info.title
				)
			)
		end
	end

	helpers.newtimer("media-player", refresh_rate, update_widget)
end

function MediaPlayer:exec(command, callback)
	local spawn_update = function()
		awful.spawn.easy_async(
			function() self:info() end,
			function(info)
				self:update_widget_icon(info["status"])
		end)
	end

	awful.spawn.easy_async(command, callback or spawn_update)
end

function MediaPlayer:signal()
	--- Adds the following mouse actions:
	--  - button 1: left click  - play/pause
	--  - button 4: scroll up   - next song
	--  - button 5: scroll down - previous song
	
	self.widget:buttons(awful.util.table.join(
		awful.button({}, 1, function() self:exec("playerctl play-pause", _) end),
		awful.button({}, 4, function() self:exec("playerctl next", _) end),
		awful.button({}, 5, function() self:exec("playerctl previous", _) end)
	))
end

return setmetatable(MediaPlayer, { __call = MediaPlayer.new, })
