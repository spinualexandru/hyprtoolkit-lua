-- Image Viewer Example for Hyprtoolkit Lua Bindings
-- Usage: hyprtoolkit-lua image_viewer.lua [image_path]

-- Get image path from command line or use a default
local imagePath = arg and arg[1] or nil

-- Create the backend
local backend = IBackend.create()
local palette = backend:getPalette()

-- State
local currentFitMode = ImageFitMode.CONTAIN
local currentImage = nil
local imageElement = nil

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
local window = CWindowBuilder.begin()
    :appTitle("Lua Image Viewer")
    :appClass("hyprtoolkit-lua-image-viewer")
    :preferredSize(Vector2D.new(800, 600))
    :minSize(Vector2D.new(400, 300))
    :commence()

-- Main container (full window)
local mainContainer = CRectangleBuilder.begin()
    :color(bgColor)
    :size(CDynamicSize.new(
        CDynamicSize.HT_SIZE_PERCENT,
        CDynamicSize.HT_SIZE_PERCENT,
        Vector2D.new(1, 1)
    ))
    :commence()

window.m_rootElement:addChild(mainContainer)

-- Create main layout (column with toolbar at top)
local mainLayout = CColumnLayoutBuilder.begin()
    :gap(0)
    :size(CDynamicSize.new(
        CDynamicSize.HT_SIZE_PERCENT,
        CDynamicSize.HT_SIZE_PERCENT,
        Vector2D.new(1, 1)
    ))
    :commence()

mainContainer:addChild(mainLayout)

-- Toolbar
local toolbar = CRectangleBuilder.begin()
    :color(toolbarBg)
    :size(CDynamicSize.new(
        CDynamicSize.HT_SIZE_PERCENT,
        CDynamicSize.HT_SIZE_ABSOLUTE,
        Vector2D.new(1, 48)
    ))
    :commence()

mainLayout:addChild(toolbar)

-- Toolbar content row
local toolbarRow = CRowLayoutBuilder.begin()
    :gap(8)
    :size(CDynamicSize.new(
        CDynamicSize.HT_SIZE_PERCENT,
        CDynamicSize.HT_SIZE_PERCENT,
        Vector2D.new(1, 1)
    ))
    :commence()

toolbarRow:setMargin(8)
toolbar:addChild(toolbarRow)

-- Title
local titleText = CTextBuilder.begin()
    :text("Image Viewer")
    :fontSize(CFontSize.new(CFontSize.HT_FONT_H3, 1.0))
    :color(textColor)
    :commence()

toolbarRow:addChild(titleText)

-- Spacer
local spacer1 = CNullBuilder.begin():commence()
spacer1:setGrow(true)
toolbarRow:addChild(spacer1)

-- Fit mode label
local fitModeLabel = CTextBuilder.begin()
    :text("Fit:")
    :fontSize(CFontSize.new(CFontSize.HT_FONT_TEXT, 1.0))
    :color(textColor)
    :commence()

toolbarRow:addChild(fitModeLabel)

-- Fit mode selector
local fitModeCombo = CComboboxBuilder.begin()
    :items({"Contain", "Cover", "Stretch", "Tile"})
    :currentItem(0)
    :size(CDynamicSize.new(
        CDynamicSize.HT_SIZE_ABSOLUTE,
        CDynamicSize.HT_SIZE_ABSOLUTE,
        Vector2D.new(120, 28)
    ))
    :onChanged(function(combo, index)
        local modes = {
            ImageFitMode.CONTAIN,
            ImageFitMode.COVER,
            ImageFitMode.STRETCH,
            ImageFitMode.TILE
        }
        currentFitMode = modes[index + 1]
        if imageElement and imagePath then
            -- Reload with new fit mode
            loadImage(imagePath)
        end
        print("[Viewer] Fit mode changed to: " .. tostring(index))
    end)
    :commence()

toolbarRow:addChild(fitModeCombo)

-- Separator
local separator = CNullBuilder.begin()
    :size(CDynamicSize.new(
        CDynamicSize.HT_SIZE_ABSOLUTE,
        CDynamicSize.HT_SIZE_ABSOLUTE,
        Vector2D.new(16, 1)
    ))
    :commence()

toolbarRow:addChild(separator)

