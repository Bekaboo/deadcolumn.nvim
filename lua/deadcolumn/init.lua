local utils = require('deadcolumn.utils')

---Default options
---@class ColorColumnOptions
local opts = {
  threshold = 0.75,
  scope = 'line',
  modes = { 'i', 'ic', 'ix', 'R', 'Rc', 'Rx', 'Rv', 'Rvc', 'Rvx' },
  warning = {
    alpha = 0.4,
    colorcode = '#FF0000',
    hlgroup = { 'Error', 'background' },
  },
}

-- Store shared data
local store = {
  previous_cc = '', ---@type string
  colorcol_bg = '', ---@type string
}

-- Functions to get the line length for different scopes
local scope_len_fn = {
  line = function()
    return vim.fn.strdisplaywidth(vim.api.nvim_get_current_line())
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
    return math.max(unpack(vim.tbl_map(vim.fn.strdisplaywidth, lines)))
  end,
  visible = function()
    local lines = vim.api.nvim_buf_get_lines(
      0,
      vim.fn.line('w0') - 1,
      vim.fn.line('w$'),
      false
    )
    return math.max(unpack(vim.tbl_map(vim.fn.strdisplaywidth, lines)))
  end,
  cursor = function()
    return vim.api.nvim_win_get_cursor(0)[2] + 1
  end
}

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
    local cc_number = nil
    if vim.startswith(cc_str, '+') then
      cc_number = vim.bo.tw > 0 and vim.bo.tw + tonumber(cc_str:sub(2))
    elseif vim.startswith(cc_str, '-') then
      cc_number = vim.bo.tw > 0 and vim.bo.tw - tonumber(cc_str:sub(2))
    else
      cc_number = tonumber(cc_str)
    end
    if
      type(cc_number) == 'number'
      and cc_number > 0
      and (not cc_min or cc_number < cc_min)
    then
      cc_min = cc_number
    end
  end
  return cc_min
end

---Show the colorcolumn
local function show_colorcolumn()
  local cc = resolve_cc(vim.w.cc)
  if not cc then
    return
  end

  local len = scope_len_fn[opts.scope]()
  local thresh = opts.threshold
  if 0 < opts.threshold and opts.threshold < 1 then
    thresh = math.floor(opts.threshold * cc)
  end
  if len < thresh or not vim.tbl_contains(opts.modes, vim.fn.mode()) then
    vim.opt.cc = ''
    return
  end

  vim.wo.cc = vim.w.cc

  -- Show blended color when len < cc
  local normal_bg = utils.get_hl('Normal', 'background') or '000000'
  if len < cc then
    vim.api.nvim_set_hl(0, 'ColorColumn', {
      bg = '#' .. utils.blend(
        store.colorcol_bg,
        normal_bg,
        (len - thresh) / (cc - thresh)
      ),
    })
  else -- Show error color when len >= cc
    local warning_color = utils.get_hl(
      opts.warning.hlgroup[1],
      opts.warning.hlgroup[2]
    ) or opts.warning.colorcode
    vim.api.nvim_set_hl(0, 'ColorColumn', {
      bg = '#' .. utils.blend(warning_color, normal_bg, opts.warning.alpha),
    })
  end
end

-- colorcolumn is a window-local option, with some special rules:
-- 1. When a window is created, it inherits the value of the previous window or
--    the global option
-- 2. When a different buffer is displayed in current window, window-local cc
--    settings changes to the value when the buffer is displayed in the first
--    time, if there's no such value, it uses value of the global option
-- 3. Once the window-local cc is set, it's not changed by the global option
--    or inheritance, it will only change when a different buffer is displayed
--    or the option is set explicitly (via set or setlocal)
local function create_autocmds()
  -- Save original cc settings
  vim.api.nvim_create_augroup('AutoColorColumn', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
    group = 'AutoColorColumn',
    callback = function()
      vim.g.cc = vim.go.cc
      vim.w.cc = vim.wo.cc
      vim.opt.cc = ''
    end,
    once = true,
  })

  -- Save previous window cc settings
  vim.api.nvim_create_autocmd({ 'WinLeave' }, {
    group = 'AutoColorColumn',
    callback = function()
      store.previous_cc = vim.w.cc
      vim.wo.cc = ''
    end,
  })

  -- Broadcast previous window or global cc settings to new windows
  vim.api.nvim_create_autocmd({ 'WinNew' }, {
    group = 'AutoColorColumn',
    callback = function()
      vim.w.cc = store.previous_cc or vim.g.cc
    end,
  })

  -- Broadcast buffer or global cc settings
  -- when a different buffer is displayed in current window
  vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
    group = 'AutoColorColumn',
    callback = function()
      vim.b.cc = vim.b.cc or vim.g.cc
      vim.w.cc = vim.b.cc or vim.g.cc
    end,
  })

  -- Save cc settings for each window
  vim.api.nvim_create_autocmd({ 'WinEnter' }, {
    group = 'AutoColorColumn',
    callback = function()
      vim.w.cc = vim.w.cc or vim.wo.cc
    end,
  })

  -- Update cc settings on option change
  vim.api.nvim_create_autocmd({ 'OptionSet' }, {
    group = 'AutoColorColumn',
    pattern = 'colorcolumn',
    callback = function()
      if vim.v.option_type == 'global' then
        vim.g.cc = vim.go.cc
        vim.w.cc = vim.go.cc
        vim.b.cc = vim.go.cc
      elseif vim.v.option_type == 'local' then
        vim.w.cc = vim.wo.cc
        vim.b.cc = vim.wo.cc
      end
      vim.go.cc = ''
      vim.wo.cc = ''
    end,
  })

  -- Save Colorcolum background color
  vim.api.nvim_create_autocmd({ 'BufWinEnter', 'ColorScheme' }, {
    group = 'AutoColorColumn',
    callback = function()
      store.colorcol_bg = utils.get_hl('ColorColumn', 'background') or '000000'
    end,
  })

  -- Show colored column
  vim.api.nvim_create_autocmd({
    'ModeChanged',
    'TextChangedI',
    'TextChanged',
    'CursorMovedI',
    'CursorMoved',
    'ColorScheme',
    'BufWinEnter',
    'WinEnter',
  }, {
    group = 'AutoColorColumn',
    callback = show_colorcolumn
  })
  vim.api.nvim_create_autocmd({ 'OptionSet' }, {
    pattern = { 'colorcolumn', 'textwidth' },
    group = 'AutoColorColumn',
    callback = show_colorcolumn,
  })
end

---Setup function
---@param user_opts ColorColumnOptions
local function setup(user_opts)
  opts = vim.tbl_deep_extend('force', opts, user_opts or {})
  if opts.warning.colorcode then
    opts.warning.colorcode = opts.warning.colorcode:gsub('#', '', 1):upper()
  end
  create_autocmds()
end

return {
  setup = setup,
}
