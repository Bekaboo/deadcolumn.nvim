local configs = require('deadcolumn.configs')
local colors = require('deadcolumn.colors')

local C_NORMAL, C_CC, C_ERROR

---Get background color in hex
---@param hlgroup_name string
---@param field 'fg'|'bg'
---@param fallback string|nil fallback color in hex, default to '#000000' if &bg is 'dark' and '#FFFFFF' if &bg is 'light'
---@return string hex color
local function get_hl_hex(hlgroup_name, field, fallback)
  fallback = fallback or vim.opt.bg == 'dark' and '#000000' or '#FFFFFF'
  if not vim.fn.hlexists(hlgroup_name) then
    return fallback
  end
  local attr_val =
    colors.get(0, { name = hlgroup_name, winhl_link = false })[field]
  return attr_val and colors.dec2hex(attr_val, 6) or fallback
end

---Update base colors: bg color of Normal & ColorColumn, and fg of Error
---@return nil
local function update_hl_hex()
  C_NORMAL = get_hl_hex(
    configs.opts.blending.hlgroup[1],
    configs.opts.blending.hlgroup[2],
    configs.opts.blending.colorcode
  )
  C_ERROR = get_hl_hex(
    configs.opts.warning.hlgroup[1],
    configs.opts.warning.hlgroup[2],
    configs.opts.warning.colorcode
  )
  C_CC = get_hl_hex('ColorColumn', 'bg')
end

---Resolve the colorcolumn value
---@param cc string|nil
---@return integer|nil cc_number smallest integer >= 0 or nil
local function cc_resolve(cc)
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

---Hide colorcolumn
---@param winid integer? window handler
local function cc_conceal(winid)
  winid = winid or 0
  local new_winhl = (
    vim.wo[winid].winhl:gsub('ColorColumn:[^,]*', '') .. ',ColorColumn:'
  ):gsub(',*$', ''):gsub('^,*', ''):gsub(',+', ',')
  if new_winhl ~= vim.wo[winid].winhl then
    vim.wo[winid].winhl = new_winhl
  end
end

---Show colorcolumn
---@param winid integer? window handler
local function cc_show(winid)
  winid = winid or 0
  local new_winhl = (
    vim.wo[winid].winhl:gsub('ColorColumn:[^,]*', '')
    .. ',ColorColumn:_ColorColumn'
  ):gsub(',*$', ''):gsub('^,*', ''):gsub(',+', ',')
  if new_winhl ~= vim.wo[winid].winhl then
    vim.wo[winid].winhl = new_winhl
  end
end

---Check if the current mode is in the correct mode
---@return boolean
local function check_mode()
  if type(configs.opts.modes) == 'boolean' then
    return configs.opts.modes ---@type boolean
  end
  if type(configs.opts.modes) == 'function' then
    return configs.opts.modes(vim.fn.mode())
  end
  return type(configs.opts.modes) == 'table'
      and vim.tbl_contains(
        configs.opts.modes --[=[@as string[]]=],
        vim.fn.mode()
      )
    or false
end

local cc_bg = nil
local cc_link = nil

---Update colorcolumn highlight or conceal it
---@param winid integer? handler, default 0
---@return nil
local function cc_update(winid)
  winid = winid or 0
  local cc = cc_resolve(vim.wo[winid].cc)
  if not check_mode() or not cc then
    cc_conceal(winid)
    return
  end

  -- Fix 'E976: using Blob as a String' after select a snippet
  -- entry from LSP server using omnifunc `<C-x><C-o>`
  ---@diagnostic disable-next-line: param-type-mismatch
  local length = configs.opts.scope()
  local thresh = configs.opts.blending.threshold
  if 0 < thresh and thresh <= 1 then
    thresh = math.floor(thresh * cc)
  end
  if length < thresh then
    cc_conceal(winid)
    return
  end

  -- Show blended color when len < cc + offset and warning color otherwise
  local show_warning = length >= cc + configs.opts.warning.offset
  if vim.go.termguicolors then
    if not C_CC or not C_NORMAL or not C_ERROR then
      update_hl_hex()
    end
    local new_cc_color = show_warning
        and colors.cblend(C_ERROR, C_NORMAL, configs.opts.warning.alpha).dec
      or colors.cblend(
        C_CC,
        C_NORMAL,
        math.min(1, (length - thresh) / (cc - thresh))
      ).dec
    if new_cc_color ~= cc_bg then
      cc_bg = new_cc_color
      vim.api.nvim_set_hl(0, '_ColorColumn', { bg = cc_bg })
    end
  else
    local link = show_warning and configs.opts.warning.hlgroup[1]
      or 'ColorColumn'
    if cc_link ~= link then
      cc_link = link
      vim.api.nvim_set_hl(0, '_ColorColumn', { link = cc_link })
    end
  end
  cc_show(winid)
end

---Setup function
---@param opts ColorColumnOptions?
local function setup(opts)
  configs.set_options(opts)

  ---Conceal colorcolumn in each window
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    cc_conceal(win)
  end

  ---Create autocmds for concealing / showing colorcolumn
  local id = vim.api.nvim_create_augroup('Deadcolumn', {})
  vim.api.nvim_create_autocmd('WinLeave', {
    desc = 'Conceal colorcolumn in other windows.',
    group = id,
    callback = function()
      cc_conceal()
    end,
  })

  vim.api.nvim_create_autocmd('ColorScheme', {
    desc = 'Update base colors.',
    group = id,
    callback = update_hl_hex,
  })

  vim.api.nvim_create_autocmd({
    'BufEnter',
    'ColorScheme',
    'CursorMoved',
    'CursorMovedI',
    'ModeChanged',
    'TextChanged',
    'TextChangedI',
    'WinEnter',
    'WinScrolled',
  }, {
    desc = 'Update colorcolumn color.',
    group = id,
    callback = function()
      cc_update()
    end,
  })

  vim.api.nvim_create_autocmd('OptionSet', {
    desc = 'Update colorcolumn color.',
    pattern = { 'colorcolumn', 'textwidth' },
    group = id,
    callback = function()
      cc_update()
    end,
  })

  if configs.opts.extra.follow_tw then
    vim.api.nvim_create_autocmd('OptionSet', {
      pattern = 'textwidth',
      desc = 'Set colorcolumn according to textwidth.',
      callback = function()
        if vim.v.option_new ~= 0 then
          vim.opt_local.colorcolumn = configs.opts.extra.follow_tw
        end
      end,
    })
    vim.api.nvim_create_autocmd('BufEnter', {
      desc = 'Set colorcolumn according to textwidth.',
      callback = function()
        if vim.bo.textwidth ~= 0 then
          vim.opt_local.colorcolumn = configs.opts.extra.follow_tw
        end
      end,
    })
  end
end

return {
  setup = setup,
  configs = configs,
  colors = colors,
}
