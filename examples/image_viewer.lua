local htk = require("hyprtoolkit")

-- Image Viewer Example for Hyprtoolkit Lua Bindings
-- Usage: hyprtoolkit-lua image_viewer.lua [image_path]

-- Get image path from command line or use a default
local imagePath = arg and arg[1] or nil

-- Create the backend
local backend = htk.Backend.create()
local palette = backend:getPalette()

-- State
local currentFitMode = htk.ImageFitMode.CONTAIN
local currentImage = nil
local imageElement = nil
local loadImage
local connections = {}

-- Helper functions for colors
local function textColor()
    return palette.text
end

local function bgColor()
    return palette.background
end

local function toolbarBg()
    return palette.base
end

local function accentColor()
    return palette.accent
end

-- Create main window
local window = htk.WindowBuilder.begin()
    :appTitle("Lua Image Viewer")
    :appClass("hyprtoolkit-lua-image-viewer")
    :preferredSize(htk.Vector2D.new(800, 600))
    :minSize(htk.Vector2D.new(400, 300))
    :commence()

-- Main container (full window)
local mainContainer = htk.RectangleBuilder.begin()
    :color(bgColor)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.PERCENT,
        htk.Vector2D.new(1, 1)
    ))
    :commence()

window.rootElement:addChild(mainContainer)

-- Create main layout (column with toolbar at top)
local mainLayout = htk.ColumnLayoutBuilder.begin()
    :gap(0)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.PERCENT,
        htk.Vector2D.new(1, 1)
    ))
    :commence()

mainContainer:addChild(mainLayout)

-- Toolbar
local toolbar = htk.RectangleBuilder.begin()
    :color(toolbarBg)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.ABSOLUTE,
        htk.Vector2D.new(1, 48)
    ))
    :commence()

mainLayout:addChild(toolbar)

-- Toolbar content row
local toolbarRow = htk.RowLayoutBuilder.begin()
    :gap(8)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.PERCENT,
        htk.Vector2D.new(1, 1)
    ))
    :commence()

toolbarRow:setMargin(8)
toolbar:addChild(toolbarRow)

-- Title
local titleText = htk.TextBuilder.begin()
    :text("Image Viewer")
    :fontSize(htk.FontSize.new(htk.FontSizeBase.H3, 1.0))
    :color(textColor)
    :commence()

toolbarRow:addChild(titleText)

-- Spacer
local spacer1 = htk.NullBuilder.begin():commence()
spacer1:setGrow(true)
toolbarRow:addChild(spacer1)

-- Fit mode label
local fitModeLabel = htk.TextBuilder.begin()
    :text("Fit:")
    :fontSize(htk.FontSize.new(htk.FontSizeBase.TEXT, 1.0))
    :color(textColor)
    :commence()

toolbarRow:addChild(fitModeLabel)

-- Fit mode selector
local fitModeCombo = htk.ComboboxBuilder.begin()
    :items({"Contain", "Cover", "Stretch", "Tile"})
    :currentItem(1)
    :size(htk.DynamicSize.new(
        htk.SizeType.ABSOLUTE,
        htk.SizeType.ABSOLUTE,
        htk.Vector2D.new(120, 28)
    ))
    :onChanged(function(combo, index)
        local modes = {
            htk.ImageFitMode.CONTAIN,
            htk.ImageFitMode.COVER,
            htk.ImageFitMode.STRETCH,
            htk.ImageFitMode.TILE
        }
        currentFitMode = modes[index]
        if imageElement and imagePath then
            -- Reload with new fit mode
            loadImage(imagePath)
        end
        print("[Viewer] Fit mode changed to: " .. tostring(index))
    end)
    :commence()

toolbarRow:addChild(fitModeCombo)

-- Separator
local separator = htk.NullBuilder.begin()
    :size(htk.DynamicSize.new(
        htk.SizeType.ABSOLUTE,
        htk.SizeType.ABSOLUTE,
        htk.Vector2D.new(16, 1)
    ))
    :commence()

toolbarRow:addChild(separator)

-- Open button (placeholder - file dialog not available in bindings)
local openButton = htk.ButtonBuilder.begin()
    :label("Info")
    :size(htk.DynamicSize.new(
        htk.SizeType.AUTO,
        htk.SizeType.AUTO,
        htk.Vector2D.new(1, 1)
    ))
    :onMainClick(function(btn)
        if imagePath then
            print("=== Image Info ===")
            print("Path: " .. imagePath)
            print("Fit Mode: " .. tostring(fitModeCombo:current()))
            print("==================")
        else
            print("[Viewer] No image loaded")
        end
    end)
    :commence()

toolbarRow:addChild(openButton)

-- Close button
local closeButton = htk.ButtonBuilder.begin()
    :label("Close")
    :size(htk.DynamicSize.new(
        htk.SizeType.AUTO,
        htk.SizeType.AUTO,
        htk.Vector2D.new(1, 1)
    ))
    :onMainClick(function(btn)
        print("[Viewer] Closing...")
        window:close()
        backend:destroy()
    end)
    :commence()

toolbarRow:addChild(closeButton)

-- Image container (takes remaining space)
local imageContainer = htk.RectangleBuilder.begin()
    :color(function()
        -- Slightly darker background for image area
        return palette.background:darken(0.1)
    end)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.PERCENT,
        htk.Vector2D.new(1, 1)
    ))
    :commence()

