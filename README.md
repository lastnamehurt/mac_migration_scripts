# Mac Migration Scripts

A comprehensive set of scripts to migrate your entire development environment from an old Mac to a new one, including applications, configurations, documents, and development tools.

## 📋 Overview

These scripts capture and restore your complete macOS environment, including:
- **Applications**: GUI apps, CLI tools, and development utilities
- **Configurations**: Shell settings, IDE preferences, SSH/GPG keys
- **Development Tools**: Language runtimes, package managers, cloud configs
- **User Data**: Documents, workspace, browser profiles

## 🚀 Quick Start

### On Your Old Mac (Source)

1. **Run the migration script**:
   ```bash
   cd ~/Workspace/mac_migration
   chmod +x migrate_mac.sh
   ./migrate_mac.sh
   ```

2. **Transfer the dotfiles directory**:
   ```bash
   # Copy to external drive, cloud storage, or transfer directly
   cp -R ~/dotfiles /path/to/backup/location/
   ```

### On Your New Mac (Destination)

1. **Transfer the dotfiles directory**:
   ```bash
   # Copy from your backup location to the new Mac
   cp -R /path/to/backup/dotfiles ~/dotfiles
   ```

2. **Run the restore script**:
   ```bash
   cd ~/Workspace/mac_migration
   chmod +x restore_mac.sh
   ./restore_mac.sh
   ```

3. **Restart your shell and applications**:
   ```bash
   source ~/.zshrc
   ```

## 📦 What Gets Migrated

### 🖥️ Applications

#### GUI Applications
- **Development**: Docker, MongoDB Compass, OpenLens (via Homebrew cask)
- **Productivity**: Miro, Spectacle, Tuple, Keychron Engine
- **All Homebrew Casks**: Automatically captured via `brew bundle dump`

#### CLI Tools
- **Kubernetes**: kubectl, k9s, eksctl, kubectx (includes kubens), eks-node-viewer (via AWS tap), teleport
- **Development**: tsh, glab, vim
- **All Homebrew Formulae**: Automatically captured

### ⚙️ Configurations

#### Shell & Editor Configs
- `.zshrc`, `.zprofile`, `.p10k.zsh` (Powerlevel10k)
- `.gitconfig`, `.gitignore_global`
- `.vimrc`, `.vim/` directory
- `.ideavimrc`, `.pryrc`, `.npmrc`, `.yarnrc`
- `.eks-node-viewer` (eks-node-viewer configuration)

#### IDE Configurations
- **JetBrains**: All IDE settings and preferences
- **VS Code**: Settings, keybindings, extensions
- **Cursor AI**: Complete configuration and settings

#### Terminal Configurations
- **iTerm2**: Preferences and customizations
- **Apple Terminal**: Settings and configurations

### 🔐 Security & Authentication

#### SSH & GPG
- **SSH Keys**: All private/public keys and configs
- **GPG Keys**: Encryption and signing keys
- **Permissions**: Automatically set correct file permissions

#### Cloud & Kubernetes
- **AWS**: CLI configuration and credentials
- **Kubernetes**: kubeconfig and cluster settings
- **Teleport**: SSH client configurations

### 🛠️ Development Tools

#### Language Managers
- **asdf**: Ruby, Node.js, Python, Java, Rust versions
- **nvm**: Node.js version manager
- **pyenv**: Python version manager
- **rbenv**: Ruby version manager
- **rustup**: Rust toolchain

#### Package Managers
- **Ruby Gems**: Global gem list
- **npm**: Global packages
- **pip**: Python packages

#### Additional Tools
- **MongoDB**: Compass configurations
- **Redis**: RedisInsight settings
- **SonarLint**: Code quality tool configs
- **Tabnine**: AI code completion settings

### 🗂️ Workspace Files

#### Workspace Root Files
- **Shell History**: `.zsh_history`, `.viminfo`, `.lesshst`
- **Development Configs**: `.gitconfig`, `.pryrc`, `.npmrc`, `.yarnrc`
- **Editor Configs**: `.vimrc`, `.ideavimrc`, `.p10k.zsh`
- **Shell Configs**: `.zprofile`, `.tool-versions`

#### Workspace Root Directories
- **Development Tools**: `.asdf`, `.nvm`, `.pyenv`, `.rbenv`, `.rustup`
- **Cloud & Kubernetes**: `.kube`, `.tsh`, `.ssh`
- **IDE Configs**: `.cursor`, `.config`, `.vim`
- **Tool Configs**: `.thor`, `.tabnine`, `.sonarlint`, `.mongodb`, `.redis-insight`, `.redisinsight-app`
- **Security**: `.gnupg`

