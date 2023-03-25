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
  ['A'] = 10,
  ['B'] = 11,
  ['C'] = 12,
  ['D'] = 13,
  ['E'] = 14,
  ['F'] = 15,
}

local tohex = {
  [0]  = '0',
  [1]  = '1',
  [2]  = '2',
  [3]  = '3',
  [4]  = '4',
  [5]  = '5',
  [6]  = '6',
  [7]  = '7',
  [8]  = '8',
  [9]  = '9',
  [10] = 'A',
  [11] = 'B',
  [12] = 'C',
  [13] = 'D',
  [14] = 'E',
  [15] = 'F',
}

---Convert an integer from hexadecimal to decimal
---@param hex string
---@return integer dec
local function hex2dec(hex)
  local digit = 1
  local dec = 0

  while digit <= #hex do
    dec = dec + todec[string.sub(hex, digit, digit)] * 16^(#hex - digit)
    digit = digit + 1
  end

  return dec
end

---Convert an integer from decimal to hexadecimal
---@param int integer
---@return string hex
local function dec2hex(int)
  local hex = ''

  while int > 0 do
    hex = tohex[int % 16] .. hex
    int = math.floor(int / 16)
  end

  return hex
end

---Convert a hex color to rgb color
---@param hex string hex code of the color
---@return integer[] rgb
local function hex2rgb(hex)
  local red = string.sub(hex, 1, 2)
  local green = string.sub(hex, 3, 4)
  local blue = string.sub(hex, 5, 6)

  return {
    hex2dec(red),
    hex2dec(green),
    hex2dec(blue),
  }
end

---Convert an rgb color to hex color
---@param rgb integer[]
---@return string
local function rgb2hex(rgb)
  return dec2hex(math.floor(rgb[1]))
      .. dec2hex(math.floor(rgb[2]))
      .. dec2hex(math.floor(rgb[3]))
end

---Blend two hex colors
---@param hex1 string the first color in hdex
---@param hex2 string the second color in hdex
---@param alpha number between 0~1, weight of the first color
---@return string hex_blended blended hex color
local function blend(hex1, hex2, alpha)
  local rgb1 = hex2rgb(hex1)
  local rgb2 = hex2rgb(hex2)

  local rgb_blended = {
    alpha * rgb1[1] + (1 - alpha) * rgb2[1],
    alpha * rgb1[2] + (1 - alpha) * rgb2[2],
    alpha * rgb1[3] + (1 - alpha) * rgb2[3],
  }

  local hex_blended = rgb2hex(rgb_blended)
  hex_blended = hex_blended .. string.rep('0', 6 - #hex_blended)
  return hex_blended
end

---Get background color in hex
---@param hlgroup_name string
---@param field string 'foreground' or 'background'
---@param fallback string|nil fallback color in hex, default to '000000'
---@return string hex color
local function get_hl(hlgroup_name, field, fallback)
  fallback = fallback or '000000'
  local has_hlgroup, hlgroup =
    pcall(vim.api.nvim_get_hl_by_name, hlgroup_name, true)
  if has_hlgroup and hlgroup[field] then
    return dec2hex(hlgroup[field])
  end
  return fallback
end

return {
  hex2dec = hex2dec,
  dec2hex = dec2hex,
  hex2rgb = hex2rgb,
  rgb2hex = rgb2hex,
  blend = blend,
  get_hl = get_hl,
}
