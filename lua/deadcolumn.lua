local configs = require('deadcolumn.configs')
local autocmds = require('deadcolumn.autocmds')

---Setup function
---@param opts ColorColumnOptions
local function setup(opts)
  configs.set_options(opts)
  if not vim.g.loaded_deadcolumn then
    vim.g.loaded_deadcolumn = true
    autocmds.init()
    autocmds.make_autocmds()
  end
end

return {
  setup = setup,
}
