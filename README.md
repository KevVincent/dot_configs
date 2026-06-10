# dot_configs

Portable copies of my shell, editor, terminal, and AI-assistant configs.

## Layout

- `nvim/` - Neovim config
- `kitty/` - Kitty terminal config
- `shell/` - shared shell config and aliases
- `tmux/` - tmux config
- `claude/` - Claude Code config and instructions
- `codex/` - Codex config and rules

## Notes

- Secrets are not stored here.
- If you use API keys, keep them in a local file such as `~/.config/secrets/openai.env` and source it from your shell.
- The `.gitignore` excludes runtime caches, session databases, and auth files.

## Suggested install

```sh
git clone https://github.com/KevVincent/dot_configs.git ~/dot_configs
```

Then symlink the tracked files into place, for example:

```sh
ln -sf ~/dot_configs/.zshrc ~/.zshrc
ln -sf ~/dot_configs/.bashrc ~/.bashrc
ln -sf ~/dot_configs/.profile ~/.profile
ln -sf ~/dot_configs/.tmux.conf ~/.tmux.conf
ln -sfn ~/dot_configs/nvim ~/.config/nvim
ln -sfn ~/dot_configs/kitty ~/.config/kitty
```
