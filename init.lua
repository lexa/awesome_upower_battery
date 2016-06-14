--------------------------------------------
-- Author: Aleksey Fedotov <lexa at cfotr.com>
-- Copyright 2016
--------------------------------------------

local setmetatable = setmetatable
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
local status_symbols = {
   [UP.DeviceState.PENDING_DISCHARGE] = 'pend. dischrg',
   [UP.DeviceState.PENDING_CHARGE]    = 'pend. chrg',
   [UP.DeviceState.FULLY_CHARGED]     = '↯',
   [UP.DeviceState.EMPTY]             = '_',
   [UP.DeviceState.DISCHARGING]       = '▼',
   [UP.DeviceState.CHARGING]          = '▲',
   [UP.DeviceState.UNKNOWN]           = '⌁'
}

local display_device;

local warning_level_colors = {
   [UP.DeviceLevel.LAST]        = '#FF0000',
   [UP.DeviceLevel.ACTION]      = '#FF0000',
   [UP.DeviceLevel.CRITICAL]    = '#F00000',
   [UP.DeviceLevel.LOW]         = '#F0F000',
   [UP.DeviceLevel.DISCHARGING] = '#00F000',
   [UP.DeviceLevel.NONE]        = '#F0F0F0',
   [UP.DeviceLevel.UNKNOWN]     = '#F0F0F0'
}

-- Returns a color according to current warning level
--
-- Warning level is set by upower and depends on charge level and time left to
-- emptying a battery
local function get_color(device)
   return warning_level_colors[device.warning_level]
end

local function update_widget (device)
   display_device = device
   msg = status_symbols[device.state] .. ' ' .. device.percentage .. '%'
   color = get_color(device)
   widget:set_markup(lib.markup.fg.color(color, msg));
end

local function init()
   client=UP.Client()
   display_device=client:get_display_device()
   update_widget(display_device)
   display_device.on_notify = update_widget
end

-- Show notifification with extra information
local function show_detail()
   local text = display_device:to_text()
   naughty.notify({
         text = text,
         title = "Battery status",
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
