local htk = require("hyprtoolkit")

-- Windows 11 Theme Example for Hyprtoolkit Lua Bindings
-- A comprehensive Fluent Design-inspired Settings app

local backend = htk.Backend.create()
local palette = backend:getPalette()
local connections = {}

-- Detect dark mode from system palette
local isDark = palette.background.r < 0.5

-- Windows 11 Fluent Design color palettes
local colors
if isDark then
    colors = {
        -- Dark theme - rich contrast
        windowBg = htk.Color.new(0.08, 0.08, 0.08, 1.0),        -- #141414 - Deep dark
        micaBg = htk.Color.new(0.11, 0.11, 0.11, 0.97),         -- Mica dark
        cardBg = htk.Color.new(0.15, 0.15, 0.15, 1.0),          -- #262626
        cardHover = htk.Color.new(0.18, 0.18, 0.18, 1.0),       -- #2E2E2E
        cardBorder = htk.Color.new(0.20, 0.20, 0.20, 1.0),      -- #333333

        heroBg = htk.Color.new(0.12, 0.12, 0.12, 1.0),          -- Hero section
        heroAccent = htk.Color.new(0.0, 0.35, 0.65, 1.0),       -- Dark blue accent

        text = htk.Color.new(1.0, 1.0, 1.0, 1.0),               -- Pure white
        textSecondary = htk.Color.new(0.65, 0.65, 0.65, 1.0),   -- Muted
        textTertiary = htk.Color.new(0.45, 0.45, 0.45, 1.0),    -- Even more muted

        accent = htk.Color.new(0.38, 0.67, 1.0, 1.0),           -- #60ABFF - Bright blue
        accentDark = htk.Color.new(0.0, 0.47, 0.84, 1.0),       -- #0078D4
        accentLight = htk.Color.new(0.6, 0.8, 1.0, 1.0),        -- Light accent

        success = htk.Color.new(0.35, 0.75, 0.45, 1.0),         -- Green
        warning = htk.Color.new(1.0, 0.7, 0.2, 1.0),            -- Orange
        error = htk.Color.new(1.0, 0.4, 0.4, 1.0),              -- Red

        divider = htk.Color.new(0.25, 0.25, 0.25, 1.0),
        selected = htk.Color.new(0.15, 0.25, 0.40, 1.0),        -- Blue tinted selection

        avatarBg = htk.Color.new(0.0, 0.47, 0.84, 1.0),         -- Avatar background
    }
else
    colors = {
        -- Light theme - clean and bright
        windowBg = htk.Color.new(0.95, 0.95, 0.95, 1.0),        -- #F2F2F2
        micaBg = htk.Color.new(0.98, 0.98, 0.98, 0.85),         -- Mica light
        cardBg = htk.Color.new(1.0, 1.0, 1.0, 1.0),             -- Pure white
        cardHover = htk.Color.new(0.97, 0.97, 0.97, 1.0),
        cardBorder = htk.Color.new(0.90, 0.90, 0.90, 1.0),

        heroBg = htk.Color.new(0.92, 0.95, 1.0, 1.0),           -- Light blue tint
        heroAccent = htk.Color.new(0.85, 0.92, 1.0, 1.0),

        text = htk.Color.new(0.1, 0.1, 0.1, 1.0),               -- Near black
        textSecondary = htk.Color.new(0.4, 0.4, 0.4, 1.0),
        textTertiary = htk.Color.new(0.6, 0.6, 0.6, 1.0),

        accent = htk.Color.new(0.0, 0.47, 0.84, 1.0),           -- #0078D4 - Windows Blue
        accentDark = htk.Color.new(0.0, 0.35, 0.65, 1.0),
        accentLight = htk.Color.new(0.85, 0.93, 1.0, 1.0),

        success = htk.Color.new(0.1, 0.6, 0.2, 1.0),
        warning = htk.Color.new(0.9, 0.55, 0.0, 1.0),
        error = htk.Color.new(0.85, 0.2, 0.2, 1.0),

        divider = htk.Color.new(0.85, 0.85, 0.85, 1.0),
        selected = htk.Color.new(0.90, 0.95, 1.0, 1.0),

        avatarBg = htk.Color.new(0.0, 0.47, 0.84, 1.0),
    }
end

-- ============================================
-- SYSTEM INFORMATION HELPERS
-- ============================================

