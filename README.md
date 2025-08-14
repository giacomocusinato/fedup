# fedup
**Post-install script for Fedora — updates, apps, drivers, GNOME customization, and development setup.**  

fedup takes a fresh Fedora Workstation install and turns it into a fully-loaded, gaming, developer-friendly desktop in one go.  

---

## 🚀 Features
- **System updates** — get the latest packages & security patches
- **Firmware updates** — optional check for system firmware
- **RPM Fusion & Flatpak** — unlock extra software sources
- **Media codecs** — full multimedia support with hardware acceleration
- **GPU drivers** — Intel, AMD, and NVIDIA proprietary driver installs
- **App installs** — curated set of everyday and dev tools
- **Development setup** — VSCode, Docker, Node.js, Python, Go, Git, Zsh + Oh My Zsh, Neovim
- **GNOME tweaks** — essential customization and keyboard shortcuts
- **Cleanup** — remove leftover junk after setup

---

## 🛠 Usage

Clone the repo and run:
```bash
git clone https://github.com/yourname/fedup.git
cd fedup
chmod +x fedup.sh
./fedup.sh
```

To run a specific step: 
```bash
STEP=step_id ./fedup.sh
```

Or run in one line with curl:
```bash
curl -sL https://raw.githubusercontent.com/giacomocusinato/fedup/main/fedup.sh | bash
```

The curl method runs the script directly without saving it locally, you might need to reboot afte rsome core steps.

## 📋 Step-by-Step

### 1️⃣ Start
Basic checks, set up the environment, and prep for the run.

### 2️⃣ Update
```bash
sudo dnf group upgrade core -y
sudo dnf upgrade --refresh -y
```
Brings your Fedora base system up to date.

### 3️⃣ Post-Update
Currently empty — placeholder in case we need post-update tasks later.

### 4️⃣ Firmware
```bash
sudo fwupdmgr refresh --force
fwupdmgr get-updates
```
Checks for firmware updates. If updates are found, you’ll be told to run `fwupdmgr update` manually.

### 5️⃣ Post-Firmware
Empty placeholder — helps keep the step sequence clean.

### 6️⃣ RPM Fusion
Enables free & non-free repositories for extra software:
```bash
sudo dnf install -y   https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm   https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```

### 7️⃣ Flatpak
Adds Flathub and integrates it into GNOME Software:
```bash
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
sudo dnf install -y gnome-software-plugin-flatpak
```

### 8️⃣ Media
Installs full multimedia support:
```bash
sudo dnf group install -y multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
sudo dnf group install -y sound-and-video
sudo dnf install -y ffmpeg-libs libva libva-utils
```

### 9️⃣ Intel GPU
Optionally swaps in Intel’s proprietary VA-API driver:
```bash
sudo dnf swap -y libva-intel-media-driver intel-media-driver --allowerasing
sudo dnf install -y libva-intel-driver
```

### 🔟 AMD GPU
Optionally swaps in AMD’s proprietary VA-API/VDPAU drivers:
```bash
sudo dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld
sudo dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
sudo dnf swap -y mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686
sudo dnf swap -y mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686
```

### 1️⃣1️⃣ NVIDIA GPU
Optionally installs proprietary NVIDIA drivers and CUDA:
```bash
sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
```

### 1️⃣2️⃣ Apps
Installs a curated set of everyday apps (browsers, productivity tools, media players, etc.).

### 1️⃣3️⃣ Dev Setup
Opinionated development environment:
- VSCode
- Docker
- Node.js (via NVM)
- Python
- Go
- Git
- Neovim
- Zsh + Oh My Zsh

Also sets Zsh as default shell (unless already set).

### 1️⃣4️⃣ GNOME Customization
Installs GNOME Tweaks, configures a few essential shortcuts:
- **Super+D** — Show desktop  
- **Super+T** — Open terminal  
- **Super+E** — Open home folder

### 1️⃣5️⃣ Cleanup
Removes leftover packages and clears caches:
```bash
sudo dnf autoremove -y
sudo dnf clean all
```

---

## 🛠 Usage
Clone the repo and run:
```bash
git clone https://github.com/yourname/fedup.git
cd fedup
chmod +x fedup.sh
./fedup.sh
```
You can resume from a specific step:
```bash
STEP=media ./fedup.sh
```

---

## ⚠️ Notes
- This script targets **Fedora Workstation 42 (GNOME)** but should work on nearby releases with minor changes.
- Some steps ask for confirmation before installing proprietary drivers.
- Firmware updates and GPU drivers may require a reboot after installation.