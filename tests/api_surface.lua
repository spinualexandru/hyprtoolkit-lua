local htk = require("hyprtoolkit")
assert(require("hyprtoolkit") == htk)
assert(_G.hyprtoolkit == nil)
assert(_G.IBackend == nil)
assert(_G.CTextBuilder == nil)
assert(_G.CWindow == nil)
assert(_G.CColor == nil)

assert(htk.VERSION == "0.3.0")
assert(htk.UPSTREAM_API_BRANCH == "main")

local requiredTables = {
    "Vector2D", "Box", "Color", "Gradient", "DynamicSize", "FontSize",
    "KeyboardKeyEvent", "TouchEvent", "NoAnimation", "BezierAnimation",
    "SpringAnimation", "AnimationPresets", "Palette", "SizeType",
    "FontSizeBase", "FontAlignment",
    "MouseButton", "Axis", "KeyboardModifier", "LogLevel", "SessionLockError",
    "PositionMode", "PositionFlag", "PointerShape", "ImageFitMode",
    "CheckboxStyle", "WindowType", "ResizeEdge", "Layer", "LayerAnchor",
    "KeyboardInteractivity", "SignalConnection", "Timer", "Output",
    "SessionLockState", "SystemIconDescription", "SystemIconFactory", "Backend",
    "Element", "WindowBuilder", "Window",
}

for _, name in ipairs(requiredTables) do
    assert(type(htk[name]) == "table", name .. " is not registered")
end

local function assertMembers(typeName, members)
    local typeTable = assert(htk[typeName], typeName .. " is not registered")
    for _, member in ipairs(members) do
        assert(typeTable[member] ~= nil, typeName .. "." .. member .. " is missing")
    end
end

local function assertProperties(typeName, properties)
    local typeTable = assert(htk[typeName], typeName .. " is not registered")
    for _, property in ipairs(properties) do
        local ok, value = pcall(function()
            return typeTable[property]
        end)
        assert(not ok or value ~= nil, typeName .. "." .. property .. " is missing")
    end
end

local enumMembers = {
    SizeType = { "ABSOLUTE", "PERCENT", "AUTO" },
    FontSizeBase = { "H1", "H2", "H3", "TEXT", "SMALL", "ABSOLUTE" },
    FontAlignment = { "LEFT", "CENTER", "RIGHT" },
    MouseButton = { "UNKNOWN", "LEFT", "RIGHT", "MIDDLE" },
    Axis = { "HORIZONTAL", "VERTICAL" },
    KeyboardModifier = {
        "SHIFT", "CAPS", "CTRL", "ALT", "MOD2", "MOD3", "META", "MOD5",
        "CTRL_SHIFT",
    },
    LogLevel = { "TRACE", "DEBUG", "WARNING", "ERROR", "CRITICAL" },
    SessionLockError = { "PLATFORM_UNINITIALIZED", "DENIED" },
    PositionMode = { "ABSOLUTE", "AUTO" },
    PositionFlag = {
        "HCENTER", "VCENTER", "CENTER", "LEFT", "RIGHT", "TOP", "BOTTOM", "ALL",
    },
    PointerShape = {
        "ARROW", "POINTER", "TEXT", "RESIZE_NS", "RESIZE_EW", "RESIZE_NESW",
        "RESIZE_NWSE",
    },
    ImageFitMode = { "STRETCH", "COVER", "CONTAIN", "TILE" },
    CheckboxStyle = { "CHECKMARK", "RADIO" },
    WindowType = { "TOPLEVEL", "POPUP", "LAYER", "LOCK_SURFACE" },
    ResizeEdge = {
        "NONE", "TOP", "BOTTOM", "LEFT", "TOP_LEFT", "BOTTOM_LEFT", "RIGHT",
        "TOP_RIGHT", "BOTTOM_RIGHT",
    },
    Layer = { "BACKGROUND", "BOTTOM", "TOP", "OVERLAY" },
    LayerAnchor = { "NONE", "TOP", "BOTTOM", "LEFT", "RIGHT" },
    KeyboardInteractivity = { "NONE", "EXCLUSIVE", "ON_DEMAND" },
}

for typeName, members in pairs(enumMembers) do
    assertMembers(typeName, members)
