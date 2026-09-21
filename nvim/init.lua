-- =========================
-- init.lua (fixed for NVIM 0.11 + Telescope ft_to_lang crash)
-- =========================

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.opt.termguicolors = true

-- NVIM 0.11 compatibility shim (kept, harmless)
if vim.treesitter and vim.treesitter.language and vim.treesitter.language.ft_to_lang == nil and type(vim.treesitter.language.get_lang) == 'function' then
  vim.treesitter.language.ft_to_lang = vim.treesitter.language.get_lang
end

-- Nerd Font flag (you currently set it false)
vim.g.have_nerd_font = false

-- Options
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.mouse = 'a'
vim.opt.showmode = false

vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

vim.opt.breakindent = true
vim.opt.undofile = false
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split'
vim.opt.cursorline = true
vim.opt.scrolloff = 10

-- Keymaps
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('i', '<C-c>', '<Esc>', { desc = 'Exit insert mode with Ctrl+C' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set({ 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action, { desc = '[C]ode [A]ction' })
vim.opt.clipboard:append 'unnamedplus'

-- Keep the system clipboard reserved for yanks.  Deletes and changes still modify the buffer,
-- but use Vim's black-hole register so they do not replace a copied value.  Visual paste needs
-- the same treatment because it normally deletes the selected text before pasting.
vim.keymap.set({ 'n', 'x' }, 'd', '"_d', { desc = 'Delete without replacing clipboard' })
vim.keymap.set({ 'n', 'x' }, 'c', '"_c', { desc = 'Change without replacing clipboard' })
vim.keymap.set({ 'n', 'x' }, 'x', '"_x', { desc = 'Delete character without replacing clipboard' })
vim.keymap.set('n', 'X', '"_X', { desc = 'Delete previous character without replacing clipboard' })
vim.keymap.set('n', 'D', '"_D', { desc = 'Delete to line end without replacing clipboard' })
vim.keymap.set('n', 'C', '"_C', { desc = 'Change to line end without replacing clipboard' })
vim.keymap.set('n', 's', '"_s', { desc = 'Substitute without replacing clipboard' })
vim.keymap.set('n', 'S', '"_S', { desc = 'Substitute line without replacing clipboard' })
vim.keymap.set('x', 'p', '"_dP', { desc = 'Paste without replacing clipboard' })
vim.keymap.set('x', 'P', '"_dP', { desc = 'Paste without replacing clipboard' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.keymap.set('n', '<A-j>', ':m .+1<CR>==')
vim.keymap.set('n', '<A-k>', ':m .-2<CR>==')
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv=gv")
vim.keymap.set('n', '<leader>r', '<cmd>checktime<CR>', { silent = true, desc = 'Reload buffers from disk' })

vim.keymap.set('n', '<A-down>', ':m .+1<CR>==')
vim.keymap.set('n', '<A-up>', ':m .-2<CR>==')
vim.keymap.set('v', '<A-down>', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', '<A-up>', ":m '<-2<CR>gv=gv")

vim.keymap.set('n', '<S-Tab>', '< <Space><Space>')
vim.keymap.set('n', '<Tab>', '> <Space><Space>')

-- Autocmd: yank highlight
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

local function jump_to_file_line_from_output()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local matches = {}
  local start_from = 1

  while true do
    local start_pos, end_pos, path, lnum = line:find('([%w%._~%-%+/@]+):(%d+)', start_from)
    if not start_pos then
      break
    end
    table.insert(matches, { start_pos = start_pos, end_pos = end_pos, path = path, lnum = tonumber(lnum) })
    start_from = end_pos + 1
  end

  local target = nil
  for _, match in ipairs(matches) do
    if col >= match.start_pos and col <= match.end_pos then
      target = match
      break
    end
  end
  target = target or (#matches == 1 and matches[1] or nil)

  if not target then
    vim.notify('No path:line target found under cursor', vim.log.levels.WARN)
    return
  end

  local path = vim.fn.expand(target.path)
  if path:sub(1, 1) ~= '/' then
    path = vim.fn.fnamemodify(vim.fn.getcwd() .. '/' .. path, ':p')
  end

  if vim.fn.filereadable(path) == 0 then
    vim.notify(('File not found: %s'):format(path), vim.log.levels.WARN)
    return
  end

  local origin_win = vim.api.nvim_get_current_win()
  local previous_win = vim.fn.win_getid(vim.fn.winnr '#')
  if previous_win ~= 0 and vim.api.nvim_win_is_valid(previous_win) and vim.api.nvim_win_get_config(previous_win).relative == '' then
    vim.api.nvim_set_current_win(previous_win)
  elseif vim.api.nvim_win_get_config(origin_win).relative ~= '' or vim.bo.filetype == 'codex' then
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local buf = vim.api.nvim_win_get_buf(win)
      if win ~= origin_win and vim.api.nvim_win_get_config(win).relative == '' and vim.bo[buf].filetype ~= 'codex' then
        vim.api.nvim_set_current_win(win)
        break
      end
    end
  end

  if vim.bo.modified then
    vim.cmd.split(vim.fn.fnameescape(path))
  else
    vim.cmd.edit(vim.fn.fnameescape(path))
  end
  local line_count = vim.api.nvim_buf_line_count(0)
  vim.api.nvim_win_set_cursor(0, { math.min(target.lnum, line_count), 0 })
  vim.cmd 'normal! zz'
end

vim.api.nvim_create_autocmd('FileType', {
  desc = 'Make Codex path:line output jumpable',
  group = vim.api.nvim_create_augroup('codex-output-jump', { clear = true }),
  pattern = 'codex',
  callback = function(event)
    vim.keymap.set('n', 'gF', jump_to_file_line_from_output, { buffer = event.buf, desc = 'Open Codex path:line target' })
  end,
})

local function open_codex_with_cmd(cmd)
  local codex = require 'codex'
  local state = require 'codex.state'

  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil

  if state.job then
    vim.fn.jobstop(state.job)
    state.job = nil
  end

  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
  end
  state.buf = nil

  codex.setup { cmd = cmd }
  codex.open()
end

local function get_visual_selection()
  local start_pos = vim.fn.getpos "'<"
  local end_pos = vim.fn.getpos "'>"
  local start_line = math.min(start_pos[2], end_pos[2])
  local end_line = math.max(start_pos[2], end_pos[2])

  if start_line <= 0 or end_line <= 0 then
    return '', start_line, end_line
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local text = table.concat(lines, '\n')
  return text, start_line, end_line
end

local codex_selection_model = 'gpt-5.3-codex-spark'
local codex_selection_reasoning_effort = 'low'
local codex_selection_verbosity = 'low'

local function make_codex_selection_prompt(instruction)
  local snippet, start_line, end_line = get_visual_selection()
  if snippet == '' then
    vim.notify('No selected code to send to Codex', vim.log.levels.WARN)
    return nil
  end

  local file = vim.api.nvim_buf_get_name(0)
  local relative_file = file ~= '' and vim.fn.fnamemodify(file, ':.') or '[No file]'
  local filetype = vim.bo.filetype ~= '' and vim.bo.filetype or 'text'

  return table.concat({
    instruction,
    '',
    'Context:',
    '- File: ' .. relative_file,
    '- Lines: ' .. start_line .. '-' .. end_line,
    '- Filetype: ' .. filetype,
    '',
    '```' .. filetype,
    snippet,
    '```',
  }, '\n')
end

local function open_codex_result_buffer(title)
  vim.cmd 'botright new'
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, 'Codex ' .. title .. ' ' .. os.date '%H:%M:%S')
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'markdown'
  vim.keymap.set('n', 'q', '<cmd>bd!<CR>', { buffer = buf, desc = 'Close Codex result' })
  return buf
end

local function set_codex_result_lines(buf, lines)
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end
end

local function run_codex_ephemeral_prompt(prompt, title)
  local buf = open_codex_result_buffer(title)
  set_codex_result_lines(buf, {
    '# ' .. title,
    '',
    'Running Codex one-shot review...',
  })

  vim.system({
    'codex',
    'exec',
    '--ephemeral',
    '-m',
    codex_selection_model,
    '-c',
    'model_reasoning_effort="' .. codex_selection_reasoning_effort .. '"',
    '-c',
    'verbosity="' .. codex_selection_verbosity .. '"',
    '--skip-git-repo-check',
    '--sandbox',
    'read-only',
    '--color',
    'never',
    '-C',
    vim.uv.cwd(),
    '-',
  }, {
    text = true,
    stdin = prompt,
  }, function(result)
    vim.schedule(function()
      local output = vim.trim(result.stdout or '')
      local stderr = vim.trim(result.stderr or '')
      local lines = {}

      if output ~= '' then
        lines = vim.split(output, '\n', { plain = true })
      else
        lines = { '# ' .. title, '', 'Codex returned no output.' }
      end

      if result.code ~= 0 then
        table.insert(lines, '')
        table.insert(lines, '---')
        table.insert(lines, '')
        table.insert(lines, 'Codex exited with code ' .. result.code .. '.')
        if stderr ~= '' then
          table.insert(lines, '')
          table.insert(lines, '```text')
          vim.list_extend(lines, vim.split(stderr, '\n', { plain = true }))
          table.insert(lines, '```')
        end
      end

      set_codex_result_lines(buf, lines)
    end)
  end)
end

local function codex_review_visual_selection()
  local prompt = make_codex_selection_prompt [[
Review the selected code snippet. Focus on correctness, bugs, API misuse, edge cases, and missing tests. Do not edit files. Return concise findings first with severity and line references relative to the snippet when possible. If you find no issues, say that clearly and mention any residual uncertainty.
]]
  if prompt then
    run_codex_ephemeral_prompt(prompt, 'Selection Review')
  end
end

local function codex_prompt_visual_selection()
  vim.ui.input({ prompt = 'Codex prompt for selection: ' }, function(input)
    if not input or vim.trim(input) == '' then
      return
    end

    local prompt = make_codex_selection_prompt(vim.trim(input))
    if prompt then
      run_codex_ephemeral_prompt(prompt, 'Selection Prompt')
    end
  end)
end

local function codex_explain_usage_visual_selection()
  local prompt = make_codex_selection_prompt [[
Explain the selected API/member/function and show a minimal realistic C++ usage example. Include what the parameters mean, what state or preconditions are required, what the return value or side effects are, and any common mistakes. Do not edit files.
]]
  if prompt then
    run_codex_ephemeral_prompt(prompt, 'API Usage Example')
  end
end

vim.api.nvim_create_user_command('CodexReviewSelection', codex_review_visual_selection, {
  range = true,
  desc = 'Review the last visual selection with Codex',
})

vim.api.nvim_create_user_command('CodexPromptSelection', codex_prompt_visual_selection, {
  range = true,
  desc = 'Prompt Codex with the last visual selection',
})

vim.api.nvim_create_user_command('CodexExplainSelection', codex_explain_usage_visual_selection, {
  range = true,
  desc = 'Explain selected API usage with Codex',
})

vim.keymap.set('x', '<leader>cr', codex_review_visual_selection, { desc = 'Review selected code with Codex' })
vim.keymap.set('x', '<leader>cR', codex_prompt_visual_selection, { desc = 'Prompt Codex with selected code' })
vim.keymap.set('x', '<leader>ce', codex_explain_usage_visual_selection, { desc = 'Explain selected API usage' })

-- lazy.nvim bootstrap
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Plugins
require('lazy').setup({
  'tpope/vim-sleuth',

  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },

  {
    'nvim-tree/nvim-tree.lua',
    version = '*',
    lazy = false,
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      local nvim_tree = require 'nvim-tree'
      local api = require 'nvim-tree.api'
      nvim_tree.setup {}
      vim.keymap.set('n', '<C-b>', function()
        api.tree.toggle { path = '<args>', find_file = false, update_root = false, focus = true }
      end, { noremap = true, silent = true, desc = 'Toggle Nvim Tree' })
    end,
  },

  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      delay = 0,
      icons = {
        mappings = vim.g.have_nerd_font,
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },
      spec = {
        { '<leader>c', group = '[C]ode', mode = { 'n', 'x' } },
        { '<leader>d', group = '[D]ocument' },
        { '<leader>r', group = '[R]ename' },
        { '<leader>s', group = '[S]earch' },
        { '<leader>w', group = '[W]orkspace' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      },
    },
  },

  -- Telescope (FIXED: disable TS in preview to stop ft_to_lang crash on NVIM 0.11)
  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      require('telescope').setup {
        defaults = {
          preview = {
            treesitter = false, -- ✅ REAL FIX
          },
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      local builtin = require 'telescope.builtin'

      local function include_dirs_from_compile_commands()
        local start = vim.api.nvim_buf_get_name(0)
        if start == '' then
          start = vim.uv.cwd()
        end

        local compile_commands = vim.fs.find('compile_commands.json', {
          upward = true,
          path = start,
        })[1]

        if not compile_commands then
          return {}
        end

        local ok, entries = pcall(vim.json.decode, table.concat(vim.fn.readfile(compile_commands), '\n'))
        if not ok or type(entries) ~= 'table' then
          return {}
        end

        local dirs = {}
        local seen = {}
        local function add_dir(dir, base_dir)
          if not dir or dir == '' then
            return
          end

          if not dir:match('^/') and base_dir and base_dir ~= '' then
            dir = base_dir .. '/' .. dir
          end

          dir = vim.fs.normalize(dir)
          if vim.fn.isdirectory(dir) == 1 and not seen[dir] then
            seen[dir] = true
            table.insert(dirs, dir)
          end
        end

        local current_file = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
        table.sort(entries, function(left, right)
          local left_file = left.file and vim.fs.normalize(left.file) or ''
          local right_file = right.file and vim.fs.normalize(right.file) or ''
          return left_file == current_file and right_file ~= current_file
        end)

        local function args_from_entry(entry)
          if type(entry.arguments) == 'table' then
            return entry.arguments
          end

          local command = entry.command or ''
          if command == '' then
            return {}
          end

          return vim.fn.split(command)
        end

        local include_flags = {
          ['-I'] = true,
          ['-isystem'] = true,
          ['-iquote'] = true,
          ['-idirafter'] = true,
        }

        for _, entry in ipairs(entries) do
          local args = args_from_entry(entry)
          local i = 1
          while i <= #args do
            local arg = args[i]
            if include_flags[arg] then
              i = i + 1
              add_dir(args[i], entry.directory)
            elseif arg:match('^-I.+') then
              add_dir(arg:sub(3), entry.directory)
            elseif arg:match('^-isystem.+') then
              add_dir(arg:sub(9), entry.directory)
            elseif arg:match('^-iquote.+') then
              add_dir(arg:sub(8), entry.directory)
            elseif arg:match('^-idirafter.+') then
              add_dir(arg:sub(12), entry.directory)
            elseif arg:match('^/I.+') then
              add_dir(arg:sub(3), entry.directory)
            end
            i = i + 1
          end
        end

        return dirs
      end

      local cached_cpp_include_dirs
      local function cpp_implicit_include_dirs()
        if cached_cpp_include_dirs then
          return cached_cpp_include_dirs
        end

        cached_cpp_include_dirs = {}
        local seen = {}
        local function add_dir(dir)
          if dir and dir ~= '' and vim.fn.isdirectory(dir) == 1 and not seen[dir] then
            seen[dir] = true
            table.insert(cached_cpp_include_dirs, dir)
          end
        end

        local output = vim.fn.systemlist('c++ -E -x c++ - -v < /dev/null 2>&1')
        local in_search_list = false
        for _, line in ipairs(output) do
          if line:match('#include <%.%.%.> search starts here:') then
            in_search_list = true
          elseif line:match('End of search list%.') then
            in_search_list = false
          elseif in_search_list then
            add_dir(vim.trim(line))
          end
        end

        return cached_cpp_include_dirs
      end

      local function grep_current_include_dir(opts)
        opts = opts or {}
        local line = vim.api.nvim_get_current_line()
        local include_path = line:match('#%s*include%s*[<"]([^>"]*)')
        local include_root = include_path and include_path:match('^([^/]+)')

        if not include_root or include_root == '' then
          vim.notify('Put the cursor on a line like #include <rosbag/...>', vim.log.levels.WARN)
          return
        end

        local search_roots = include_dirs_from_compile_commands()
        vim.list_extend(search_roots, cpp_implicit_include_dirs())
        vim.list_extend(search_roots, {
          '/usr/include',
          '/usr/local/include',
          '/opt/ros/' .. (vim.env.ROS_DISTRO or '') .. '/include',
        })

        local grep_dir
        for _, root in ipairs(search_roots) do
          local include_dir = root .. '/' .. include_root
          local include_file = root .. '/' .. include_path
          if vim.fn.isdirectory(include_dir) == 1 then
            grep_dir = include_dir
            break
          elseif vim.fn.filereadable(include_file) == 1 then
            grep_dir = vim.fs.dirname(include_file)
            break
          end
        end

        if not grep_dir then
          vim.notify('Could not find installed include path for ' .. include_path, vim.log.levels.WARN)
          return
        end

        builtin.live_grep {
          cwd = grep_dir,
          prompt_title = 'RG ' .. grep_dir,
          default_text = opts.args,
        }
      end

      vim.api.nvim_create_user_command('SearchIncludeHeaders', function(opts)
        grep_current_include_dir(opts)
      end, {
        nargs = '*',
        desc = 'Ripgrep inside the installed include directory from the current #include line',
      })

      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>si', function()
        grep_current_include_dir()
      end, { desc = '[S]earch [I]nclude headers' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
    end,
  },

  -- ✅ FIXED: nvim-devdocs spec (your original had vim.keymap.set directly inside the plugin table)
  {
    'luckasRanarison/nvim-devdocs',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    opts = {},
    keys = {
      {
        '<leader>dscpp',
        function()
          vim.cmd 'DevdocsOpen cpp'
        end,
        desc = 'Open C++ DevDocs TOC',
      },
    },
  },

  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },

  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'williamboman/mason.nvim', opts = {} },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
          map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
          map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
          vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostics' })
          map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
          map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
          map('<leader>dm', function()
            require('telescope.builtin').lsp_document_symbols {
              symbols = { 'field', 'property', 'variable', 'constant', 'enummember' },
              prompt_title = 'LSP Data Members',
            }
          end, '[D]ata [M]embers')
          map('<leader>df', function()
            require('telescope.builtin').lsp_document_symbols {
              symbols = { 'function', 'method', 'constructor', 'operator' },
              prompt_title = 'LSP Functions and Methods',
            }
          end, '[D]ocument [F]unctions')
          map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_references) then
            map('<leader>fr', function()
              local active_client = vim.lsp.get_client_by_id(event.data.client_id)
              if not active_client then
                vim.notify('LSP client is no longer attached', vim.log.levels.WARN)
                return
              end

              local offset_encoding = active_client.offset_encoding or 'utf-16'
              local params = vim.lsp.util.make_position_params(0, offset_encoding)
              params.context = { includeDeclaration = true }

              active_client:request(vim.lsp.protocol.Methods.textDocument_references, params, function(err, result)
                if err then
                  vim.notify('LSP references failed: ' .. (err.message or tostring(err)), vim.log.levels.ERROR)
                  return
                end

                if not result or vim.tbl_isempty(result) then
                  vim.notify('No references found', vim.log.levels.INFO)
                  return
                end

                local current_uri = vim.uri_from_bufnr(event.buf)
                local filtered = vim.tbl_filter(function(location)
                  return location.uri == current_uri or location.targetUri == current_uri
                end, result)

                if vim.tbl_isempty(filtered) then
                  vim.notify('No references found in current file', vim.log.levels.INFO)
                  return
                end

                vim.fn.setloclist(0, {}, ' ', {
                  title = 'LSP references in current file',
                  items = vim.lsp.util.locations_to_items(filtered, offset_encoding),
                })
                vim.cmd.lopen()
              end, event.buf)
            end, '[F]ile [R]eferences')
          end

          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

      local servers = {
        clangd = {
          cmd = {
            'clangd',
            '--background-index',
            '--clang-tidy',
            '--completion-style=bundled',
            '--cross-file-rename',
            '--header-insertion=iwyu',
          },
        },
        pyright = {
          python = {
            analysis = {
              autoSearchPaths = true,
              diagnosticMode = 'openFilesOnly',
              useLibraryCodeForTypes = true,
              reportDuplicateImport = true,
            },
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              completion = { callSnippet = 'Replace' },
            },
          },
        },
      }

      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, { 'stylua', 'codelldb' })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      vim.diagnostic.config {
        virtual_text = { prefix = '●', spacing = 2 },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      }

      require('mason-lspconfig').setup {
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
            vim.keymap.set('n', '<Leader>ld', vim.diagnostic.open_float, { desc = 'Hover diagnostics' })
          end,
        },
      }
    end,
  },

  -- DAP (unchanged logic, kept)
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'mfussenegger/nvim-dap-python',
      'rcarriga/nvim-dap-ui',
      'theHamsta/nvim-dap-virtual-text',
      'nvim-neotest/nvim-nio',
      'folke/neodev.nvim',
    },
    config = function()
      require('neodev').setup { library = { plugins = { 'nvim-dap-ui' }, types = true } }

      local dap = require 'dap'
      vim.keymap.set('n', '<Leader>db', dap.toggle_breakpoint, { desc = 'Toggle Breakpoint' })
      vim.keymap.set('n', '<Leader>dc', dap.continue, { desc = 'Start/Continue Debug' })
      vim.keymap.set('n', '<Leader>do', dap.step_over, { desc = 'Step Over' })
      vim.keymap.set('n', '<Leader>di', dap.step_into, { desc = 'Step Into' })
      vim.keymap.set('n', '<Leader>dO', dap.step_out, { desc = 'Step Out' })

      local sign = vim.fn.sign_define
      sign('DapBreakpoint', { text = ' ', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
      sign('DapBreakpointCondition', { text = ' ', texthl = 'DapBreakpointCondition', linehl = '', numhl = '' })
      sign('DapLogPoint', { text = '◆ ', texthl = 'DapLogPoint', linehl = '', numhl = '' })
      sign('DapStoppedLine', { text = '󰁕 ', texthl = 'DapLogPoint', linehl = '', numhl = '' })
      sign('DapBreakpointRejected', { text = ' ', texthl = 'DapBreakpointRejected', linehl = '', numhl = '' })

      dap.adapters.codelldb = {
        type = 'server',
        port = '${port}',
        executable = {
          command = vim.fn.expand '$HOME/.local/share/nvim/mason/bin/codelldb',
          args = { '--port', '${port}' },
        },
      }

      dap.configurations.cpp = {
        {
          name = 'C++: Run file',
          type = 'codelldb',
          request = 'launch',
          program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
        },
        {
          name = 'C++: Attach to process',
          type = 'codelldb',
          request = 'attach',
          pid = require('dap.utils').pick_process,
          args = {},
        },
        {
          name = 'C++: ROS Node',
          type = 'codelldb',
          request = 'launch',
          program = function()
            local pkgName = vim.fn.input('ROS Package: ', '')
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/install/' .. pkgName .. '/lib/' .. pkgName .. '/', 'file')
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
        },
      }

      require('dapui').setup {
        controls = { icons = { pause = '⏸ ', play = '▶ ', terminate = '⏹ ' } },
        floating = { border = 'rounded' },
        layouts = {
          {
            elements = {
              { id = 'stacks', size = 0.30 },
              { id = 'breakpoints', size = 0.20 },
              { id = 'scopes', size = 0.50 },
            },
            position = 'left',
            size = 40,
          },
          {
            elements = { { id = 'console', size = 0.50 }, { id = 'repl', size = 0.50 } },
            position = 'bottom',
            size = 10,
          },
        },
      }

      require('nvim-dap-virtual-text').setup()
      require('dap-python').setup()

      table.insert(require('dap').configurations.python, {
        type = 'python',
        request = 'launch',
        name = 'Python: ROS2 lauch test',
        program = '/opt/ros/humble/bin/launch_test',
        args = { '${file}' },
      })
      require('dap-python').test_runner = 'pytest'

      vim.api.nvim_create_user_command('DapUIToggle', ":lua require('dapui').toggle()", {})
      vim.api.nvim_create_user_command('DapPytestMethod', ":lua require('dap-python').test_method()", {})
      vim.api.nvim_create_user_command('DapResetUI', ":lua require('dapui').open({reset = true})", { desc = 'Reset DAP UI Layout' })
      vim.api.nvim_create_user_command(
        'DapLogBreakpoint',
        ":lua require('dap').set_breakpoint(nil, nil, vim.fn.input('Log Message: '))",
        { desc = 'Set log message breakpoint' }
      )
      vim.api.nvim_create_user_command(
        'DapConditionBreakpoint',
        ":lua require('dap').set_breakpoint(vim.fn.input('Breakpoint Condition: '))",
        { desc = 'Set conditional breakpoint' }
      )

      local dapui = require 'dapui'
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.exited.dapui_config = function()
        dapui.close()
      end

      vim.keymap.set('n', '<Leader>duo', dapui.open, { desc = 'Open DAP UI' })
      vim.keymap.set('n', '<Leader>dq', dapui.close, { desc = 'Close DAP UI' })
    end,
  },

  {
    'ErickKramer/nvim-ros2',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    opts = {
      autocmds = true,
      telescope = true,
      treesitter = true,
    },
  },

  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        local disable_filetypes = { c = true, cpp = true }
        local lsp_format_opt
        if disable_filetypes[vim.bo[bufnr].filetype] then
          lsp_format_opt = 'never'
        else
          lsp_format_opt = 'fallback'
        end
        return { timeout_ms = 500, lsp_format = lsp_format_opt }
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        json = { 'prettier' },
        python = { 'ruff' },
        cpp = { 'clang-format' },
      },
    },
  },

  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      {
        'L3MON4D3/LuaSnip',
        build = (function()
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
      },
      'saadparwaiz1/cmp_luasnip',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
    },
    config = function()
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'
      luasnip.config.setup {}

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = { completeopt = 'menu,menuone,noinsert' },
        mapping = cmp.mapping.preset.insert {
          ['<C-n>'] = cmp.mapping.select_next_item(),
          ['<C-p>'] = cmp.mapping.select_prev_item(),
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-y>'] = cmp.mapping.confirm { select = true },
          ['<C-Space>'] = cmp.mapping.complete {},
          ['<C-l>'] = cmp.mapping(function()
            if luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            end
          end, { 'i', 's' }),
          ['<C-h>'] = cmp.mapping(function()
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            end
          end, { 'i', 's' }),
        },
        sources = {
          { name = 'lazydev', group_index = 0 },
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'path' },
        },
      }
    end,
  },

  {
    'askfiy/visual_studio_code',
    priority = 1000,
    init = function()
      vim.cmd.colorscheme 'visual_studio_code'
      vim.cmd.hi 'Comment gui=none'
    end,
  },

  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },
  { 'sindrets/diffview.nvim' },

  {
    'echasnovski/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.surround').setup()
    end,
  },

  {
    'echasnovski/mini.indentscope',
    version = '*',
    config = function()
      require('mini.indentscope').setup()
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    opts = {
      ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'xml' },
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
    },
  },

  {
    'stevearc/oil.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      CustomOilBar = function()
        local path = vim.fn.expand '%'
        path = path:gsub('oil://', '')
        return '  ' .. vim.fn.fnamemodify(path, ':.')
      end

      require('oil').setup {
        columns = { 'icon' },
        keymaps = {
          ['<C-h>'] = false,
          ['<C-l>'] = false,
          ['<C-k>'] = false,
          ['<C-j>'] = false,
          ['<M-h>'] = 'actions.select_split',
        },
        win_options = { winbar = '%{v:lua.CustomOilBar()}' },
        view_options = {
          show_hidden = true,
          is_always_hidden = function(name, _)
            local folder_skip = { 'dev-tools.locks', 'dune.lock', '_build' }
            return vim.tbl_contains(folder_skip, name)
          end,
        },
      }

      vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
      vim.keymap.set('n', '<space>-', require('oil').toggle_float)
    end,
  },

  {
    'kdheepak/lazygit.nvim',
    lazy = false,
    cmd = { 'LazyGit', 'LazyGitConfig', 'LazyGitCurrentFile', 'LazyGitFilter', 'LazyGitFilterCurrentFile' },
    dependencies = { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim' },
    config = function()
      require('telescope').load_extension 'lazygit'
    end,
  },

  {
    'taketwo/vim-ros',
    cond = function()
      return vim.fn.executable 'ros2' == 1 or vim.fn.executable 'rosrun' == 1
    end,
    config = function()
      vim.g.ros_make = 'current'
      vim.g.ros_build_system = 'catkin-tools'
      vim.g.ros_disable_warnings = 1
    end,
  },

  {
    'bi0ha2ard/ros-builder.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'skywind3000/asyncrun.vim' },
    config = function()
      local launcher = require('ros-builder.launchers').asyncrun_qf
      local colcon_opts = {
        cmake_args = { '-DCMAKE_CXX_FLAGS=-ggdb' },
        mixins = { 'compile-commands', 'ccache', 'mold' },
        build = { '--symlink-install' },
      }
      require('ros-builder').setup {
        options = { launcher = launcher },
        keys = { build = '<leader>b', test = '<leader>bt' },
        systems = {
          colcon_ninja = { opts = colcon_opts },
          colcon = { opts = colcon_opts },
          catkin = { opts = { build = { '-j12', '--no-notify' } } },
        },
      }
    end,
  },

  {
    'kkrampis/codex.nvim',
    lazy = true,
    cmd = { 'Codex', 'CodexToggle' },
    keys = {
      {
        '<leader>cc',
        function()
          require('codex').toggle()
        end,
        desc = 'Toggle current Codex session',
        mode = { 'n', 't' },
      },
      {
        '<leader>cö',
        function()
          open_codex_with_cmd { 'codex', 'resume', '--last' }
        end,
        desc = 'Resume last Codex session',
        mode = { 'n', 't' },
      },
      {
        '<leader>cp',
        function()
          open_codex_with_cmd { 'codex', 'resume' }
        end,
        desc = 'Open Codex session picker',
        mode = { 'n', 't' },
      },
    },
    opts = {
      keymaps = {
        toggle = nil,
        quit = '<C-q>',
      },
      border = 'rounded',
      width = 0.8,
      height = 0.8,
      cmd = { 'codex' },
      model = nil,
      autoinstall = true,
      panel = false,
      use_buffer = false,
    },
  },
  {
    'coder/claudecode.nvim',
    dependencies = { 'folke/snacks.nvim' },
    config = true,
    cmd = {
      'ClaudeCode',
      'ClaudeCodeFocus',
      'ClaudeCodeOpen',
      'ClaudeCodeClose',
      'ClaudeCodeStart',
      'ClaudeCodeStop',
      'ClaudeCodeStatus',
      'ClaudeCodeSelectModel',
      'ClaudeCodeSend',
      'ClaudeCodeTreeAdd',
      'ClaudeCodeAdd',
      'ClaudeCodeDiffAccept',
      'ClaudeCodeDiffDeny',
    },
    keys = {
      { '<leader>b', nil, desc = 'AI/Claude Code' },
      { '<leader>bb', '<cmd>ClaudeCode<cr>', desc = 'Toggle Claude' },
      { '<leader>bf', '<cmd>ClaudeCodeFocus<cr>', desc = 'Focus Claude' },
      { '<leader>br', '<cmd>ClaudeCode --resume<cr>', desc = 'Resume Claude' },
      { '<leader>bl', '<cmd>ClaudeCode --continue<cr>', desc = 'Continue Claude' },
      { '<leader>bm', '<cmd>ClaudeCodeSelectModel<cr>', desc = 'Select Claude model' },
      { '<leader>bB', '<cmd>ClaudeCodeAdd %<cr>', desc = 'Add current buffer' },
      { '<leader>bs', '<cmd>ClaudeCodeSend<cr>', mode = 'v', desc = 'Send to Claude' },
      {
        '<leader>bs',
        '<cmd>ClaudeCodeTreeAdd<cr>',
        desc = 'Add file',
        ft = { 'NvimTree', 'neo-tree', 'oil', 'minifiles', 'netrw' },
      },
      -- Diff management
      { '<leader>ba', '<cmd>ClaudeCodeDiffAccept<cr>', desc = 'Accept diff' },
      { '<leader>bd', '<cmd>ClaudeCodeDiffDeny<cr>', desc = 'Deny diff' },
    },
  },

}, {
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- vim: ts=2 sts=2 sw=2 et
