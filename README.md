# `visual-lines.nvim`

Highlight visually selected line numbers in Neovim.

![visual-lines](https://github.com/user-attachments/assets/ab93c731-b8c4-48fe-b282-bdb589754daa)

## ✨ Features

- Set a custom foreground and background color while visually selecting lines
- That's it!

## 📦 Installation and Configuration

[folke/lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    'joncrangle/visual-lines.nvim',
}
```

<details>
<summary>Full configuration with default values</summary>

```lua
{
    'joncrangle/visual-lines.nvim',
    ---@type VisualLineNumbersOptions
    opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        fg = '#F9E2AF', -- defaults to your `CursorLineNr` highlight color
        bg = 'NONE',
        highlight_group = 'VisualLineNr', -- highlight group name
        max_lines = 2000, -- maximum number of lines
        priority = 10, -- priority for extmarks

        -- Filetypes and buftypes to exclude
        -- To add a new one, create an entry and set it to `true`.
        -- To remove a default, set it to `false`.
        exclude_filetypes = {
            alpha = true,
            checkhealth = true,
            dashboard = true,
            help = true,
            lazy = true,
            lazygit = true,
            lspinfo = true,
            man = true,
            mason = true,
            minifiles = true,
            ministarter = true,
            ["neo-tree"] = true,
            noice = true,
            notify = true,
            NvimTree = true,
            qf = true,
            snacks_dashboard = true,
            snacks_picker_input = true,
            snacks_picker_list = true,
            snacks_terminal = true,
            TelescopePrompt = true,
            TelescopeResults = true,
            Trouble = true,
        },
        exclude_buftypes = {
            nofile = true,
            prompt = true,
            quickfix = true,
            terminal = true,
        },
    },
}
```

## 🧰 Commands

- `:VisualLineNumbers enable`
- `:VisualLineNumbers disable`
- `:VisualLineNumbers toggle`