end

local builderNames = {
    "Text", "Button", "Textbox", "Checkbox", "Slider", "Combobox", "Spinbox",
    "Rectangle", "ColumnLayout", "RowLayout", "ScrollArea", "Image", "Null",
    "Line", "ProgressBar",
}

for _, name in ipairs(builderNames) do
    local builder = htk[name .. "Builder"]
    local element = htk[name .. "Element"]
    assert(type(builder) == "table", name .. "Builder is not registered")
    assert(type(builder.begin) == "function", name .. "Builder.begin is missing")
    assert(type(element) == "table", name .. "Element is not registered")
end

assert(type(htk.RadioGroup) == "table")
assert(type(htk.RadioGroup.create) == "function")
assert(htk.KeyboardModifier.CTRL_SHIFT ~= nil)
assert(htk.PointerShape.RESIZE_NWSE ~= nil)
assert(htk.ResizeEdge.BOTTOM_RIGHT ~= nil)
assert(htk.CheckboxStyle.RADIO ~= nil)
assert(htk.Layer.OVERLAY == 3)
assert(htk.LayerAnchor.RIGHT == 8)
assert(htk.KeyboardInteractivity.ON_DEMAND == 2)

assertMembers("Vector2D", {
    "new", "floor", "round", "clamp", "distance",
})
assertProperties("Vector2D", { "x", "y" })
assertMembers("Box", {
    "new", "pos", "size", "middle", "containsPoint", "empty", "intersection",
    "expand", "round", "translate", "scale",
})
assertProperties("Box", { "x", "y", "w", "h" })
assertMembers("Color", {
    "new", "fromHex", "getAsHex", "asRGB", "asHSL", "asOkLab", "brighten",
    "darken", "mix", "stripA",
})
assertProperties("Color", { "r", "g", "b", "a" })
assertMembers("Gradient", { "new", "solid" })
assertProperties("Gradient", { "colors", "angle" })
assertMembers("DynamicSize", {
    "new", "absolute", "percent", "auto", "mixed", "calculate",
})
assertMembers("FontSize", {
    "new", "h1", "h2", "h3", "text", "small", "absolute", "ptSize",
})
assertMembers("KeyboardKeyEvent", {
    "hasModifier",
})
assertProperties("KeyboardKeyEvent", {
    "xkbKeysym", "down", "repeat", "utf8", "modMask",
})
assertProperties("TouchEvent", { "id", "position", "timeMs" })
assertMembers("NoAnimation", { "new" })
assertMembers("BezierAnimation", { "new" })
assertProperties("BezierAnimation", { "durationMs", "control1", "control2" })
assertMembers("SpringAnimation", { "new" })
assertProperties("SpringAnimation", {
    "stiffness", "damping", "mass", "valueEpsilon", "velocityEpsilon",
})
assertMembers("AnimationPresets", { "Slow", "Medium", "Fast", "Snappy", "Bouncy" })
assertMembers("Palette", {
    "palette", "emptyPalette",
})
assertProperties("Palette", {
    "background", "text", "base", "alternateBase", "brightText", "linkText",
    "accent", "accentSecondary", "h1Size", "h2Size", "h3Size", "fontSize",
    "smallFontSize", "iconTheme", "bigRounding", "smallRounding", "fontFamily",
    "fontFamilyMonospace",
})

assertMembers("Backend", {
    "create", "destroy", "enterLoop", "getPalette", "systemIcons", "getOutputs",
    "setLogCallback", "addTimer", "addIdle", "addFd", "removeFd",
    "acquireSessionLock", "onOutputAdded",
})
assert(htk.Backend.aquireSessionLock == nil)
assertMembers("Timer", {
    "cancel", "passed", "canForceUpdate", "leftMs", "cancelled", "updateTimeout",
})
assertMembers("Output", { "handle", "port", "desc", "fps", "onRemoved" })
assertMembers("SessionLockState", { "unlock", "onFinished" })
assertMembers("SystemIconFactory", { "lookupIcon" })
assertMembers("SystemIconDescription", { "exists", "scalable" })
assertMembers("SignalConnection", { "connected", "disconnect" })

