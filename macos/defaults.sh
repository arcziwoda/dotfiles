#!/usr/bin/env bash
# macOS system preferences. Idempotent — run it again any time.
# Not stowed: this is a script you execute, not a config file to symlink.
#
# To find the key behind a setting you changed in System Settings:
#   defaults read > /tmp/before; # change it in the UI
#   defaults read > /tmp/after; diff /tmp/before /tmp/after
set -euo pipefail

echo "==> Keyboard"
# Fast key repeat. This is the setting that makes hjkl navigation usable.
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Holding a key repeats it instead of opening the accent picker.
# Trade-off: the press-and-hold popup for á/ä/å is gone. Polish diacritics are
# unaffected if you type them with Option (Ghostty keeps the right Option key
# native for exactly this reason).
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Text substitutions that corrupt code and commit messages.
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Full keyboard access: Tab moves between all controls, not just text fields.
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

echo "==> Finder"
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
# List view by default (Nlsv; the others are icnv, clmv, Flwv).
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
# Don't warn when changing a file extension.
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# Search the current folder rather than the whole Mac.
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# Keep .DS_Store off network and USB volumes.
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

echo "==> Restarting affected apps"
killall Finder >/dev/null 2>&1 || true
killall cfprefsd >/dev/null 2>&1 || true

echo
echo "Done. Keyboard repeat rates need a logout to take full effect."