-- Read a file and return its contents
local function readFile(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*all")
    f:close()
    return content
end

-- Read first line of a file
local function readLine(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local line = f:read("*line")
    f:close()
    return line
end

-- Get hostname
local function getHostname()
    return readLine("/etc/hostname") or os.getenv("HOSTNAME") or "Unknown"
end

-- Get kernel version
local function getKernelVersion()
    local version = readLine("/proc/version")
    if version then
        return version:match("Linux version ([%d%.%-]+)") or "Unknown"
    end
    return "Unknown"
end

-- Get CPU model
local function getCpuModel()
    local cpuinfo = readFile("/proc/cpuinfo")
    if cpuinfo then
        local model = cpuinfo:match("model name%s*:%s*([^\n]+)")
        if model then
            -- Shorten common names
            model = model:gsub("%(R%)", "")
            model = model:gsub("%(TM%)", "")
            model = model:gsub("CPU ", "")
            model = model:gsub("%s+", " ")
            return model:sub(1, 40)  -- Truncate if too long
        end
    end
    return "Unknown CPU"
end

-- Get memory info (total and available in GB)
local function getMemoryInfo()
    local meminfo = readFile("/proc/meminfo")
    if meminfo then
        local total = meminfo:match("MemTotal:%s*(%d+)")
        local available = meminfo:match("MemAvailable:%s*(%d+)")
        if total and available then
            local totalGB = tonumber(total) / 1024 / 1024
            local availGB = tonumber(available) / 1024 / 1024
            local usedGB = totalGB - availGB
            local percent = math.floor((usedGB / totalGB) * 100)
            return {
                total = totalGB,
                available = availGB,
                used = usedGB,
                percent = percent
            }
        end
    end
    return { total = 0, available = 0, used = 0, percent = 0 }
end

-- Get uptime
local function getUptime()
    local uptime = readLine("/proc/uptime")
    if uptime then
        local seconds = tonumber(uptime:match("([%d%.]+)"))
        if seconds then
            local days = math.floor(seconds / 86400)
            local hours = math.floor((seconds % 86400) / 3600)
            local mins = math.floor((seconds % 3600) / 60)
            if days > 0 then
                return string.format("%dd %dh %dm", days, hours, mins)
            elseif hours > 0 then
                return string.format("%dh %dm", hours, mins)
            else
                return string.format("%dm", mins)
            end
        end
    end
    return "Unknown"
end

-- Get battery info
local function getBatteryInfo()
    local batPath = "/sys/class/power_supply/BAT0"
    local capacity = readLine(batPath .. "/capacity")
    local status = readLine(batPath .. "/status")
    if capacity then
        return {
            percent = tonumber(capacity) or 0,
            status = status or "Unknown",
            present = true
        }
    end
    -- Try BAT1
    batPath = "/sys/class/power_supply/BAT1"
    capacity = readLine(batPath .. "/capacity")
    status = readLine(batPath .. "/status")
    if capacity then
        return {
            percent = tonumber(capacity) or 0,
            status = status or "Unknown",
            present = true
        }
    end
    return { percent = 0, status = "N/A", present = false }
end

-- Get load average
local function getLoadAverage()
    local loadavg = readLine("/proc/loadavg")
    if loadavg then
        local one, five, fifteen = loadavg:match("([%d%.]+)%s+([%d%.]+)%s+([%d%.]+)")
        return {
            one = tonumber(one) or 0,
            five = tonumber(five) or 0,
            fifteen = tonumber(fifteen) or 0
        }
    end
    return { one = 0, five = 0, fifteen = 0 }
end

-- Get distro name from os-release
local function getDistro()
    local osrelease = readFile("/etc/os-release")
    if osrelease then
        local name = osrelease:match('PRETTY_NAME="([^"]+)"')
        return name or "Linux"
    end
    return "Linux"
end

-- Get current user
local function getUser()
    return os.getenv("USER") or "user"
end

-- Get desktop session
local function getDesktop()
    return os.getenv("XDG_CURRENT_DESKTOP") or os.getenv("DESKTOP_SESSION") or "Unknown"
end

-- Gather all system info
local sysinfo = {
    hostname = getHostname():gsub("%s+$", ""),
    kernel = getKernelVersion(),
    cpu = getCpuModel(),
    memory = getMemoryInfo(),
    uptime = getUptime(),
    battery = getBatteryInfo(),
    load = getLoadAverage(),
    distro = getDistro(),
    user = getUser(),
    desktop = getDesktop(),
}

-- State
local selectedNavIndex = 0
local nightLightEnabled = false
local focusAssistEnabled = true
local bluetoothEnabled = true
local wifiEnabled = true

-- Create main window
local window = htk.WindowBuilder.begin()
    :appTitle("Settings")
    :appClass("hyprtoolkit-win11-settings")
    :preferredSize(htk.Vector2D.new(1100, 750))
    :minSize(htk.Vector2D.new(900, 600))
    :commence()

-- ============================================
-- MAIN BACKGROUND
-- ============================================
local mainBg = htk.RectangleBuilder.begin()
    :color(function() return colors.windowBg end)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.PERCENT,
        htk.Vector2D.new(1, 1)
    ))
    :commence()

