#!/usr/bin/env bash
set -euo pipefail

# Function to copy with timeout
copy_with_timeout() {
  local src="$1"
  local dst="$2"
  local timeout=30  # 30 seconds timeout
  
  timeout $timeout cp -R "$src" "$dst" 2>/dev/null || echo "   ⚠️  Timeout copying $(basename "$src")"
}

# ── Only GUI apps go here ──
declare -a MANUAL_APPS=(
  "MongoDB Compass.app"
  "Miro.app"
  "Spectacle.app"
  "Tuple.app"
  "Tuple 2.app"
  "Keychron Engine.app"
)

DOTFILES_DIR="${HOME}/dotfiles"
echo "📦 Packaging environment into $DOTFILES_DIR"
rm -rf "$DOTFILES_DIR"
mkdir -p "$DOTFILES_DIR"

# 1. Essential configs
echo "📝 Copying essential configs..."
for f in .zshrc .zprofile .gitconfig .vimrc .tool-versions .p10k.zsh .ideavimrc .pryrc .npmrc .yarnrc; do
  [[ -f "$HOME/$f" ]] && cp "$HOME/$f" "$DOTFILES_DIR/"
done

# 1a. Vim config directory
[[ -d "$HOME/.vim" ]] && cp -R "$HOME/.vim" "$DOTFILES_DIR/.vim"

# 2. Homebrew manifests
echo "🍺 Dumping Homebrew manifests..."
brew bundle dump --force --file="$DOTFILES_DIR/Brewfile"
brew list --cask > "$DOTFILES_DIR/casks.txt"
brew list --formula > "$DOTFILES_DIR/formulae.txt"

# 3. Mac App Store apps
if command -v mas &>/dev/null; then
  mas list > "$DOTFILES_DIR/mas_apps.txt"
else
  echo "⚠️  'mas' command not found. Install with: brew install mas"
  echo "# Mac App Store apps - install manually or run: brew install mas" > "$DOTFILES_DIR/mas_apps.txt"
fi

# 4. Manual apps
echo "📱 Copying manual apps..."
mkdir -p "$DOTFILES_DIR/manual_apps"
for app in "${MANUAL_APPS[@]}"; do
  if [[ -d "/Applications/$app" ]]; then
    echo "   📦 Copying $app..."
    cp -R "/Applications/$app" "$DOTFILES_DIR/manual_apps/"
  else
    echo "   ⚠️  $app not found, skipping..."
  fi
done

# 5. SSH & GPG (Critical)
echo "🔐 Copying SSH & GPG keys..."
[[ -d "$HOME/.ssh" ]] && cp -R "$HOME/.ssh" "$DOTFILES_DIR/.ssh"
[[ -d "$HOME/.gnupg" ]] && cp -R "$HOME/.gnupg" "$DOTFILES_DIR/.gnupg"

# 6. Development tools & configs
echo "🛠️  Copying development tools..."
for tool in config nvm pyenv rbenv rustup; do
  if [[ -d "$HOME/.$tool" ]]; then
    echo "   🛠️  Copying .$tool... (this may take a moment)"
    copy_with_timeout "$HOME/.$tool" "$DOTFILES_DIR/.$tool"
  fi
done

# 7. IDE configurations
echo "💻 Copying IDE configs..."
for ide in "JetBrains:jetbrains" "Code/User:vscode" "Cursor:cursor"; do
  ide_name="${ide%:*}"
  dir_name="${ide#*:}"
  if [[ -d "$HOME/Library/Application Support/$ide_name" ]]; then
    echo "   💻 Copying $ide_name config..."
    cp -R "$HOME/Library/Application Support/$ide_name" "$DOTFILES_DIR/$dir_name" 2>/dev/null || echo "   ⚠️  Failed to copy $ide_name"
  fi
done
if [[ -d "$HOME/.cursor" ]]; then
  echo "   💻 Copying .cursor config..."
  cp -R "$HOME/.cursor" "$DOTFILES_DIR/.cursor" 2>/dev/null || echo "   ⚠️  Failed to copy .cursor"
fi

# 8. Development tool configs
echo "🔧 Copying tool configs..."
for tool in mongodb redis-insight redisinsight-app sonarlint tabnine thor; do
  if [[ -d "$HOME/.$tool" ]]; then
    echo "   🔧 Copying .$tool..."
    cp -R "$HOME/.$tool" "$DOTFILES_DIR/.$tool"
  fi
done

# 9. App-specific configs
echo "📱 Copying app configs..."
for app in "RedisInsight:redisinsight" "Keychron Engine:keychron_engine" "Logi:logi" "LogiOptionsPlus:logioptionsplus" "Logitech:logitech" "Spectacle:spectacle"; do
  app_name="${app%:*}"
  dir_name="${app#*:}"
  if [[ -d "$HOME/Library/Application Support/$app_name" ]]; then
    echo "   📱 Copying $app_name config..."
    cp -R "$HOME/Library/Application Support/$app_name" "$DOTFILES_DIR/$dir_name" || true
  fi
done

# 10. Cloud configs
echo "☁️  Copying cloud configs..."
[[ -d "$HOME/.kube" ]] && cp -R "$HOME/.kube" "$DOTFILES_DIR/.kube"
[[ -d "$HOME/.aws"  ]] && cp -R "$HOME/.aws"  "$DOTFILES_DIR/.aws"

