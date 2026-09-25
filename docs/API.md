# Lua API

This matrix is audited against Hyprtoolkit's development branch (`main`). All
names live below the table returned by `require("hyprtoolkit")`.

## Module and values

| Type or table | Constructors, members, and methods |
| --- | --- |
| Module | `VERSION`, `UPSTREAM_API_BRANCH` |
| `Vector2D` | `new([x, y])`; read/write `x`, `y`; `floor`, `round`, `clamp`, `distance`; `+`, `-`, `*`, `/`, `==`, string conversion |
| `Box` | `new()`, `new(x, y, w, h)`, `new(pos, size)`; read/write `x`, `y`, `w`, `h`; `pos`, `size`, `middle`, `containsPoint`, `empty`, `intersection`, `expand`, `round`, `translate`, `scale` |
| `Color` | `new()`, `new(r, g, b[, a])`, `fromHex`; read/write `r`, `g`, `b`, `a`; `getAsHex`, `asRGB`, `asHSL`, `asOkLab`, `brighten`, `darken`, `mix`, `stripA`; `+`, `-`, scalar `*`, `==`, string conversion |
| `Gradient` | `new(colors[, angle])`, `solid(color)`; read/write `colors`, `angle`; `==` |
| `DynamicSize` | `new(typeX, typeY, vector)`, `absolute`, `percent`, `auto`, `mixed`; `calculate(elementSize[, grow=true])` |
| `FontSize` | `new(base[, multiplier])`, `h1`, `h2`, `h3`, `text`, `small`, `absolute`; `ptSize` |
| `KeyboardKeyEvent` | read-only callback fields `xkbKeysym`, `down`, `repeat`, `utf8`, `modMask`; `hasModifier` |
| `TouchEvent` | read-only callback fields `id`, `position`, `timeMs` |
| `NoAnimation` | `new()`; `==` |
| `BezierAnimation` | `new([fields])`; read/write `durationMs`, `control1`, `control2`; `==` |
| `SpringAnimation` | `new([fields])`; read/write `stiffness`, `damping`, `mass`, `valueEpsilon`, `velocityEpsilon`; `==` |
| `AnimationPresets` | read-only `Slow`, `Medium`, `Fast`, `Snappy`, `Bouncy` (each a `SpringAnimation`) |
| `Palette` | `palette`, `emptyPalette`; read/write colors `background`, `text`, `base`, `alternateBase`, `brightText`, `linkText`, `accent`, `accentSecondary`; read/write variables `h1Size`, `h2Size`, `h3Size`, `fontSize`, `smallFontSize`, `iconTheme`, `bigRounding`, `smallRounding`, `fontFamily`, `fontFamilyMonospace` |

`Color:asRGB()` returns `{r, g, b}`, `asHSL()` returns `{h, s, l}`, and
`asOkLab()` returns `{l, a, b}`. A `Gradient` or a callback returning one can
be passed anywhere upstream accepts a `gradientFn`.

`TouchEvent.position` is upstream's element-local `local` field, renamed
because `local` is a Lua keyword.

Animation values correspond to upstream's `SAnimation` alternatives.
`BezierAnimation.new` and `SpringAnimation.new` start from upstream's defaults
and accept an optional table of the listed fields, for example
`SpringAnimation.new({ stiffness = 300, damping = 14 })`. Unknown fields and
wrongly typed values raise an error. Each `AnimationPresets` lookup returns a
fresh copy, so modifying one does not change the preset.

## Enums and constants

| Table | Members |
| --- | --- |
| `SizeType` | `ABSOLUTE`, `PERCENT`, `AUTO` |
| `FontSizeBase` | `H1`, `H2`, `H3`, `TEXT`, `SMALL`, `ABSOLUTE` |
| `FontAlignment` | `LEFT`, `CENTER`, `RIGHT` |
| `MouseButton` | `UNKNOWN`, `LEFT`, `RIGHT`, `MIDDLE` |
| `Axis` | `HORIZONTAL`, `VERTICAL` |
| `KeyboardModifier` | `SHIFT`, `CAPS`, `CTRL`, `ALT`, `MOD2`, `MOD3`, `META`, `MOD5`, `CTRL_SHIFT` |
| `LogLevel` | `TRACE`, `DEBUG`, `WARNING`, `ERROR`, `CRITICAL` |
| `SessionLockError` | `PLATFORM_UNINITIALIZED`, `DENIED` |
| `PositionMode` | `ABSOLUTE`, `AUTO` |
| `PositionFlag` | `HCENTER`, `VCENTER`, `CENTER`, `LEFT`, `RIGHT`, `TOP`, `BOTTOM`, `ALL` |
| `PointerShape` | `ARROW`, `POINTER`, `TEXT`, `RESIZE_NS`, `RESIZE_EW`, `RESIZE_NESW`, `RESIZE_NWSE` |
| `ImageFitMode` | `STRETCH`, `COVER`, `CONTAIN`, `TILE` |
| `CheckboxStyle` | `CHECKMARK`, `RADIO` |
| `WindowType` | `TOPLEVEL`, `POPUP`, `LAYER`, `LOCK_SURFACE` |
| `ResizeEdge` | `NONE`, `TOP`, `BOTTOM`, `LEFT`, `TOP_LEFT`, `BOTTOM_LEFT`, `RIGHT`, `TOP_RIGHT`, `BOTTOM_RIGHT` |
| `Layer` | `BACKGROUND`, `BOTTOM`, `TOP`, `OVERLAY` |
| `LayerAnchor` | `NONE`, `TOP`, `BOTTOM`, `LEFT`, `RIGHT`; combine flags numerically when needed |
| `KeyboardInteractivity` | `NONE`, `EXCLUSIVE`, `ON_DEMAND` |

