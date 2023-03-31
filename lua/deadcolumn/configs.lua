local M = {}

---Default options
---@class ColorColumnOptions
M.default = {
  scope = 'line',
  modes = { 'i', 'ic', 'ix', 'R', 'Rc', 'Rx', 'Rv', 'Rvc', 'Rvx' },
  blending = {
    threshold = 0.75,
    colorcode = '#000000',
    hlgroup = { 'Normal', 'background' },
  },
  warning = {
    alpha = 0.4,
    colorcode = '#FF0000',
    hlgroup = { 'Error', 'background' },
  },
  extra = {
    follow_tw = nil,
  },
}

function M.set_options(user_opts)
  M.user = vim.tbl_deep_extend('force', M.default, user_opts or {})
  -- Sanity check
  if M.user.threshold then
    vim.notify(
      '[deadcolumn] opts.threshold is deprecated and will be removed by 2023-06, use opts.blending.threshold instead',
      vim.log.levels.WARN
    )
    M.user.blending.threshold = M.user.threshold
  end
  assert(vim.tbl_islist(M.user.modes), 'modes must be a list of strings')
  assert(
    vim.tbl_contains({ 'line', 'buffer', 'visible', 'cursor' }, M.user.scope),
    'scope must be one of "line", "buffer", "visible", "cursor"'
  )
  assert(M.user.blending.threshold >= 0, 'blending.threshold must be >= 0')
  assert(
    M.user.blending.colorcode:match('^#?%x%x%x%x%x%x$'),
    'blending.colorcode must be a 6-digit hex color code'
  )
  assert(
    vim.tbl_contains(
      { 'foreground', 'background' },
      M.user.blending.hlgroup[2]
    ),
    'blending.hlgroup[2] must be "foreground" or "background"'
  )
  assert(M.user.warning.alpha >= 0, 'warning.alpha must be >= 0')
  assert(M.user.warning.alpha <= 1, 'warning.alpha must be <= 1')
  assert(
    M.user.warning.colorcode:match('^#?%x%x%x%x%x%x$'),
    'warning.colorcode must be a 6-digit hex color code'
  )
  assert(
    vim.tbl_contains({ 'foreground', 'background' }, M.user.warning.hlgroup[2]),
    'warning.hlgroup[2] must be "foreground" or "background"'
  )
  assert(
    type(M.user.extra.follow_tw) == 'nil'
      or type(M.user.extra.follow_tw) == 'string',
    'extra.follow_tw must be nil or a string'
  )

  -- Preprocess
  M.user.blending.colorcode = M.user.blending.colorcode:upper()
  M.user.warning.colorcode = M.user.warning.colorcode:upper()
end

return M