window.rootElement:addChild(mainBg)

-- Main horizontal layout
local mainRow = htk.RowLayoutBuilder.begin()
    :gap(0)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.PERCENT,
        htk.Vector2D.new(1, 1)
    ))
    :commence()

mainBg:addChild(mainRow)

-- ============================================
-- SIDEBAR (Navigation Pane)
-- ============================================
local sidebar = htk.RectangleBuilder.begin()
    :color(function() return colors.micaBg end)
    :size(htk.DynamicSize.new(
        htk.SizeType.ABSOLUTE,
        htk.SizeType.PERCENT,
        htk.Vector2D.new(300, 1)
    ))
    :commence()

mainRow:addChild(sidebar)

local sidebarLayout = htk.ColumnLayoutBuilder.begin()
    :gap(2)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.PERCENT,
        htk.Vector2D.new(1, 1)
    ))
    :commence()

sidebarLayout:setMargin(16)
sidebar:addChild(sidebarLayout)

-- ============================================
-- USER PROFILE SECTION (Top of sidebar)
-- ============================================
local profileCard = htk.RectangleBuilder.begin()
    :color(function() return colors.cardBg end)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.ABSOLUTE,
        htk.Vector2D.new(1, 72)
    ))
    :rounding(8)
    :commence()

sidebarLayout:addChild(profileCard)

-- Profile row layout
local profileRow = htk.RowLayoutBuilder.begin()
    :gap(12)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.PERCENT,
        htk.Vector2D.new(1, 1)
    ))
    :commence()

profileRow:setMargin(12)
profileCard:addChild(profileRow)

-- Avatar circle
local avatar = htk.RectangleBuilder.begin()
    :color(function() return colors.avatarBg end)
    :size(htk.DynamicSize.new(
        htk.SizeType.ABSOLUTE,
        htk.SizeType.ABSOLUTE,
        htk.Vector2D.new(48, 48)
    ))
    :rounding(24)
    :commence()

profileRow:addChild(avatar)

-- Avatar initial
local avatarText = htk.TextBuilder.begin()
    :text("A")
    :fontSize(htk.FontSize.new(htk.FontSizeBase.H2, 1.0))
    :color(function() return htk.Color.new(1, 1, 1, 1) end)
    :align(htk.FontAlignment.CENTER)
    :commence()

avatarText:setPositionMode(htk.PositionMode.ABSOLUTE)
avatarText:setPositionFlag(htk.PositionFlag.CENTER, true)
avatar:addChild(avatarText)

-- User info column
local userInfo = htk.ColumnLayoutBuilder.begin()
    :gap(2)
    :size(htk.DynamicSize.new(
        htk.SizeType.AUTO,
        htk.SizeType.AUTO,
        htk.Vector2D.new(1, 1)
    ))
    :commence()

profileRow:addChild(userInfo)

local userName = htk.TextBuilder.begin()
    :text(sysinfo.user)
    :fontSize(htk.FontSize.new(htk.FontSizeBase.TEXT, 1.1))
    :color(function() return colors.text end)
    :commence()

userInfo:addChild(userName)

local userEmail = htk.TextBuilder.begin()
    :text(sysinfo.user .. "@" .. sysinfo.hostname)
    :fontSize(htk.FontSize.new(htk.FontSizeBase.SMALL, 1.0))
    :color(function() return colors.textSecondary end)
    :commence()

userInfo:addChild(userEmail)

-- Spacer after profile
local profileSpacer = htk.NullBuilder.begin()
    :size(htk.DynamicSize.new(
        htk.SizeType.ABSOLUTE,
        htk.SizeType.ABSOLUTE,
        htk.Vector2D.new(0, 12)
    ))
    :commence()

