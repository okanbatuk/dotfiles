---@diagnostic disable: undefined-global
-- --- 1. CORE SETTINGS ---
-- Set leader key to Space
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

local node_path = vim.fn.exepath("node")
if node_path ~= "" then
  vim.g.node_host_prog = node_path
end

-- UI & Editor Settings
vim.opt.clipboard = "unnamedplus" -- Sync with system clipboard
vim.opt.number = true             -- Show line numbers
vim.opt.relativenumber = true     -- Relative numbers for easier jumping
vim.opt.termguicolors = true      -- True color support

-- Load legacy vimrc if exists
local vimrc = vim.fn.stdpath("config") .. "/vimrc.vim"
if vim.fn.filereadable(vimrc) == 1 then
  vim.cmd.source(vimrc)
end

-- --- 2. LAZY.NVIM BOOTSTRAP ---
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- --- 3. PLUGIN CONFIGURATION ---
require("lazy").setup({
    -- Theme
    { "folke/tokyonight.nvim",                 lazy = false,       priority = 1000 },

    -- Oil.nvim: Edit your filesystem like a normal Neovim buffer
    {
      'stevearc/oil.nvim',
      opts = {
        view_options = { show_hidden = true }, -- Show dotfiles by default
        -- Custom keymaps for easier navigation
        keymaps = {
          ["h"] = "actions.parent", -- Go to parent directory
          ["l"] = "actions.select", -- Open file or enter directory
        },
      },
      dependencies = { "nvim-tree/nvim-web-devicons" },
    },

    -- Telescope: The ultimate fuzzy finder (Built-in fzf experience)
    {
      'nvim-telescope/telescope.nvim',
      tag = '0.1.5',
      dependencies = { 'nvim-lua/plenary.nvim' },
      opts = {
        defaults = {
          -- Include hidden files by default in searches
          find_command = { "fd", "--type", "f", "--strip-cwd-prefix", "--hidden", "--exclude", ".git" },
        }
      }
    },

    -- Lualine: Status line for better visibility
    {
      'nvim-lualine/lualine.nvim',
      dependencies = { 'nvim-tree/nvim-web-devicons' },
      opts = {
        options = {
          theme = 'tokyonight', -- Synchronize with your theme
          section_separators = '',
          component_separators = '',
          globalstatus = true, -- Single bar at the bottom for all splits
        },
        sections = {
          lualine_z = {
            {
              'datetime',
              style = '%a %H:%M' -- Displays time in HH:MM:SS format
            }
          }
        }
      }
    },

    -- Treesitter: Advanced syntax highlighting
    { "nvim-treesitter/nvim-treesitter",       build = ":TSUpdate" },

    -- Your previous plugins
    { 'tpope/vim-sensible' },
    { 'vim-scripts/Txtfmt-The-Vim-Highlighter' },
  },
  {
    rocks = {
      enabled = false,
      hererocks = false,
    }
  }
)

-- Set colorscheme
vim.cmd("colorscheme tokyonight")

-- --- 4. KEYMAPPINGS ---

-- Oil.nvim: Open file explorer (Minus key is default and very ergonomic)
vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory with Oil" })

-- Telescope: Find files & Grep (Internal version of your 'fo' alias)
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Search text in project' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'List open buffers' })

-- Handlr: Open file or URL under cursor (Space + o)
vim.keymap.set("n", "<leader>o", function()
  local file = vim.fn.expand("<cfile>")
  vim.fn.jobstart({ "handlr", "open", file }, { detach = true })
  print("Handlr dispatched: " .. file)
end, { desc = "Open with handlr" })

-- Nautilus: Open current directory in GNOME Files (Space + e)
vim.keymap.set("n", "<leader>e", function()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" or dir == "." then dir = vim.fn.getcwd() end
  vim.fn.jobstart({ "nautilus", dir }, { detach = true })
end, { desc = "Open Nautilus" })

-- Clipboard management
vim.keymap.set("v", "p", 'pgvy', { noremap = true, silent = true }) -- Keep clipboard clean
vim.keymap.set("n", "x", '"_x', { noremap = true })                 -- Don't yank on 'x' delete
