-- local hyper = {"cmd", "alt", "ctrl","shift"}
-- A global variable for the Hyper Mode
hyper = hs.hotkey.modal.new({}, "F17")

hs.window.animationDuration = 0
hs.notify.new({title = "Hammerspoon", informativeText = "Hammerspoon Config Reloaded", withdrawAfter = 2}):send()

-- Enter Hyper Mode when F18 (Hyper/Capslock) is pressed
function enterHyperMode()
    hyper.triggered = false
    hyper:enter()
end

-- Leave Hyper Mode when F18 (Hyper/Capslock) is pressed,
-- send ESCAPE if no other keys are pressed.
function exitHyperMode()
    hyper:exit()
    -- if not hyper.triggered then
    --     hs.eventtap.keyStroke({}, "ESCAPE")
    -- end
end

-- Bind the Hyper Key
f18 = hs.hotkey.bind({}, "F18", enterHyperMode, exitHyperMode)

-- Toggle Capslock
hyper:bind(
    {},
    "tab",
    function()
        hs.hid.capslock.toggle()
    end
)

-- Config Reload
hyper:bind(
    {},
    "R",
    function()
        hs.reload()
    end
)

-- Defeat Paste Blocking
hyper:bind(
    {},
    "V",
    function()
        hs.eventtap.keyStrokes(hs.pasteboard.getContents())
    end
)

-- Toggle Apps
function toggleApp(name, alias)
    local focused = hs.window.focusedWindow()
    if focused then
        app = focused:application()
        -- hs.alert.show(app:title())
        if app:title() == name or app:title() == alias then
            app:hide()
            return
        end
    end
    hs.application.launchOrFocus(name)
end

hyper:bind(
    {},
    "C",
    function()
        toggleApp("Visual Studio Code", "Code")
    end
)
hyper:bind(
    {},
    "D",
    function()
        toggleApp("Finder")
    end
)
hyper:bind(
    {},
    "E",
    function()
        toggleApp("Microsoft Excel")
    end
)
hyper:bind(
    {},
    "G",
    function()
        toggleApp("Google Chrome")
    end
)
hyper:bind(
    {},
    "I",
    function()
        toggleApp("iTerm", "iTerm2")
    end
)
hyper:bind(
    {},
    "O",
    function()
        toggleApp("Microsoft Outlook", "Outlook")
    end
)
hyper:bind(
    {},
    "P",
    function()
        toggleApp("Preview")
    end
)
hyper:bind(
    {},
    "S",
    function()
        toggleApp("Slack")
    end
)
hyper:bind(
    {},
    "T",
    function()
        toggleApp("Sublime Text")
    end
)
hyper:bind(
    {},
    "W",
    function()
        toggleApp("WhatsApp")
    end
)
hyper:bind(
    {},
    "X",
    function()
        toggleApp("Firefox")
    end
)
hyper:bind(
    {},
    "Z",
    function()
        toggleApp("zoom.us")
    end
)

-- Toggle Mouse to Screen Center
hyper:bind(
    {},
    "M",
    function()
        local screen = hs.mouse.getCurrentScreen()
        local nextScreen = screen:previous()
        local rect = nextScreen:fullFrame()
        local center = hs.geometry.rectMidPoint(rect)
        hs.mouse.absolutePosition(center)
    end
)

-- Toggle Window Screens
MACBOOK_DISPLAY = "Built%-in Retina Display"
MAIN_DISPLAY = "S24R35x"
VERTICAL_DISPLAY = "DELL P2419H"

hyper_1 = false
hyper_2 = false
hyper_3 = false
hyper_4 = false

function moveToNextScreen(name, pos, dir)
    local focused = hs.window.focusedWindow()
    if name then
        focused:moveToScreen(name)
        if pos == "UP" then
            focused:moveToUnit({0, 0, 1, 0.5})()
        elseif pos == "DOWN" then
            focused:moveToUnit({0, 0.5, 1, 0.5})()
        else
            focused:maximize()
        end
    else
        if dir == "prev" then
            focused:moveToScreen(focused:screen():previous())
        else
            focused:moveToScreen(focused:screen():next())
        end
        local screenName = focused:screen():name()
        if screenName == MACBOOK_DISPLAY then
            focused:maximize()
        elseif screenName == MAIN_DISPLAY then
            focused:maximize()
        elseif screenName == VERTICAL_DISPLAY then
            focused:moveToUnit({0, 0, 1, 0.5})()
        else
            focused:maximize()
        end
    end
