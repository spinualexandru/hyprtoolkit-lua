local htk = require("hyprtoolkit")

-- WARNING: running this example takes over the active graphical session.
-- It is intentionally not part of the automated test suite.

local backend = assert(htk.Backend.create(), "failed to create Hyprtoolkit backend")
local lockState, lockError = backend:acquireSessionLock()
if not lockState then
    error("failed to acquire the session lock: " .. tostring(lockError))
end

local windows = {}
local connections = {}
local finished = false

local function closeSurface(handle)
    local entry = windows[handle]
    if not entry then
        return
    end

    entry.window:close()
    windows[handle] = nil
end

local function closeAll()
    local handles = {}
    for handle in pairs(windows) do
        handles[#handles + 1] = handle
    end
    for _, handle in ipairs(handles) do
        closeSurface(handle)
    end
end

local function createSurface(output)
    local handle = output:handle()
    if windows[handle] then
        return
    end

    local window = htk.WindowBuilder.begin()
        :type(htk.WindowType.LOCK_SURFACE)
        :preferredOutput(output)
        :commence()

    local background = htk.RectangleBuilder.begin()
        :color(htk.Color.new(0.04, 0.05, 0.08, 1))
        :size(htk.DynamicSize.percent(1, 1))
        :commence()
    window.rootElement:addChild(background)

    local content = htk.ColumnLayoutBuilder.begin()
        :gap(16)
        :commence()
    content:setPositionMode(htk.PositionMode.ABSOLUTE)
    content:setPositionFlag(htk.PositionFlag.CENTER, true)
    background:addChild(content)

    content:addChild(htk.TextBuilder.begin()
        :text("Hyprtoolkit Lua session lock")
        :fontSize(htk.FontSize.h1())
        :color(htk.Color.new(0.95, 0.96, 1, 1))
        :commence())

    content:addChild(htk.TextBuilder.begin()
        :text(output:desc())
        :color(htk.Color.new(0.72, 0.76, 0.88, 1))
        :commence())

    content:addChild(htk.ButtonBuilder.begin()
        :label("Unlock")
        :accent(true)
        :onMainClick(function(button)
            button:setEnabled(false)
            button:setLabel("Unlocking...")
            lockState:unlock()
        end)
        :commence())

    windows[handle] = {
        output = output,
        window = window,
    }

    connections[#connections + 1] = output:onRemoved(function()
        closeSurface(handle)
    end)
    connections[#connections + 1] = window:onCloseRequest(function()
        if not finished then
            lockState:unlock()
        end
    end)
    connections[#connections + 1] = window:onKeyboardKey(function(event)
        if event.down and event.xkbKeysym == 65307 then
            lockState:unlock()
        end
    end)

    window:open()
end

connections[#connections + 1] = backend:onOutputAdded(createSurface)
connections[#connections + 1] = lockState:onFinished(function()
    finished = true
    closeAll()
    backend:destroy()
end)

for _, output in ipairs(backend:getOutputs()) do
    createSurface(output)
end

backend:enterLoop()
