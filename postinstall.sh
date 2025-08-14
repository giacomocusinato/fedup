#!/usr/bin/env bash
set -euo pipefail

STEP="${STEP:-start}"

source "$(dirname "$0")/lib/ui.sh"

# STEP: start
if [[ "$STEP" == "start" ]]; then
  step_banner "start" "🚀" "Starting Fedora post-install setup"
  STEP="update"
fi

# STEP: update
if [[ "$STEP" == "update" ]]; then
  step_banner "update" "🔄" "Updating system packages"
  sudo dnf group upgrade -y core
  sudo dnf upgrade -y
  STEP="post-update"
fi

# STEP: post-update
if [[ "$STEP" == "post-update" ]]; then
  step_banner "post-update" "🛠️" "Post-update placeholder"
  STEP="firmware"
fi

# STEP: firmware
if [[ "$STEP" == "firmware" ]]; then
  step_banner "firmware" "📦" "Checking firmware updates"
  sudo fwupdmgr refresh --force
  if fwupdmgr get-updates | grep -q "Upgrade available"; then
    echo "📦 Firmware updates available — please run 'fwupdmgr update' manually."
  else
    echo "✅ No firmware updates found."
  fi
  STEP="post-firmware"
fi

# STEP: post-firmware
if [[ "$STEP" == "post-firmware" ]]; then
  step_banner "post-firmware" "🧩" "Post-firmware placeholder"
  STEP="rpmfusion"
fi

# STEP: rpmfusion
if [[ "$STEP" == "rpmfusion" ]]; then
  step_banner "rpmfusion" "📦" "Enabling RPM Fusion (free & nonfree)"
  if rpm -q rpmfusion-free-release >/dev/null 2>&1; then
    echo "✔ RPM Fusion already enabled."
    return 0
  fi
  sudo dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
  STEP="flatpak"
fi

# STEP: flatpak
if [[ "$STEP" == "flatpak" ]]; then
  step_banner "flatpak" "📦" "Installing Flatpak and configuring Flathub"

  sudo dnf install -y flatpak
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak remote-modify --enable flathub

  STEP="media"
fi

# STEP: media
if [[ "$STEP" == "media" ]]; then
  step_banner "media" "🎞️" "Installing multimedia codecs and tools"
  sudo dnf group install -y multimedia --setopt="install_weak_deps=False"
  sudo dnf swap -y 'ffmpeg-free' 'ffmpeg' --allowerasing
  sudo dnf group install -y sound-and-video
  sudo dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264
  STEP="intel"
fi

# STEP: intel
if [[ "$STEP" == "intel" ]]; then
  step_banner "intel" "🧠" "Intel VA-API driver setup"
  read -p "💬 Is this system using Intel graphics? [y/N]: " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    sudo dnf install -y intel-media-driver libva-utils
    sudo dnf swap -y libva-intel-media-driver intel-media-driver --allowerasing || true
  else
    echo "⏭️ Skipping Intel driver installation."
  fi
  STEP="amd"
fi

# STEP: amd
if [[ "$STEP" == "amd" ]]; then
  step_banner "amd" "🕹️" "AMD VA-API and VDPAU drivers (proprietary replacements)"
  read -p "💬 Do you want to install proprietary AMD VA-API/VDPAU drivers? [y/N]: " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    sudo dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld
    sudo dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
    sudo dnf swap -y mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686
    sudo dnf swap -y mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686
  else
    echo "⏭️ Skipping AMD driver installation."
  fi
  STEP="nvidia"
fi

# STEP: nvidia
if [[ "$STEP" == "nvidia" ]]; then
  step_banner "nvidia" "💻" "NVIDIA drivers"
  read -p "💬 Do you want to install proprietary NVIDIA drivers? [y/N]: " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
    echo "⌛ Waiting 5 seconds to let akmods trigger..."
    sleep 5
  else
    echo "⏭️ Skipping NVIDIA driver installation."
  fi
  STEP="vaapi"
fi

# STEP: vaapi
if [[ "$STEP" == "vaapi" ]]; then
  step_banner "vaapi" "🎬" "Installing VA-API debug and test tools"
  sudo dnf install -y libva-utils vainfo vdpauinfo
  STEP="gnome"
fi