sidebarLayout:addChild(profileSpacer)

-- ============================================
-- SEARCH BOX
-- ============================================
local searchBox = htk.RectangleBuilder.begin()
    :color(function() return colors.cardBg end)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.ABSOLUTE,
        htk.Vector2D.new(1, 40)
    ))
    :rounding(20)
    :borderColor(function() return colors.cardBorder end)
    :borderThickness(1)
    :commence()

sidebarLayout:addChild(searchBox)

local searchIcon = htk.TextBuilder.begin()
    :text("Search settings")
    :fontSize(htk.FontSize.new(htk.FontSizeBase.TEXT, 0.95))
    :color(function() return colors.textTertiary end)
    :commence()

searchIcon:setMargin(16)
searchIcon:setPositionMode(htk.PositionMode.ABSOLUTE)
searchIcon:setPositionFlag(htk.PositionFlag.VCENTER, true)
searchBox:addChild(searchIcon)

-- Spacer after search
local searchSpacer = htk.NullBuilder.begin()
    :size(htk.DynamicSize.new(
        htk.SizeType.ABSOLUTE,
        htk.SizeType.ABSOLUTE,
        htk.Vector2D.new(0, 16)
    ))
    :commence()

sidebarLayout:addChild(searchSpacer)

-- ============================================
-- NAVIGATION ITEMS
-- ============================================
local navItems = {
    {label = "System", selected = true},
    {label = "Bluetooth & devices"},
    {label = "Network & internet"},
    {label = "Personalization"},
    {label = "Apps"},
    {label = "Accounts"},
    {label = "Time & language"},
    {label = "Gaming"},
    {label = "Accessibility"},
    {label = "Privacy & security"},
    {label = "Windows Update"},
}

for i, item in ipairs(navItems) do
    local isSelected = (i == 1)

    local navItem = htk.RectangleBuilder.begin()
        :color(function()
            if isSelected then
                return colors.selected
            else
                return htk.Color.new(0, 0, 0, 0)
            end
        end)
        :size(htk.DynamicSize.new(
            htk.SizeType.PERCENT,
            htk.SizeType.ABSOLUTE,
            htk.Vector2D.new(1, 40)
        ))
        :rounding(6)
        :commence()

    sidebarLayout:addChild(navItem)

    -- Selection indicator bar
    if isSelected then
        local indicator = htk.RectangleBuilder.begin()
            :color(function() return colors.accent end)
            :size(htk.DynamicSize.new(
                htk.SizeType.ABSOLUTE,
                htk.SizeType.ABSOLUTE,
                htk.Vector2D.new(3, 18)
            ))
            :rounding(2)
            :commence()

        indicator:setMargin(4)
        indicator:setPositionMode(htk.PositionMode.ABSOLUTE)
        indicator:setPositionFlag(htk.PositionFlag.VCENTER, true)
        navItem:addChild(indicator)
    end

    local navLabel = htk.TextBuilder.begin()
        :text(item.label)
        :fontSize(htk.FontSize.new(htk.FontSizeBase.TEXT, 1.0))
        :color(function() return colors.text end)
        :commence()

    navLabel:setMargin(16)
    navLabel:setPositionMode(htk.PositionMode.ABSOLUTE)
    navLabel:setPositionFlag(htk.PositionFlag.VCENTER, true)
    navItem:addChild(navLabel)
end

-- ============================================
-- CONTENT AREA (Scrollable)
-- ============================================
local scrollArea = htk.ScrollAreaBuilder.begin()
    :scrollX(false)
    :scrollY(true)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.PERCENT,
        htk.Vector2D.new(0.3, 1)
    ))
    :commence()

scrollArea:setGrow(true)
mainRow:addChild(scrollArea)

-- Content column - use 90% width with ABSOLUTE + HCENTER (per C++ test pattern)
local contentScroll = htk.ColumnLayoutBuilder.begin()
    :gap(16)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.AUTO,
        htk.Vector2D.new(0.9, 1)
    ))
    :commence()

contentScroll:setMargin(16)
contentScroll:setPositionMode(htk.PositionMode.ABSOLUTE)
contentScroll:setPositionFlag(htk.PositionFlag.HCENTER, true)
scrollArea:addChild(contentScroll)

