# dot_configs

Portable copies of my shell, editor, terminal, and AI-assistant configs.

## Layout

- `nvim/` - Neovim config
- `kitty/` - Kitty terminal config
- `shell/` - shared shell config and aliases
- `tmux/` - tmux config
- `claude/` - Claude Code config and instructions
- `codex/` - Codex config and rules

## Current versions

- `nvim`: `v0.11.6`
- `zsh`: `5.8.1`
- `bash`: `5.1.16`
- `oh-my-zsh`: `061f773` from `master`
- `zsh-autosuggestions`: `v0.7.1-6-g85919cd`
- `zsh-completions`: `0.35.0-425-g684021f`
- `zsh-syntax-highlighting`: `0.8.0-4-g1d85c69`
- `powerlevel10k`: `8ed1f58`
- `nvim plugins`: pinned in `nvim/lazy-lock.json`

## Notes

- Secrets are not stored here.
- If you use API keys, keep them in a local file such as `~/.config/secrets/openai.env` and source it from your shell.
- The `.gitignore` excludes runtime caches, session databases, and auth files.

## Fast setup on a new laptop

1. Clone the repo:

```sh
git clone https://github.com/KevVincent/dot_configs.git ~/dot_configs
cd ~/dot_configs
```

2. Run the bootstrap script:

```sh
./install.sh
```

3. Restart your shell or open a new terminal.

The script will:

- create symlinks for `.zshrc`, `.bashrc`, `.profile`, `.tmux.conf`
- install or refresh Oh My Zsh and the pinned Zsh plugins/theme
- link Neovim and Kitty config directories
- print the versions it detected so you can verify the machine matches

## Manual symlink example

If you want to do it yourself:

```sh
ln -sf ~/dot_configs/.zshrc ~/.zshrc
ln -sf ~/dot_configs/.bashrc ~/.bashrc
ln -sf ~/dot_configs/.profile ~/.profile
ln -sf ~/dot_configs/.tmux.conf ~/.tmux.conf
ln -sfn ~/dot_configs/nvim ~/.config/nvim
ln -sfn ~/dot_configs/kitty ~/.config/kitty
```