# STEP: gnome
if [[ "$STEP" == "gnome" ]]; then
  step_banner "gnome" "🧩" "GNOME Tweaks, Extensions and curstomizations"
  sudo dnf install -y gnome-tweaks gnome-extensions

  # Super + T → Open terminal
  gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Super>t']"
  # Super + D → Show desktop
  gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']"
  # Super + E → Open home folder
  gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"

  STEP="apps"
fi

# STEP: apps
if [[ "$STEP" == "apps" ]]; then
  step_banner "apps" "📦" "Install essential desktop applications"

  sudo dnf install -y dialog

  cmd=(dialog --separate-output --checklist "Select apps to install:" 30 88 24)

  options=(
    # ── Browsers ───────────────────────────────────────────────────────────────
    __hdr_browsers   "──────── 🌐 Browsers ────────" off
    firefox          "Firefox — Privacy-focused web browser" on
    chromium         "Chromium — Open-source Chrome base" off
    chrome           "Google Chrome — Proprietary browser by Google" off
    brave            "Brave — Privacy-focused browser with adblock" on
    zen              "Zen Browser — Minimal and privacy-focused browser" off

    # ── Media & Streaming ─────────────────────────────────────────────────────
    __hdr_media      "──────── 🎬 Media & Streaming ────────" off
    vlc              "VLC — Versatile media player" on
    obs              "OBS Studio — Screen recording & streaming" on
    spotify          "Spotify — Music streaming service" off

    # ── Downloads & Torrents ─────────────────────────────────────────────────
    __hdr_torrents   "──────── 📡 Downloads & Torrents ────────" off
    qbittorrent      "qBittorrent — Lightweight torrent client" off
    transmission     "Transmission — Simple torrent client" on

    # ── Communication & Email ─────────────────────────────────────────────────
    __hdr_comm       "──────── 📬 Communication & Email ────────" off
    thunderbird      "Thunderbird — Email client from Mozilla" off

    # ── Password Managers ────────────────────────────────────────────────────
    __hdr_pw         "──────── 🔑 Password Managers ────────" off
    bitwarden        "Bitwarden — Secure open-source password manager" on
    1password        "1Password — Premium password manager" off

    # ── Creativity & Image/Audio ─────────────────────────────────────────────
    __hdr_creative   "──────── 🎨 Creativity & Image/Audio ────────" off
    gimp             "GIMP — Image manipulation program" on
    darktable        "Darktable — RAW photo editor" off
    inkscape         "Inkscape — Vector graphics editor" off
    audacity         "Audacity — Audio recording & editing" off

    # ── Gaming ────────────────────────────────────────────────────────────────
    __hdr_gaming     "──────── 🎮 Gaming ────────" off
    steam            "Steam — Gaming platform and store" on

    # ── System & Utilities ───────────────────────────────────────────────────
    __hdr_system     "──────── 🛠 System & Utilities ────────" off
    btop             "btop — Resource monitor" on
    timeshift        "Timeshift — System restore tool" on
    corectrl         "CoreCtrl — GPU tuning utility" on
  )

  choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
  clear

  # Skip any "header" selections (tags starting with __hdr_)
  for choice in $choices; do
    [[ "$choice" == __hdr_* ]] && continue
    case $choice in
      # 🌐 Browsers
      firefox)    sudo dnf install -y firefox ;;
      chromium)   sudo dnf install -y chromium ;;
      chrome)
        # Ensure Chrome repo exists & enabled; then install
        sudo dnf install -y fedora-workstation-repositories || true
        if ! sudo dnf repolist --enabled | grep -q "^google-chrome"; then
          # dnf config-manager may require dnf-plugins-core
          sudo dnf install -y dnf-plugins-core || true
          sudo dnf config-manager --set-enabled google-chrome || true
        fi
        sudo dnf install -y google-chrome-stable
        ;;
      brave)      flatpak install -y flathub com.brave.Browser ;;
      zen)        flatpak install -y flathub io.github.zen_browser.zen ;;

      # 🎬 Media & Streaming
      vlc)        sudo dnf install -y vlc ;;
      obs)        sudo dnf install -y obs-studio ;;
      spotify)    flatpak install -y flathub com.spotify.Client ;;

      # 📡 Downloads & Torrents
      qbittorrent)  sudo dnf install -y qbittorrent ;;
      transmission) sudo dnf install -y transmission ;;

      # 📬 Communication & Email
      thunderbird)  sudo dnf install -y thunderbird ;;

      # 🔑 Password Managers
      bitwarden)    flatpak install -y flathub com.bitwarden.desktop ;;
      1password)    flatpak install -y flathub com.1password.1Password ;;

      # 🎨 Creativity & Image/Audio
      gimp)       sudo dnf install -y gimp ;;
      darktable)  sudo dnf install -y darktable ;;
      inkscape)   sudo dnf install -y inkscape ;;
      audacity)   flatpak install -y flathub org.audacityteam.Audacity ;;

      # 🎮 Gaming
      steam)      flatpak install -y flathub com.valvesoftware.Steam ;;

      # 🛠 System & Utilities
      btop)       sudo dnf install -y btop ;;
      timeshift)  sudo dnf install -y timeshift ;;
      corectrl)   sudo dnf install -y corectrl ;;
    esac
  done

  echo -e "\n✅ All selected apps installed."
  STEP="done"
