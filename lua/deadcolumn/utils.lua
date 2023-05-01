local colors = require('deadcolumn.colors')
local configs = require('deadcolumn.configs')

---Fallback to the first non-empty string
---@vararg string
---@return string|nil
local function str_fallback(...)
  local args = { ... }
  for _, arg in pairs(args) do
    if type(arg) == 'string' and arg ~= '' then
      return arg
    end
  end
  return nil
end

---Set a window-local option safely without changing the window view
---@param win integer window handle, 0 for current window
---@param name string option name
---@param value any option value
local function win_safe_set_option(win, name, value)
  local winview = vim.fn.winsaveview()
  vim.wo[win][name] = value
  vim.fn.winrestview(winview)
end

---Resolve the colorcolumn value
---@param cc string|nil
---@return integer|nil cc_number smallest integer >= 0 or nil
local function resolve_cc(cc)
  if not cc or cc == '' then
    return nil
  end
  local cc_tbl = vim.split(cc, ',')
  local cc_min = nil
  for _, cc_str in ipairs(cc_tbl) do
    local cc_number = tonumber(cc_str)
    if vim.startswith(cc_str, '+') or vim.startswith(cc_str, '-') then
      cc_number = vim.bo.tw > 0 and vim.bo.tw + cc_number or nil
    end
    if cc_number and cc_number > 0 and (not cc_min or cc_number < cc_min) then
      cc_min = cc_number
    end
  end
  return cc_min
end

return {
  resolve_cc = resolve_cc,
  str_fallback = str_fallback,
  win_safe_set_option = win_safe_set_option,
}