imageContainer:setGrow(true)
mainLayout:addChild(imageContainer)

-- Function to load and display an image
loadImage = function(path)
    imagePath = path

    -- Remove existing image if any
    if imageElement then
        imageContainer:removeChild(imageElement)
    end

    -- Create new image element - add directly to mainContainer like minimal test
    imageElement = htk.ImageBuilder.begin()
        :path(path)
        :fitMode(currentFitMode)
        :sync(true)  -- Load synchronously for immediate display
        :size(htk.DynamicSize.new(
            htk.SizeType.PERCENT,
            htk.SizeType.PERCENT,
            htk.Vector2D.new(0.9, 0.85)  -- Leave room for toolbar/status
        ))
        :commence()

    -- Add with ABSOLUTE positioning to mainContainer (bypassing layout)
    imageElement:setPositionMode(htk.PositionMode.ABSOLUTE)
    imageElement:setPositionFlag(htk.PositionFlag.CENTER, true)
    imageContainer:addChild(imageElement)

    -- Update title
    local filename = path:match("([^/]+)$") or path
    titleText:rebuild()
        :text("Image Viewer - " .. filename)
        :fontSize(htk.FontSize.new(htk.FontSizeBase.H3, 1.0))
        :color(textColor)
        :commence()

    print("[Viewer] Loaded: " .. path)
end

-- If no image provided, show placeholder text
if not imagePath then
    local placeholderLayout = htk.ColumnLayoutBuilder.begin()
        :gap(12)
        :size(htk.DynamicSize.new(
            htk.SizeType.AUTO,
            htk.SizeType.AUTO,
            htk.Vector2D.new(1, 1)
        ))
        :commence()

    placeholderLayout:setPositionMode(htk.PositionMode.ABSOLUTE)
    placeholderLayout:setPositionFlag(htk.PositionFlag.CENTER, true)
    imageContainer:addChild(placeholderLayout)

    local placeholderText = htk.TextBuilder.begin()
        :text("No image loaded")
        :fontSize(htk.FontSize.new(htk.FontSizeBase.H2, 1.0))
        :color(function()
            return palette.text:darken(0.3)
        end)
        :align(htk.FontAlignment.CENTER)
        :commence()

    placeholderLayout:addChild(placeholderText)

    local hintText = htk.TextBuilder.begin()
        :text("Usage: hyprtoolkit-lua image_viewer.lua <image_path>")
        :fontSize(htk.FontSize.new(htk.FontSizeBase.TEXT, 1.0))
        :color(function()
            return palette.text:darken(0.5)
        end)
        :align(htk.FontAlignment.CENTER)
        :commence()

    placeholderLayout:addChild(hintText)
else
    -- Load the image from command line
    loadImage(imagePath)
end

-- Status bar at bottom
local statusBar = htk.RectangleBuilder.begin()
    :color(toolbarBg)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.ABSOLUTE,
        htk.Vector2D.new(1, 24)
    ))
    :commence()

mainLayout:addChild(statusBar)

local statusText = htk.TextBuilder.begin()
    :text(imagePath and ("Loaded: " .. imagePath) or "Ready")
    :fontSize(htk.FontSize.new(htk.FontSizeBase.SMALL, 1.0))
    :color(function()
        return palette.text:darken(0.2)
    end)
    :commence()

statusText:setMargin(4)
statusBar:addChild(statusText)

-- Handle keyboard events
connections[#connections + 1] = window:onKeyboardKey(function(event)
    if event.down then
        -- Escape to close
        if event.xkbKeysym == 65307 then  -- XKB_KEY_Escape
            print("[Viewer] Escape pressed, closing...")
            window:close()
            backend:destroy()
        -- Number keys 1-4 to change fit mode
        elseif event.xkbKeysym >= 49 and event.xkbKeysym <= 52 then
            local modeIndex = event.xkbKeysym - 48  -- 1-4
            fitModeCombo:setCurrent(modeIndex)
            local modes = {
                htk.ImageFitMode.CONTAIN,
                htk.ImageFitMode.COVER,
                htk.ImageFitMode.STRETCH,
                htk.ImageFitMode.TILE
            }
            currentFitMode = modes[modeIndex]
            if imageElement and imagePath then
                -- Reload with new fit mode
                loadImage(imagePath)
            end
            print("[Viewer] Fit mode: " .. tostring(modeIndex))
        end
    end
end)

-- Handle window close request
connections[#connections + 1] = window:onCloseRequest(function()
    print("[Viewer] Window close requested")
    window:close()
    backend:destroy()
end)

-- Handle window resize
connections[#connections + 1] = window:onResized(function(size)
    -- Update status with window size
    local sizeStr = string.format("%.0fx%.0f", size.x, size.y)
    local statusStr = imagePath and (imagePath .. " | " .. sizeStr) or ("Ready | " .. sizeStr)
    statusText:rebuild()
        :text(statusStr)
        :fontSize(htk.FontSize.new(htk.FontSizeBase.SMALL, 1.0))
        :color(function()
            return palette.text:darken(0.2)
        end)
        :commence()
end)

-- Open window and run the event loop
print("[Viewer] Starting image viewer...")
print("[Viewer] Keyboard shortcuts:")
print("  1-4: Change fit mode (Contain/Cover/Stretch/Tile)")
print("  Escape: Close")
window:open()
backend:enterLoop()

print("[Viewer] Application exited")
