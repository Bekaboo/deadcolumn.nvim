<h1 align='center'>
    deadcolumn.nvim
</h1>

[![luarocks](https://img.shields.io/luarocks/v/bekaboo/deadcolumn.nvim?logo=lua&color=blue)](https://luarocks.org/modules/bekaboo/deadcolumn.nvim)

<p align='center'>
    <b>Don't across that column in Neovim</b>
</p>

<p align='center'>
    <img src=https://user-images.githubusercontent.com/76579810/227669246-1cb53d93-1a8b-4edd-949e-9e6da6fa698b.gif width=90%>
</p>

Deadcolumn is a neovim plugin to assist users in maintaining a specific column
width in their code. This plugin operates by gradually displaying the
`colorcolumn` as the user approaches it. It is useful for people who wish to
keep their code aligned within a specific column range.

**Table of Contents**

- [Features](#features)
- [Installation](#installation)
- [Options](#options)
- [FAQ](#faq)
- [Known Issues](#known-issues)
- [Similar Projects](#similar-projects)

## Features

- Gradually display the `colorcolumn` as the user approaches it:

    <img src=https://user-images.githubusercontent.com/76579810/227671471-4b92fd6b-6006-4be6-ad40-7e598a2e6cec.gif width=70%>

- Display the column in warning color if current line exceeds `colorcolumn`:

    <img src=https://user-images.githubusercontent.com/76579810/227671655-2718d41c-a336-4f3d-af46-91646de5d98b.gif width=70%>

- Handle multiple values of `colorcolumn` properly:

    - `:set colorcolumn=-10,25,+2 textwidth=20`:

    <img src=https://user-images.githubusercontent.com/76579810/227671926-2824a013-0690-4548-8817-c4aedc77a076.gif width=70%>

- Show the colored column only when you need it

    - Show the colored column in insert mode only:

        <img src=https://user-images.githubusercontent.com/76579810/227672206-eebdb9fd-04d9-4aa1-9cc8-bf2f61e4ccfb.gif width=70%>

    - Show the colored column only when current line is longer than
      `colorcolumn`:

        <img src=https://user-images.githubusercontent.com/76579810/227672529-8e11425e-3c8f-4f19-99f5-f453a0476dbf.gif width=70%>


    - and more...

## Installation

- Using [lazy.nvim](https://github.com/folke/lazy.nvim)

    ```lua
    lua require('lazy').setup({
        { 'Bekaboo/deadcolumn.nvim' }
    })
    ```

- Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

    ```lua
    require('packer').startup(function(use)
        use 'Bekaboo/deadcolumn.nvim'
    end)
    ```

## Options

:warning: **Notice**

You don't need to call the `setup()` function if you don't want to change the
default options, the plugin should work out of the box if you set `colorcolumn`
to a value greater than 0.

The following is the default options, you can pass a table to the `setup()`
function to override the default options.

```lua
local opts = {
    scope = 'line', ---@type string|fun(): integer
    ---@type string[]|fun(mode: string): boolean
    modes = function(mode)
        return mode:find('^[ictRss\x13]') ~= nil
    end,
    blending = {
        threshold = 0.75,
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

require('deadcolumn').setup(opts) -- Call the setup function
```

- `scope` (string|function): The scope for showing the colored column, there
  are several possible values:

    - `'line'`: colored column will be shown based on the length of the current
      line.

    - `'buffer'`: colored column will be shown based on the length of the
      longest line in current buffer (up to 1000 lines around current line).

    - `'visible'`: colored column will be shown based on the length of the
      longest line in the visible area.

    - `'cursor'`: colored column will be shown based on current cursor
      position.

    - `function() -> number`: callback function that returns a number as the
      length of the row. For example, to show the colored column based on the
      longest line in the nearby 100 lines:

      ```lua
        require('deadcolumn').setup({
            scope = function()
                local max = 0
                for i = -50, 50 do
                    local len = vim.fn.strdisplaywidth(vim.fn.getline(vim.fn.line('.') + i))
                    if len > max then
                        max = len
                    end
                end
                return max
            end
        })
      ```

- `modes` (table|function): In which modes to show the colored column.

    - If `modes` is a table, it should contain a list of mode names

    - If `modes` is a function, it should accept a string as the mode name and
      return a boolean value indicating whether to show the colored column in
      that mode.

- `blending` (table): Blending options.

    - `threshold` (number): The threshold for showing the colored column.

        - If `threshold` is a number between 0 and 1, it will be treated as a
          relative threshold, the colored column will be shown when the current
          line is longer than `threshold` times the `colorcolumn`.

        - If `threshold` is a number greater than 1, it will be treated as a fixed
          threshold, the colored column will be shown when the current line is
          longer than `threshold` characters.

    - `colorcode` (string): The color code to be used as the background color for
      blending.

    - `hlgroup` (table): The highlight group to be used as the background color
      for blending.

        - *If the highlight group is not found, `colorcode` will be used*.

- `warning` (table): Warning color options.

    - `alpha` (number): The alpha value for the warning color, blended with the
      background color.

    - `offset` (number): The offset for the warning color, the warning color
      will be shown when the length of the line exceeds `colorcolumn` by
      `offset` characters.

    - `colorcode` (string): The color code for the warning color.

    - `hlgroup` (table): The highlight group for the warning color.

        - *If the highlight group is not found, `colorcode` will be used*.

- `extra` (table): Extra functionalities.

    - `follow_tw` (nil|string):

        - If `follow_tw` is `nil`: the functionalities is disabled.

        - If `follow_tw` is string: `colorcolumn` will be set to this value
          when `textwidth` is set, and will be restored to the original value
          when `textwidth` is unset.

          Suggested value for this option is `'+1'`.

## FAQ

### Why can't I see the colored column?

This can have several reasons:

1. If you are using the default config, it is expected that you can't see the
   colored column in normal mode, because the colored column is only shown in
   insert mode and replace mode by default. You can change the `modes` option
    to show the colored column in normal mode.

2. Please make sure you have set `colorcolumn` to a value greater than 0 in
   your config. Also, make sure that you have `termguicolors` set using
   `:set termguicolors`

3. If you set `colorcolumn` to a relative value (e.g. `'-10'`), make sure
   `textwidth` is set to a value greater than 0.

### How to set different `colorcolumn` for different filetypes?

This plugin does not set `colorcolumn` for you, it only reads and uses the
value of `colorcolumn` of the current buffer to show the colored column
when needed.

It leaves to you to set `colorcolumn` for different filetypes, under different
conditions, which is more flexible compared to setting `colorcolumn` in the
plugin setup function.

There are mainly two ways to set `colorcolumn` for different filetypes:

1. Using `autocmd`:

    You can use the `autocmd` command to set `colorcolumn` for different
    filetypes.

    For example, you can set `colorcolumn` to 80 for markdown files:

    ```vim
    autocmd FileType markdown setlocal colorcolumn=80
    ```

2. Using `ftplugin`:

    You can also use the `ftplugin` directory to set `colorcolumn` for
    different filetypes.

    For example, you can create a file named `markdown.vim` in the
    `ftplugin` directory under your config directory, and set `colorcolumn`
    to 80 for `markdown` files:

    ```vim
    setlocal colorcolumn=80
    ```

## Known Issues

### Transparent Background

If you are using a transparent background, the colored column may not be
displayed properly, since the background color of the colored column
dynamically changed based on the blending of `'Normal'` background color and
the orignial `'ColorColumn'` background color.

If Deadcolumn cannot find the `'Normal'` background color, it will use
`'#000000'` (pure black) as the default background color for blending.

There is no way to fix this, since terminal emulators do not support setting
a transparent background color for a specific character.

**Workarounds:**

1. You can set `opts.threshold` to 1 to disable blending when the length is
   smaller than `colorcolumn` and show the colored column only when it is
   greater than `colorcolumn`, OR

2. You can assign a different highlight group or a fixed colorcode to be used
   for blending with the original `'ColorColumn'` background color, for
   example:

   ```lua
   require('deadcolumn').setup({
       blending = {
           colorcode = '#1F2430',
           hlgroup = { 'NonText', 'bg' },
       },
   })
   ```

## Similar Projects

- [smartcolumn.nvim](https://github.com/m4xshen/smartcolumn.nvim)
- [virt-column.nvim](https://github.com/lukas-reineke/virt-column.nvim)
- [virtcolumn.nvim](https://github.com/xiyaowong/virtcolumn.nvim)