## Core

| Type | Methods |
| --- | --- |
| `Backend` | `create`, `destroy`, `enterLoop`, `getPalette`, `getOutputs`, `systemIcons`, `setLogCallback`, `addTimer(timeoutMs, callback[, force=false])`, `addIdle`, `addFd`, `removeFd`, `acquireSessionLock`, `onOutputAdded` |
| `Timer` | `cancel`, `passed`, `canForceUpdate`, `leftMs`, `cancelled`, `updateTimeout` |
| `Output` | `handle`, `port`, `desc`, `fps`, `onRemoved` |
| `SessionLockState` | `unlock`, `onFinished` |
| `SystemIconFactory` | `lookupIcon` |
| `SystemIconDescription` | `exists`, `scalable` |
| `SignalConnection` | `connected`, `disconnect` |

`Backend:acquireSessionLock()` returns `lockState, nil` on success and
`nil, SessionLockError` on failure. `onOutputAdded`, `Output:onRemoved`,
`SessionLockState:onFinished`, and all window event methods return a
`SignalConnection`; retain the connection in Lua.

## Elements

Every concrete element inherits:

`size`, `posFromParent`, `reposition(box[, maxSize])`, `forceReposition`,
`setPositionMode`, `setPositionFlag`, `setAbsolutePosition`, `addChild`,
`removeChild`, `clearChildren`, `setMargin`, `setGrouped`, `setTooltip`,
`setGrow(x[, y])`, `setReceivesMouse`, `setMouseEnter`, `setMouseLeave`,
`setMouseMove`, `setMouseButton`, `setMouseAxis`, `setReceivesTouch`,
`setTouchDown`, `setTouchMotion`, `setTouchUp`, `setTouchCancel`,
`setRepositioned`, `setOpacity`, `animateOpacity`, and `animateGeometry`.

`animateOpacity`, `animateGeometry`, and the element-specific `animateColor` /
`animateBorderColor` methods take a `NoAnimation`, `BezierAnimation`, or
`SpringAnimation`. They install a persistent policy: later property or layout
changes animate, and passing `NoAnimation.new()` removes the policy. Geometry
animation is presentation-only; layout and input use the final coordinates
immediately.

Touch callbacks receive a `TouchEvent`. Upstream currently delivers touch input
only through embedded surfaces, so these callbacks do not fire in windows
created by the native Wayland backend.

Color-taking builder methods accept a `Color` or a callback returning one.
`RectangleBuilder:borderGradient` accepts a `Gradient`, a `Color` (solid
gradient), or a callback returning either.

