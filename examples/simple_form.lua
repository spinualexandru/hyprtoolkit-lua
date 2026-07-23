local htk = require("hyprtoolkit")

-- Simple Form Example for Hyprtoolkit Lua Bindings
-- This demonstrates creating a basic registration form using Lua

-- Create the backend (entry point)
local backend = htk.Backend.create()
local palette = backend:getPalette()
local connections = {}

-- Helper function for palette text color
local function textColor()
    return palette.text
end

-- Helper function for palette background color
local function bgColor()
    return palette.background
end

-- Helper function for alternate base color
local function altBaseColor()
    return palette.alternateBase
end

-- Create main window
local window = htk.WindowBuilder.begin()
    :appTitle("Lua Form Example")
    :appClass("hyprtoolkit-lua-form")
    :preferredSize(htk.Vector2D.new(450, 400))
    :minSize(htk.Vector2D.new(350, 300))
    :commence()

-- Background rectangle (fills window)
local bg = htk.RectangleBuilder.begin()
    :color(bgColor)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.PERCENT,
        htk.Vector2D.new(1, 1)
    ))
    :commence()

window.rootElement:addChild(bg)

-- Main content layout (column, centered)
local mainLayout = htk.ColumnLayoutBuilder.begin()
    :gap(12)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.AUTO,
        htk.Vector2D.new(0.85, 1)
    ))
    :commence()

mainLayout:setMargin(20)
mainLayout:setPositionMode(htk.PositionMode.ABSOLUTE)
mainLayout:setPositionFlag(htk.PositionFlag.HCENTER, true)

bg:addChild(mainLayout)

-- Title
local title = htk.TextBuilder.begin()
    :text("User Registration")
    :fontSize(htk.FontSize.new(htk.FontSizeBase.H1, 1.0))
    :color(textColor)
    :align(htk.FontAlignment.CENTER)
    :commence()

title:setPositionFlag(htk.PositionFlag.HCENTER, true)
mainLayout:addChild(title)

-- Subtitle
local subtitle = htk.TextBuilder.begin()
    :text("Please fill in your details below")
    :fontSize(htk.FontSize.new(htk.FontSizeBase.TEXT, 1.0))
    :color(function()
        return palette.text:darken(0.3)
    end)
    :align(htk.FontAlignment.CENTER)
    :commence()

subtitle:setPositionFlag(htk.PositionFlag.HCENTER, true)
mainLayout:addChild(subtitle)

-- Separator line
local separator = htk.RectangleBuilder.begin()
    :color(function()
        return palette.text:darken(0.7)
    end)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.ABSOLUTE,
        htk.Vector2D.new(0.6, 2)
    ))
    :commence()

separator:setMargin(8)
separator:setPositionFlag(htk.PositionFlag.HCENTER, true)
mainLayout:addChild(separator)

-- Name field label
local nameLabel = htk.TextBuilder.begin()
    :text("Full Name:")
    :fontSize(htk.FontSize.new(htk.FontSizeBase.TEXT, 1.0))
    :color(textColor)
    :commence()

mainLayout:addChild(nameLabel)

-- Name input field
local nameInput = htk.TextboxBuilder.begin()
    :placeholder("Enter your full name")
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.ABSOLUTE,
        htk.Vector2D.new(1, 32)
    ))
    :onTextEdited(function(textbox, text)
        print("[Form] Name changed to: " .. text)
    end)
    :commence()

mainLayout:addChild(nameInput)

-- Email field label
local emailLabel = htk.TextBuilder.begin()
    :text("Email Address:")
    :fontSize(htk.FontSize.new(htk.FontSizeBase.TEXT, 1.0))
    :color(textColor)
    :commence()

mainLayout:addChild(emailLabel)

-- Email input field
local emailInput = htk.TextboxBuilder.begin()
    :placeholder("you@example.com")
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.ABSOLUTE,
        htk.Vector2D.new(1, 32)
    ))
    :commence()

mainLayout:addChild(emailInput)

-- Priority slider row
local sliderRow = htk.RowLayoutBuilder.begin()
    :gap(12)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.AUTO,
        htk.Vector2D.new(1, 1)
    ))
    :commence()

local sliderLabel = htk.TextBuilder.begin()
    :text("Priority:")
    :fontSize(htk.FontSize.new(htk.FontSizeBase.TEXT, 1.0))
    :color(textColor)
    :commence()

local priorityValue = htk.TextBuilder.begin()
    :text("5")
    :fontSize(htk.FontSize.new(htk.FontSizeBase.TEXT, 1.0))
    :color(function()
        return palette.accent
    end)
    :commence()

local prioritySlider = htk.SliderBuilder.begin()
    :min(1)
    :max(10)
    :val(5)
    :snapInt(true)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.ABSOLUTE,
        htk.Vector2D.new(0.5, 14)
    ))
    :onChanged(function(slider, value)
        local intVal = math.floor(value + 0.5)
        priorityValue:rebuild():text(tostring(intVal)):commence()
        print("[Form] Priority set to: " .. intVal)
    end)
    :commence()

sliderRow:addChild(sliderLabel)
sliderRow:addChild(prioritySlider)
sliderRow:addChild(priorityValue)
mainLayout:addChild(sliderRow)