-- ============================================
-- PAGE HEADER
-- ============================================
local pageTitle = htk.TextBuilder.begin()
    :text("System")
    :fontSize(htk.FontSize.new(htk.FontSizeBase.H1, 1.4))
    :color(function() return colors.text end)
    :commence()

pageTitle:setPositionMode(htk.PositionMode.ABSOLUTE)
pageTitle:setPositionFlag(htk.PositionFlag.HCENTER, true)

contentScroll:addChild(pageTitle)

-- ============================================
-- HERO CARD (Device Info)
-- ============================================
local heroCard = htk.RectangleBuilder.begin()
    :color(function() return colors.heroBg end)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.ABSOLUTE,
        htk.Vector2D.new(1, 120)
    ))
    :rounding(12)
    :borderColor(function() return colors.cardBorder end)
    :borderThickness(1)
    :commence()

contentScroll:addChild(heroCard)

local heroContent = htk.RowLayoutBuilder.begin()
    :gap(24)
    :size(htk.DynamicSize.new(
        htk.SizeType.AUTO,
        htk.SizeType.AUTO,
        htk.Vector2D.new(1, 1)
    ))
    :commence()

heroContent:setMargin(24)
heroContent:setPositionMode(htk.PositionMode.ABSOLUTE)
heroContent:setPositionFlag(htk.PositionFlag.CENTER, true)
heroCard:addChild(heroContent)

-- Device icon placeholder (large circle)
local deviceIcon = htk.RectangleBuilder.begin()
    :color(function() return colors.accent end)
    :size(htk.DynamicSize.new(
        htk.SizeType.ABSOLUTE,
        htk.SizeType.ABSOLUTE,
        htk.Vector2D.new(72, 72)
    ))
    :rounding(12)
    :commence()

deviceIcon:setPositionMode(htk.PositionMode.ABSOLUTE)
deviceIcon:setPositionFlag(htk.PositionFlag.VCENTER, true)
heroContent:addChild(deviceIcon)

local deviceIconText = htk.TextBuilder.begin()
    :text("PC")
    :fontSize(htk.FontSize.new(htk.FontSizeBase.H2, 1.0))
    :color(function() return htk.Color.new(1, 1, 1, 1) end)
    :align(htk.FontAlignment.CENTER)
    :commence()

deviceIconText:setPositionMode(htk.PositionMode.ABSOLUTE)
deviceIconText:setPositionFlag(htk.PositionFlag.CENTER, true)
deviceIcon:addChild(deviceIconText)

-- Device info
local deviceInfo = htk.ColumnLayoutBuilder.begin()
    :gap(6)
    :size(htk.DynamicSize.new(
        htk.SizeType.AUTO,
        htk.SizeType.AUTO,
        htk.Vector2D.new(1, 1)
    ))
    :commence()

deviceInfo:setPositionMode(htk.PositionMode.ABSOLUTE)
deviceInfo:setPositionFlag(htk.PositionFlag.VCENTER, true)
heroContent:addChild(deviceInfo)

local deviceName = htk.TextBuilder.begin()
    :text(sysinfo.hostname:upper())
    :fontSize(htk.FontSize.new(htk.FontSizeBase.H3, 1.0))
    :color(function() return colors.text end)
    :commence()

deviceInfo:addChild(deviceName)

local deviceDetails = htk.TextBuilder.begin()
    :text(sysinfo.distro .. "  |  " .. sysinfo.desktop)
    :fontSize(htk.FontSize.new(htk.FontSizeBase.SMALL, 1.0))
    :color(function() return colors.textSecondary end)
    :commence()

deviceInfo:addChild(deviceDetails)

local uptimeText = htk.TextBuilder.begin()
    :text("Uptime: " .. sysinfo.uptime)
    :fontSize(htk.FontSize.new(htk.FontSizeBase.TEXT, 1.0))
    :color(function() return colors.accent end)
    :commence()

deviceInfo:addChild(uptimeText)

-- ============================================
-- SYSTEM MONITOR WIDGETS
-- ============================================
local monitorLabel = htk.TextBuilder.begin()
    :text("System Monitor")
    :fontSize(htk.FontSize.new(htk.FontSizeBase.TEXT, 1.0))
    :color(function() return colors.textSecondary end)
    :commence()

contentScroll:addChild(monitorLabel)

