function colorMyVim(color)
  color = color or 'tokyonight-night'
  vim.cmd.colorscheme(color)
  vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
  vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })
  vim.cmd.hi 'Comment gui=none'
end
return {
  'folke/tokyonight.nvim',
  priority = 1000,
  init = colorMyVim 'tokyonight-night',
}