-- Category dropdown
local categoryRow = htk.RowLayoutBuilder.begin()
    :gap(12)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.AUTO,
        htk.Vector2D.new(1, 1)
    ))
    :commence()

local categoryLabel = htk.TextBuilder.begin()
    :text("Category:")
    :fontSize(htk.FontSize.new(htk.FontSizeBase.TEXT, 1.0))
    :color(textColor)
    :commence()

local categoryCombo = htk.ComboboxBuilder.begin()
    :items({"General Inquiry", "Technical Support", "Sales", "Feedback", "Other"})
    :currentItem(1)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.ABSOLUTE,
        htk.Vector2D.new(0.6, 28)
    ))
    :onChanged(function(combo, index)
        print("[Form] Category selected: " .. tostring(index))
    end)
    :commence()

categoryRow:addChild(categoryLabel)
categoryRow:addChild(categoryCombo)
mainLayout:addChild(categoryRow)

-- Checkbox row for newsletter
local checkboxRow = htk.RowLayoutBuilder.begin()
    :gap(10)
    :size(htk.DynamicSize.new(
        htk.SizeType.AUTO,
        htk.SizeType.AUTO,
        htk.Vector2D.new(1, 1)
    ))
    :commence()

local newsletterSubscribed = false

local newsletterCheck = htk.CheckboxBuilder.begin()
    :toggled(false)
    :onToggled(function(checkbox, state)
        newsletterSubscribed = state
        print("[Form] Newsletter subscription: " .. tostring(state))
    end)
    :commence()

local checkboxLabel = htk.TextBuilder.begin()
    :text("Subscribe to newsletter")
    :fontSize(htk.FontSize.new(htk.FontSizeBase.TEXT, 1.0))
    :color(textColor)
    :commence()

checkboxRow:addChild(newsletterCheck)
checkboxRow:addChild(checkboxLabel)
mainLayout:addChild(checkboxRow)

-- Terms checkbox
local termsRow = htk.RowLayoutBuilder.begin()
    :gap(10)
    :size(htk.DynamicSize.new(
        htk.SizeType.AUTO,
        htk.SizeType.AUTO,
        htk.Vector2D.new(1, 1)
    ))
    :commence()

local termsAccepted = false

local termsCheck = htk.CheckboxBuilder.begin()
    :toggled(false)
    :onToggled(function(checkbox, state)
        termsAccepted = state
    end)
    :commence()

local termsLabel = htk.TextBuilder.begin()
    :text("I agree to the terms and conditions")
    :fontSize(htk.FontSize.new(htk.FontSizeBase.TEXT, 1.0))
    :color(textColor)
    :commence()

termsRow:addChild(termsCheck)
termsRow:addChild(termsLabel)
mainLayout:addChild(termsRow)

-- Spacer
local spacer = htk.NullBuilder.begin()
    :size(htk.DynamicSize.new(
        htk.SizeType.ABSOLUTE,
        htk.SizeType.ABSOLUTE,
        htk.Vector2D.new(0, 16)
    ))
    :commence()

mainLayout:addChild(spacer)

-- Button row
local buttonRow = htk.RowLayoutBuilder.begin()
    :gap(12)
    :size(htk.DynamicSize.new(
        htk.SizeType.PERCENT,
        htk.SizeType.AUTO,
        htk.Vector2D.new(1, 1)
    ))
    :commence()

-- Right-align buttons with a spacer
local buttonSpacer = htk.NullBuilder.begin():commence()
buttonSpacer:setGrow(true)

-- Cancel button
local cancelButton = htk.ButtonBuilder.begin()
    :label("Cancel")
    :size(htk.DynamicSize.new(
        htk.SizeType.AUTO,
        htk.SizeType.AUTO,
        htk.Vector2D.new(1, 1)
    ))
    :onMainClick(function(btn)
        print("[Form] Cancelled")
        window:close()
        backend:destroy()
    end)
    :commence()

-- Submit button
local submitButton = htk.ButtonBuilder.begin()
    :label("Submit")
    :size(htk.DynamicSize.new(
        htk.SizeType.AUTO,
        htk.SizeType.AUTO,
        htk.Vector2D.new(1, 1)
    ))
    :onMainClick(function(btn)
        local name = nameInput:currentText()
        local email = emailInput:currentText()
        local category = categoryCombo:current()

        print("=== Form Submitted ===")
        print("Name: " .. name)
        print("Email: " .. email)
        print("Category: " .. tostring(category))
        print("Newsletter: " .. tostring(newsletterSubscribed))
        print("Terms accepted: " .. tostring(termsAccepted))
        print("======================")

        if not termsAccepted then
            print("[Error] You must accept the terms and conditions!")
            return
        end

        if name == "" then
            print("[Error] Name is required!")
            return
        end

        -- Success - update button text
        btn:rebuild():label("Submitted!"):commence()
    end)
    :commence()

buttonRow:addChild(buttonSpacer)
buttonRow:addChild(cancelButton)
buttonRow:addChild(submitButton)
mainLayout:addChild(buttonRow)

-- Handle window close request
connections[#connections + 1] = window:onCloseRequest(function()
    print("[Form] Window close requested")
    window:close()
    backend:destroy()
end)

-- Open window and run the event loop
print("[Form] Starting application...")
window:open()
backend:enterLoop()

print("[Form] Application exited")
