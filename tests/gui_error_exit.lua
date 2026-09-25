-- A script that fails after handing callbacks to Hyprtoolkit, but before entering the event loop,
-- must exit with status 1. Upstream tears the backend down (destroying pending idle, timer and
-- window callbacks) from an atexit handler after the Lua state has been closed, which used to
-- segfault in luaL_unref.
--
-- Usage: hyprtoolkit-lua tests/gui_error_exit.lua [path/to/hyprtoolkit-lua]
-- The script re-runs itself with --child and checks how that child process exited.

if arg[1] ~= "--child" then
    local projectRoot = assert(arg[0]:match("^(.*)/tests/[^/]+$"))
    local runner = arg[1] or (projectRoot .. "/build/hyprtoolkit-lua")

    local function shellQuote(value)
        return "'" .. (value:gsub("'", "'\\''")) .. "'"
    end

    local _, how, code = os.execute(shellQuote(runner) .. " " .. shellQuote(arg[0]) .. " --child")
    assert(how == "exit" and code == 1,
        string.format("expected the failing script to exit with status 1, got %s %s", tostring(how), tostring(code)))

    print("hyprtoolkit error exit OK")
    return
end

local htk = require("hyprtoolkit")

local backend = assert(htk.Backend.create(), "failed to create Hyprtoolkit backend")
backend:setLogCallback(function(_, _) end)
backend:addIdle(function() end)
local timer = backend:addTimer(60000, function() end)
local outputConnection = backend:onOutputAdded(function(_) end)

local window = htk.WindowBuilder.begin()
    :appTitle("Hyprtoolkit Lua error exit")
    :appClass("hyprtoolkit-lua-error-exit")
    :preferredSize(htk.Vector2D.new(320, 200))
    :commence()
local closeConnection = window:onCloseRequest(function() end)

local background = htk.RectangleBuilder.begin()
    :color(function() return htk.Color.new(0.1, 0.1, 0.1) end)
    :size(htk.DynamicSize.percent(1, 1))
    :commence()
window.rootElement:addChild(background)

local button = htk.ButtonBuilder.begin()
    :label("Unreachable")
    :onMainClick(function(_) end)
    :commence()
background:addChild(button)

-- Registered from a coroutine that is collected before the state is closed.
coroutine.wrap(function()
    button:setMouseEnter(function(_) end)
end)()
collectgarbage()

assert(timer ~= nil and outputConnection ~= nil and closeConnection ~= nil)
error("expected failure after registering callbacks")
