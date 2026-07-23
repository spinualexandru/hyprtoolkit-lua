local htk = require("hyprtoolkit")

local backend = assert(htk.Backend.create(), "failed to create Hyprtoolkit backend")
local palette = backend:getPalette()
local connections = {}

local window = htk.WindowBuilder.begin()
    :appTitle("Hyprtoolkit Lua 0.2 controls")
    :appClass("hyprtoolkit-lua-latest-controls")
    :preferredSize(htk.Vector2D.new(680, 620))
    :minSize(htk.Vector2D.new(440, 360))
    :resizable(true)
    :inhibitShortcuts(false)
    :commence()

local background = htk.RectangleBuilder.begin()
    :color(function()
        return palette.background
    end)
    :borderGradient(function()
        return htk.Gradient.new({
            palette.accent,
            palette.accentSecondary,
        }, 35)
    end)
    :borderThickness(3)
    :rounding(10)
    :size(htk.DynamicSize.percent(1, 1))
    :commence()
window.rootElement:addChild(background)

local scroll = htk.ScrollAreaBuilder.begin()
    :scrollY(true)
    :showScrollbar(true)
    :size(htk.DynamicSize.percent(1, 1))
    :commence()
scroll:setMargin(18)
background:addChild(scroll)

local controls = htk.ColumnLayoutBuilder.begin()
    :gap(12)
    :size(htk.DynamicSize.mixed(
        htk.SizeType.PERCENT,
        htk.SizeType.AUTO,
        1,
        1
    ))
    :commence()
scroll:addChild(controls)

local heading = htk.TextBuilder.begin()
    :text("Current-main controls")
    :fontSize(htk.FontSize.h1())
    :interactable(true)
    :commence()
controls:addChild(heading)

local status = htk.TextBuilder.begin()
    :text("All selector indices below are Lua-native (1-based).")
    :fontSize(htk.FontSize.text())
    :commence()
controls:addChild(status)

local password = htk.TextboxBuilder.begin()
    :placeholder("Password with eye icon")
    :defaultText("hyprtoolkit")
    :password(true)
    :eyeIcon(true)
    :size(htk.DynamicSize.mixed(
        htk.SizeType.PERCENT,
        htk.SizeType.ABSOLUTE,
        1,
        36
    ))
    :commence()
password:setPassword(true)
password:setText("hyprtoolkit")
controls:addChild(password)

local progress = htk.ProgressBarBuilder.begin()
    :value(0.35)
    :size(htk.DynamicSize.mixed(
        htk.SizeType.PERCENT,
        htk.SizeType.ABSOLUTE,
        1,
        14
    ))
    :commence()
progress:setValue(0.55)
controls:addChild(progress)

local indeterminate = htk.ProgressBarBuilder.begin()
    :indeterminate(true)
    :size(htk.DynamicSize.mixed(
        htk.SizeType.PERCENT,
        htk.SizeType.ABSOLUTE,
        1,
        14
    ))
    :commence()
controls:addChild(indeterminate)

local radioOne = htk.CheckboxBuilder.begin()
    :style(htk.CheckboxStyle.RADIO)
    :toggled(true)
    :commence()
local radioTwo = htk.CheckboxBuilder.begin()
    :style(htk.CheckboxStyle.RADIO)
    :commence()
local radioGroup = htk.RadioGroup.create()
radioGroup:add(radioOne)
radioGroup:add(radioTwo)
radioGroup:onSelected(function(_)
    status:setText("Radio selection changed")
end)

local radioRow = htk.RowLayoutBuilder.begin():gap(10):commence()
radioRow:addChild(radioOne)
radioRow:addChild(htk.TextBuilder.begin():text("Radio one"):commence())
radioRow:addChild(radioTwo)
radioRow:addChild(htk.TextBuilder.begin():text("Radio two"):commence())
controls:addChild(radioRow)

local selector = htk.ComboboxBuilder.begin()
    :items({ "First item", "Second item", "Third item" })
    :currentItem(2)
    :onChanged(function(_, index)
        status:setText("Combobox selected Lua index " .. index)
    end)
    :commence()
controls:addChild(selector)

local spinbox = htk.SpinboxBuilder.begin()
    :label("Choice")
    :items({ "One", "Two", "Three" })
    :currentItem(1)
    :onChanged(function(_, index)
        status:setText("Spinbox selected Lua index " .. index)
    end)
    :commence()
controls:addChild(spinbox)

local buttonRow = htk.RowLayoutBuilder.begin():gap(10):commence()
local accentButton = htk.ButtonBuilder.begin()
    :label("Advance progress")
    :accent(true)
    :ellipsize(true)
    :onMainClick(function(button)
        progress:setValue(0.9)
        button:setLabel("Progress updated")
        status:setText("Imperative element setters applied")
    end)
    :commence()
local disabledButton = htk.ButtonBuilder.begin()
    :label("Disabled")
    :enabled(false)
    :commence()
local resizeButton = htk.ButtonBuilder.begin()
    :label("Resize window")
    :onMainClick(function()
        window:setSize(htk.Vector2D.new(760, 680))
    end)
    :commence()
buttonRow:addChild(accentButton)
buttonRow:addChild(disabledButton)
buttonRow:addChild(resizeButton)
controls:addChild(buttonRow)

connections[#connections + 1] = window:onResized(function(size)
    status:setText(string.format("Window resized to %.0f x %.0f", size.x, size.y))
end)

connections[#connections + 1] = window:onCloseRequest(function()
    window:close()
    backend:destroy()
end)

connections[#connections + 1] = window:onKeyboardKey(function(event)
    if event.down and event.xkbKeysym == 65307 then
        window:close()
        backend:destroy()
    end
end)

print("Close the window or press Escape to exit.")
window:open()
backend:enterLoop()