### 🎨 Application Configurations

#### Development Tools
- **RedisInsight**: Database GUI settings
- **Keychron Engine**: Keyboard configuration
- **Logi Options+**: Logitech device settings
- **Spectacle**: Window management preferences

### 📁 User Data

#### Directories
- **Workspace**: All development projects (compressed as .tar.gz or .zip)
- **Workspace Root Files**: Important configuration files from workspace root
- **Documents**: Personal documents (compressed as .tar.gz or .zip)
- **Desktop**: Desktop files (compressed as .tar.gz or .zip)
- **Downloads**: Downloaded files (compressed as .tar.gz or .zip)

#### Browser Data
- **Chrome Profile**: Bookmarks, extensions, settings (compressed as .tar.gz or .zip)

## 🔧 Script Details

### `migrate_mac.sh`

**Purpose**: Captures your complete environment from the old Mac

**What it does**:
1. Creates a `~/dotfiles` directory
2. Copies shell and editor configurations
3. Dumps Homebrew manifests (Brewfile, formulae, casks)
4. Captures Mac App Store applications
5. Copies manual GUI applications
6. Exports language package lists
7. Backs up IDE and terminal preferences
8. Captures SSH/GPG keys and cloud configurations
9. Archives user directories and browser profiles
10. Copies workspace root files and directories
11. Compresses workspace directory
12. Copies additional configuration directories

### `restore_mac.sh`

**Purpose**: Restores your environment on the new Mac

**What it does**:
1. Installs Xcode Command Line Tools
2. Installs and configures Homebrew
3. Installs essential CLI tools (git, kubectl, k9s, eksctl, etc.)
4. Installs eks-node-viewer via AWS Homebrew tap
5. Installs OpenLens via Homebrew cask
6. Installs asdf and language plugins
7. Restores all Homebrew packages and casks
8. Installs Mac App Store applications
9. Copies manual applications
10. Links all configuration files (including .eks-node-viewer)
11. Restores IDE and terminal settings
12. Installs language packages
13. Restores SSH/GPG keys with proper permissions
14. Restores cloud and Kubernetes configurations
15. Restores workspace root files and directories
16. Extracts workspace directory
17. Extracts user directories and browser data

## 🛡️ Security Features

### SSH Key Permissions
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/id_*.pub
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/known_hosts
```

### GPG Key Permissions
```bash
chmod 700 ~/.gnupg
```

## 📋 Prerequisites

### On Old Mac
- macOS with Homebrew installed
- Applications already installed and configured
- SSH/GPG keys already set up

### On New Mac
- Fresh macOS installation
- Internet connection for downloads
- Administrator privileges

## 🔄 Manual Steps (After Restoration)

1. **Authenticate with services**:
   - Sign into applications (Slack, Zoom, etc.)
   - Authenticate with cloud providers
   - Set up any 2FA tokens

2. **Verify installations**:
   ```bash
   # Check key tools
   which git kubectl docker
   brew list | head -10
   asdf list
   ```

3. **Test configurations**:
   ```bash
   # Test SSH
   ssh -T git@github.com
   
   # Test GPG
   gpg --list-secret-keys
   
   # Test Kubernetes
   kubectl cluster-info
   ```

## 🚨 Troubleshooting

### Common Issues

**Homebrew not found**:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**SSH keys not working**:
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*
```

**Git configuration missing**:
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Logs and Debugging

The scripts use `set -euo pipefail` for error handling. Check for:
- Missing files (script will continue with `|| true`)
- Permission issues (especially with SSH/GPG keys)
- Network connectivity for downloads

## 📝 Customization

### Adding New Applications

1. **GUI Apps**: Add to `MANUAL_APPS` array in `migrate_mac.sh`
2. **CLI Tools**: Install via Homebrew (automatically captured)
3. **Configurations**: Add to the appropriate section in both scripts

### Modifying Configurations

Edit the scripts to:
- Add new configuration directories
- Include additional preference files
- Customize installation steps

## 🤝 Contributing

To improve these scripts:

1. Test on a fresh macOS installation
2. Verify all configurations are properly restored
3. Update this README with any changes
4. Test with different macOS versions

## 📄 License

These scripts are provided as-is for personal use. Modify as needed for your environment.

---

**Happy migrating! 🚀**

*Last updated: $(date)* 
