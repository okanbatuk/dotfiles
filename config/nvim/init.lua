local vimrc = vim.fn.stdpath("config") .. "/vimrc.vim"
vim.cmd.source(vimrc)
vim.cmd("colorscheme tokyonight")

-- Sync everythin with system clipboard (d, y, p, x, c)
vim.opt.clipboard = "unnamedplus"

local vim = vim
local Plug = vim.fn['plug#']

vim.call('plug#begin')
Plug('tpope/vim-sensible')
Plug('vim-scripts/Txtfmt-The-Vim-Highlighter')
vim.call('plug#end')

require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'
  use 'folke/tokyonight.nvim'
end)

-- send the replaced text to the black hole register to keep the clipboard clean.
vim.keymap.set("v", "p", '"_dP', { noremap = true, silent = true })

-- Prevent single character deletions with 'x' from overwriting the clipboard
vim.keymap.set("n", "x", '"_x', { noremap = true })
