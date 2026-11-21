-- Place Stretchly break windows on their respective monitors.
--
-- With allScreens enabled, Stretchly opens one break window per monitor, sized to fit that monitor.
-- Wayland clients can't choose their monitor, so Hyprland opens them all on the same one.
-- When a break window opens, move it to the free monitor that best matches its size.
-- This runs inside Hyprland as the window opens, so the window is placed before it's noticeably on the wrong monitor.

local break_classes = { electron = true, Stretchly = true, stretchly = true }
-- Sometimes, the window title is just "Stretchly" for some reason.
local break_titles = { ["Time to take a break!"] = true, Stretchly = true, stretchly = true }

-- Remove the subscriptions from a previous load of the config so that windows aren't handled twice.
if _G.stretchly_break_subscriptions then
  for _, subscription in ipairs(_G.stretchly_break_subscriptions) do
    if subscription:is_active() then
      subscription:remove()
    end
  end
end

-- Window address -> name of the monitor it was moved to
local assignments = {}

local function is_break_window(window)
  return window ~= nil and break_classes[window.class] == true and break_titles[window.title] == true
end

-- The title event fires before the window opens, when it doesn't have a monitor or a size yet.
local function is_placeable(window)
  return window.monitor ~= nil and window.size.x > 0 and window.size.y > 0
end

-- Electron sizes windows in logical pixels, so compare against each monitor's logical size.
local function logical_size(monitor)
  local width = monitor.width / monitor.scale
  local height = monitor.height / monitor.scale
  -- Rotated by 90 or 270 degrees
  if monitor.transform % 2 == 1 then
    width, height = height, width
  end
  return width, height
end

local function taken_monitors()
  local taken = {}
  for address, monitor_name in pairs(assignments) do
    if hl.get_window("address:" .. address) == nil then
      assignments[address] = nil
    else
      taken[monitor_name] = true
    end
  end
  return taken
end

-- Price is right rules: prefer the closest monitor that the window fits on.
-- Fall back to the closest free monitor when the window doesn't fit on any of them.
local function best_monitor(window)
  local taken = taken_monitors()
  local window_width, window_height = window.size.x, window.size.y
  local best, best_distance, best_fits
  for _, monitor in ipairs(hl.get_monitors()) do
    if not taken[monitor.name] and not monitor.is_mirror then
      local monitor_width, monitor_height = logical_size(monitor)
      local fits = window_width <= monitor_width + 0.5 and window_height <= monitor_height + 0.5
      local dx, dy = monitor_width - window_width, monitor_height - window_height
      local distance = dx * dx + dy * dy
      if best == nil or (fits and not best_fits) or (fits == best_fits and distance < best_distance) then
        best, best_distance, best_fits = monitor, distance, fits
      end
    end
  end
  return best
end

local function place_break_window(window)
  if not is_break_window(window) or not is_placeable(window) or assignments[window.address] ~= nil then
    return
  end
  local monitor = best_monitor(window)
  if monitor == nil then
    return
  end
  assignments[window.address] = monitor.name
  -- Target the window explicitly instead of relying on focus.
  -- Break windows keep focus with stay_focused, so focusing another break window doesn't work.
  local selector = "address:" .. window.address
  hl.dispatch(hl.dsp.window.move({ monitor = monitor.name, window = selector, follow = false }))
  hl.dispatch(hl.dsp.window.pin({ window = selector, action = "enable" }))
  hl.dispatch(hl.dsp.window.center({ window = selector }))
end

_G.stretchly_break_subscriptions = {
  hl.on("window.open", place_break_window),
  -- Stretchly may set the title after the window opens.
  hl.on("window.title", place_break_window),
  hl.on("window.close", function(window)
    if window ~= nil then
      assignments[window.address] = nil
    end
  end),
}
