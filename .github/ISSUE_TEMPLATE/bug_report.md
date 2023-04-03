---
name: Bug report
about: Create a report to help us improve
title: "[Bug]"
labels: ''
assignees: ''

---

**Describe the bug**

- Context

    When and how you triggered the bug

- Expected behavior

    Descriptions and screenshots

- Actual behavior

    Descriptions and screenshots

**To Reproduce**

- Minimal `init.lua`

    ```lua
    vim.opt.termguicolors = true

    local package_root = '/tmp/nvim/site'
    vim.opt.rtp:prepend(package_root)
    vim.opt.pp:prepend(package_root)

    local plugin_root = package_root .. '/pack/test/start'
    local plugin_dir = plugin_root .. '/deadcolumn.nvim'
    local source = 'https://github.com/Bekaboo/deadcolumn.nvim.git'
    if vim.loop.fs_stat(plugin_root) == nil then
      vim.fn.mkdir(plugin_root, 'p')
    end
    if vim.loop.fs_stat(plugin_dir) then
      vim.notify(
        string.format('Path %s already exists, '
                   .. 'remove them manually for a fresh install', plugin_dir),
        vim.log.levels.WARN
      )
    end
    os.execute(string.format('git clone %s %s', source, plugin_dir))

    -- Put your config here to test the setup function
    require('deadcolumn').setup()

    -- Put ftplugin under '/tmp/nvim/site/ftplugin' to test ftplugins

    -- vim:ts=2:sts=2:sw=2:et:
    ```

- Steps to reproduce the behavior

    1. Save the above config as `minimal.lua`
    2. Start Neovim using `nvim --clean -u minimal.lua`
    3. ...

**Environment**

- Neovim version: [e.g. 0.8.0]

- Operating system: [e.g. Ubuntu 20.04]

**Additional context**

Add any other context about the problem here.