# 10a. eks-node-viewer config
echo "🔍 Copying eks-node-viewer config..."
[[ -f "$HOME/.eks-node-viewer" ]] && cp "$HOME/.eks-node-viewer" "$DOTFILES_DIR/.eks-node-viewer"

# 11. Chrome profile
echo "🌐 Copying Chrome profile..."
if [[ -d "$HOME/Library/Application Support/Google/Chrome/Default" ]]; then
  echo "   📦 Compressing Chrome profile..."
  # Try tar.gz first, then zip if tar.gz fails
  if tar czf "$DOTFILES_DIR/ChromeProfile.tar.gz" -C "$HOME/Library/Application Support/Google/Chrome" Default 2>/dev/null; then
    echo "   ✅ Chrome profile compressed as ChromeProfile.tar.gz"
  elif zip -r "$DOTFILES_DIR/ChromeProfile.zip" Default -C "$HOME/Library/Application Support/Google/Chrome" 2>/dev/null; then
    echo "   ✅ Chrome profile compressed as ChromeProfile.zip"
  else
    echo "   ⚠️  Failed to compress Chrome profile"
  fi
fi

# 12. Workspace and workspace files
echo "💼 Compressing workspace and workspace files..."

# Capture workspace directory if it exists
if [[ -d "$HOME/workspace" ]]; then
    echo "   📦 Compressing workspace directory..."
    # Try tar.gz first, then zip if tar.gz fails
    if tar czf "$DOTFILES_DIR/workspace.tar.gz" -C "$HOME" workspace 2>/dev/null; then
        echo "   ✅ Workspace compressed as workspace.tar.gz"
    elif zip -r "$DOTFILES_DIR/workspace.zip" workspace -C "$HOME" 2>/dev/null; then
        echo "   ✅ Workspace compressed as workspace.zip"
    else
        echo "   ⚠️  Failed to compress workspace directory"
    fi
fi

# Capture important workspace root files and directories
echo "📁 Capturing workspace root files..."
WORKSPACE_ROOT_FILES=(
  ".zsh_history"
  ".viminfo"
  ".lesshst"
  ".gitconfig"
  ".pryrc"
  ".npmrc"
  ".p10k.zsh"
  ".ideavimrc"
  ".vimrc"
  ".zprofile"
  ".yarnrc"
  ".tool-versions"
)

WORKSPACE_ROOT_DIRS=(
  ".tsh"
  ".kube"
  ".thor"
  ".tabnine"
  ".sonarlint"
  ".redisinsight-app"
  ".redis-insight"
  ".mongodb"
  ".rustup"
  ".rbenv"
  ".pyenv"
  ".nvm"
  ".gnupg"
  ".vim"
  ".cursor"
  ".config"
  ".ssh"
  ".asdf"
)

# Copy important workspace root files
for file in "${WORKSPACE_ROOT_FILES[@]}"; do
  if [[ -f "$HOME/$file" ]]; then
    echo "   📄 Copying workspace root file: $file"
    cp "$HOME/$file" "$DOTFILES_DIR/"
  fi
done

# Copy important workspace root directories
for dir in "${WORKSPACE_ROOT_DIRS[@]}"; do
  if [[ -d "$HOME/$dir" ]]; then
    echo "   📁 Copying workspace root directory: $dir"
    cp -R "$HOME/$dir" "$DOTFILES_DIR/"
  fi
done

# 8. User directories (compressed)
echo "📁 Archiving user directories..."
for dir in Documents Desktop Downloads; do
  if [[ -d "$HOME/$dir" ]]; then
    echo "   📦 Compressing $dir..."
    # Try tar.gz first, then zip if tar.gz fails
    if tar czf "$DOTFILES_DIR/${dir}.tar.gz" -C "$HOME" "$dir" 2>/dev/null; then
      echo "   ✅ $dir compressed as ${dir}.tar.gz"
    elif zip -r "$DOTFILES_DIR/${dir}.zip" "$dir" -C "$HOME" 2>/dev/null; then
      echo "   ✅ $dir compressed as ${dir}.zip"
    else
      echo "   ⚠️  Failed to compress $dir"
    fi
  fi
done

echo ""
echo "✅ Migration complete! Transfer ~/dotfiles to your new Mac."
echo ""
echo "📊 Migration Summary:"
echo "   📝 Config files: $(ls -1 ~/dotfiles/*.rc ~/dotfiles/.*rc ~/dotfiles/.*config 2>/dev/null | wc -l | tr -d ' ')"
echo "   🍺 Homebrew packages: $(cat ~/dotfiles/formulae.txt | wc -l | tr -d ' ')"
echo "   📱 Manual apps: $(ls -1 ~/dotfiles/manual_apps/*.app 2>/dev/null | wc -l | tr -d ' ')"
echo "   🔐 SSH keys: $(ls -1 ~/dotfiles/.ssh/id_* 2>/dev/null | wc -l | tr -d ' ')"
echo "   🛠️  Development tools: $(find ~/dotfiles/.config ~/dotfiles/.nvm ~/dotfiles/.pyenv ~/dotfiles/.rbenv -type d 2>/dev/null | wc -l | tr -d ' ')"
echo "   📦 Compressed archives: $(ls -1 ~/dotfiles/*.tar.gz 2>/dev/null | wc -l | tr -d ' ')"
echo ""
echo "📁 Total size: $(du -sh ~/dotfiles | cut -f1)"
echo "" 
