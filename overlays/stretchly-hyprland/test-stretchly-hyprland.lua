-- Unit tests for stretchly-hyprland.lua using a fake Hyprland Lua API.
--
-- Usage: lua test-stretchly-hyprland.lua path/to/stretchly-hyprland.lua

local module_path = assert(arg[1], "usage: lua test-stretchly-hyprland.lua path/to/stretchly-hyprland.lua")

-- Fake Hyprland

local function monitor(name, width, height, options)
  options = options or {}
  return {
    name = name,
    width = width,
    height = height,
    scale = options.scale or 1.0,
    transform = options.transform or 0,
    is_mirror = options.is_mirror or false,
  }
end

local function new_hyprland(monitors)
  local fake = {
    monitors = monitors,
    windows = {},
    subscriptions = {},
    dispatched = {},
    next_address = 1,
  }

  local function find_monitor(name)
    for _, m in ipairs(fake.monitors) do
      if m.name == name then
        return m
      end
    end
  end

  local function find_window(selector)
    local address = assert(selector:match("^address:(.+)$"), "unexpected window selector " .. selector)
    return fake.windows[address]
  end

  local function dispatcher(kind)
    return function(args)
      return { kind = kind, args = args }
    end
  end

  local hl = {
    dsp = {
      focus = dispatcher("focus"),
      window = {
        move = dispatcher("move"),
        pin = dispatcher("pin"),
        center = dispatcher("center"),
      },
    },
  }

  function hl.get_monitors()
    return fake.monitors
  end

  function hl.get_window(selector)
    return find_window(selector)
  end

  function hl.on(event, callback)
    local subscription = { event = event, callback = callback, active = true }
    function subscription:is_active()
      return self.active
    end
    function subscription:remove()
      self.active = false
    end
    table.insert(fake.subscriptions, subscription)
    return subscription
  end

  function hl.dispatch(d)
    table.insert(fake.dispatched, d)
    local window = d.args.window and find_window(d.args.window)
    if d.kind == "move" then
      assert(window, "move must target a window explicitly")
      assert(d.args.follow == false, "move must not move focus along with the window")
      window.monitor = assert(find_monitor(d.args.monitor), "unknown monitor " .. tostring(d.args.monitor))
    elseif d.kind == "pin" then
      assert(window, "pin must target a window explicitly")
      assert(d.args.action == "enable", "pin must enable pinning instead of toggling it")
      window.pinned = true
    elseif d.kind == "center" then
      assert(window, "center must target a window explicitly")
      window.centered = true
    else
      error("unexpected dispatcher " .. d.kind)
    end
  end

  function fake.emit(event, window)
    for _, subscription in ipairs(fake.subscriptions) do
      if subscription.active and subscription.event == event then
        subscription.callback(window)
      end
    end
  end

  -- Open a window the way Hyprland does: the title event arrives before the window has a size or monitor.
  function fake.open(class, title, width, height, monitor_name)
    local address = string.format("0x%x", fake.next_address)
    fake.next_address = fake.next_address + 1
    local window = {
      address = address,
      class = class,
      title = title,
      size = { x = 0, y = 0 },
      monitor = nil,
      pinned = false,
    }
    fake.windows[address] = window
    fake.emit("window.title", window)
    window.size = { x = width, y = height }
    window.monitor = find_monitor(monitor_name)
    fake.emit("window.open", window)
    return window
  end

  function fake.close(window)
    fake.emit("window.close", window)
    fake.windows[window.address] = nil
  end

  function fake.active_subscriptions()
    local count = 0
    for _, subscription in ipairs(fake.subscriptions) do
      if subscription.active then
        count = count + 1
      end
    end
    return count
  end

  return fake, hl
end

local function load_handler(monitors)
  local fake, hl = new_hyprland(monitors)
  _G.hl = hl
  _G.stretchly_break_subscriptions = nil
  dofile(module_path)
  return fake
end

local function open_break(fake, width, height, monitor_name)
  return fake.open("stretchly", "Time to take a break!", width, height, monitor_name)
end

