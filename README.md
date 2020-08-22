<h1 align="center">AwesomeWM Media Player Widget</h1>

Pure Lua implementation of a Media Player Widget, supports any media player
complaint with [MPRIS D-Bus MediaPlayer2.Player interface](https://specifications.freedesktop.org/mpris-spec/2.2/Player_Interface.html)

Some examples are: mpd, vlc, audacious, bmp, xmms2, spotify and [mpv with a
plugin](https://github.com/hoyon/mpv-mpris)

<p align="center">
<span><img src="/screenshot.png?raw=true" alt="Media Player Screenshot" /></span>
</p>

## Installation

[Lua D-Bus Proxy](https://github.com/stefano-m/lua-dbus_proxy) handles
connections with D-Bus interface to read data regarding current playing music
and artist to fill the widget. Lua D-Bus proxy is available [at
Luarocks.](https://luarocks.org/modules/stefano-m/dbus_proxy)
Further installation info [available here](https://github.com/stefano-m/lua-dbus_proxy#installation)

Drop the plugin code into your AwesomeWM configuration folder. e.g.:

```bash
[[ -d ~/.config/awesome/plugins ]] || mkdir ~/.config/awesome/plugins
cd ~/.config/awesome/plugins

git clone https://github.com/macunha1/awesomewm-media-player-widget \
    ~/.config/awesome/plugins/media-player
```

In case your AwesomeWM configuration is a git repository, you can add as a
submodule with

``` bash
cd ~/.config/awesome

git submodule add -b master \
    -f --name media-player-widget \
    https://github.com/macunha1/awesomewm-media-player-widget \
    plugins/media-player

git submodule sync --recursive .
```

### Usage

Lastly, import the plugin into your `rc.lua`, configure according to your style
and _keep on Rollin'_:

```lua
-- load the widget code
local media_player = require("plugins.media-player")

-- be free to configure your media player widget:
local spotify_widget = media_player({
    icons  = {
        play   = theme.play,
        pause  = theme.pause
    },
    font         = theme.font,
    name         = "spotify", -- target media player
    refresh_rate = 0.3 -- interval between widget update calls
}).widget

fake.wibar:set {
    layout = wibox.layout.align.horizontal,
    -- ...
    {
        -- ...
        separator,
        media_player_widget,
        -- ...
    }
    -- ...
}
```

By default the widget hides itself when no data regarding a media player is
found through MPRIS D-Bus interface. In case you're planning to inspect many at
the same time, it's possible to create many instances of the widget
(`media_player`) and attach to your wibar.