-- Open button (placeholder - file dialog not available in bindings)
local openButton = CButtonBuilder.begin()
    :label("Info")
    :size(CDynamicSize.new(
        CDynamicSize.HT_SIZE_AUTO,
        CDynamicSize.HT_SIZE_AUTO,
        Vector2D.new(1, 1)
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
local closeButton = CButtonBuilder.begin()
    :label("Close")
    :size(CDynamicSize.new(
        CDynamicSize.HT_SIZE_AUTO,
        CDynamicSize.HT_SIZE_AUTO,
        Vector2D.new(1, 1)
    ))
    :onMainClick(function(btn)
        print("[Viewer] Closing...")
        window:close()
        backend:destroy()
    end)
    :commence()

toolbarRow:addChild(closeButton)

-- Image container (takes remaining space)
local imageContainer = CRectangleBuilder.begin()
    :color(function()
        -- Slightly darker background for image area
        return palette.background:darken(0.1)
    end)
    :size(CDynamicSize.new(
        CDynamicSize.HT_SIZE_PERCENT,
        CDynamicSize.HT_SIZE_PERCENT,
        Vector2D.new(1, 1)
    ))
    :commence()

imageContainer:setGrow(true)
mainLayout:addChild(imageContainer)

-- Function to load and display an image
local function loadImage(path)
    imagePath = path

    -- Remove existing image if any
    if imageElement then
        mainContainer:removeChild(imageElement)
    end

    -- Create new image element - add directly to mainContainer like minimal test
    imageElement = CImageBuilder.begin()
        :path(path)
        :fitMode(currentFitMode)
        :sync(true)  -- Load synchronously for immediate display
        :size(CDynamicSize.new(
            CDynamicSize.HT_SIZE_PERCENT,
            CDynamicSize.HT_SIZE_PERCENT,
            Vector2D.new(0.9, 0.85)  -- Leave room for toolbar/status
        ))
        :commence()

    -- Add with ABSOLUTE positioning to mainContainer (bypassing layout)
    imageElement:setPositionMode(PositionMode.ABSOLUTE)
    imageElement:setPositionFlag(PositionFlag.CENTER, true)
    mainContainer:addChild(imageElement)

    -- Update title
    local filename = path:match("([^/]+)$") or path
    titleText:rebuild()
        :text("Image Viewer - " .. filename)
        :fontSize(CFontSize.new(CFontSize.HT_FONT_H3, 1.0))
        :color(textColor)
        :commence()

    print("[Viewer] Loaded: " .. path)
end

-- If no image provided, show placeholder text
if not imagePath then
    local placeholderLayout = CColumnLayoutBuilder.begin()
        :gap(12)
        :size(CDynamicSize.new(
            CDynamicSize.HT_SIZE_AUTO,
            CDynamicSize.HT_SIZE_AUTO,
            Vector2D.new(1, 1)
        ))
        :commence()

    placeholderLayout:setPositionMode(PositionMode.ABSOLUTE)
    placeholderLayout:setPositionFlag(PositionFlag.CENTER, true)
    imageContainer:addChild(placeholderLayout)

    local placeholderText = CTextBuilder.begin()
        :text("No image loaded")
        :fontSize(CFontSize.new(CFontSize.HT_FONT_H2, 1.0))
        :color(function()
            return palette.text:darken(0.3)
        end)
        :align(FontAlignment.CENTER)
        :commence()

    placeholderLayout:addChild(placeholderText)

    local hintText = CTextBuilder.begin()
        :text("Usage: hyprtoolkit-lua image_viewer.lua <image_path>")
        :fontSize(CFontSize.new(CFontSize.HT_FONT_TEXT, 1.0))
        :color(function()
            return palette.text:darken(0.5)
        end)
        :align(FontAlignment.CENTER)
        :commence()

    placeholderLayout:addChild(hintText)
else
    -- Load the image from command line
    loadImage(imagePath)
end

-- Status bar at bottom
local statusBar = CRectangleBuilder.begin()
    :color(toolbarBg)
    :size(CDynamicSize.new(
        CDynamicSize.HT_SIZE_PERCENT,
        CDynamicSize.HT_SIZE_ABSOLUTE,
        Vector2D.new(1, 24)
    ))
    :commence()

mainLayout:addChild(statusBar)

local statusText = CTextBuilder.begin()
    :text(imagePath and ("Loaded: " .. imagePath) or "Ready")
    :fontSize(CFontSize.new(CFontSize.HT_FONT_SMALL, 1.0))
    :color(function()
        return palette.text:darken(0.2)
    end)
    :commence()

statusText:setMargin(4)
statusBar:addChild(statusText)

-- Handle keyboard events
window:onKeyboardKey(function(event)
    if event.down then
        -- Escape to close
        if event.xkbKeysym == 65307 then  -- XKB_KEY_Escape
            print("[Viewer] Escape pressed, closing...")
            window:close()
            backend:destroy()
        -- Number keys 1-4 to change fit mode
        elseif event.xkbKeysym >= 49 and event.xkbKeysym <= 52 then
            local modeIndex = event.xkbKeysym - 49  -- 0-3
            fitModeCombo:setCurrent(modeIndex)
            local modes = {
                ImageFitMode.CONTAIN,
                ImageFitMode.COVER,
                ImageFitMode.STRETCH,
                ImageFitMode.TILE
            }
            currentFitMode = modes[modeIndex + 1]
            if imageElement and imagePath then
                -- Reload with new fit mode
                loadImage(imagePath)
            end
            print("[Viewer] Fit mode: " .. tostring(modeIndex))
        end
    end
end)

-- Handle window close request
window:onCloseRequest(function()
    print("[Viewer] Window close requested")
    window:close()
    backend:destroy()
end)

-- Handle window resize
window:onResized(function(size)
    -- Update status with window size
    local sizeStr = string.format("%.0fx%.0f", size.x, size.y)
    local statusStr = imagePath and (imagePath .. " | " .. sizeStr) or ("Ready | " .. sizeStr)
    statusText:rebuild()
        :text(statusStr)
        :fontSize(CFontSize.new(CFontSize.HT_FONT_SMALL, 1.0))
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