fi

# STEP: dev
if [[ "$STEP" == "dev" ]]; then
  step_banner "dev" "💻" "Opinionated development environment"

  read -p "Proceed with the opinionated dev setup (VSCode, Python, Git, NVM/Node, Go, Zsh+OhMyZsh, Starship, Docker, NeoVim)? [Y/n]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ && -n "$confirm" ]]; then
    echo "⏭️ Skipping dev setup."
    STEP="done"
  else
    echo "🔧 Installing base tools..."
    sudo dnf install -y curl git tar util-linux-user

    append_once() {
      local line="$1" file="$2"
      grep -qxF "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
    }

    # ── VS Code ─
    echo "🧩 VS Code"
    if ! command -v code >/dev/null 2>&1; then
      sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
      sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
      sudo dnf check-update || true
      sudo dnf install -y code
    fi

    # ── Python 3 + pip ─
    echo "🐍 Python"
    sudo dnf install -y python3 python3-pip

    # ── Git ─
    echo "🌿 Git"
    sudo dnf install -y git

    # ── Node.js via NVM ─
    echo "🟢 Node (NVM)"
    if [[ ! -d "$HOME/.nvm" ]]; then
      curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi
    append_once 'export NVM_DIR="$HOME/.nvm"' "$HOME/.bashrc"
    append_once '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' "$HOME/.bashrc"
    append_once 'export NVM_DIR="$HOME/.nvm"' "$HOME/.zshrc"
    append_once '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' "$HOME/.zshrc"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm install --lts || true

    # ── Go ─
    echo "💠 Go"
    sudo dnf install -y golang

    # ── Zsh + Oh My Zsh ─
    echo "🐚 Zsh + Oh My Zsh"
    sudo dnf install -y zsh
    if [[ "$SHELL" != "$(command -v zsh)" ]]; then
      chsh -s "$(command -v zsh)" || echo "⚠️ Could not change login shell automatically."
    fi
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
      RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
      git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
      git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi
    if grep -q '^plugins=' "$HOME/.zshrc" 2>/dev/null; then
      sed -i 's/^plugins=.*/plugins=(git aliases zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
    else
      echo 'plugins=(git aliases zsh-autosuggestions zsh-syntax-highlighting)' >> "$HOME/.zshrc"
    fi

    # ── Docker + Compose ─
    echo "🐳 Docker"
    sudo dnf install -y docker docker-compose
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"
    echo "⚠️ You may need to log out/in for docker group changes to take effect."

    # ── NeoVim ─
    echo "📝 NeoVim"
    sudo dnf install -y neovim

    echo -e "\n✅ Dev setup complete. Open a new terminal (Zsh) to load changes."
    STEP="done"
  fi
fi


step_banner "cleanup" "🧹" "Cleaning package caches"
sudo dnf autoremove -y || true
sudo dnf clean all -y || true
echo "✔ Cleanup complete."
STEP="done"


# STEP: done
if [[ "$STEP" == "done" ]]; then
  step_banner "done" "🎉" "Post-installation complete"
  echo "🎯 You're all set! Customize further or reboot when ready."
fi

# Change shell to Zsh only if not already default
if [[ "$SHELL" != "$(command -v zsh)" ]]; then
  echo "Changing default shell to Zsh..."
  chsh -s "$(command -v zsh)"
else
  echo "✅ Zsh is already the default shell — skipping chsh."
fi
