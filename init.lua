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

-- Returns a color according to current charge percentage
local function get_color(percentage, charging)
   local color = '#F00000'
   if charging and percentage == 100 then
      color = beautiful.fg_normal
   elseif percentage > 35 and percentage < 60 then
      color = '#F0F000'
   elseif percentage >= 40 then
      color = '#00F000'
   end
   return color;
end

local device_data;

-- Convert time from minutes into human readable value
local function format_time(time_in_minutes)
   if (time_in_minutes > 0) then
      return os.date('!%X', time_in_minutes)
   else
      return "N/A"
   end
end

local function update_widget (device)
   device_data = device
   msg = status[device.state] .. ' ' .. device.percentage .. '%'
   color = get_color(device.percentage, device.state == 4)
   widget:set_markup(lib.markup.fg.color(color, msg));
end

local function init()
   client=UP.Client()
   display_device=client:get_display_device()
   update_widget(display_device)
   display_device.on_notify = update_widget
end

local function is_charging()
   return device_data.state == 1
end

-- Show notifification with extra information
local function show_detail()
   local text = ''
   if (is_charging()) then
      text = text .. 'Time to full ' .. format_time(device_data.time_to_full) .. '\n'
   else
      text = text .. 'Remaining time ' .. format_time(device_data.time_to_empty) .. '\n'
   end

   text = text .. 'Energy ' .. tostring(device_data.energy) .. '/' .. tostring(device_data.energy_full) .. ' Wh\n'
   text = text .. 'Energy rate ' .. tostring(device_data.energy_rate) .. ' W'
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
