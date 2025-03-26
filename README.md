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
    event = { 'BufReadPre', 'BufNewFile' }, -- optional
    opts = {},
}
```

<details>
<summary>Full configuration with default values</summary>

```lua
{
    'joncrangle/visual-lines.nvim',
    event = { 'BufReadPre', 'BufNewFile' }, -- optional
    ---@type VisualLineNumbersOptions
    opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        fg = '#F9E2AF', -- defaults to your `CursorLineNr` highlight color
        bg = 'NONE',
        highlight_group = 'VisualLineNr', -- highlight group name
        priority = 10, -- priority for extmarks
    },
}
```
