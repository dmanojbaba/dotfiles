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

-- Bind the Hyper key
f18 = hs.hotkey.bind({}, "F18", enterHyperMode, exitHyperMode)

-- Toggle Capslock
hyper:bind(
    {},
    "tab",
    function()
        hs.hid.capslock.toggle()
    end
)

-- Reload Config
hyper:bind(
    {},
    "R",
    function()
        hs.reload()
    end
)

-- Defeating Paste Blocking
hyper:bind(
    {},
    "V",
    function()
        hs.eventtap.keyStrokes(hs.pasteboard.getContents())
    end
)

-- Toggle Apps
function toggleApp(name, alias)
    focused = hs.window.focusedWindow()
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
        -- local focused = hs.window.focusedWindow()
        -- focused:minimize()
        local screen = hs.mouse.getCurrentScreen()
        local nextScreen = screen:previous()
        local rect = nextScreen:fullFrame()
        local center = hs.geometry.rectMidPoint(rect)
        hs.mouse.absolutePosition(center)
    end
)

-- Toggle Window Screens
MACBOOK_MONITOR = "Built%-in Retina Display"

function moveToNextScreen(name, pos)
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
        focused:moveToScreen(focused:screen():next())
        focused:maximize()
    end
end

hyper:bind(
    {},
    "N",
    function()
        moveToNextScreen()
    end
)

-- Toggle Window Units
hyper_h = false
hyper_j = false
hyper_k = false
hyper_l = false
hyper_f = false

-- Full Screen
hyper:bind(
    {},
    "F",
    function()
        if hyper_f then
            hs.window.focusedWindow():moveToUnit({0, 0, 1, 1})
            hyper_f = false
        else
            hs.window.focusedWindow():moveToUnit({0.05, 0.05, 0.9, 0.9})
            hyper_f = true
        end
    end
)

-- Left
hyper:bind(
    {},
    "H",
    function()
        if hyper_h then
            hs.window.focusedWindow():moveToUnit({0, 0, 1, 1})
            hyper_h = false
        else
            hs.window.focusedWindow():moveToUnit({0, 0, 0.5, 1})
            hyper_h = true
        end
    end
)

-- Down
hyper:bind(
    {},
    "J",
    function()
        if hyper_j then
            hs.window.focusedWindow():moveToUnit({0, 0, 1, 1})
            hyper_j = false
        else
            hs.window.focusedWindow():moveToUnit({0, 0.5, 1, 0.5})
            hyper_j = true
        end
    end
)

-- Up
hyper:bind(
    {},
    "K",
    function()
        if hyper_k then
            hs.window.focusedWindow():moveToUnit({0, 0, 1, 1})
            hyper_k = false
        else
            hs.window.focusedWindow():moveToUnit({0, 0, 1, 0.5})
            hyper_k = true
        end
    end
)

-- Right
hyper:bind(
    {},
    "L",
    function()
        if hyper_l then
            hs.window.focusedWindow():moveToUnit({0, 0, 1, 1})
            hyper_l = false
        else
            hs.window.focusedWindow():moveToUnit({0.5, 0, 0.5, 1})
            hyper_l = true
        end
    end
)

require("local_config")
-- END
