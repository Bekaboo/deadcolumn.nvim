local M = {}

-- stylua: ignore start
local todec = {
  ['0'] = 0,
  ['1'] = 1,
  ['2'] = 2,
  ['3'] = 3,
  ['4'] = 4,
  ['5'] = 5,
  ['6'] = 6,
  ['7'] = 7,
  ['8'] = 8,
  ['9'] = 9,
  ['a'] = 10,
  ['b'] = 11,
  ['c'] = 12,
  ['d'] = 13,
  ['e'] = 14,
  ['f'] = 15,
  ['A'] = 10,
  ['B'] = 11,
  ['C'] = 12,
  ['D'] = 13,
  ['E'] = 14,
  ['F'] = 15,
}
-- stylua: ignore end

---Wrapper of nvim_get_hl(), add new option `winhl_link` to get
---highlight attributes without being affected by winhl
---@param ns_id integer
---@param opts table{ name: string?, id: integer?, link: boolean? }
---@return vim.api.keyset.highlight: highlight attributes
function M.get(ns_id, opts)
  local no_winhl_link = opts.winhl_link == false
  opts.winhl_link = nil
  local attr = vim.api.nvim_get_hl(ns_id, opts)
  -- We want to get true highlight attribute not affected by winhl
  if no_winhl_link then
    while attr.link do
      opts.name = attr.link
      attr = vim.api.nvim_get_hl(ns_id, opts)
    end
  end
  return attr
end

---Convert an integer from decimal to hexadecimal
---@param int integer
---@param n_digits integer? number of digits used for the hex code
---@return string hex
function M.dec2hex(int, n_digits)
  return not n_digits and string.format('%x', int)
    or string.format('%0' .. n_digits .. 'x', int)
end

---Convert an integer from hexadecimal to decimal
---@param hex string
---@return integer dec
function M.hex2dec(hex)
  local digit = 1
  local dec = 0
  while digit <= #hex do
    dec = dec + todec[string.sub(hex, digit, digit)] * 16 ^ (#hex - digit)
    digit = digit + 1
  end
  return dec
end

---Convert a hex color to rgb color
---@param hex string hex code of the color
---@return integer[] rgb
function M.hex2rgb(hex)
  return {
    M.hex2dec(string.sub(hex, 1, 2)),
    M.hex2dec(string.sub(hex, 3, 4)),
    M.hex2dec(string.sub(hex, 5, 6)),
  }
end

---Convert an rgb color to hex color
---@param rgb integer[]
---@return string
function M.rgb2hex(rgb)
  local hex = {
    M.dec2hex(math.floor(rgb[1])),
    M.dec2hex(math.floor(rgb[2])),
    M.dec2hex(math.floor(rgb[3])),
  }
  hex = {
    string.rep('0', 2 - #hex[1]) .. hex[1],
    string.rep('0', 2 - #hex[2]) .. hex[2],
    string.rep('0', 2 - #hex[3]) .. hex[3],
  }
  return table.concat(hex, '')
end

---Blend two colors
---@param c1 string|number|table the first color, in hex, dec, or rgb
---@param c2 string|number|table the second color, in hex, dec, or rgb
---@param alpha number? between 0~1, weight of the first color, default to 0.5
---@return { hex: string, dec: integer, r: integer, g: integer, b: integer }
function M.cblend(c1, c2, alpha)
  alpha = alpha or 0.5
  c1 = type(c1) == 'number' and M.dec2hex(c1, 6) or c1
  c2 = type(c2) == 'number' and M.dec2hex(c2, 6) or c2
  local rgb1 = type(c1) == 'string' and M.hex2rgb(c1:gsub('#', '', 1)) or c1
  local rgb2 = type(c2) == 'string' and M.hex2rgb(c2:gsub('#', '', 1)) or c2
  local rgb_blended = {
    alpha * rgb1[1] + (1 - alpha) * rgb2[1],
    alpha * rgb1[2] + (1 - alpha) * rgb2[2],
    alpha * rgb1[3] + (1 - alpha) * rgb2[3],
  }
  local hex = M.rgb2hex(rgb_blended)
  return {
    hex = '#' .. hex,
    dec = M.hex2dec(hex),
    r = math.floor(rgb_blended[1]),
    g = math.floor(rgb_blended[2]),
    b = math.floor(rgb_blended[3]),
  }
end

return M