| Builder | Builder methods after `begin()` | Element-specific methods |
| --- | --- | --- |
| `TextBuilder` / `TextElement` | `text`, `color`, `a`, `fontSize`, `align`, `fontFamily`, `clampSize`, `callback`, `noEllipsize`, `size`, `async`, `interactable`, `commence` | `rebuild`, `size`, `setText`, `animateColor` |
| `ButtonBuilder` / `ButtonElement` | `label`, `noBorder`, `noBg`, `accent`, `ellipsize`, `enabled`, `alignText`, `fontFamily`, `fontSize`, `onMainClick`, `onRightClick`, `size`, `commence` | `rebuild`, `size`, `setLabel`, `setEnabled` |
| `TextboxBuilder` / `TextboxElement` | `placeholder`, `defaultText`, `onTextEdited`, `multiline`, `password`, `eyeIcon`, `size`, `commence` | `rebuild`, `size`, `focus([true])`, `currentText`, `cursorPos`, `selection`, `setText`, `setPassword` |
| `CheckboxBuilder` / `CheckboxElement` | `toggled`, `style`, `onToggled`, `size`, `commence` | `rebuild`, `size`, `state`, `setState` |
| `SliderBuilder` / `SliderElement` | `min`, `max`, `val`, `snapInt`, `showLabel`, `onChanged`, `size`, `commence` | `rebuild`, `size`, `sliding` |
| `ComboboxBuilder` / `ComboboxElement` | `items`, `currentItem`, `onChanged`, `size`, `commence` | `rebuild`, `size`, `current`, `setCurrent` |
| `SpinboxBuilder` / `SpinboxElement` | `label`, `items`, `currentItem`, `onChanged`, `fill`, `size`, `commence` | `rebuild`, `size`, `current`, `setCurrent` |
| `RectangleBuilder` / `RectangleElement` | `color`, `borderColor`, `borderGradient`, `rounding`, `borderThickness`, `size`, `commence` | `rebuild`, `size`, `animateColor`, `animateBorderColor` |
| `ColumnLayoutBuilder` / `ColumnLayoutElement` | `gap`, `size`, `commence` | `rebuild`, `size` |
| `RowLayoutBuilder` / `RowLayoutElement` | `gap`, `size`, `commence` | `rebuild`, `size` |
| `ScrollAreaBuilder` / `ScrollAreaElement` | `scrollX`, `scrollY`, `blockUserScroll`, `showScrollbar`, `size`, `commence` | `rebuild`, `size`, `getCurrentScroll`, `setScroll` |
| `ImageBuilder` / `ImageElement` | `path`, `icon`, `data`, `a`, `fitMode`, `sync`, `rounding`, `size`, `commence` | `rebuild`, `size` |
| `NullBuilder` / `NullElement` | `size`, `commence` | `rebuild`, `size` |
| `LineBuilder` / `LineElement` | `color`, `thick`, `points`, `size`, `commence` | `rebuild`, `size` |
| `ProgressBarBuilder` / `ProgressBarElement` | `value`, `indeterminate`, `size`, `commence` | `rebuild`, `size`, `value`, `setValue` |

`RadioGroup.create()` returns a group with `add`, `selected`, `setSelected`,
and `onSelected`.

`ImageBuilder:data` accepts a binary Lua string or a dense byte array. Byte
array entries must be integers in `0..255`. Upstream treats `path`, `icon`, and
`data` as exclusive sources: the last one set wins.

Combobox and spinbox indices are always 1-based. Their item lists may be empty;
an empty list reports `current() == 1`, ignores `setCurrent`, and never calls
`onChanged`.

Textbox cursor and selection results are upstream byte offsets; `selection()`
returns two offsets. `onTextEdited` fires only for committed user edits, not
for `setText`, `rebuild`, or uncommitted input-method preedit text.

## Windows

| Type | Methods and properties |
| --- | --- |
| `WindowBuilder` | `begin`, `type`, `appTitle`, `appClass`, `preferredSize`, `minSize`, `maxSize`, `resizable`, `autosize`, `preferredOutput`, `marginTopLeft`, `marginBottomRight`, `layer`, `anchor`, `exclusiveEdge`, `exclusiveZone`, `kbInteractive`, `inhibitShortcuts`, `parent`, `pos`, `commence` |
| `Window` | `pixelSize`, `scale`, `close`, `open`, `cursorPos`, `setSize`, `startInteractiveResize`; read/write `rootElement`; `onResized`, `onCloseRequest`, `onPopupClosed`, `onLayerClosed`, `onKeyboardKey` |

## Intentional exclusions

These facilities are not Lua-meaningful or are unsafe implementation details:

- Renderer lifecycle and internal calls such as `Element.paint`, intrinsic
  layout hooks, texture internals, and input-method implementation hooks.
- Anything declared behind upstream `HT_HIDDEN`.
- Direct `Timer` construction and `Timer.call`; timers are backend-owned and
  created with `Backend:addTimer`.
- Construction of Hyprutils `CLoggerConnection` and the corresponding backend
  creation-data field.
- The `Color` constructor taking a foreign Hyprgraphics `CColor`; conversion
  results are returned as named Lua records.
- Raw Hyprutils signal objects and static listeners; Lua receives
  disconnectable `SignalConnection` adapters.
- The embedded backend (`IEmbeddedBackend`, `IEmbeddedSurface`) and its host
  service interfaces (`IEventLoop`, `IClipboard`, `ITextInput`, `ICursor`,
  `IOutputProvider`, `ISessionLockProvider`). The host must own a current GLES3
  context and framebuffer and drive rendering and input, which a Lua script
  cannot provide.
