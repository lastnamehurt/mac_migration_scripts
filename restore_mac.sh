#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${HOME}/dotfiles"
[[ -d "$DOTFILES_DIR" ]] || { echo "❌ Dotfiles directory not found at $DOTFILES_DIR"; exit 1; }
echo "🚀 Bootstrapping from $DOTFILES_DIR"

# 1. Xcode CLI
echo "🛠️  Installing Xcode Command Line Tools..."
xcode-select --install 2>/dev/null || true

# 2. Homebrew
if ! command -v brew &>/dev/null; then
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 3. Essential tools
echo "🔧 Installing essential tools..."
brew install git vim kubectl k9s eksctl teleport tsh glab eks-node-viewer || true

# 3a. asdf (language version manager)
if ! command -v asdf &>/dev/null; then
  echo "📦 Installing asdf..."
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.11.3
  echo '. $HOME/.asdf/asdf.sh' >> ~/.zshrc
  source ~/.zshrc
fi

# 3b. asdf plugins & versions
echo "🔌 Installing asdf plugins..."
asdf plugin-add ruby || true
asdf plugin-add nodejs || true
asdf plugin-add python || true
asdf plugin-add java || true
asdf plugin-add rust || true
asdf install

# 4. Homebrew packages
echo "📦 Installing Homebrew packages..."
brew bundle --file="$DOTFILES_DIR/Brewfile"

# 5. Mac App Store apps
if ! command -v mas &>/dev/null; then
  echo "📱 Installing mas (Mac App Store CLI)..."
  brew install mas
fi
if [[ -f "$DOTFILES_DIR/mas_apps.txt" ]] && ! grep -q "^#" "$DOTFILES_DIR/mas_apps.txt"; then
  mas install < "$DOTFILES_DIR/mas_apps.txt"
fi

# 6. Manual apps
echo "📱 Installing manual apps..."
cp -R "$DOTFILES_DIR/manual_apps/"*.app /Applications/ || true

# 7. Essential configs
echo "📝 Linking essential configs..."
for f in .zshrc .zprofile .gitconfig .vimrc .tool-versions .p10k.zsh .ideavimrc .pryrc .npmrc .yarnrc; do
  [[ -f "$DOTFILES_DIR/$f" ]] && ln -sf "$DOTFILES_DIR/$f" "$HOME/$f"
done
[[ -d "$DOTFILES_DIR/.vim" ]] && ln -sf "$DOTFILES_DIR/.vim" "$HOME/.vim"

# 8. SSH & GPG
echo "🔐 Restoring SSH & GPG keys..."
cp -R "$DOTFILES_DIR/.ssh" "$HOME/.ssh" || true
cp -R "$DOTFILES_DIR/.gnupg" "$HOME/.gnupg" || true

# 9. Development tools & configs
echo "🛠️  Restoring development tools..."
cp -R "$DOTFILES_DIR/.config" "$HOME/.config" || true
cp -R "$DOTFILES_DIR/.nvm" "$HOME/.nvm" || true
cp -R "$DOTFILES_DIR/.pyenv" "$HOME/.pyenv" || true
cp -R "$DOTFILES_DIR/.rbenv" "$HOME/.rbenv" || true
cp -R "$DOTFILES_DIR/.rustup" "$HOME/.rustup" || true

# 10. IDE configurations
echo "💻 Restoring IDE configs..."
mkdir -p "$HOME/Library/Application Support/JetBrains"
cp -R "$DOTFILES_DIR/jetbrains"/* "$HOME/Library/Application Support/JetBrains/" || true
mkdir -p "$HOME/Library/Application Support/Code/User"
cp -R "$DOTFILES_DIR/vscode"/* "$HOME/Library/Application Support/Code/User/" || true
mkdir -p "$HOME/Library/Application Support/Cursor"
cp -R "$DOTFILES_DIR/cursor"/* "$HOME/Library/Application Support/Cursor/" || true
cp -R "$DOTFILES_DIR/.cursor" "$HOME/.cursor" || true

# 11. Development tool configs
echo "🔧 Restoring tool configs..."
cp -R "$DOTFILES_DIR/.mongodb" "$HOME/.mongodb" || true
cp -R "$DOTFILES_DIR/.redis-insight" "$HOME/.redis-insight" || true
cp -R "$DOTFILES_DIR/.redisinsight-app" "$HOME/.redisinsight-app" || true
cp -R "$DOTFILES_DIR/.sonarlint" "$HOME/.sonarlint" || true
cp -R "$DOTFILES_DIR/.tabnine" "$HOME/.tabnine" || true
cp -R "$DOTFILES_DIR/.thor" "$HOME/.thor" || true

# 12. App-specific configs
echo "📱 Restoring app configs..."
cp -R "$DOTFILES_DIR/redisinsight" "$HOME/Library/Application Support/RedisInsight" || true
cp -R "$DOTFILES_DIR/keychron_engine" "$HOME/Library/Application Support/Keychron Engine" || true
cp -R "$DOTFILES_DIR/logi" "$HOME/Library/Application Support/Logi" || true
cp -R "$DOTFILES_DIR/logioptionsplus" "$HOME/Library/Application Support/LogiOptionsPlus" || true
cp -R "$DOTFILES_DIR/logitech" "$HOME/Library/Application Support/Logitech" || true
cp -R "$DOTFILES_DIR/spectacle" "$HOME/Library/Application Support/Spectacle" || true

# 13. Cloud configs
echo "☁️  Restoring cloud configs..."
cp -R "$DOTFILES_DIR/.kube" "$HOME/.kube" || true
cp -R "$DOTFILES_DIR/.aws" "$HOME/.aws" || true

# 14. Chrome profile
echo "🌐 Restoring Chrome profile..."
mkdir -p "$HOME/Library/Application Support/Google/Chrome"
tar xzf "$DOTFILES_DIR/ChromeProfile.tar.gz" -C "$HOME/Library/Application Support/Google/Chrome" || true

# 15. Workspace
echo "💼 Extracting workspace..."
[[ -f "$DOTFILES_DIR/workspace.tar.gz" ]] && tar xzf "$DOTFILES_DIR/workspace.tar.gz" -C "$HOME" || true

# 11. User directories
echo "📁 Extracting user directories..."
for dir in Documents Desktop Downloads; do
  [[ -f "$DOTFILES_DIR/${dir}.tar.gz" ]] && tar xzf "$DOTFILES_DIR/${dir}.tar.gz" -C "$HOME"
done

# 12. Set proper permissions
echo "🔒 Setting proper permissions..."
chmod 700 "$HOME/.ssh" || true
chmod 600 "$HOME/.ssh/id_*" || true
chmod 644 "$HOME/.ssh/id_*.pub" || true
chmod 600 "$HOME/.ssh/config" || true
chmod 600 "$HOME/.ssh/known_hosts" || true
chmod 700 "$HOME/.gnupg" || true

# 13. Source updated shell config
source ~/.zshrc

echo "✅ Bootstrap complete! Restart your shell and applications."
echo "🔐 SSH and GPG keys have been restored with proper permissions"
echo "📦 All applications and tools are ready to use" 