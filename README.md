# hyprtoolkit-lua
Hyprtoolkit Lua bindings


## Dependencies
- hyprland
- hyprtoolkit
- lua
- cmake

## Quickstart

### Build from source

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
```

# Run example
```bash
./build/hyprtoolkit-lua examples/simple_form.lua
 ./build/hyprtoolkit-lua examples/win11_theme.lua
 ./build/hyprtoolkit-lua examples/image_viewer.lua /path/to/image.png
```
