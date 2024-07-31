local M = {}

---Config class for clipboard.nvim
---@class config
---@field autosave_history boolean Whether the clipboard should be automatically saved to a file to persist between sessions.
---@field history_size integer The Amount of items to save in the clipboard. Expect it to slow down at high values.
---@field max_item_length integer The max amount of lines to show of each item in the clipboard.
---@field item_separator string The character to use for the separator between clipboard items. Should never be more than one character.
---@field special_symbols boolean Whether to show special symbols, e.g. the symbols for trailing newlines.
---@field item_numbers boolean Whether to show the item indices in the clipboard.
local default_config = {
  autosave_history = true,
  history_size = 50,
  max_item_length = 4,
  item_separator = "─",
  special_symbols = true,
}

---@type config
---@diagnostic disable-next-line unused_fields
local user_config = {}

local state_file = "clipboard-history"
local state_path = vim.fn.stdpath("state")
local path_separator = vim.fn.has("win32") == 1 and "\\" or "/"
local state_file_path = vim.fn.resolve(state_path .. path_separator .. state_file)

local clipboard_history = {}

---@class popup
---@field buf integer
---@field win integer|nil
---@field width integer
---@field height integer
---@field line_width integer
local popup = {}

---- LOCAL FUNCTIONS --------------------------------------------------------------------------

local function get_saved_clipboard_history()
  if vim.fn.filereadable(state_file_path) == 1 then
    local state_file_contents = vim.fn.readfile(state_file_path, "b")

    if #state_file_contents > 1 and state_file_contents[1] ~= "" then
      clipboard_history = state_file_contents
    end
  else
    vim.notify(
      'No clipboard history file found. This is nothing to worry about as it will be created when you exit. If you have the reason to, it can be created manually by running :lua require("clipboard").save_clipboard().',
      vim.log.levels.WARN
    )
  end
end

local function update_clipboard_history()
  local yank_content = vim.fn.getreg('"')

  if yank_content ~= "" then
    table.insert(clipboard_history, 1, yank_content)
  end

  while #clipboard_history > user_config.history_size do
    table.remove(clipboard_history)
  end
end

local function close_popup()
  if vim.api.nvim_buf_is_valid(popup.buf) then
    vim.api.nvim_buf_delete(popup.buf, { force = true })
  end
end

local function render_clipboard_items()
  vim.api.nvim_set_option_value("modifiable", true, { buf = popup.buf })

  local fill_lines = {}

  for _ = 1, #clipboard_history do
    table.insert(fill_lines, "")
  end

  vim.api.nvim_buf_set_lines(popup.buf, 0, -1, false, fill_lines)

  for i, item in ipairs(clipboard_history) do
    local lines = vim.split(item, "\n")

    local first_line_virt = {}
    local rest_lines_virt = {}

    local first_line = #lines[1] > popup.line_width and lines[1]:sub(1, popup.line_width)
      or lines[1]

    if #lines == 2 and lines[2] == "" and user_config.special_symbols then
      local first_line_with_arrow = #first_line + 3 > popup.line_width
          and first_line:sub(1, popup.line_width - 3)
        or first_line

      first_line_virt = { { first_line_with_arrow, "Normal" }, { " 󰌑", "Special" } }
    else
      first_line_virt = { { first_line, "Normal" } }
    end

    if #lines > 1 and lines[2] ~= "" and user_config.special_symbols then
      for j = 2, #lines do
        local line = #lines[j] > popup.line_width and lines[j]:sub(1, popup.line_width) or lines[j]

        if j >= user_config.max_item_length then
          local line_with_dots = #line + 3 > popup.line_width and line:sub(1, popup.line_width - 3)
            or line

          table.insert(rest_lines_virt, { { line_with_dots, "Normal" }, { " ", "Special" } })
          break
        elseif j + 1 == #lines and lines[j + 1] == "" and user_config.special_symbols then
          local line_with_arrow = #line + 3 > popup.line_width and line:sub(1, popup.line_width - 3)
            or line

          table.insert(rest_lines_virt, { { line_with_arrow, "Normal" }, { " 󰌑", "Special" } })
          break
        else
          table.insert(rest_lines_virt, { { line, "Normal" } })
        end
      end
    end

    if i < #clipboard_history and user_config.item_separator ~= "" then
      table.insert(rest_lines_virt, {
        {
          user_config.item_separator:rep(popup.line_width),
          "LineNr",
        },
      })
    end

    vim.api.nvim_buf_set_extmark(popup.buf, popup.ns_id, i - 1, 0, {
      virt_text = first_line_virt,
      virt_text_pos = "overlay",
      virt_lines = rest_lines_virt,
    })
  end

  vim.api.nvim_set_option_value("modifiable", false, { buf = popup.buf })
end

local function remove_clipboard_item()
  local line_nr, _ = unpack(vim.api.nvim_win_get_cursor(popup.win))

  table.remove(clipboard_history, line_nr)

  if #clipboard_history > 0 then
    render_clipboard_items()
  else
    close_popup()
  end
end

