<h1 align='center'>
    deadcolumn.nvim
</h1>

<p align='center'>
    <b>Don't across that column in Neovim</b>
</p>

<p align='center'>
    <img src=https://user-images.githubusercontent.com/76579810/227669246-1cb53d93-1a8b-4edd-949e-9e6da6fa698b.gif width=80%>
</p>

Deadcolumn is a Neovim plugin designed to users in maintaining a
specific column width in their code. This plugin operates by gradually
displaying the `colorcolumn` as the user approaches it. It is useful for
people who wish to keep their code aligned within a specific column range.

**Table of Contents**

- [Features](#features)
- [Installation](#installation)
- [Options](#options)
- [FAQ](#faq)

## Features

- Gradually display the `colorcolumn` as the user approaches it:

    <img src=https://user-images.githubusercontent.com/76579810/227671471-4b92fd6b-6006-4be6-ad40-7e598a2e6cec.gif width=50%>

- Display the column in warning color if current line exceeds `colorcolumn`:

    <img src=https://user-images.githubusercontent.com/76579810/227671655-2718d41c-a336-4f3d-af46-91646de5d98b.gif width=50%>

- Handle multiple values of `colorcolumn` properly:

    - `:set colorcolumn=-10,25,+2 textwidth=20`:

    <img src=https://user-images.githubusercontent.com/76579810/227671926-2824a013-0690-4548-8817-c4aedc77a076.gif width=50%>

- Show the colored column only when you need it

    - Show the colored column in insert mode only:

        <img src=https://user-images.githubusercontent.com/76579810/227672206-eebdb9fd-04d9-4aa1-9cc8-bf2f61e4ccfb.gif width=50%>

    - Show the colored column only when current line is longer than the
        `colorcolumn`:

        <img src=https://user-images.githubusercontent.com/76579810/227672529-8e11425e-3c8f-4f19-99f5-f453a0476dbf.gif width=50%>


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

You don't need to call the `setup()` function if you don't want to
change the default options, the plugin should work out of the box if you set
`colorcolumn` to a value greater than 0.

The following is the default options, you can pass a table to the `setup()`
function to override the default options.

```lua
local opts = {
    threshold = 0.75,
    scope = 'line',
    modes = { 'i', 'ic', 'ix', 'R', 'Rc', 'Rx', 'Rv', 'Rvc', 'Rvx' },
    warning = {
        alpha = 0.4,
        colorcode = '#FF0000',
        hlgroup = {
            'Error',
            'background',
        },
    },
}

require('deadcolumn').setup(opts) -- Call the setup function
```

- `threshold` (number): The threshold for showing the colored column.

    - If `threshold` is a number between 0 and 1, it will be treated as a
        relative threshold, the colored column will be shown when the current
        line is longer than `threshold` times the `colorcolumn`.

    - If `threshold` is a number greater than 1, it will be treated as a
        fixed threshold, the colored column will be shown when the current line
        is longer than `threshold` characters.

- `scope` (string): The scope for showing the colored column, there are several
    possible values:

    - `'line'`: the colored column will be shown when the
        current line is longer than the `colorcolumn`.

    - `'buffer'`: the colored column will be shown when
        any line in the current buffer is longer than the `colorcolumn`.

    - `'visible'`:, the colored column will be shown when
        any line in the visible area is longer than the `colorcolumn`.

    - `'cursor'`: the colored column will be shown when the cursor column is
        greater than the `colorcolumn`.

- `modes` (table): In which modes to show the colored column.

- `warning` (table): Warning color options.

    - `alpha` (number): The alpha value for the warning color, blended with
        the background color.

    - `colorcode` (string): The color code for the warning color.

    - `hlgroup` (table): The highlight group for the warning color.

        - *If the highlight group is not found, `colorcode` will be used*.

## FAQ

- **Why can't I see the colored column?**

    Please make sure you have set `colorcolumn` to a value greater than 0.

    If you set `colorcolumn` to a relative value (e.g. `'-10'`), make sure
    `textwidth` is set to a value greater than 0.

- **How to set different `colorcolumn` for different filetypes?**

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

        For example, you can create a file named `markdown.lua` in the `ftplugin`
        directory under your config directory, and set `colorcolumn` to 80 for
        `markdown` files:

        ```lua
        vim.bo.colorcolumn = '80'
        ```
