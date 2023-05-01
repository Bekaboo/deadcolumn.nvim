local colors = require('deadcolumn.colors')
local configs = require('deadcolumn.configs')
local utils = require('deadcolumn.utils')

-- Store shared data
local store = {
  previous_cc = '', ---@type string
  colorcol_bg = '', ---@type string
}

-- Functions to get the line length for different scopes
local scope_fn = {
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

---Set to be relative to textwidth if textwidth is set
---@param info table event info
local function set_relative_cc(info)
  if not configs.opts.extra.follow_tw then
    return
  end
  if info.event == 'BufWinEnter' and vim.b._cc_last_set_by == 'modeline' then
    return
  end
  if vim.bo.textwidth > 0 then
    vim.w.cc = configs.opts.extra.follow_tw
  else
    vim.w.cc = utils.str_fallback(vim.b.cc, vim.g.cc)
  end
end

---Redraw the colorcolumn
local function redraw_cc()
  local cc = utils.resolve_cc(vim.w.cc)
  if not cc then
    -- Save window view to prevent cursor
    -- from being reset.
    utils.win_safe_set_option(0, 'cc', '')
    return
  end

  if not vim.tbl_contains(configs.opts.modes, vim.fn.mode()) then
    utils.win_safe_set_option(0, 'cc', '')
    return
  end

  local len = type(configs.opts.scope) == 'string'
      and scope_fn[configs.opts.scope]()
    or configs.opts.scope()
  local thresh = configs.opts.blending.threshold
  if 0 < thresh and thresh <= 1 then
    thresh = math.floor(thresh * cc)
  end
  if len < thresh then
    utils.win_safe_set_option(0, 'cc', '')
    return
  end

  utils.win_safe_set_option(0, 'cc', vim.w.cc)

  -- Show blended color when len < cc
  local normal_bg = colors.get_hl(
    configs.opts.blending.hlgroup[1],
    configs.opts.blending.hlgroup[2],
    configs.opts.blending.colorcode
  )
  if len < cc + configs.opts.warning.offset then
    vim.api.nvim_set_hl(0, 'ColorColumn', {
      bg = colors.blend(
        store.colorcol_bg,
        normal_bg,
        (len - thresh) / (cc - thresh)
      ),
    })
  else -- Show error color when len >= cc + offset
    local warning_color = colors.get_hl(
      configs.opts.warning.hlgroup[1],
      configs.opts.warning.hlgroup[2],
      configs.opts.warning.colorcode
    )
    vim.api.nvim_set_hl(0, 'ColorColumn', {
      bg = colors.blend(warning_color, normal_bg, configs.opts.warning.alpha),
    })
  end
end

---Initialization
---Record & reset colorcolumn settings for each window,
---and save the background color of hl-ColorColumn
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

---Make autocmds to track colorcolumn settings
---@param group number autocmd group id
local function autocmd_track_cc(group)
  -- Save previous window cc settings
  vim.api.nvim_create_autocmd({ 'WinLeave' }, {
    group = group,
    callback = function()
      store.previous_cc = vim.w.cc
      utils.win_safe_set_option(0, 'cc', '')
    end,
  })

  -- Broadcast previous window or global cc settings to new windows
  vim.api.nvim_create_autocmd({ 'WinNew' }, {
    group = group,
    callback = function()
      vim.w.cc = utils.str_fallback(store.previous_cc, vim.g.cc)
    end,
  })

  -- Handle cc settings from ftplugins
  -- Detect cc changes in a quite hacky way, because OptionSet autocmd is not
  -- triggered when cc is set in a ftplugin
  -- Quirk: these two commands are not the same in a ftplugin:
  --     setlocal cc=80   " vimscript
  --     vim.wo.cc = '80' -- lua
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
    group = group,
    callback = function()
      vim.b._cc = vim.wo.cc
      vim.g._cc = vim.go.cc
    end,
  })
  vim.api.nvim_create_autocmd({ 'FileType' }, {
    group = group,
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

  -- On entering a buffer, check and set vim.b.cc and vim.w.cc in the
  -- following order:
  -- 1. If vim.wo.cc is non empty, then it is set from a modeline, use it.
  --    Notice that this is after the 'FileType' event, which applies ftplugin
  --    settings
  -- 2. If vim.b.cc is non empty, it is set previously by broadcasting or an
  --    ftplugin, use it
  -- 3. Else use vim.g.cc
  -- We want to unset vim.wo.cc on leaving a buffer, so that vim.wo.cc reflects
  -- changes from modelines
  vim.api.nvim_create_autocmd({ 'BufLeave' }, {
    group = group,
    callback = function()
      utils.win_safe_set_option(0, 'cc', '')
    end,
  })
  vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
    group = group,
    callback = function()
      vim.b.cc = utils.str_fallback(vim.wo.cc, vim.b.cc, vim.g.cc)
      vim.w.cc = utils.str_fallback(vim.wo.cc, vim.b.cc, vim.g.cc)
      if vim.b.cc == vim.wo.cc then
        vim.b._cc_last_set_by = 'modeline'
      end
      if not vim.tbl_contains(configs.opts.modes, vim.fn.mode()) then
        utils.win_safe_set_option(0, 'cc', '')
      end
    end,
  })

  -- Save cc settings for each window
  vim.api.nvim_create_autocmd({ 'WinEnter' }, {
    group = group,
    callback = function()
      vim.w.cc = utils.str_fallback(vim.w.cc, vim.wo.cc)
    end,
  })

  -- Update cc settings on option change
  vim.api.nvim_create_autocmd({ 'OptionSet' }, {
    group = group,
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
      utils.win_safe_set_option(0, 'cc', '')
    end,
  })
end

---Make autocmds to display colorcolumn
---@param group number autocmd group id
local function autocmd_display_cc(group)
  -- Update Colorcolum background color on ColorScheme
  vim.api.nvim_create_autocmd({ 'ColorScheme' }, {
    group = group,
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
    group = group,
    callback = redraw_cc,
  })
  vim.api.nvim_create_autocmd({ 'OptionSet' }, {
    pattern = { 'colorcolumn', 'textwidth' },
    group = group,
    callback = redraw_cc,
  })
end

---Make autocmds to set colorcolumn relative to textwidth
---@param group number augroup id
local function autocmd_follow_tw(group)
  -- Set cc to be relative to textwidth if textwidth is set
  vim.api.nvim_create_autocmd({ 'OptionSet' }, {
    pattern = 'textwidth',
    group = group,
    callback = set_relative_cc,
  })
  vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
    group = group,
    callback = set_relative_cc,
  })
end

---Make all autocmds
local function make_autocmds()
  local group = vim.api.nvim_create_augroup('AutoColorColumn', {})
  autocmd_track_cc(group)
  autocmd_follow_tw(group)
  autocmd_display_cc(group)
end

return {
  init = init,
  make_autocmds = make_autocmds,
}