local function paste_selected(opts)
  local line_nr, _ = unpack(vim.api.nvim_win_get_cursor(popup.win))
  local line_to_paste = clipboard_history[line_nr]

  close_popup()

  if opts.range ~= 0 then
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    local start_line, start_col = start_pos[2], start_pos[3]
    local end_line, end_col = end_pos[2], end_pos[3]

    local mode = end_col == vim.v.maxcol and "V" or "v"

    vim.cmd(("normal! %dG%d|%s%dG%d|"):format(start_line, start_col, mode, end_line, end_col))

    vim.api.nvim_paste(line_to_paste, true, -1)
  else
    vim.api.nvim_paste(line_to_paste, true, -1)
  end
end

local function set_popup_keymaps(opts)
  vim.keymap.set("n", "<cr>", function()
    paste_selected(opts)
  end, { buffer = popup.buf })

  vim.keymap.set("n", "<esc>", close_popup, { buffer = popup.buf })
  vim.keymap.set("n", "<c-c>", close_popup, { buffer = popup.buf })

  vim.keymap.set("n", "X", function()
    remove_clipboard_item()
  end, { buffer = popup.buf })
end

local function set_popup_autocmds()
  vim.api.nvim_create_autocmd({ "WinClosed" }, {
    buffer = popup.buf,
    callback = close_popup,
  })
end

local function show_clipboard(opts)
  if #clipboard_history > 0 then
    popup = {
      buf = vim.api.nvim_create_buf(false, true),
      width = math.floor(vim.o.columns * 0.45),
      height = math.floor(vim.o.lines * 0.4),
    }

    popup.line_width = popup.width - 3 - #tostring(user_config.history_size)

    popup.win = vim.api.nvim_open_win(popup.buf, true, {
      width = popup.width,
      height = popup.height,
      relative = "win",
      border = "rounded",
      style = "minimal",
      anchor = "NW",
      col = (vim.o.columns - popup.width) / 2,
      row = ((vim.o.lines - popup.height) / 2) - 1,
      title = " Clipboard ",
      title_pos = "center",
    })

    vim.api.nvim_set_option_value(
      "winhl",
      "Normal:Normal,FloatBorder:FloatermBorder,CursorLine:Normal,FloatTitle:texCmdTitle",
      { win = popup.win }
    )

    popup.ns_id = vim.api.nvim_create_namespace("clipboard")

    vim.api.nvim_set_option_value("number", true, { win = popup.win })
    vim.api.nvim_set_option_value(
      "numberwidth",
      #tostring(user_config.history_size) + 2,
      { win = popup.win }
    )

    vim.api.nvim_set_option_value("cursorline", true, { win = popup.win })

    render_clipboard_items()

    set_popup_keymaps(opts)
    set_popup_autocmds()
  else
    print("Clipboard is empty.")
  end
end

---- PUBLIC FUNCTIONS -------------------------------------------------------------------------

---# Opens the clipboard.
function M.open_clipboard()
  show_clipboard()
end

---# Saves the clipboard to the state file.
---
---If `autosave_history = true` this usually doesn't have to be called.
function M.save_clipboard()
  if #clipboard_history > 0 then
    vim.fn.writefile(clipboard_history, state_file_path, "b")
  else
    vim.fn.writefile({}, state_file_path, "b")
  end
end

---# Clears the clipboard.
---
---Does not update the state file automatically.
function M.clear_clipboard()
  clipboard_history = {}
end

---- PLUGIN SETUP -----------------------------------------------------------------------------

local function create_autocmds()
  local clipboard_augroup = vim.api.nvim_create_augroup("Clipboard", { clear = true })

  vim.api.nvim_create_autocmd("TextYankPost", {
    group = clipboard_augroup,
    callback = update_clipboard_history,
  })

  if user_config.autosave_history then
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = clipboard_augroup,
      callback = M.save_clipboard,
    })
  end
end

local function create_user_commands()
  vim.api.nvim_create_user_command(
    "Clipboard",
    show_clipboard,
    { desc = "Open clipboard", nargs = 0, range = true }
  )

  vim.api.nvim_create_user_command("ClipboardClear", function()
    M.clear_clipboard()

    if user_config.autosave_history then
      M.save_clipboard()
    end
  end, { desc = "Clear clipboard", nargs = 0 })
end

---# Should be called from the lazy config to setup and edit the plugin config.
---
---It is recommended to not use this function directly, but instead use the `opts` table in the lazy config which calls this function automatically.
---@param opts? config Optional config
function M.setup(opts)
  ---@type config
  user_config = vim.tbl_deep_extend("keep", opts or {}, default_config)

  assert(#user_config.item_separator > 1, "item_separator cannot be more than one character")
  assert(user_config.max_item_length > 0, "max_item_length must be 1 or higher")
  assert(user_config.history_size > 0, "history_size must be 1 or higher")

  create_user_commands()

  get_saved_clipboard_history()

  create_autocmds()

  while #clipboard_history > user_config.history_size do
    table.remove(clipboard_history)
  end
end

return M
