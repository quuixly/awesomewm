-- If LuaRocks is installed, load it
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
require("awful.hotkeys_popup.keys")

-- Freedesktop menu (Arch uses this)
local has_fdo, freedesktop = pcall(require, "freedesktop")

-- {{{ Error handling
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Startup error",
        text = awesome.startup_errors
    })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        if in_error then return end
        in_error = true

        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Error!",
            text = tostring(err)
        })
        in_error = false
    end)
end
-- }}}

-- {{{ Variables
beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
beautiful.wallpaper = "/home/quuixly/Pictures/mountain.jpg"
beautiful.useless_gap = "10"

terminal = "alacritty"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

modkey = "Mod4"

awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.floating,
    awful.layout.suit.max,
    awful.layout.suit.spiral,
    awful.layout.suit.fair,
}
-- }}}

-- {{{ Menu
local myawesomemenu = {
    { "Hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
    { "Edit config", editor_cmd .. " " .. awesome.conffile },
    { "Restart", awesome.restart },
    { "Quit", function() awesome.quit() end },
}

local menu_awesome = { "Awesome", myawesomemenu, beautiful.awesome_icon }
local menu_terminal = { "Terminal", terminal }

if has_fdo then
    mymainmenu = freedesktop.menu.build({
        before = { menu_awesome },
        after = { menu_terminal }
    })
else
    mymainmenu = awful.menu({
        items = { menu_awesome, menu_terminal }
    })
end

mylauncher = awful.widget.launcher({
    image = beautiful.awesome_icon,
    menu = mymainmenu
})

menubar.utils.terminal = terminal
-- }}}

-- {{{ Widgets
local mykeyboardlayout = awful.widget.keyboardlayout()
local mytextclock = wibox.widget.textclock()

-- Battery widget (plain text)
local battery_widget = wibox.widget {
    {
        id = "txt",
        align = "center",
        valign = "center",
        font = "sans 10",
        widget = wibox.widget.textbox,
    },
    layout = wibox.container.margin(_, 5, 5)
}

local function update_battery()
    local cmd = "upower -i `upower -e | grep BAT` | grep -E 'percentage|state' | awk '{print $2}'"
    awful.spawn.easy_async_with_shell(cmd, function(stdout)
        local lines = {}
        for line in stdout:gmatch('[^\r\n]+') do table.insert(lines, line) end

        local state = lines[1] or ""
        local percent = lines[2] or ""

        if state == "charging" then
            battery_widget.txt.text = "Charging: " .. percent
        elseif state == "fully-charged" then
            battery_widget.txt.text = "Charged: " .. percent
        else
            battery_widget.txt.text = "Battery: " .. percent
        end
    end)
end

gears.timer {
    timeout = 10,
    autostart = true,
    call_now = true,
    callback = update_battery
}

-- }}}

-- {{{ Screen setup
local taglist_buttons = gears.table.join(
    awful.button({}, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end),
    awful.button({}, 3, awful.tag.viewtoggle)
)

local tasklist_buttons = gears.table.join(
    awful.button({}, 1, function(c)
        if c == client.focus then
            c.minimized = true
        else
            c:emit_signal("request::activate", "tasklist", {raise = true})
        end
    end)
)

local function set_wallpaper(s)
    if beautiful.wallpaper then
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end

screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    set_wallpaper(s)

    awful.tag({ "1","2","3","4","5","6","7","8","9" }, s, awful.layout.layouts[1])

    s.mypromptbox = awful.widget.prompt()
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
        awful.button({}, 1, function() awful.layout.inc(1) end),
        awful.button({}, 3, function() awful.layout.inc(-1) end)
    ))

    s.mytaglist = awful.widget.taglist {
        screen = s,
        filter = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    s.mytasklist = awful.widget.tasklist {
        screen = s,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons
    }

    s.mywibox = awful.wibar({ position = "top", screen = s })

    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        {
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
	    s.mytaglist,
            s.mypromptbox,
        },
	nil,
        {
            layout = wibox.layout.fixed.horizontal,
            wibox.widget.systray(),
	    battery_widget,
            mytextclock,
        }
    }
end)
-- }}}

-- {{{ Mouse
root.buttons(gears.table.join(
    awful.button({}, 3, function() mymainmenu:toggle() end)
))
-- }}}

-- {{{ Keybindings
globalkeys = gears.table.join(
    awful.key({ modkey }, "t", function() awful.spawn(terminal) end,
        { description = "Open terminal", group = "launcher" }),

    awful.key({ modkey }, "f", function() awful.spawn("firefox") end,
        { description = "Open Firefox", group = "launcher" }),

    awful.key({ modkey }, "e", function() awful.spawn("nemo") end,
        { description = "Open file manager", group = "launcher" }),

    awful.key({ modkey }, "r", function() awful.screen.focused().mypromptbox:run() end,
        { description = "Run prompt", group = "launcher" }),

    awful.key({ modkey, "Control" }, "r", awesome.restart,
        { description = "Restart Awesome", group = "awesome" }),

    awful.key({ modkey }, "q",
        function()
            if client.focus then
                client.focus:kill()
            end
        end,
        { description = "close focused window", group = "client" }),
	
    awful.key({}, "XF86AudioRaiseVolume",
        function()
            awful.spawn("pamixer --increase 5")
        end,
        { description = "volume up", group = "audio" }),

    awful.key({}, "XF86AudioLowerVolume",
        function()
            awful.spawn("pamixer --decrease 5")
        end,
        { description = "volume down", group = "audio" }),

    awful.key({}, "XF86AudioMute",
        function()
            awful.spawn("pamixer --toggle-mute")
        end,
        { description = "toggle mute", group = "audio" }),

    -- Brightness up
    awful.key({ }, "XF86MonBrightnessUp",
        function()
            awful.spawn("brightnessctl set +5%", false)
        end,
        {description = "brightness up", group = "brightness"}),

    -- Brightness down
    awful.key({ }, "XF86MonBrightnessDown",
        function()
            awful.spawn("brightnessctl set 5%-", false)
        end,
        {description = "brightness down", group = "brightness"}),

    -- Focus windows with Win + Arrow keys
    awful.key({ modkey }, "Left",
        function() awful.client.focus.bydirection("left") end,
        { description = "focus left", group = "client" }),

    awful.key({ modkey }, "Right",
        function() awful.client.focus.bydirection("right") end,
        { description = "focus right", group = "client" }),

    awful.key({ modkey }, "Up",
        function() awful.client.focus.bydirection("up") end,
        { description = "focus up", group = "client" }),

    awful.key({ modkey }, "Down",
        function() awful.client.focus.bydirection("down") end,
        { description = "focus down", group = "client" })



)

root.keys(globalkeys)
-- }}}

-- Windows switching
-- Tag navigation: Mod + number to view tag, Mod+Shift+number to move client
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,

        -- View tag only
        awful.key({ modkey }, "#" .. i + 9,
                  function()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),

        -- Move focused client to tag
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                      end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"})
    )
end

-- reapply the keys
root.keys(globalkeys)


-- {{{ Rules
awful.rules.rules = {
    {
        rule = { },
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen
        }
    }
}
-- }}}

-- {{{ Signals
client.connect_signal("focus", function(c)
    c.border_color = beautiful.border_focus
end)

client.connect_signal("unfocus", function(c)
    c.border_color = beautiful.border_normal
end)
-- }}}

-- Enable touchpad tapping (optional)
awful.spawn.with_shell('xinput set-prop 12 "libinput Tapping Enabled" 1')

