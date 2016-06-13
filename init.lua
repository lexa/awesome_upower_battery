--------------------------------------------
-- Author: Aleksey Fedotov <lexa at cfotr.com>
-- Copyright 2016
--------------------------------------------

local setmetatable = setmetatable
local type = type
local capi = {
   mouse = mouse,
}
local lgi = require 'lgi'
local UP = lgi.require('UPowerGlib')
local os = require ('os')
local pairs = pairs
local tostring = tostring
local naughty = require ('naughty')
local awful = require ('awful')
local beautiful = require ('beautiful')
local wibox = require('wibox')
local lib = {
   markup = require('obvious.lib.markup')
}
local widget = wibox.widget.textbox()

module('upower_battery')
local status = {
  [6] = 'pend. dischrg',
  [5] = 'pend. chrg',
  [4] = '↯',
  [3] = '_',
  [2] = '▼',
  [1] = '▲',
  [0] = '⌁'
}

local display_device;

local warning_level_colors = {
  [6] = '#FF0000',
  [5] = '#FF0000',
  [4] = '#F00000',
  [3] = '#F0F000',
  [2] = '#00F000',
  [1] = '#F0F0F0',
  [0] = '#F0F0F0'
}

-- Returns a color according to current warning level
--
-- Warning level is set by upower and depends on charge level and time left to
-- emptying a battery
local function get_color(device)
   return warning_level_colors[device.warning_level]
end


-- Convert time from minutes into human readable value
local function format_time(time_in_minutes)
   if (time_in_minutes > 0) then
      return os.date('!%X', time_in_minutes)
   else
      return "N/A"
   end
end

local function update_widget (device)
   display_device = device
   msg = status[device.state] .. ' ' .. device.percentage .. '%'
   color = get_color(device)
   widget:set_markup(lib.markup.fg.color(color, msg));
end

local function init()
   client=UP.Client()
   display_device=client:get_display_device()
   update_widget(display_device)
   display_device.on_notify = update_widget
end

local function is_charging()
   return display_device.state == UP.DeviceState.CHARGING
end

-- Show notifification with extra information
local function show_detail()
   local text = ''
   if (is_charging()) then
      text = text .. 'Time to full ' .. format_time(display_device.time_to_full) .. '\n'
   else
      text = text .. 'Remaining time ' .. format_time(display_device.time_to_empty) .. '\n'
   end

   text = text .. 'Energy ' .. tostring(display_device.energy) .. '/' .. tostring(display_device.energy_full) .. ' Wh\n'
   text = text .. 'Energy rate ' .. tostring(display_device.energy_rate) .. ' W'
   naughty.notify({
         text = text,
         screen = capi.mouse.screen
   })
end

widget:buttons(awful.util.table.join(
                  awful.button({ }, 1, show_detail)
))

setmetatable(_M, { __call = function ()
                      init()
                      return widget
end })
