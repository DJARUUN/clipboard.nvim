<div align="center">

# clipboard.nvim

A simple lua plugin that saves your yanks to a clipboard that persists between sessions.

https://github.com/user-attachments/assets/d5d509b1-67fb-40e8-a29f-2e69bde6813f

</div>

## ⚡ Requirements

- Neovim 0.8+

## 📦 Installation

clipboard.nvim supports all the usual plugin managers

<details open>
  <summary><a href="https://github.com/folke/lazy.nvim">🔗</a> lazy.nvim</summary>

```lua
{
  "https://gitlab.com/djaruun/clipboard.nvim.git",
  opts = {},
}
```
</details>

<details>
  <summary><a href="https://github.com/wbthomason/packer.nvim">🔗</a> packer</summary>

```lua
use({
   "https://gitlab.com/djaruun/clipboard.nvim.git",
   config = function()
   require("clipboard").setup()
   end,
})
```
</details>

## 🔌 Quick start

The default configurations above is all you need to make the plugin work, but keep in mind that it does not set any keymaps by default so you would need to do that yourself.

<details>
<summary>Full keymap example for lazy.nvim</summary>

```lua
{
  "djaruun/clipboard.nvim",
  opts = {},
  keys = {
    {
      mode = { "n", "v" },
      "<leader>sc",
      function()
        require("clipboard").open_clipboard()
      end,
      desc = "Open clipboard",
    },
  }
}
```
</details>

## 🚀 Usage

Do `<leader>sc` (or whatever keymap you set, if any) or `:Clipboard` to open the clipboard. If you haven't yanked anything after installing the plugin and doing this it will just print out `Clipboard is empty.`. To see it in action, yank a bit of text and try opening it again.

This will open a popup window that shows the clipboard history in order from newest to oldest. Use `<CR>` to paste the selected entry at the cursor or selection, `X` to remove the selected entry or `<ESC>` to close the window.

## 🔧 Configuration

This is the default config. If you are fine with the defaults you don't need to do anything here. Just call the `setup` function without any arguments or leave the `opts` table empty (if you're using lazy.nvim).

```lua
require("clipboard").setup({
  ---@field boolean
  -- Whether the clipboard should be automatically saved to a file to
  -- persist between sessions.
  autosave_history = true,

  ---@field integer
  -- The amount of items to save in the clipboard. Expect it to slow
  -- down at high values.
  history_size = 50,

  ---@field integer
  -- The max amount of lines to show of each item in the clipboard.
  max_item_length = 4,

  ---@field string
  -- The character to use for the separator between clipboard items.
  -- Should never be more than one character.
  item_separator = "─",

  ---@field boolean
  -- Whether to show special symbols, e.g. the symbols for trailing
  -- newlines.
  special_symbols = true,

  ---@field string|table<string>
  -- The border of the popup window. This can either be any of the
  -- builtin styles, e.g. "rounded", or a custom border in form of
  -- a table of each border character. Check out
  -- `:h nvim_open_win()` for the exact specification.
  border = "rounded",

  ---@field highlights
  -- The highlight groups for the clipboard window.
  highlights = {
    normal = "Normal",
    special = "Special",
    border = "FloatermBorder",
    title = "texCmdTitle",
    item_separator = "LineNr",
  },
})
```

## 🗃️ API

**Opens the clipboard.**
```lua
require("clipboard").open_clipboard()
```

---

**Saves the clipboard to the state file.**

If `autosave_history = true` this usually doesn't have to be called.
```lua
require("clipboard").save_clipboard()
```

---

**Clears the clipboard.**

Does not update the state file automatically.
```lua
require("clipboard").clear_clipboard()
```

## 💫 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=djaruun/clipboard.nvim&type=Date&theme=dark)](https://star-history.com/#djaruun/clipboard.nvim&Date)
