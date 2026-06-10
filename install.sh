#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
home="${HOME}"

say() {
  printf '%s\n' "$*"
}

link_file() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
}

ensure_dir() {
  mkdir -p "$1"
}

checkout_repo() {
  local repo_url="$1"
  local dest="$2"
  local ref="$3"

  if [ -d "$dest/.git" ]; then
    git -C "$dest" fetch --all --tags
  else
    git clone "$repo_url" "$dest"
  fi

  git -C "$dest" checkout "$ref"
}

say "Linking shell and terminal config..."
link_file "$repo_root/.zshrc" "$home/.zshrc"
link_file "$repo_root/.bashrc" "$home/.bashrc"
link_file "$repo_root/.profile" "$home/.profile"
link_file "$repo_root/.tmux.conf" "$home/.tmux.conf"

say "Linking Neovim and Kitty config..."
ensure_dir "$home/.config"
link_file "$repo_root/nvim" "$home/.config/nvim"
link_file "$repo_root/kitty" "$home/.config/kitty"

say "Installing Oh My Zsh and pinned plugins..."
if [ ! -d "$home/.oh-my-zsh/.git" ]; then
  git clone https://github.com/ohmyzsh/ohmyzsh.git "$home/.oh-my-zsh"
fi
git -C "$home/.oh-my-zsh" checkout 061f773

ensure_dir "$home/.oh-my-zsh/custom/plugins"
ensure_dir "$home/.oh-my-zsh/custom/themes"

checkout_repo https://github.com/zsh-users/zsh-autosuggestions.git "$home/.oh-my-zsh/custom/plugins/zsh-autosuggestions" v0.7.1
checkout_repo https://github.com/zsh-users/zsh-completions.git "$home/.oh-my-zsh/custom/plugins/zsh-completions" 684021f
checkout_repo https://github.com/zsh-users/zsh-syntax-highlighting.git "$home/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" 1d85c69
checkout_repo https://github.com/romkatv/powerlevel10k.git "$home/.oh-my-zsh/custom/themes/powerlevel10k" 8ed1f58

say "Verifying installed versions..."
say "nvim: $(nvim --version | head -n 1)"
say "zsh: $(zsh --version)"
say "bash: $(bash --version | head -n 1)"
say "oh-my-zsh: $(git -C "$home/.oh-my-zsh" rev-parse --short HEAD)"
say "zsh-autosuggestions: $(git -C "$home/.oh-my-zsh/custom/plugins/zsh-autosuggestions" describe --tags --always --dirty)"
say "zsh-completions: $(git -C "$home/.oh-my-zsh/custom/plugins/zsh-completions" describe --tags --always --dirty)"
say "zsh-syntax-highlighting: $(git -C "$home/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" describe --tags --always --dirty)"
say "powerlevel10k: $(git -C "$home/.oh-my-zsh/custom/themes/powerlevel10k" describe --tags --always --dirty)"

say "Done."
