local colors = require('deadcolumn.colors')
local configs = require('deadcolumn.configs')

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
  end,
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

---Redraw the colorcolumn
local function redraw_colorcolumn()
  local cc = resolve_cc(vim.w.cc)
  if not cc then
    vim.wo.cc = ''
    return
  end

  local len = scope_len_fn[configs.user.scope]()
  local thresh = configs.user.blending.threshold
  if 0 < thresh and thresh <= 1 then
    thresh = math.floor(configs.user.threshold * cc)
  end
  if
    len < thresh or not vim.tbl_contains(configs.user.modes, vim.fn.mode())
  then
    vim.wo.cc = ''
    return
  end

  vim.wo.cc = vim.w.cc

  -- Show blended color when len < cc
  local normal_bg = colors.get_hl(
    configs.user.blending.hlgroup[1],
    configs.user.blending.hlgroup[2],
    configs.user.blending.colorcode
  )
  if len < cc then
    vim.api.nvim_set_hl(0, 'ColorColumn', {
      bg = colors.blend(
        store.colorcol_bg,
        normal_bg,
        (len - thresh) / (cc - thresh)
      ),
    })
  else -- Show error color when len >= cc
    local warning_color = colors.get_hl(
      configs.user.warning.hlgroup[1],
      configs.user.warning.hlgroup[2],
      configs.user.warning.colorcode
    )
    vim.api.nvim_set_hl(0, 'ColorColumn', {
      bg = colors.blend(warning_color, normal_bg, configs.user.warning.alpha),
    })
  end
end

---Hide the colorcolumn
local function init()
  local wins = vim.api.nvim_list_wins()
  for _, win in ipairs(wins) do
    vim.w[win].cc = vim.wo[win].cc
  end
  vim.g.cc = vim.go.cc
  for _, win in ipairs(wins) do
    vim.wo[win].cc = ''
  end
  vim.go.cc = ''
  store.colorcol_bg = colors.get_hl('ColorColumn', 'background')
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
local function make_autocmds()
  vim.api.nvim_create_augroup('AutoColorColumn', { clear = true })

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
      vim.w.cc = str_fallback(store.previous_cc, vim.g.cc)
    end,
  })

  -- Handle cc settings from ftplugins
  -- Detect cc changes in a quite hacky way, because OptionSet autocmd is not
  -- triggered when cc is set in a ftplugin
  -- Quirk: these two commands are not the same in a ftplugin:
  --     setlocal cc=80 " vimscript
  --     vim.wo.cc = 80 -- lua
  -- The former (vimscript) will set the 'buffer-local' cc, i.e. it will set cc
  -- for current window BUT will be reset for a different buffer displayed in
  -- the same window.
  -- The latter (lua) will set the 'window-local' cc, i.e. it will set cc for
  -- current window and will NOT be reset for a different buffer displayed in
  -- the same window.
  -- Currently there is no way to tell which one is used in a ftplugin, since I
  -- prefer the vimscript way, I simulate its behavior here when a change is
  -- detected for cc in current window.
  vim.api.nvim_create_autocmd({ 'BufReadPre' }, {
    group = 'AutoColorColumn',
    callback = function()
      vim.b._cc = vim.wo.cc
      vim.g._cc = vim.go.cc
    end,
  })
  vim.api.nvim_create_autocmd({ 'FileType' }, {
    group = 'AutoColorColumn',
    callback = function()
      -- If cc changes between BufReadPre and FileType, it is an ftplugin
      -- that sets cc, so we accept it as a 'buffer-local' (phony) cc setting
      -- Notice that we will do nothing if vim.b._cc is nil, which means the
      -- buffer is not the same buffer that triggers BufReadPre
      if vim.b._cc and vim.wo.cc ~= vim.b._cc then
        vim.b.cc = vim.wo.cc
        if vim.go.cc ~= vim.g._cc then
          vim.g.cc = vim.go.cc
        end
      end
    end,
  })

  -- Broadcast buffer or global cc settings
  -- when a different buffer is displayed in current window
  vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
    group = 'AutoColorColumn',
    callback = function()
      vim.b.cc = str_fallback(vim.b.cc, vim.g.cc)
      vim.w.cc = str_fallback(vim.b.cc, vim.g.cc)
      if not vim.tbl_contains(configs.user.modes, vim.fn.mode()) then
        vim.wo.cc = ''
      end
    end,
  })

  -- Save cc settings for each window
  vim.api.nvim_create_autocmd({ 'WinEnter' }, {
    group = 'AutoColorColumn',
    callback = function()
      vim.w.cc = str_fallback(vim.w.cc, vim.wo.cc)
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

  -- Update Colorcolum background color on color scheme change
  vim.api.nvim_create_autocmd({ 'ColorScheme' }, {
    group = 'AutoColorColumn',
    callback = function()
      store.colorcol_bg = colors.get_hl('ColorColumn', 'background')
    end,
  })

  -- Show colored column
  vim.api.nvim_create_autocmd({
    'WinScrolled',
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
    callback = redraw_colorcolumn,
  })
  vim.api.nvim_create_autocmd({ 'OptionSet' }, {
    pattern = { 'colorcolumn', 'textwidth' },
    group = 'AutoColorColumn',
    callback = redraw_colorcolumn,
  })

  -- Fix cursor position issues
  vim.on_key(function(char)
    local mode = vim.fn.mode()
    vim.w._last_key = char
    if vim.startswith(mode, 'n') and char == '$' then
      vim.w._eol = true
    end
  end, vim.api.nvim_create_namespace('AutoColorColumn'))
  vim.api.nvim_create_autocmd({ 'BufWinEnter', 'InsertEnter' }, {
    group = 'AutoColorColumn',
    callback = function()
      -- Record last cursor row position and largest column position
      vim.w._cursor = vim.api.nvim_win_get_cursor(0)
      vim.print('WinEnter/InsertEnter, set vim.w._cursor to ' .. vim.inspect(vim.w._cursor))
    end,
  })
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    group = 'AutoColorColumn',
    callback = function(tbl)
      if not vim.w._cursor then
        vim.print('No _cursor, return')
        return
      end
      local cursor = vim.api.nvim_win_get_cursor(0)
      -- Same row, update _cursor, set _eol and return
      if cursor[1] == vim.w._cursor[1] then
        vim.print('Same row, update _cursor')
        vim.w._cursor = cursor
        vim.w._eol = vim.w._last_key == '$' and true or false
        return
      end
      -- Different row, if in normal mode and _eol is set, move cursor to EOL,
      -- update _cursor and return
      if tbl.event == 'CursorMoved' and vim.w._eol then
        vim.print('CursorMoved, mode is n and _eol is true')
        vim.cmd('silent! normal! $')
        vim.w._cursor = cursor
        return
      end
      -- Different row, in normal mode but _eol is not set, or in
      -- insert/replace mode, should update cursor column to furthest column
      -- position and udate _cursor
      if cursor[2] < vim.w._cursor[2] then
        local target = { cursor[1], vim.w._cursor[2] }
        vim.api.nvim_win_set_cursor(0, target)
        vim.w._cursor = target
        vim.print('CursorMoved, mode is n and _eol is false, or mode is i/r, set cursor to ' .. vim.inspect(target) .. ', update _cursor')
      else
        vim.w._cursor = cursor
        vim.print('CursorMoved, mode is n and _eol is false, or mode is i/r, update _cursor')
      end
    end,
  })
end

return {
  init = init,
  make_autocmds = make_autocmds,
}