assertMembers("Element", {
    "size", "posFromParent", "reposition", "forceReposition", "setPositionMode",
    "setPositionFlag", "setAbsolutePosition", "addChild", "removeChild",
    "clearChildren", "setMargin", "setGrouped", "setTooltip", "setGrow",
    "setReceivesMouse", "setMouseEnter", "setMouseLeave", "setMouseMove",
    "setMouseButton", "setMouseAxis", "setReceivesTouch", "setTouchDown",
    "setTouchMotion", "setTouchUp", "setTouchCancel", "setRepositioned",
    "setOpacity", "animateOpacity", "animateGeometry",
})

local vector = htk.Vector2D.new(4, 6)
assert(vector.x == 4 and vector.y == 6)
vector.x = 8
vector.y = 12
assert(vector.x == 8 and vector.y == 12)
assert(htk.Vector2D.new() == htk.Vector2D.new(0, 0))
assert((vector + htk.Vector2D.new(1, 2)) == htk.Vector2D.new(9, 14))
assert((vector - htk.Vector2D.new(1, 2)) == htk.Vector2D.new(7, 10))
assert((vector * 2) == htk.Vector2D.new(16, 24))
assert((vector / 2) == htk.Vector2D.new(4, 6))
local box = htk.Box.new(1, 2, 3, 4)
assert(box.x == 1 and box.h == 4)
box.w = 6
assert(box.w == 6)
assert(htk.Box.new(htk.Vector2D.new(1, 2), htk.Vector2D.new(3, 4)).w == 3)

local color = htk.Color.new(0.2, 0.3, 0.4, 0.5)
local rgb = color:asRGB()
local hsl = color:asHSL()
local lab = color:asOkLab()
assert(type(rgb.r) == "number" and type(rgb.g) == "number" and type(rgb.b) == "number")
assert(type(hsl.h) == "number" and type(hsl.s) == "number" and type(hsl.l) == "number")
assert(type(lab.l) == "number" and type(lab.a) == "number" and type(lab.b) == "number")
assert((color + htk.Color.new(0.1, 0.1, 0.1, 0.1)).r > color.r)
assert((color - htk.Color.new(0.1, 0.1, 0.1, 0.1)).r < color.r)
assert((color * 0.5).r < color.r)
assert(color == htk.Color.new(0.2, 0.3, 0.4, 0.5))
assert(type(tostring(color)) == "string")
assert(htk.Color.fromHex(color:getAsHex()) ~= nil)
assert(color:brighten(0.1) ~= nil)
assert(color:darken(0.1) ~= nil)
assert(color:mix(htk.Color.new(1, 1, 1), 0.5) ~= nil)
assert(color:stripA().a == 1)