-- Helper function to create a stat widget with progress bar
local function createStatWidget(title, value, percent, accentColor)
    local widget = htk.RectangleBuilder.begin()
        :color(function() return colors.cardBg end)
        :size(htk.DynamicSize.new(
            htk.SizeType.ABSOLUTE,
            htk.SizeType.ABSOLUTE,
            htk.Vector2D.new(140, 100)
        ))
        :rounding(12)
        :borderColor(function() return colors.cardBorder end)
        :borderThickness(1)
        :commence()

    -- Title (positioned at top)
    local titleText = htk.TextBuilder.begin()
        :text(title)
        :fontSize(htk.FontSize.new(htk.FontSizeBase.SMALL, 1.0))
        :color(function() return colors.textSecondary end)
        :commence()

    titleText:setMargin(12)
    titleText:setPositionMode(htk.PositionMode.ABSOLUTE)
    titleText:setPositionFlag(htk.PositionFlag.TOP, true)
    titleText:setPositionFlag(htk.PositionFlag.LEFT, true)
    widget:addChild(titleText)

    -- Value (large, centered)
    local valueText = htk.TextBuilder.begin()
        :text(value)
        :fontSize(htk.FontSize.new(htk.FontSizeBase.H2, 1.0))
        :color(function() return accentColor or colors.accent end)
        :commence()

    valueText:setPositionMode(htk.PositionMode.ABSOLUTE)
    valueText:setPositionFlag(htk.PositionFlag.CENTER, true)
    widget:addChild(valueText)

    -- Progress bar background (at bottom)
    local barBg = htk.RectangleBuilder.begin()
        :color(function() return colors.cardBorder end)
        :size(htk.DynamicSize.new(
            htk.SizeType.ABSOLUTE,
            htk.SizeType.ABSOLUTE,
            htk.Vector2D.new(116, 6)
        ))
        :rounding(3)
        :commence()

    barBg:setMargin(12)
    barBg:setPositionMode(htk.PositionMode.ABSOLUTE)
    barBg:setPositionFlag(htk.PositionFlag.BOTTOM, true)
    barBg:setPositionFlag(htk.PositionFlag.LEFT, true)
    widget:addChild(barBg)

    -- Progress bar fill
    local fillWidth = math.max(1, math.floor(116 * percent / 100))
    local barFill = htk.RectangleBuilder.begin()
        :color(function() return accentColor or colors.accent end)
        :size(htk.DynamicSize.new(
            htk.SizeType.ABSOLUTE,
            htk.SizeType.PERCENT,
            htk.Vector2D.new(fillWidth, 1)
        ))
        :rounding(3)
        :commence()

    barFill:setPositionMode(htk.PositionMode.ABSOLUTE)
    barBg:addChild(barFill)

    return widget
end

-- Stats container (rectangle wrapper for row layout)
local statsContainer = htk.RectangleBuilder.begin()
    :color(function() return htk.Color.new(0, 0, 0, 0) end)  -- Transparent
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.ABSOLUTE,
        htk.Vector2D.new(1, 120)
    ))
    :commence()

contentScroll:addChild(statsContainer)

-- Stats row
local statsRow = htk.RowLayoutBuilder.begin()
    :gap(12)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.PERCENT,
        htk.Vector2D.new(1, 1)
    ))
    :commence()

statsRow:setPositionMode(htk.PositionMode.ABSOLUTE)
statsContainer:addChild(statsRow)

-- CPU Load widget (use load average as percentage - cap at 100)
local cpuPercent = math.min(100, sysinfo.load.one * 25)  -- Rough approximation
statsRow:addChild(createStatWidget(
    "CPU LOAD",
    string.format("%.1f", sysinfo.load.one),
    cpuPercent,
    htk.Color.new(0.3, 0.7, 1.0, 1.0)  -- Blue
))

-- Memory widget
statsRow:addChild(createStatWidget(
    "MEMORY",
    string.format("%d%%", sysinfo.memory.percent),
    sysinfo.memory.percent,
    htk.Color.new(0.6, 0.4, 0.9, 1.0)  -- Purple
))

-- Battery widget (or uptime if no battery)
if sysinfo.battery.present then
    local batColor
    if sysinfo.battery.percent > 50 then
        batColor = htk.Color.new(0.3, 0.8, 0.4, 1.0)  -- Green
    elseif sysinfo.battery.percent > 20 then
        batColor = htk.Color.new(1.0, 0.7, 0.2, 1.0)  -- Orange
    else
        batColor = htk.Color.new(1.0, 0.3, 0.3, 1.0)  -- Red
    end
    statsRow:addChild(createStatWidget(
        "BATTERY",
        string.format("%d%%", sysinfo.battery.percent),
        sysinfo.battery.percent,
        batColor
    ))