local function laptop_and_external()
  return { monitor("eDP-1", 1920, 1080), monitor("DP-13", 2560, 1440) }
end

-- Tests

local tests = {}

local function expect_equal(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)), 2)
  end
end

local function expect_placed(window, monitor_name)
  expect_equal(window.monitor and window.monitor.name, monitor_name, "monitor of " .. window.address)
  expect_equal(window.pinned, true, "pinned " .. window.address)
  expect_equal(window.centered, true, "centered " .. window.address)
end

tests["places each break window on the monitor matching its size"] = function()
  local fake = load_handler(laptop_and_external())
  -- Hyprland opens both windows on the focused monitor.
  local laptop = open_break(fake, 1920, 1080, "DP-13")
  local external = open_break(fake, 2560, 1440, "DP-13")
  expect_placed(laptop, "eDP-1")
  expect_placed(external, "DP-13")
end

tests["places windows regardless of the order they open in"] = function()
  local fake = load_handler(laptop_and_external())
  local external = open_break(fake, 2560, 1440, "eDP-1")
  local laptop = open_break(fake, 1920, 1080, "eDP-1")
  expect_placed(external, "DP-13")
  expect_placed(laptop, "eDP-1")
end

tests["ignores the title event before the window has a size"] = function()
  local fake = load_handler(laptop_and_external())
  -- A window that never opens must not claim a monitor.
  local window = { address = "0xdead", class = "stretchly", title = "Time to take a break!", size = { x = 0, y = 0 } }
  fake.windows[window.address] = window
  fake.emit("window.title", window)
  expect_equal(#fake.dispatched, 0, "dispatches for a window without a size")
  local laptop = open_break(fake, 1920, 1080, "DP-13")
  expect_placed(laptop, "eDP-1")
end

tests["places a window whose title changes to the break title after opening"] = function()
  local fake = load_handler(laptop_and_external())
  local window = fake.open("stretchly", "Loading", 1920, 1080, "DP-13")
  expect_equal(#fake.dispatched, 0, "dispatches before the break title")
  window.title = "Time to take a break!"
  fake.emit("window.title", window)
  expect_placed(window, "eDP-1")
end

tests["ignores windows that aren't Stretchly breaks"] = function()
  local fake = load_handler(laptop_and_external())
  fake.open("foot", "Time to take a break!", 1920, 1080, "DP-13")
  fake.open("stretchly", "Preferences", 1920, 1080, "DP-13")
  expect_equal(#fake.dispatched, 0, "dispatches for other windows")
end

tests["accepts the other class and title variants Stretchly uses"] = function()
  local fake = load_handler(laptop_and_external())
  local first = fake.open("electron", "Stretchly", 1920, 1080, "DP-13")
  local second = fake.open("Stretchly", "stretchly", 2560, 1440, "eDP-1")
  expect_placed(first, "eDP-1")
  expect_placed(second, "DP-13")
end

tests["only places a window once"] = function()
  local fake = load_handler(laptop_and_external())
  local window = open_break(fake, 1920, 1080, "DP-13")
  local dispatched = #fake.dispatched
  fake.emit("window.title", window)
  fake.emit("window.open", window)
  expect_equal(#fake.dispatched, dispatched, "dispatches after the window was placed")
end

tests["gives identical monitors one break window each"] = function()
  local fake = load_handler({ monitor("DP-1", 2560, 1440), monitor("DP-2", 2560, 1440) })
  local first = open_break(fake, 2560, 1440, "DP-1")
  local second = open_break(fake, 2560, 1440, "DP-1")
  expect_placed(first, "DP-1")
  expect_placed(second, "DP-2")
end

tests["frees a monitor when its break window closes"] = function()
  local fake = load_handler({ monitor("DP-1", 2560, 1440), monitor("DP-2", 2560, 1440) })
  local first = open_break(fake, 2560, 1440, "DP-1")
  open_break(fake, 2560, 1440, "DP-1")
  fake.close(first)
  local next_break = open_break(fake, 2560, 1440, "DP-2")
  expect_placed(next_break, "DP-1")
end

tests["frees a monitor when its break window disappears without a close event"] = function()
  local fake = load_handler({ monitor("DP-1", 2560, 1440) })
  local first = open_break(fake, 2560, 1440, "DP-1")
  fake.windows[first.address] = nil
  local next_break = open_break(fake, 2560, 1440, "DP-1")
  expect_placed(next_break, "DP-1")
end

tests["leaves a window alone when every monitor already has a break window"] = function()
  local fake = load_handler({ monitor("DP-1", 2560, 1440) })
  open_break(fake, 2560, 1440, "DP-1")
  local dispatched = #fake.dispatched
  local extra = open_break(fake, 2560, 1440, "DP-1")
  expect_equal(#fake.dispatched, dispatched, "dispatches for a window without a free monitor")
  expect_equal(extra.pinned, false, "pinned extra window")
end

tests["prefers a monitor the window fits on over a closer one it doesn't"] = function()
  local fake = load_handler({ monitor("small", 1900, 1080), monitor("large", 3840, 2160) })
  local window = open_break(fake, 1920, 1080, "small")
  expect_placed(window, "large")
end

tests["falls back to the closest free monitor when the window fits on none"] = function()
  local fake = load_handler({ monitor("eDP-1", 1920, 1080), monitor("DP-13", 2560, 1440) })
  local window = open_break(fake, 2600, 1500, "eDP-1")
  expect_placed(window, "DP-13")
end

tests["compares against the logical size of scaled monitors"] = function()
  local fake = load_handler({ monitor("eDP-1", 2880, 1800, { scale = 2.0 }), monitor("DP-1", 1920, 1080) })
  -- Electron sizes the window to the logical size, 1440x900.
  local laptop = open_break(fake, 1440, 900, "DP-1")
  local external = open_break(fake, 1920, 1080, "DP-1")
  expect_placed(laptop, "eDP-1")
  expect_placed(external, "DP-1")
end

tests["accounts for fractional scaling rounding"] = function()
  local fake = load_handler({ monitor("eDP-1", 1920, 1200, { scale = 1.25 }), monitor("DP-1", 1920, 1080) })
  -- 1920 / 1.25 = 1536 and 1200 / 1.25 = 960.
  local laptop = open_break(fake, 1536, 960, "DP-1")
  expect_placed(laptop, "eDP-1")
end

tests["swaps the dimensions of rotated monitors"] = function()
  local fake = load_handler({ monitor("DP-1", 2560, 1440, { transform = 1 }), monitor("DP-2", 2560, 1440) })
  local portrait = open_break(fake, 1440, 2560, "DP-2")
  local landscape = open_break(fake, 2560, 1440, "DP-2")
  expect_placed(portrait, "DP-1")
  expect_placed(landscape, "DP-2")
end

tests["skips mirrored monitors"] = function()
  local fake = load_handler({ monitor("DP-1", 1920, 1080, { is_mirror = true }), monitor("DP-2", 2560, 1440) })
  local window = open_break(fake, 1920, 1080, "DP-1")
  expect_placed(window, "DP-2")
end

tests["removes its old subscriptions when the config reloads"] = function()
  local fake = load_handler(laptop_and_external())
  local subscriptions = fake.active_subscriptions()
  dofile(module_path)
  expect_equal(fake.active_subscriptions(), subscriptions, "active subscriptions after reloading")
  local laptop = open_break(fake, 1920, 1080, "DP-13")
  expect_placed(laptop, "eDP-1")
  -- Only the current handler acts: move, pin, and center once each.
  expect_equal(#fake.dispatched, 3, "dispatches after reloading")
end

-- Runner

local names = {}
for name in pairs(tests) do
  table.insert(names, name)
end
table.sort(names)

local failures = 0
for _, name in ipairs(names) do
  local ok, err = pcall(tests[name])
  if ok then
    print("PASS " .. name)
  else
    failures = failures + 1
    print("FAIL " .. name .. "\n  " .. tostring(err))
  end
end
print(string.format("%d tests, %d failures", #names, failures))
os.exit(failures == 0 and 0 or 1)
