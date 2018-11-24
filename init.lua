--------------------------------------------
-- Author: Aleksey Fedotov <lexa at cfotr.com>
-- Copyright 2016
--------------------------------------------

local setmetatable = setmetatable
local capi = {
   mouse = mouse,
}
local lgi = require ('lgi')
local UP = lgi.require('UPowerGlib')
local naughty = require ('naughty')
local awful = require ('awful')
local beautiful = require ('beautiful')
local wibox = require('wibox')
local math = require('math')

local upower_battery = { mt = {} };

local status_symbols = {
   [UP.DeviceState.PENDING_DISCHARGE] = 'pend. dischrg',
   [UP.DeviceState.PENDING_CHARGE]    = 'pend. chrg',
   [UP.DeviceState.FULLY_CHARGED]     = '↯',
   [UP.DeviceState.EMPTY]             = '_',
   [UP.DeviceState.DISCHARGING]       = '▼',
   [UP.DeviceState.CHARGING]          = '▲',
   [UP.DeviceState.UNKNOWN]           = '⌁'
}

local warning_level_colors = {
   [UP.DeviceLevel.LAST]        = '#FF0000',
   [UP.DeviceLevel.ACTION]      = '#FF0000',
   [UP.DeviceLevel.CRITICAL]    = '#F00000',
   [UP.DeviceLevel.LOW]         = '#F0F000',
   [UP.DeviceLevel.DISCHARGING] = '#00F000',
   [UP.DeviceLevel.NONE]        = (beautiful.fg_normal or '#F0F0F0'),
   [UP.DeviceLevel.UNKNOWN]     = (beautiful.fg_normal or '#F0F0F0'),
}

-- Returns a color according to current warning level
--
-- Warning level is set by upower and depends on charge level and time left to
-- emptying a battery
local function get_color(device)
   return warning_level_colors[device.warning_level]
end

local function format_html(text, color)
   return "<span color='" .. color .. "'>" .. text .. "</span>"
end

local function round(f)
  return math.ceil(f-0.5);
end

local function update_widget (widget, device)
   msg = status_symbols[device.state] .. ' ' .. round(device.percentage) .. '%'
   color = get_color(device)
   widget:set_markup(format_html(msg, color));
end

-- Show notifification with extra information
local function show_detail(device)
  local text = device:to_text()
  naughty.notify({
      text = text,
      title = "Battery status",
      screen = capi.mouse.screen
  })
end

local function new()
   local widget = wibox.widget.textbox()
   local client = UP.Client:new()
   local display_device = client:get_display_device()
   if not display_device.is_present then
     -- try to find any other working device
     for _, d in ipairs(client:get_devices()) do
       if d.is_present then
         display_device=d
         break
       end
     end
     if not display_device.is_present then
       return
     end
   end

   widget:buttons(awful.util.table.join(
                    awful.button({ }, 1, function () show_detail(display_device) end)
   ))

   display_device.on_notify = function (device)
     update_widget(widget, device)
   end
   update_widget(widget, display_device)
   return widget
end

function upower_battery.mt:__call(...)
  return new(...)
end

return setmetatable(upower_battery, upower_battery.mt)