else
    -- Show uptime instead
    local uptimeHours = tonumber(readLine("/proc/uptime"):match("([%d%.]+)")) / 3600
    statsRow:addChild(createStatWidget(
        "UPTIME",
        sysinfo.uptime,
        math.min(100, uptimeHours),  -- 100 hours = full bar
        htk.Color.new(0.3, 0.8, 0.4, 1.0)
    ))
end

-- Disk/Storage widget (simplified - show used percentage based on memory as proxy)
statsRow:addChild(createStatWidget(
    "LOAD AVG",
    string.format("%.2f", sysinfo.load.fifteen),
    math.min(100, sysinfo.load.fifteen * 25),
    htk.Color.new(1.0, 0.6, 0.3, 1.0)  -- Orange
))

-- ============================================
-- SETTINGS CARDS
-- ============================================
local function createSettingCard(title, description, hasToggle, toggleState, hasSlider, sliderValue)
    local card = htk.RectangleBuilder.begin()
        :color(function() return colors.cardBg end)
        :size(htk.DynamicSize.new(
            htk.SizeType.PERCENT,
            htk.SizeType.ABSOLUTE,
            htk.Vector2D.new(1, hasSlider and 80 or 64)
        ))
        :rounding(8)
        :borderColor(function() return colors.cardBorder end)
        :borderThickness(1)
        :commence()

    local cardContent = htk.RowLayoutBuilder.begin()
        :gap(16)
        :size(htk.DynamicSize.new(
            htk.SizeType.PERCENT,
            htk.SizeType.PERCENT,
            htk.Vector2D.new(1, 1)
        ))
        :commence()

    cardContent:setMargin(16)
    card:addChild(cardContent)

    -- Text column
    local textCol = htk.ColumnLayoutBuilder.begin()
        :gap(4)
        :size(htk.DynamicSize.new(
            htk.SizeType.PERCENT,
            htk.SizeType.AUTO,
            htk.Vector2D.new(1, 1)
        ))
        :commence()

    textCol:setGrow(true)
    textCol:setPositionMode(htk.PositionMode.ABSOLUTE)
    textCol:setPositionFlag(htk.PositionFlag.VCENTER, true)
    cardContent:addChild(textCol)

    local titleText = htk.TextBuilder.begin()
        :text(title)
        :fontSize(htk.FontSize.new(htk.FontSizeBase.TEXT, 1.0))
        :color(function() return colors.text end)
        :commence()

    textCol:addChild(titleText)

    if description then
        local descText = htk.TextBuilder.begin()
            :text(description)
            :fontSize(htk.FontSize.new(htk.FontSizeBase.SMALL, 1.0))
            :color(function() return colors.textSecondary end)
            :commence()

        textCol:addChild(descText)
    end

    if hasSlider then
        local slider = htk.SliderBuilder.begin()
            :min(0)
            :max(100)
            :val(sliderValue or 75)
            :size(htk.DynamicSize.new(
                htk.SizeType.PERCENT,
                htk.SizeType.ABSOLUTE,
                htk.Vector2D.new(0.5, 8)
            ))
            :onChanged(function(s, val)
                print("[Settings] " .. title .. ": " .. math.floor(val) .. "%")
            end)
            :commence()

        textCol:addChild(slider)
    end

    if hasToggle then
        local toggle = htk.CheckboxBuilder.begin()
            :toggled(toggleState or false)
            :onToggled(function(cb, state)
                print("[Settings] " .. title .. ": " .. tostring(state))
            end)
            :commence()

        toggle:setPositionMode(htk.PositionMode.ABSOLUTE)
        toggle:setPositionFlag(htk.PositionFlag.VCENTER, true)
        cardContent:addChild(toggle)
    else
        -- Arrow indicator
        local arrow = htk.TextBuilder.begin()
            :text(">")
            :fontSize(htk.FontSize.new(htk.FontSizeBase.H3, 1.0))
            :color(function() return colors.textTertiary end)
            :commence()

        arrow:setPositionMode(htk.PositionMode.ABSOLUTE)
        arrow:setPositionFlag(htk.PositionFlag.VCENTER, true)
        cardContent:addChild(arrow)
    end

    return card
end

