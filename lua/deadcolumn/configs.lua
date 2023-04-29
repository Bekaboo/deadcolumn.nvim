local M = {}

---Default options
---@class ColorColumnOptions
M.opts = {
  scope = 'line',
  modes = { 'i', 'ic', 'ix', 'R', 'Rc', 'Rx', 'Rv', 'Rvc', 'Rvx' },
  blending = {
    threshold = 0.75,
    colorcode = '#000000',
    hlgroup = { 'Normal', 'background' },
  },
  warning = {
    alpha = 0.4,
    offset = 0,
    colorcode = '#FF0000',
    hlgroup = { 'Error', 'background' },
  },
  extra = {
    follow_tw = nil,
  },
}

function M.set_options(user_opts)
  M.opts = vim.tbl_deep_extend('force', M.opts, user_opts or {})
  -- Sanity check
  if M.opts.threshold then
    vim.notify(
      '[deadcolumn] opts.threshold is deprecated and will be removed by 2023-06, use opts.blending.threshold instead',
      vim.log.levels.WARN
    )
    M.opts.blending.threshold = M.opts.threshold
  end
  assert(vim.tbl_islist(M.opts.modes), 'modes must be a list of strings')
  assert(
    vim.tbl_contains({ 'line', 'buffer', 'visible', 'cursor' }, M.opts.scope),
    'scope must be one of "line", "buffer", "visible", "cursor"'
  )
  assert(M.opts.blending.threshold >= 0, 'blending.threshold must be >= 0')
  assert(
    M.opts.blending.colorcode:match('^#?%x%x%x%x%x%x$'),
    'blending.colorcode must be a 6-digit hex color code'
  )
  assert(
    vim.tbl_contains(
      { 'foreground', 'background' },
      M.opts.blending.hlgroup[2]
    ),
    'blending.hlgroup[2] must be "foreground" or "background"'
  )
  assert(M.opts.warning.alpha >= 0, 'warning.alpha must be >= 0')
  assert(M.opts.warning.alpha <= 1, 'warning.alpha must be <= 1')
  assert(
    type(M.opts.warning.offset) == 'number'
      and math.floor(M.opts.warning.offset) == M.opts.warning.offset,
    'warning.offset must be an integer'
  )
  assert(
    M.opts.warning.colorcode:match('^#?%x%x%x%x%x%x$'),
    'warning.colorcode must be a 6-digit hex color code'
  )
  assert(
    vim.tbl_contains({ 'foreground', 'background' }, M.opts.warning.hlgroup[2]),
    'warning.hlgroup[2] must be "foreground" or "background"'
  )
  assert(
    type(M.opts.extra.follow_tw) == 'nil'
      or type(M.opts.extra.follow_tw) == 'string',
    'extra.follow_tw must be nil or a string'
  )

  -- Preprocess
  M.opts.blending.colorcode = M.opts.blending.colorcode:upper()
  M.opts.warning.colorcode = M.opts.warning.colorcode:upper()
end

return M
