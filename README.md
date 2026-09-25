# hyprtoolkit-lua

Build native Wayland apps for Hyprland in Lua.

hyprtoolkit-lua gives Lua 5.4 scripts the full widget set of
[Hyprtoolkit](https://github.com/hyprwm/hyprtoolkit): windows, layer-shell
surfaces, layouts, buttons, text inputs, sliders, images, animations, and the
system theme. There are no C++ build steps for your app. Write a `.lua` file
and run it.

```lua
local htk = require("hyprtoolkit")

local backend = htk.Backend.create()
local palette = backend:getPalette()

local window = htk.WindowBuilder.begin()
    :appTitle("Hello, Hyprland")
    :appClass("hello-htk")
    :preferredSize(htk.Vector2D.new(360, 180))
    :commence()

local background = htk.RectangleBuilder.begin()
    :color(function() return palette.background end)
    :size(htk.DynamicSize.percent(1, 1))
    :commence()
window.rootElement:addChild(background)

local column = htk.ColumnLayoutBuilder.begin()
    :gap(12)
    :size(htk.DynamicSize.mixed(htk.SizeType.PERCENT, htk.SizeType.AUTO, 1, 1))
    :commence()
column:setMargin(24)
background:addChild(column)

local label = htk.TextBuilder.begin():text("Nothing clicked yet"):commence()
column:addChild(label)

local clicks = 0
column:addChild(htk.ButtonBuilder.begin()
    :label("Click me")
    :onMainClick(function()
        clicks = clicks + 1
        label:setText(("Clicked %d time%s"):format(clicks, clicks == 1 and "" or "s"))
    end)
    :commence())

local onClose = window:onCloseRequest(function()
    window:close()
    backend:destroy()
end)

window:open()
backend:enterLoop()
```

```bash
hyprtoolkit-lua hello.lua
```

## Contents

- [Installing](#installing)
- [How an app is put together](#how-an-app-is-put-together)
- [Layout and sizing](#layout-and-sizing)
- [Handling input](#handling-input)
- [Theming](#theming)
- [Animations](#animations)
- [Timers and the event loop](#timers-and-the-event-loop)
- [Bars, overlays, and popups](#bars-overlays-and-popups)
- [Lua-specific behavior](#lua-specific-behavior)
- [Embedding in a C++ application](#embedding-in-a-c-application)
- [Examples](#examples)
- [Contributing](#contributing)

## Installing

You need:

- A Wayland compositor. Hyprland is the one this is tested on.
- Lua 5.4.
- CMake 3.19+ and a C++23 compiler.
- Hyprtoolkit built from its `main` branch.

That last point matters. hyprtoolkit-lua tracks Hyprtoolkit's development
branch, and tagged releases such as `v0.6.0` are missing APIs it uses. If
configuration stops with "requires Hyprtoolkit's development branch", CMake
found a release build instead of a `main` build.

From this repository, build Hyprtoolkit from `main` into `$HOME/.local`.
If you already have a `main` checkout, use its path in place of
`../hyprtoolkit-source`. These commands work in Fish and Bash:

```bash
git clone --branch main https://github.com/hyprwm/hyprtoolkit ../hyprtoolkit-source
cmake -S ../hyprtoolkit-source -B ../hyprtoolkit-source/build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build ../hyprtoolkit-source/build --parallel 4
cmake --install ../hyprtoolkit-source/build
```

Check that pkg-config sees the local installation. This command should print
`$HOME/.local/lib`, expanded to your home directory:

```bash
env PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig" pkg-config --variable=libdir hyprtoolkit
```

Then build and install hyprtoolkit-lua against it. The first configure fetches
[sol2](https://github.com/ThePhD/sol2), so it needs network access. Use a new
build directory if you previously configured against another Hyprtoolkit
installation; CMake caches the pkg-config paths.

```bash
env PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig" cmake -S . -B build-local -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build build-local --parallel 4
cmake --install build-local
```

This installs the `hyprtoolkit-lua` runner, the `libhyprtoolkit-lua` library,
its headers (plus the sol2 headers they use), and a `hyprtoolkit-lua.pc` file.
The installed runner looks for both shared libraries in `$HOME/.local/lib`.
`PKG_CONFIG_PATH` selects the library at build time; it does not configure the
runtime loader. Verify that both libraries resolve without any `not found`
lines:

```bash
ldd "$HOME/.local/bin/hyprtoolkit-lua" | grep -E 'libhyprtoolkit|not found'
```

If `libhyprtoolkit-lua.so.0` is still `not found`, rebuild and reinstall this
checkout to give the runner its library search path. If `libhyprtoolkit.so`
is `not found`, install the matching Hyprtoolkit `main` build into the same
prefix, then rebuild hyprtoolkit-lua against it. Do not link a different
Hyprtoolkit shared-library version under the missing name.

If `hyprtoolkit-lua` is not on your `PATH`, add `$HOME/.local/bin`. In Fish,
run `fish_add_path "$HOME/.local/bin"`.

The runner passes extra command-line arguments to your script through the
standard `arg` table:

```bash
hyprtoolkit-lua viewer.lua ~/Pictures/wallpaper.png   # arg[1] is the path
```

## How an app is put together

Every app follows the same shape:

1. Create one `Backend`. It owns the connection to the compositor and the event
   loop. A process can only have one.
2. Build a `Window`, then attach elements to `window.rootElement`.
3. Call `window:open()` and `backend:enterLoop()`. The loop runs until you call
   `backend:destroy()`, usually from `onCloseRequest`.

Everything visible is created with a builder. Call `begin()`, chain setters,
and finish with `commence()` to get the element:

```lua
local button = htk.ButtonBuilder.begin()
    :label("Save")
    :accent(true)
    :commence()
```

To change an element after it exists, call `rebuild()`. It returns a builder
preloaded with the element's current settings, so you only chain what changes.
`commence()` then updates the same element in place:

```lua
button:rebuild():label("Saved"):enabled(false):commence()
```

Common changes also have direct setters, such as `TextElement:setText`,
`ButtonElement:setLabel`, `CheckboxElement:setState`, and
`ProgressBarElement:setValue`.

The available widgets are `Text`, `Button`, `Textbox`, `Checkbox` (and
`RadioGroup`), `Slider`, `Combobox`, `Spinbox`, `ProgressBar`, `Image`,
`Rectangle`, `Line`, `ColumnLayout`, `RowLayout`, `ScrollArea`, and `Null`.
Each has an `XBuilder` and an `XElement` table. The [API reference](docs/API.md)
lists every method.

## Layout and sizing

Elements are nested with `addChild`. `ColumnLayout` stacks children vertically
and `RowLayout` horizontally, both with an optional `gap`. `ScrollArea` clips and
scrolls whatever you put inside it.

Sizes are `DynamicSize` values, and each axis can be absolute pixels, a
fraction of the parent, or automatic:

```lua
htk.DynamicSize.absolute(200, 32)      -- 200 x 32 px
htk.DynamicSize.percent(1, 0.5)        -- full width, half height of the parent
htk.DynamicSize.auto()                 -- as big as the content needs
htk.DynamicSize.mixed(htk.SizeType.PERCENT, htk.SizeType.ABSOLUTE, 1, 40)
```

Pass one to any builder's `size`. A few element methods adjust placement
further:

```lua
element:setMargin(12)                                 -- inner padding
element:setGrow(true)                                 -- take up leftover space in a layout
element:setPositionMode(htk.PositionMode.ABSOLUTE)    -- position inside the parent
element:setPositionFlag(htk.PositionFlag.CENTER, true)
```

## Handling input

Widget-level events are set on the builder and receive the element as their
first argument:

```lua
local volume = htk.SliderBuilder.begin()
    :min(0):max(100):val(40):snapInt(true)
    :onChanged(function(slider, value)
        print("volume", value)
    end)
    :commence()

local name = htk.TextboxBuilder.begin()
    :placeholder("Your name")
    :onTextEdited(function(textbox, text)
        print("typed", text)
    end)
    :commence()
```

Any element can also receive raw pointer events once you opt in:

```lua
card:setReceivesMouse(true)
card:setMouseEnter(function(position) card:setOpacity(1) end)
card:setMouseLeave(function() card:setOpacity(0.7) end)
card:setMouseButton(function(button, pressed)
    if button == htk.MouseButton.RIGHT and pressed then openMenu() end
end)
```

Window and backend events work a little differently. They return a
`SignalConnection`, and the callback only stays registered while you hold on
to that object. Store it somewhere that lives as long as the window:

```lua
local connections = {}

connections.key = window:onKeyboardKey(function(event)
    if event.down and event:hasModifier(htk.KeyboardModifier.CTRL) and event.xkbKeysym == 0x71 then -- XKB_KEY_q
        window:close()
        backend:destroy()
    end
end)

-- connections.key:disconnect() stops it early.
```

If a local connection goes out of scope, the garbage collector disconnects it
and the handler silently stops firing.

## Theming

`backend:getPalette()` returns the user's Hyprtoolkit theme: colors such as
`background`, `text`, `base`, `alternateBase`, `accent`, and
`accentSecondary`, plus font sizes, font families, and corner roundings.

Anywhere a builder takes a color, you can pass a fixed `Color` or a function
that returns one. The toolkit calls color functions again whenever the theme
reloads, so reading from the palette keeps your app in step with the user's
theme:

```lua
local palette = backend:getPalette()

htk.RectangleBuilder.begin()
    :color(function() return palette.base end)
    :borderColor(htk.Color.fromHex(0xFF3B82F6))
    :borderThickness(1)
    :rounding(palette.smallRounding)
    :commence()
```

`Color` supports `brighten`, `darken`, `mix`, and arithmetic, and borders can
take a `Gradient`:

```lua
:borderGradient(htk.Gradient.new({ palette.accent, palette.accentSecondary }, 45))
```

## Animations

Animations are policies you install on an element. After that, changes to the
animated property transition smoothly instead of jumping:

```lua
title:animateOpacity(htk.AnimationPresets.Fast)
title:setOpacity(0.4)                  -- fades

panel:animateColor(htk.BezierAnimation.new({ durationMs = 150 }))
panel:rebuild():color(htk.Color.new(0.1, 0.1, 0.15)):commence()   -- cross-fades

sidebar:animateGeometry(htk.AnimationPresets.Bouncy)              -- layout moves spring
```

Available policies are `animateOpacity` and `animateGeometry` on any element,
`animateColor` on text and rectangles, and `animateBorderColor` on rectangles.

The presets are springs named `Slow`, `Medium`, `Fast`, `Snappy`, and `Bouncy`.
You can also tune your own:

```lua
local wobbly = htk.SpringAnimation.new({ stiffness = 300, damping = 10 })
local ease = htk.BezierAnimation.new({
    durationMs = 250,
    control1 = htk.Vector2D.new(0.4, 0),
    control2 = htk.Vector2D.new(0.2, 1),
})
```

To turn a policy off again, pass `htk.NoAnimation.new()`.

## Timers and the event loop

Your script runs once to set things up. After `enterLoop()`, everything happens
in callbacks, so use the backend for anything time-based:

```lua
backend:addTimer(1000, function(timer)
    clock:setText(os.date("%H:%M:%S"))
end)

backend:addIdle(function()
    -- runs once, after pending events are handled
end)

backend:addFd(fd, function()
    -- the file descriptor is readable
end)
```

A timer fires once. To repeat, add a new timer from inside the callback. Keep
the returned `Timer` if you want to `cancel()` it.

## Bars, overlays, and popups

Set a window's `type` to make something other than a regular app window.
Layer-shell surfaces are what status bars, docks, and notifications use:

```lua
local bar = htk.WindowBuilder.begin()
    :type(htk.WindowType.LAYER)
    :layer(htk.Layer.TOP)
    :anchor(htk.LayerAnchor.TOP | htk.LayerAnchor.LEFT | htk.LayerAnchor.RIGHT)
    :exclusiveZone(32)
    :preferredSize(htk.Vector2D.new(0, 32))
    :commence()
```

`htk.WindowType.POPUP` creates a popup relative to a `parent` window and `pos`.
`htk.WindowType.LOCK_SURFACE` builds lock screens after
`backend:acquireSessionLock()`; see `examples/session_lock.lua`.

## Lua-specific behavior

A few things differ from the C++ API so that they feel natural in Lua:

- **Indices are 1-based.** Combobox and spinbox items count from 1 in builders,
  getters, setters, and `onChanged` callbacks.
- **Errors in callbacks don't crash your app.** They are printed to stderr with
  the name of the callback, such as `ButtonBuilder.onMainClick`, and the app
  keeps running. Errors in top-level script code stop the script as usual.
- **No globals.** Everything lives in the table returned by
  `require("hyprtoolkit")`.
- **Text positions are byte offsets.** `TextboxElement:cursorPos()` and
  `selection()` return UTF-8 byte offsets, not character counts.

## Embedding in a C++ application

The library can host Lua UI code inside your own program. Link against
`hyprtoolkit-lua` through pkg-config and either create a ready-made state or add
the module to one you already have:

```cpp
#include <hyprtoolkit-lua/LuaBindings.hpp>

auto state = Hyprtoolkit::Lua::createLuaState(); // standard libs + require("hyprtoolkit")
state->doFile("ui.lua");

// Or, for an existing sol::state with the package library open:
Hyprtoolkit::Lua::registerAllBindings(myLuaState);
```

## Examples

The `examples/` directory has complete apps. Run them from a Hyprland session:

| Example | Shows |
| --- | --- |
| `simple_form.lua` | Text inputs, validation, and buttons in a form |
| `latest_controls.lua` | Every control: radio groups, combobox, spinbox, progress bars, password fields |
| `win11_theme.lua` | A larger Fluent-style settings app with custom theming |
| `image_viewer.lua` | Loading and fitting images; takes an image path argument |
| `session_lock.lua` | A lock screen on every output |

```bash
hyprtoolkit-lua examples/latest_controls.lua
hyprtoolkit-lua examples/image_viewer.lua ~/Pictures/photo.png
```

`session_lock.lua` really locks your session, so only run it when you mean to.

## Contributing

Build in debug mode and run the tests:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j"$(nproc)"
ctest --test-dir build --output-on-failure
```

The default test is headless and checks the whole Lua API surface. Tests that
open real windows need a Wayland session and are opt-in:

```bash
cmake -S . -B build -DHYPRTOOLKIT_LUA_ENABLE_GUI_TESTS=ON
ctest --test-dir build -L gui --output-on-failure
```

[docs/API.md](docs/API.md) is the complete API reference and records which
parts of Hyprtoolkit are deliberately left out.
