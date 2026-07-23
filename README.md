# hyprtoolkit-lua

C++23 Lua 5.4 bindings for Hyprtoolkit.

Version 0.2 is a breaking API refresh for Hyprtoolkit commit
`67d9012d7d3a902a6a37e313fbfaf56ce7d3c53e`. The released Hyprtoolkit
`v0.5.4` tag is not compatible: the tag and current `main` report the same
package version while exposing different public APIs, so CMake probes for the
required current-main symbols.

## Lua module

Load the namespaced module:

```lua
local htk = require("hyprtoolkit")

print(htk.VERSION)              -- 0.2.0
print(htk.UPSTREAM_API_COMMIT)  -- 67d9012d...

local backend = htk.Backend.create()
local window = htk.WindowBuilder.begin()
    :appTitle("Hello from Lua")
    :preferredSize(htk.Vector2D.new(480, 320))
    :resizable(true)
    :commence()
```

The binding does not create a global `hyprtoolkit` table or C++-prefixed
globals. Repeated `require("hyprtoolkit")` calls return the same module.

Combobox and spinbox item indices are `1..n` everywhere in Lua, including
builder defaults, getters, setters, and callbacks. Textbox cursor and selection
positions remain UTF-8 byte offsets, matching upstream.

Signal methods return a `SignalConnection`. Retain it for as long as the
callback should remain active:

```lua
local connections = {}

connections[#connections + 1] = window:onCloseRequest(function()
    window:close()
    backend:destroy()
end)

-- Optional early disconnect:
connections[1]:disconnect()
```

See [the API matrix](docs/API.md) for the complete surface and intentional
exclusions.

## Requirements

- Hyprtoolkit commit `67d9012d7d3a902a6a37e313fbfaf56ce7d3c53e`
- Lua 5.4 exactly
- CMake 3.19 or newer
- A C++23 compiler
- Hyprtoolkit's public pkg-config dependencies

Sol2 is fetched at pinned commit
`c1f95a773c6f8f4fde8ca3efe872e7286afe4444`.

## Build

Make the exact upstream build visible through `pkg-config`, then configure:

```bash
export PKG_CONFIG_PATH=/path/to/hyprtoolkit-prefix/lib/pkgconfig

cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j"$(nproc)"
ctest --test-dir build --output-on-failure
```

To opt into the real Wayland GUI smoke test:

```bash
cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Debug \
    -DHYPRTOOLKIT_LUA_ENABLE_GUI_TESTS=ON
cmake --build build -j"$(nproc)"
ctest --test-dir build -R gui-smoke --output-on-failure
```

## Examples

Run examples from an active Hyprland session:

```bash
./build/hyprtoolkit-lua examples/simple_form.lua
./build/hyprtoolkit-lua examples/latest_controls.lua
./build/hyprtoolkit-lua examples/win11_theme.lua
./build/hyprtoolkit-lua examples/image_viewer.lua /path/to/image.png
```

`examples/session_lock.lua` acquires the compositor session lock and creates a
lock surface per output. It takes over the graphical session, so run it only
when you intentionally want to test locking:

```bash
./build/hyprtoolkit-lua examples/session_lock.lua
```
