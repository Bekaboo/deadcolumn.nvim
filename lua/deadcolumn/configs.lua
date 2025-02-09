local M = {}

local function displaywidth(line)
  if vim.fn.type(line) == vim.v.t_blob then
    -- This is a workaround for the error "E976: using Blob as a String" on
    -- strdisplaywidth. Lines containing control characters are expected to be
    -- only composed of ASCII.
    return #line
  end
  return vim.fn.strdisplaywidth(line)
end

-- Functions to get the line length for different scopes
local scope_fn = {
  line = function()
    return displaywidth(vim.api.nvim_get_current_line())
  end,
  buffer = function()
    local range = 1000
    local current_linenr = vim.fn.line('.')
    local lines = vim.api.nvim_buf_get_lines(
      0,
      math.max(0, current_linenr - 1 - range),
      current_linenr + range,
      false
    )
    return math.max(0, unpack(vim.tbl_map(displaywidth, lines)))
  end,
  visible = function()
    local lines = vim.api.nvim_buf_get_lines(
      0,
      vim.fn.line('w0') - 1,
      vim.fn.line('w$'),
      false
    )
    return math.max(0, unpack(vim.tbl_map(displaywidth, lines)))
  end,
  cursor = function()
    return vim.api.nvim_win_get_cursor(0)[2] + 1
  end,
}

---Default options
---@class ColorColumnOptions
M.opts = {
  scope = 'line', ---@type string|fun(): integer
  ---@type string[]|boolean|fun(mode: string): boolean
  modes = function(mode)
    return mode:find('^[iRss\x13]') ~= nil
  end,
  blending = {
    threshold = 0.5,
    colorcode = '#000000',
    hlgroup = { 'Normal', 'bg' },
  },
  warning = {
    alpha = 0.4,
    offset = 0,
    colorcode = '#FF0000',
    hlgroup = { 'Error', 'bg' },
  },
  extra = {
    ---@type string?
    follow_tw = nil,
  },
}

function M.set_options(user_opts)
  M.opts = vim.tbl_deep_extend('force', M.opts, user_opts or {})
  local islist = vim.islist or vim.tbl_islist
  -- Sanity check
  assert(
    type(M.opts.modes) == 'boolean'
      or type(M.opts.modes) == 'function'
      or type(M.opts.modes) == 'table'
        and islist(M.opts.modes --[[@as table]]),
    'modes must be a function or a list of strings'
  )
  assert(
    type(M.opts.scope) == 'function'
      or vim.tbl_contains(
        { 'line', 'buffer', 'visible', 'cursor' },
        M.opts.scope
      ),
    'scope must be a function or one of "line", "buffer", "visible", "cursor"'
  )
  assert(M.opts.blending.threshold >= 0, 'blending.threshold must be >= 0')
  assert(
    M.opts.blending.colorcode:match('^#?%x%x%x%x%x%x$'),
    'blending.colorcode must be a 6-digit hex color code'
  )
  assert(
    vim.tbl_contains(
      { 'foreground', 'background', 'fg', 'bg' },
      M.opts.blending.hlgroup[2]
    ),
    'blending.hlgroup[2] must be "foreground"/"fg" or "background"/"bg"'
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
    vim.tbl_contains(
      { 'foreground', 'background', 'fg', 'bg' },
      M.opts.warning.hlgroup[2]
    ),
    'warning.hlgroup[2] must be "foreground"/"fg" or "background"/"bg"'
  )
  assert(
    type(M.opts.extra.follow_tw) == 'nil'
      or type(M.opts.extra.follow_tw) == 'string',
    'extra.follow_tw must be nil or a string'
  )

  -- Preprocess
  -- For compatibility, 'foreground'/'background' may be provided as field name
  -- of hlgroup attributes. These field names come from the return value of
  -- `nvim_get_hl_by_name()`, which is now deprecated. New api `nvim_get_hl`
  -- returns hlgroup attributes with field names 'fg'/'bg' instead.
  M.opts.blending.hlgroup[2] = M.opts.blending.hlgroup[2]
    :gsub('^foreground$', 'fg')
    :gsub('^background$', 'bg')
  M.opts.warning.hlgroup[2] = M.opts.warning.hlgroup[2]
    :gsub('^foreground$', 'fg')
    :gsub('^background$', 'bg')
  M.opts.scope = type(M.opts.scope) == 'string' and scope_fn[M.opts.scope]
    or M.opts.scope
end

return M
