# Upower based battery widget for Awesome WM #

This is a text widget for displaying battery status. What distinguish it from
myriads of other like it, is the usage of upower-glib for acquiring battery
status. Upower is a system daemon for managing power supply status, it installed
by default on most modern Linux systems.

## Unique features ##

Most other battery widgets use external applications to get battery status. They
poll acpid/powerstatus/etc and parse their output, that is terribly inefficient.
This widget provides a event based approach based on dbus signals from upowerd.
This means:

1. No polling. Since widget utilizes a dbus signaling interface for getting
   notifications of power supply changes, there is no need in polling battery
   status. That reduces number of wakeups and overall CPU load and battery
   consumption.

2. No WM freezes. This widget doesn't use blocking calls to external applications,
   so there is no way it will freeze your WM.

## Requirements ##

- [AwesomeWM-3.5.6](https://awesomewm.org) with dbus support enabled
- [upower-0.99](https://upower.freedesktop.org/)

## Installation ##

 This package could be installed by cloning git repository into ~/.config/awesome/upower_battery

```
 git clone https://github.com/lexa/awesome_upower_battery ~/.config/awesome/upower_battery
```

 Then add following snippet into your rc.lua:

```
 local battery = require("upower_battery");
 mybattery = battery();
```

 the only thing left is to add widget into your layout, for example if you want to see it in your right layout:

```
 right_layout:add(mykeyboardlayout)
```

 After AweseomeWM restart, widget will appear.

## Usage ##
 Widget shows current battery charge and a symbolic indicator of current battery state
 - ↯ - on AC and fully charged
 - _ - battery is empty
 - ▼ - discharging
 - ▲ - charging
 - ⌁ - state unknown

 By clicking on widget you will get a more verbose status information about battery status.

## Troubleshooting ##
 If you experienced any malfunction, feel free to create a bug report at https://github.com/lexa/awesome_upower_battery/issues. Please include output of 'upower -d' into bug report.
