#!/usr/bin/env bash
set -euo pipefail

# iTerm2 configs commented out - uncomment if switching back to iTerm2

DOTFILES_DIR="${HOME}/Downloads/dotfiles"
[[ -d "$DOTFILES_DIR" ]] || { echo "❌ Dotfiles directory not found at $DOTFILES_DIR"; exit 1; }
echo "🚀 Bootstrapping from $DOTFILES_DIR"

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Function to check if a Homebrew package is installed
brew_installed() {
    brew list | grep -q "^$1$"
}

# Function to check if a Mac App Store app is installed
mas_installed() {
    mas list | grep -q "$1"
}

# 1. Xcode CLI
echo "🛠️  Installing Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Please complete the Xcode installation in the popup window, then press Enter to continue..."
    read -r
else
    echo "✅ Xcode Command Line Tools already installed"
fi

# 2. Homebrew
if ! command_exists brew; then
    echo "🍺 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "✅ Homebrew already installed"
fi

# 3. Essential tools with individual checks
echo "🔧 Installing essential tools..."
ESSENTIAL_TOOLS=("git" "vim" "kubectl" "k9s" "eksctl" "teleport" "tsh" "glab" "kubectx" "git-split-diffs" "rbenv" "ruby-build")
for tool in "${ESSENTIAL_TOOLS[@]}"; do
    if ! brew_installed "$tool"; then
        echo "Installing $tool..."
        brew install "$tool"
    else
        echo "✅ $tool already installed"
    fi
done

# 3a. eks-node-viewer (requires AWS tap)
echo "🔍 Installing eks-node-viewer..."
if ! command_exists eks-node-viewer; then
    echo "Adding AWS Homebrew tap..."
    brew tap aws/tap
    echo "Installing eks-node-viewer..."
    brew install eks-node-viewer
else
    echo "✅ eks-node-viewer already installed"
fi

# 3b. OpenLens (Homebrew cask)
echo "🔍 Installing OpenLens..."
if ! brew_installed "openlens"; then
    echo "Installing OpenLens..."
    brew install --cask openlens
else
    echo "✅ OpenLens already installed"
fi

# 3a. asdf (language version manager)
if ! command_exists asdf; then
    echo "📦 Installing asdf..."
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.11.3
    echo '. $HOME/.asdf/asdf.sh' >> ~/.zshrc
    source ~/.zshrc
else
    echo "✅ asdf already installed"
fi

# 3b. asdf plugins & versions
echo "🔌 Installing asdf plugins..."
ASDF_PLUGINS=("ruby" "nodejs" "python" "java" "rust")
for plugin in "${ASDF_PLUGINS[@]}"; do
    if ! asdf plugin-list | grep -q "^$plugin$"; then
        echo "Adding asdf plugin: $plugin"
        asdf plugin-add "$plugin"
    else
        echo "✅ asdf plugin $plugin already installed"
    fi
done
asdf install