-- ============================================
-- PROCESSOR SECTION
-- ============================================
local cpuLabel = htk.TextBuilder.begin()
    :text("Processor")
    :fontSize(htk.FontSize.new(htk.FontSizeBase.TEXT, 1.0))
    :color(function() return colors.textSecondary end)
    :commence()

contentScroll:addChild(cpuLabel)

contentScroll:addChild(createSettingCard(
    "CPU",
    sysinfo.cpu,
    false, false, false
))

local loadStr = string.format("%.2f / %.2f / %.2f (1/5/15 min)",
    sysinfo.load.one, sysinfo.load.five, sysinfo.load.fifteen)
contentScroll:addChild(createSettingCard(
    "Load Average",
    loadStr,
    false, false, false
))

-- ============================================
-- MEMORY SECTION
-- ============================================
local memLabel = htk.TextBuilder.begin()
    :text("Memory")
    :fontSize(htk.FontSize.new(htk.FontSizeBase.TEXT, 1.0))
    :color(function() return colors.textSecondary end)
    :commence()

contentScroll:addChild(memLabel)

local memDesc = string.format("%.1f GB used of %.1f GB total",
    sysinfo.memory.used, sysinfo.memory.total)
contentScroll:addChild(createSettingCard(
    "RAM Usage",
    memDesc,
    false, nil, true, sysinfo.memory.percent
))

-- ============================================
-- POWER & BATTERY SECTION
-- ============================================
local powerLabel = htk.TextBuilder.begin()
    :text("Power & battery")
    :fontSize(htk.FontSize.new(htk.FontSizeBase.TEXT, 1.0))
    :color(function() return colors.textSecondary end)
    :commence()

contentScroll:addChild(powerLabel)

if sysinfo.battery.present then
    local batDesc = string.format("%s - %d%%", sysinfo.battery.status, sysinfo.battery.percent)
    contentScroll:addChild(createSettingCard(
        "Battery",
        batDesc,
        false, nil, true, sysinfo.battery.percent
    ))
else
    contentScroll:addChild(createSettingCard(
        "Battery",
        "No battery detected - AC power",
        false, false, false
    ))
end

contentScroll:addChild(createSettingCard("Battery saver", "Extend battery life when low", true, false, false))

-- ============================================
-- DISPLAY SECTION
-- ============================================
local displayLabel = htk.TextBuilder.begin()
    :text("Display")
    :fontSize(htk.FontSize.new(htk.FontSizeBase.TEXT, 1.0))
    :color(function() return colors.textSecondary end)
    :commence()

contentScroll:addChild(displayLabel)

contentScroll:addChild(createSettingCard("Brightness", "Adjust screen brightness", false, nil, true, 75))
contentScroll:addChild(createSettingCard("Night light", "Reduce blue light in the evening", true, nightLightEnabled, false))

-- ============================================
-- EVENT HANDLERS
-- ============================================
connections[#connections + 1] = window:onCloseRequest(function()
    print("[Settings] Closing...")
    window:close()
    backend:destroy()
end)

connections[#connections + 1] = window:onKeyboardKey(function(event)
    if event.down and event.xkbKeysym == 65307 then
        window:close()
        backend:destroy()
    end
end)

-- ============================================
-- START
-- ============================================
print("=========================================")
print("  Windows 11 Settings - Lua Demo")
print("=========================================")
print("Theme:    " .. (isDark and "Dark Mode" or "Light Mode"))
print("Host:     " .. sysinfo.hostname)
print("User:     " .. sysinfo.user)
print("Distro:   " .. sysinfo.distro)
print("Desktop:  " .. sysinfo.desktop)
print("Kernel:   " .. sysinfo.kernel)
print("CPU:      " .. sysinfo.cpu)
print("Memory:   " .. string.format("%.1f/%.1f GB (%d%%)",
    sysinfo.memory.used, sysinfo.memory.total, sysinfo.memory.percent))
print("Uptime:   " .. sysinfo.uptime)
if sysinfo.battery.present then
    print("Battery:  " .. sysinfo.battery.percent .. "% (" .. sysinfo.battery.status .. ")")
end
print("Load:     " .. string.format("%.2f %.2f %.2f",
    sysinfo.load.one, sysinfo.load.five, sysinfo.load.fifteen))
print("=========================================")
print("Press Escape to close")
print("=========================================")

window:open()
backend:enterLoop()

print("[Settings] Application exited")