end

hyper:bind(
    {},
    "left",
    function()
        moveToNextScreen(nil, nil, "prev")
    end
)

hyper:bind(
    {},
    "right",
    function()
        moveToNextScreen()
    end
)

hyper:bind(
    {},
    "Q",
    function()
        local focused = hs.window.focusedWindow()
        if focused then
            local screenName = focused:screen():name()
            app = focused:application()
            hs.alert.show(screenName)
            hs.alert.show(app:title())
        else
            hs.alert.show("No Focused Window")
        end
    end
)

hyper:bind(
    {},
    "1",
    function()
        local focused = hs.window.focusedWindow()
        hyper_1 = true
        hyper_2 = false
        hyper_3 = false
        hyper_4 = false
        focused:moveToScreen(MACBOOK_DISPLAY)
        focused:maximize()
    end
)
hyper:bind(
    {},
    "2",
    function()
        local focused = hs.window.focusedWindow()
        if focused then
            hyper_1 = false
            hyper_2 = true
            hyper_3 = false
            hyper_4 = false
            focused:moveToScreen(MAIN_DISPLAY)
            focused:moveToUnit({0, 0, 1, 1})()
        end
    end
)
hyper:bind(
    {},
    "3",
    function()
        local focused = hs.window.focusedWindow()
        if focused then
            focused:moveToScreen(VERTICAL_DISPLAY)
            focused:moveToUnit({0, 0, 1, 0.5})()
        end
    end
)
hyper:bind(
    {},
    "4",
    function()
        local focused = hs.window.focusedWindow()
        if focused then
            focused:moveToScreen(VERTICAL_DISPLAY)
            focused:moveToUnit({0, 0.5, 1, 0.5})()
        end
    end
)
hyper:bind(
    {},
    "5",
    function()
        local focused = hs.window.focusedWindow()
        if focused then
            local screenName = focused:screen():name()
            focused:moveToScreen(VERTICAL_DISPLAY)
            focused:maximize()
        end
    end
)

-- Toggle Window Units
hyper_h = false
hyper_j = false
hyper_k = false
hyper_l = false
hyper_f = false

-- Fullscreen
hyper:bind(
    {},
    "F",
    function()
        if hyper_f == false then
            hs.window.focusedWindow():moveToUnit({0.05, 0.05, 0.9, 0.9})
            hyper_f = true
        else
            hs.window.focusedWindow():moveToUnit({0, 0, 1, 1})
            hyper_f = false
        end
    end
)

-- Left
hyper:bind(
    {},
    "H",
    function()
        if hyper_h == false then
            hs.window.focusedWindow():moveToUnit({0, 0, 0.5, 1})
            hyper_h = true
        else
            hs.window.focusedWindow():moveToUnit({0, 0, 1, 1})
            hyper_h = false
        end
    end
)

-- Down
hyper:bind(
    {},
    "J",
    function()
        if hyper_j == false then
            hs.window.focusedWindow():moveToUnit({0, 0.5, 1, 0.5})
            hyper_j = true
        else
            hs.window.focusedWindow():moveToUnit({0, 0, 1, 1})
            hyper_j = false
        end
    end
)

-- Up
hyper:bind(
    {},
    "K",
    function()
        if hyper_k == false then
            hs.window.focusedWindow():moveToUnit({0, 0, 1, 0.5})
            hyper_k = true
        else
            hs.window.focusedWindow():moveToUnit({0, 0, 1, 1})
            hyper_k = false
        end
    end
)

-- Right
hyper:bind(
    {},
    "L",
    function()
        if hyper_l == false then
            hs.window.focusedWindow():moveToUnit({0.5, 0, 0.5, 1})
            hyper_l = true
        else
            hs.window.focusedWindow():moveToUnit({0, 0, 1, 1})
            hyper_l = false
        end
    end
)

require("local_config")

-- END
