local M = {}

---Default options
---@class ColorColumnOptions
M.default = {
  threshold = 0.75,
  scope = 'line',
  modes = { 'i', 'ic', 'ix', 'R', 'Rc', 'Rx', 'Rv', 'Rvc', 'Rvx' },
  warning = {
    alpha = 0.4,
    colorcode = '#FF0000',
    hlgroup = { 'Error', 'background' },
  },
}

function M.set_options(user_opts)
  M.user = vim.tbl_deep_extend('force', M.default, user_opts or {})
  if M.user.warning.colorcode then
    M.user.warning.colorcode =
      M.user.warning.colorcode:gsub('#', '', 1):upper()
  end
  -- Sanity check
  assert(M.user.threshold >= 0, 'threshold must be >= 0')
  assert(vim.tbl_islist(M.user.modes), 'modes must be a list of strings')
  assert(
    vim.tbl_contains({ 'line', 'buffer', 'visible', 'cursor' }, M.user.scope),
    'scope must be one of "line", "buffer", "visible", "cursor"'
  )
  assert(M.user.warning.alpha >= 0, 'warning.alpha must be >= 0')
  assert(M.user.warning.alpha <= 1, 'warning.alpha must be <= 1')
  assert(
    M.user.warning.colorcode:match('^%x%x%x%x%x%x$'),
    'warning.colorcode must be a 6-digit hex color code'
  )
  assert(
    vim.tbl_contains({ 'foreground', 'background' }, M.user.warning.hlgroup[2]),
    'warning.hlgroup[2] must be "foreground" or "background"'
  )
end

return M