# 4. Homebrew packages with selective installation
echo "📦 Installing Homebrew packages..."
if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
    # Read Brewfile and install only missing packages
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        # Extract package name (simplified parsing)
        if [[ "$line" =~ ^[[:space:]]*brew[[:space:]]+\"([^\"]+)\" ]]; then
            package="${BASH_REMATCH[1]}"
            if ! brew_installed "$package"; then
                echo "Installing $package..."
                brew install "$package"
            else
                echo "✅ $package already installed"
            fi
        elif [[ "$line" =~ ^[[:space:]]*cask[[:space:]]+\"([^\"]+)\" ]]; then
            package="${BASH_REMATCH[1]}"
            if ! brew_installed "$package"; then
                echo "Installing cask $package..."
                brew install --cask "$package"
            else
                echo "✅ cask $package already installed"
            fi
        fi
    done < "$DOTFILES_DIR/Brewfile"
else
    echo "⚠️  Brewfile not found at $DOTFILES_DIR/Brewfile"
fi

# 5. Mac App Store apps with checks
if ! command_exists mas; then
    echo "📱 Installing mas (Mac App Store CLI)..."
    brew install mas
fi

if [[ -f "$DOTFILES_DIR/mas_apps.txt" ]]; then
    echo "📱 Installing Mac App Store apps..."
    while IFS= read -r app_id; do
        # Skip comments and empty lines
        [[ "$app_id" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${app_id// }" ]] && continue

        if ! mas_installed "$app_id"; then
            echo "Installing Mac App Store app: $app_id"
            mas install "$app_id"
        else
            echo "✅ Mac App Store app $app_id already installed"
        fi
    done < "$DOTFILES_DIR/mas_apps.txt"
else
    echo "⚠️  mas_apps.txt not found"
fi

# 6. Manual apps with permission check
echo "📱 Installing manual apps..."
if [[ -d "$DOTFILES_DIR/manual_apps" ]]; then
    for app in "$DOTFILES_DIR/manual_apps/"*.app; do
        if [[ -e "$app" ]]; then
            app_name=$(basename "$app")
            if [[ ! -d "/Applications/$app_name" ]]; then
                echo "Installing $app_name..."
                if [[ -w "/Applications" ]]; then
                    cp -R "$app" "/Applications/"
                else
                    echo "⚠️  Need sudo to install $app_name"
                    sudo cp -R "$app" "/Applications/"
                fi
            else
                echo "✅ $app_name already installed"
            fi
        fi
    done
else
    echo "⚠️  manual_apps directory not found"
fi

# 7. Essential configs
echo "📝 Linking essential configs..."
CONFIG_FILES=(".zprofile" ".gitconfig" ".vimrc" ".tool-versions" ".p10k.zsh" ".ideavimrc" ".pryrc" ".npmrc" ".yarnrc")
# Note: .zshrc handled separately to preserve Starship while merging other configs
for f in "${CONFIG_FILES[@]}"; do
    if [[ -f "$DOTFILES_DIR/$f" ]]; then
        echo "Linking $f..."
        ln -sf "$DOTFILES_DIR/$f" "$HOME/$f"
    fi
done

# 7a. eks-node-viewer config
if [[ -f "$DOTFILES_DIR/.eks-node-viewer" ]]; then
    echo "Linking .eks-node-viewer..."
    ln -sf "$DOTFILES_DIR/.eks-node-viewer" "$HOME/.eks-node-viewer"
fi

if [[ -d "$DOTFILES_DIR/.vim" ]]; then
    echo "Linking .vim directory..."
    ln -sf "$DOTFILES_DIR/.vim" "$HOME/.vim"
fi

# 7b. Handle .zshrc specially to preserve Starship while merging other configs
echo "📝 Merging .zshrc configs..."
if [[ -f "$DOTFILES_DIR/.zshrc" ]]; then
    # Backup current .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        echo "✅ Backed up current .zshrc"
    fi

    # Create a merged .zshrc that excludes Powerlevel10k but includes other configs
    echo "Creating merged .zshrc..."
    {
        # Start with Starship initialization
        echo 'eval "$(starship init zsh)"'
        echo ""

        # Extract non-Powerlevel10k content from dotfiles .zshrc
        grep -v -E "^(#.*POWERLEVEL10K|if.*p10k|source.*p10k|PROMPT=|PS2=)" "$DOTFILES_DIR/.zshrc" | \
        grep -v -E "^(parse_git_branch|setopt PROMPT_SUBST)" | \
        sed '/^$/d'

    } > "$HOME/.zshrc"
    echo "✅ Merged .zshrc created (Powerlevel10k removed, Starship preserved)"
fi



# 8. SSH & GPG
echo "🔐 Restoring SSH & GPG keys..."
if [[ -d "$DOTFILES_DIR/.ssh" ]]; then
    cp -R "$DOTFILES_DIR/.ssh" "$HOME/.ssh"
fi
if [[ -d "$DOTFILES_DIR/.gnupg" ]]; then
    cp -R "$DOTFILES_DIR/.gnupg" "$HOME/.gnupg"
fi

# 9. Development tools & configs
echo "🛠️  Restoring development tools..."
DEV_DIRS=(".config" ".nvm" ".pyenv" ".rbenv" ".rustup")
for dir in "${DEV_DIRS[@]}"; do
    if [[ -d "$DOTFILES_DIR/$dir" ]]; then
        echo "Copying $dir..."
        cp -R "$DOTFILES_DIR/$dir" "$HOME/$dir"
    fi
done

# 10. IDE configurations
echo "💻 Restoring IDE configs..."
if [[ -d "$DOTFILES_DIR/jetbrains" ]]; then
    mkdir -p "$HOME/Library/Application Support/JetBrains"
    cp -R "$DOTFILES_DIR/jetbrains"/* "$HOME/Library/Application Support/JetBrains/"
fi

if [[ -d "$DOTFILES_DIR/vscode" ]]; then
    mkdir -p "$HOME/Library/Application Support/Code/User"
    cp -R "$DOTFILES_DIR/vscode"/* "$HOME/Library/Application Support/Code/User/"
fi

if [[ -d "$DOTFILES_DIR/cursor" ]]; then
    mkdir -p "$HOME/Library/Application Support/Cursor"
    cp -R "$DOTFILES_DIR/cursor"/* "$HOME/Library/Application Support/Cursor/"
fi

if [[ -d "$DOTFILES_DIR/.cursor" ]]; then
    cp -R "$DOTFILES_DIR/.cursor" "$HOME/.cursor"
fi

# 11. Development tool configs
echo "🔧 Restoring tool configs..."
TOOL_DIRS=(".mongodb" ".redis-insight" ".redisinsight-app" ".sonarlint" ".tabnine" ".thor")
for dir in "${TOOL_DIRS[@]}"; do
    if [[ -d "$DOTFILES_DIR/$dir" ]]; then
        echo "Copying $dir..."
        cp -R "$DOTFILES_DIR/$dir" "$HOME/$dir"
    fi
done

# 12. App-specific configs
echo "📱 Restoring app configs..."
APP_CONFIGS=(
    "redisinsight:RedisInsight"
    "keychron_engine:Keychron Engine"
    "logi:Logi"
    "logioptionsplus:LogiOptionsPlus"
    "logitech:Logitech"
    "spectacle:Spectacle"
    # "iterm2:iTerm2"  # Commented out for Alacritty setup
)
for config in "${APP_CONFIGS[@]}"; do
    IFS=':' read -r src_dir app_name <<< "$config"
    if [[ -d "$DOTFILES_DIR/$src_dir" ]]; then
        echo "Copying $app_name config..."
        cp -R "$DOTFILES_DIR/$src_dir" "$HOME/Library/Application Support/$app_name"
    fi
done

# 13. Cloud configs
echo "☁️  Restoring cloud configs..."
CLOUD_DIRS=(".kube" ".aws")
for dir in "${CLOUD_DIRS[@]}"; do
    if [[ -d "$DOTFILES_DIR/$dir" ]]; then
        echo "Copying $dir..."
        cp -R "$DOTFILES_DIR/$dir" "$HOME/$dir"
    fi
done

# 14. Chrome profile
echo "🌐 Restoring Chrome profile..."
if [[ -f "$DOTFILES_DIR/ChromeProfile.tar.gz" ]]; then
    mkdir -p "$HOME/Library/Application Support/Google/Chrome"
    echo "Extracting Chrome profile from ChromeProfile.tar.gz..."
    tar xzf "$DOTFILES_DIR/ChromeProfile.tar.gz" -C "$HOME/Library/Application Support/Google/Chrome"
elif [[ -f "$DOTFILES_DIR/ChromeProfile.zip" ]]; then
    mkdir -p "$HOME/Library/Application Support/Google/Chrome"
    echo "Extracting Chrome profile from ChromeProfile.zip..."
    unzip -q "$DOTFILES_DIR/ChromeProfile.zip" -d "$HOME/Library/Application Support/Google/Chrome"
else
    echo "No Chrome profile archive found (ChromeProfile.tar.gz or ChromeProfile.zip)"
fi

# 15. Workspace and workspace files
echo "💼 Extracting workspace and workspace files..."

# Extract workspace directory if it exists
if [[ -f "$DOTFILES_DIR/workspace.tar.gz" ]]; then
    echo "Extracting workspace from workspace.tar.gz..."
    tar xzf "$DOTFILES_DIR/workspace.tar.gz" -C "$HOME"
elif [[ -f "$DOTFILES_DIR/workspace.zip" ]]; then
    echo "Extracting workspace from workspace.zip..."
    unzip -q "$DOTFILES_DIR/workspace.zip" -d "$HOME"
else
    echo "No workspace archive found (workspace.tar.gz or workspace.zip)"
fi

# Restore important workspace root files and directories
echo "📁 Restoring workspace root files..."

# List of workspace root files to restore
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

# List of workspace root directories to restore
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

# Restore workspace root files
for file in "${WORKSPACE_ROOT_FILES[@]}"; do
  if [[ -f "$DOTFILES_DIR/$file" ]]; then
    echo "Restoring workspace root file: $file"
    cp "$DOTFILES_DIR/$file" "$HOME/$file"
  fi
done

# Restore workspace root directories
for dir in "${WORKSPACE_ROOT_DIRS[@]}"; do
  if [[ -d "$DOTFILES_DIR/$dir" ]]; then
    echo "Restoring workspace root directory: $dir"
    cp -R "$DOTFILES_DIR/$dir" "$HOME/$dir"
  fi
done

# 16. User directories
echo "📁 Extracting user directories..."
USER_DIRS=("Documents" "Desktop" "Downloads")
for dir in "${USER_DIRS[@]}"; do
  if [[ -f "$DOTFILES_DIR/${dir}.tar.gz" ]]; then
    echo "Extracting $dir from ${dir}.tar.gz..."
    tar xzf "$DOTFILES_DIR/${dir}.tar.gz" -C "$HOME"
  elif [[ -f "$DOTFILES_DIR/${dir}.zip" ]]; then
    echo "Extracting $dir from ${dir}.zip..."
    unzip -q "$DOTFILES_DIR/${dir}.zip" -d "$HOME"
  else
    echo "No $dir archive found (${dir}.tar.gz or ${dir}.zip)"
  fi
done

# 17. Set proper permissions
echo "🔒 Setting proper permissions..."
if [[ -d "$HOME/.ssh" ]]; then
    chmod 700 "$HOME/.ssh"
    chmod 600 "$HOME/.ssh/id_*" 2>/dev/null || true
    chmod 644 "$HOME/.ssh/id_*.pub" 2>/dev/null || true
    chmod 600 "$HOME/.ssh/config" 2>/dev/null || true
    chmod 600 "$HOME/.ssh/known_hosts" 2>/dev/null || true
fi

if [[ -d "$HOME/.gnupg" ]]; then
    chmod 700 "$HOME/.gnupg"
fi

# 18. Source updated shell config
echo "🔄 Sourcing updated shell config..."
source ~/.zshrc

echo "✅ Bootstrap complete! Restart your shell and applications."
echo "🔐 SSH and GPG keys have been restored with proper permissions"
echo "📦 All applications and tools are ready to use"