local gradient = htk.Gradient.new({
    htk.Color.new(1, 0, 0),
    htk.Color.new(0, 0, 1),
}, 45)
assert(#gradient.colors == 2)
assert(gradient.angle == 45)
gradient.angle = 90
gradient.colors = { htk.Color.new(0, 1, 0) }
assert(gradient.angle == 90 and #gradient.colors == 1)
assert(htk.Gradient.solid(color) == htk.Gradient.solid(color))

assert(htk.DynamicSize.absolute(10, 20) ~= nil)
assert(htk.DynamicSize.percent(0.5, 1) ~= nil)
assert(htk.DynamicSize.auto() ~= nil)
assert(htk.DynamicSize.absolute(10, 20):calculate(htk.Vector2D.new(100, 100))
    == htk.Vector2D.new(10, 20))
assert(htk.DynamicSize.absolute(10, 20):calculate(htk.Vector2D.new(100, 100), false)
    == htk.Vector2D.new(10, 20))
assert(htk.DynamicSize.percent(0.5, 1):calculate(htk.Vector2D.new(100, 40), true)
    == htk.Vector2D.new(50, 40))
assert(htk.FontSize.new(htk.FontSizeBase.H1) ~= nil)
assert(htk.FontSize.absolute(12):ptSize() == 12)
assert(htk.FontSize.h1() ~= nil)
assert(htk.FontSize.h2(1.2) ~= nil)
assert(htk.FontSize.h3() ~= nil)
assert(htk.FontSize.text() ~= nil)
assert(htk.FontSize.small() ~= nil)

local noAnimation = htk.NoAnimation.new()
assert(noAnimation == htk.NoAnimation.new())

local bezier = htk.BezierAnimation.new()
assert(bezier.durationMs == 200)
assert(bezier.control1 == htk.Vector2D.new(0.23, 1))
assert(bezier.control2 == htk.Vector2D.new(0.32, 1))
bezier = htk.BezierAnimation.new({
    durationMs = 350,
    control1 = htk.Vector2D.new(0.4, 0),
})
assert(bezier.durationMs == 350)
assert(bezier.control1 == htk.Vector2D.new(0.4, 0))
assert(bezier.control2 == htk.Vector2D.new(0.32, 1))
bezier.durationMs = 120
assert(bezier.durationMs == 120)
assert(not pcall(htk.BezierAnimation.new, { duration = 100 }))
assert(not pcall(htk.BezierAnimation.new, { control1 = { 0.4, 0 } }))

local spring = htk.SpringAnimation.new()
assert(spring.stiffness == 250 and spring.damping == 25 and spring.mass == 1)
assert(spring == htk.AnimationPresets.Medium)
spring = htk.SpringAnimation.new({ stiffness = 300, damping = 14 })
assert(spring == htk.AnimationPresets.Bouncy)
spring.mass = 2
assert(spring.mass == 2)
assert(not pcall(htk.SpringAnimation.new, { stifness = 300 }))
assert(not pcall(htk.SpringAnimation.new, { damping = "loose" }))

assert(htk.AnimationPresets.Fast.stiffness == 450)
assert(htk.AnimationPresets.Snappy.damping == 42)
assert(htk.AnimationPresets.Slow.stiffness == 120)
assert(htk.AnimationPresets.Missing == nil)
local preset = htk.AnimationPresets.Fast
preset.stiffness = 1
assert(htk.AnimationPresets.Fast.stiffness == 450)
assert(not pcall(function()
    htk.AnimationPresets.Custom = spring
end))

local palette = htk.Palette.emptyPalette()
local paletteColorProperties = {
    "background", "text", "base", "alternateBase", "brightText", "linkText",
    "accent", "accentSecondary",
}
for _, property in ipairs(paletteColorProperties) do
    palette[property] = color
    assert(palette[property] == color)
end
local paletteNumberProperties = {
    "h1Size", "h2Size", "h3Size", "fontSize", "smallFontSize", "bigRounding",
    "smallRounding",
}
for _, property in ipairs(paletteNumberProperties) do
    palette[property] = 17
    assert(palette[property] == 17)
end
for _, property in ipairs({ "iconTheme", "fontFamily", "fontFamilyMonospace" }) do
    palette[property] = "test"
    assert(palette[property] == "test")
end

local elementMethods = {
    Text = {
        builder = {
            "begin", "text", "color", "a", "fontSize", "align", "fontFamily",
            "clampSize", "callback", "noEllipsize", "size", "async",
            "interactable", "commence",
        },
        element = { "rebuild", "size", "setText", "animateColor" },
    },
    Button = {
        builder = {
            "begin", "label", "noBorder", "noBg", "accent", "ellipsize",
            "enabled", "alignText", "fontFamily", "fontSize", "onMainClick",
            "onRightClick", "size", "commence",
        },
        element = { "rebuild", "size", "setLabel", "setEnabled" },
    },
    Textbox = {
        builder = {
            "begin", "placeholder", "defaultText", "onTextEdited", "multiline",
            "password", "eyeIcon", "size", "commence",
        },
        element = {
            "rebuild", "size", "focus", "currentText", "cursorPos", "selection",
            "setText", "setPassword",
        },
    },
    Checkbox = {
        builder = { "begin", "toggled", "style", "onToggled", "size", "commence" },
        element = { "rebuild", "size", "state", "setState" },
    },
    Slider = {
        builder = {
            "begin", "min", "max", "val", "snapInt", "showLabel", "onChanged",
            "size", "commence",
        },
        element = { "rebuild", "size", "sliding" },
    },
    Combobox = {
        builder = { "begin", "items", "currentItem", "onChanged", "size", "commence" },
        element = { "rebuild", "size", "current", "setCurrent" },
    },
    Spinbox = {
        builder = {
            "begin", "label", "items", "currentItem", "onChanged", "fill", "size",
            "commence",
        },
        element = { "rebuild", "size", "current", "setCurrent" },
    },
    Rectangle = {
        builder = {
            "begin", "color", "borderColor", "borderGradient", "rounding",
            "borderThickness", "size", "commence",
        },
        element = { "rebuild", "size", "animateColor", "animateBorderColor" },
    },
    ColumnLayout = {
        builder = { "begin", "gap", "size", "commence" },
        element = { "rebuild", "size" },
    },
    RowLayout = {
        builder = { "begin", "gap", "size", "commence" },
        element = { "rebuild", "size" },
    },
    ScrollArea = {
        builder = {
            "begin", "scrollX", "scrollY", "blockUserScroll", "showScrollbar",
            "size", "commence",
        },
        element = { "rebuild", "size", "getCurrentScroll", "setScroll" },
    },
    Image = {
        builder = {
            "begin", "path", "icon", "data", "a", "fitMode", "sync", "rounding",
            "size", "commence",
        },
        element = { "rebuild", "size" },
    },
    Null = {
        builder = { "begin", "size", "commence" },
        element = { "rebuild", "size" },
    },
    Line = {
        builder = { "begin", "color", "thick", "points", "size", "commence" },
        element = { "rebuild", "size" },
    },
    ProgressBar = {
        builder = { "begin", "value", "indeterminate", "size", "commence" },
        element = { "rebuild", "size", "value", "setValue" },
    },
}

for name, methods in pairs(elementMethods) do
    assertMembers(name .. "Builder", methods.builder)
    assertMembers(name .. "Element", methods.element)
end

assertMembers("RadioGroup", {
    "create", "add", "selected", "setSelected", "onSelected",
})
assertMembers("WindowBuilder", {
    "begin", "type", "appTitle", "appClass", "preferredSize", "minSize",
    "maxSize", "resizable", "autosize", "preferredOutput", "marginTopLeft",
    "marginBottomRight", "layer", "anchor", "exclusiveEdge", "exclusiveZone",
    "kbInteractive", "inhibitShortcuts", "parent", "pos", "commence",
})
assert(htk.WindowBuilder.prefferedOutput == nil)
assertMembers("Window", {
    "pixelSize", "scale", "close", "open", "cursorPos", "setSize",
    "startInteractiveResize", "onResized", "onCloseRequest",
    "onPopupClosed", "onLayerClosed", "onKeyboardKey",
})
assertProperties("Window", { "rootElement" })

assert(htk.ComboboxBuilder.begin():items({ "one", "two" }):currentItem(1) ~= nil)
assert(htk.SpinboxBuilder.begin():items({ "one", "two" }):currentItem(2) ~= nil)
assert(not pcall(function()
    htk.ComboboxBuilder.begin():items({ "one" }):currentItem(0)
end))
assert(not pcall(function()
    htk.ComboboxBuilder.begin():items({ "one" }):currentItem(-1)
end))
assert(htk.ComboboxBuilder.begin():items({}) ~= nil)
assert(htk.SpinboxBuilder.begin():items({}) ~= nil)
assert(not pcall(function()
    htk.ComboboxBuilder.begin():items({ "one", 2 })
end))
assert(htk.SliderBuilder.begin():showLabel(false) ~= nil)

assert(htk.ImageBuilder.begin():data("\137PNG\0binary") ~= nil)
assert(htk.ImageBuilder.begin():data({ 0, 1, 127, 255 }) ~= nil)
assert(htk.RectangleBuilder.begin():borderGradient(gradient) ~= nil)
assert(htk.RectangleBuilder.begin():borderGradient(function()
    return gradient
end) ~= nil)
assert(not pcall(function()
    htk.ImageBuilder.begin():data({ 256 })
end))
assert(not pcall(function()
    htk.ImageBuilder.begin():data({ 1.5 })
end))
assert(not pcall(function()
    htk.ImageBuilder.begin():data({ [1] = 0, [3] = 2 })
end))

print("hyprtoolkit Lua API surface OK")
