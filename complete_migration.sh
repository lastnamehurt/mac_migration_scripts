#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${HOME}/dotfiles"
echo "🔧 Completing migration from where it failed..."

# 11. Chrome profile (if not already done)
if [[ ! -f "$DOTFILES_DIR/ChromeProfile.tar.gz" ]]; then
  echo "🌐 Copying Chrome profile..."
  [[ -d "$HOME/Library/Application Support/Google/Chrome/Default" ]] &&
    tar czf "$DOTFILES_DIR/ChromeProfile.tar.gz" -C "$HOME/Library/Application Support/Google/Chrome" Default
fi

# 12. Workspace (if not already done)
if [[ ! -f "$DOTFILES_DIR/workspace.tar.gz" ]]; then
  echo "💼 Compressing workspace..."
  [[ -d "$HOME/workspace" ]] && tar czf "$DOTFILES_DIR/workspace.tar.gz" -C "$HOME" workspace
fi

# 8. User directories (compressed) - with better error handling
echo "📁 Archiving user directories..."
for dir in Documents Desktop Downloads; do
  if [[ ! -f "$DOTFILES_DIR/${dir}.tar.gz" ]] && [[ -d "$HOME/$dir" ]]; then
    echo "   📦 Compressing $dir..."
    # Use simpler tar command without extended attributes
    tar -czf "$DOTFILES_DIR/${dir}.tar.gz" -C "$HOME" "$dir" 2>/dev/null || echo "   ⚠️  Failed to compress $dir"
  fi
done

echo ""
echo "✅ Migration completion finished!"
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