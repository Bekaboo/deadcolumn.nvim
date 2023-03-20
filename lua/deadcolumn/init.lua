local utils = require('deadcolumn.utils')

local opts = {
  threshold = 0.75,
  scope = 'line',
  modes = {
    'i',
    'ic',
    'ix',
    'R',
    'Rc',
    'Rx',
    'Rv',
    'Rvc',
    'Rvx',
  },
  warning = {
    alpha = 0.4,
    colorcode = nil,
    hlgroup = { 'Error', 'background' },
  },
}

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
      vim.g.prevwincc = vim.w.cc
      vim.wo.cc = ''
    end,
  })

  -- Broadcast previous window or global cc settings to new windows
  vim.api.nvim_create_autocmd({ 'WinNew' }, {
    group = 'AutoColorColumn',
    callback = function()
      vim.w.cc = vim.g.prevwincc or vim.g.cc
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
      vim.g.colorcolumn_bg = utils.get_hl('ColorColumn', 'background')
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
    callback = function()
      local cc = tonumber(vim.w.cc)

      if not cc then
        return
      end

      local length = 0
      if opts.scope == 'line' then
        length = vim.fn.strdisplaywidth(vim.api.nvim_get_current_line())
      elseif opts.scope == 'buffer' then
        -- local lines = vim.api.nvim_buf_get_lines(0, vim.fn.line('w0') - 1,
        --   vim.fn.line('w$'), false)
        local range = 1000
        local current_linenr = vim.fn.line('.')
        local lines = vim.api.nvim_buf_get_lines(
          0,
          math.max(0, current_linenr - 1 - range),
          current_linenr + range,
          false
        )
        length = math.max(unpack(vim.tbl_map(vim.fn.strdisplaywidth, lines)))
      elseif opts.scope == 'visible' then
        local lines = vim.api.nvim_buf_get_lines(
          0,
          vim.fn.line('w0') - 1,
          vim.fn.line('w$'),
          false
        )
        length = math.max(unpack(vim.tbl_map(vim.fn.strdisplaywidth, lines)))
      end

      local thresh
      if 0 < opts.threshold and opts.threshold < 1 then
        thresh = math.floor(opts.threshold * cc)
      else
        thresh = opts.threshold
      end

      if
        length < thresh
        or not vim.tbl_contains(opts.modes, vim.fn.mode())
      then
        vim.opt.cc = ''
        return
      end

      vim.wo.cc = vim.w.cc

      -- Show blended color when length < cc
      if length < cc then
        vim.api.nvim_set_hl(0, 'ColorColumn', {
          bg = '#' .. utils.blend(
            vim.g.colorcolumn_bg,
            utils.get_hl('Normal', 'background'),
            (length - thresh) / (cc - thresh)
          ),
        })
      else -- Show error color when length >= cc
        local warning_color = opts.warning.colorcode
          or utils.get_hl(opts.warning.hlgroup[1], opts.warning.hlgroup[2])
        vim.print(warning_color)
        vim.api.nvim_set_hl(0, 'ColorColumn', {
          bg = '#' .. utils.blend(
            warning_color,
            utils.get_hl('Normal', 'background'),
            opts.warning.alpha
          ),
        })
      end
    end,
  })
end

---Setup function
---@param user_opts table|nil
local function setup(user_opts)
  opts = vim.tbl_deep_extend('force', opts, user_opts or {})
  if opts.warning.colorcode then
    opts.warning.colorcode = opts.warning.colorcode:gsub('#', '', 1):upper()
  end
  create_autocmds()
  vim.g.loaded_deadcolumn = true
end

return {
  setup = setup,
}
