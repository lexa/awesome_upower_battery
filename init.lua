--------------------------------------------
-- Author: Aleksey Fedotov <lexa at cfotr.com>
-- Copyright 2016
--------------------------------------------

local setmetatable = setmetatable
local type = type
local capi = {
   mouse = mouse,
   dbus = dbus,
}
local luadbus = require ('lua-dbus')
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

--DisplayDevice require upower 0.99
local function update_widget (device)
   device_data = device
   msg = status[device['State']] .. ' ' .. device['Percentage'] .. '%'
   color = get_color(device['Percentage'], device['State'] == 4)
   widget:set_markup(lib.markup.fg.color(color, msg));
end

-- Get current battery status
local function request_battery_status ()
   luadbus.call('GetAll', update_widget, {
                   bus = 'system',
                   path = '/org/freedesktop/UPower/devices/DisplayDevice',
                   interface = 'org.freedesktop.DBus.Properties',
                   destination = 'org.freedesktop.UPower',
                   args = { 's', 'org.freedesktop.UPower.Device' }
   })
end

local function init()
   capi.dbus.add_match('system',
                       "type='signal',interface='org.freedesktop.DBus.Properties',path='/org/freedesktop/UPower/devices/DisplayDevice'")
   capi.dbus.connect_signal('org.freedesktop.DBus.Properties',
                            function (_, _, rest) update_widget(rest) end)

   request_battery_status();
end

local function is_charging()
   return device_data['State'] == 1
end

-- Show notifification with extra information
local function show_detail()
   local text = ''
   if (is_charging()) then
      text = text .. 'Time to full ' .. format_time(device_data['TimeToFull']) .. '\n'
   else
      text = text .. 'Remaining time ' .. format_time(device_data['TimeToEmpty']) .. '\n'
   end

   text = text .. 'Energy ' .. tostring(device_data['Energy']) .. '/' .. tostring(device_data['EnergyFull']) .. ' Wh\n'
   text = text .. 'Energy rate ' .. tostring(device_data['EnergyRate']) .. ' W'
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
