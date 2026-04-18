#!/bin/bash
set -e

# This script runs INSIDE the chroot environment

export DEBIAN_FRONTEND=noninteractive

echo "Configuring internal system..."
apt-get update
apt-get install -y locales debconf-utils
sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen
locale-gen
export LANG=en_US.UTF-8

# 1. Configure Repositories (Enable Contrib, Non-Free, Non-Free-Firmware)
cat > /etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware

deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware

deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
EOF

apt-get update

# 2. Install Kernel and Core Packages (Updated with Firmware)
# Preseed grub-pc to avoid prompts
echo "grub-pc grub-pc/install_devices multiselect" | debconf-set-selections

# firmware-linux and specific drivers for common hardware (WiFi, GPU)
# Using grub-pc (BIOS) and grub-efi-amd64-bin (EFI binaries) for best compatibility
apt-get install -y linux-image-amd64 live-boot systemd-sysv grub-pc grub-efi-amd64-bin grub-common lsb-release plymouth-x11 \
    firmware-linux firmware-linux-nonfree firmware-iwlwifi firmware-realtek firmware-amd-graphics firmware-misc-nonfree \
    intel-microcode amd64-microcode bluetooth bluez pulseaudio-module-bluetooth

# Configure GRUB defaults
cat > /etc/default/grub <<EOF
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR=\`lsb_release -i -s 2> /dev/null || echo AxiomOS\`
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX=""
GRUB_GFXMODE=1920x1080,auto
EOF

# Fix for adduser/usbmux warning
mkdir -p /var/lib/usbmux

# 3. Install Desktop Environment (KDE Plasma) and Window Manager
# kde-standard gives a good balance. kde-full is huge.
apt-get install -y kde-standard sddm calamares calamares-settings-debian

# 4. Install Essential Applications & Utilities
# Browser, Terminal, File Manager
apt-get install -y firefox-esr konsole dolphin network-manager-gnome pulseaudio

# Productivity (LibreOffice)
apt-get install -y libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-kf5

# Custom App Dependencies (Python/Qt)
apt-get install -y python3-pyqt6 python3-psutil python3-requests python3-yaml

# Multimedia (VLC, Codecs)
apt-get install -y vlc ffmpeg gstreamer1.0-libav gstreamer1.0-plugins-ugly gstreamer1.0-vaapi

# Utilities (Archive, Partitioning, System Monitor, Package Manager)
apt-get install -y ark gparted htop btop synaptic gwenview kcalc kate ufw plasma-discover

# 4. Install "Unique" GUI Elements (Themes & Icons)
# Install Plymouth for boot splash, Arc Theme for GTK/KDE, Papirus Icons
# Install Plymouth for boot splash, Arc Theme for GTK/KDE, Papirus Icons, and ImageMagick for asset generation
# Install Plymouth for boot splash, Arc Theme for GTK/KDE, Papirus Icons, and ImageMagick for asset generation
apt-get install -y papirus-icon-theme arc-theme neofetch plymouth plymouth-themes kde-config-gtk-style breeze-gtk-theme imagemagick fonts-dejavu

# --- Deep Branding: Boot Splash ---
# Ensure Plymouth and DRM modules are in initramfs
echo "plymouth" >> /etc/initramfs-tools/modules
echo "drm" >> /etc/initramfs-tools/modules

# Create custom AxiomOS Plymouth theme
mkdir -p /usr/share/plymouth/themes/axiomos

cat > /usr/share/plymouth/themes/axiomos/axiomos.plymouth <<EOF
[Plymouth Theme]
Name=AxiomOS
Description=AxiomOS Custom Theme
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/axiomos
ScriptFile=/usr/share/plymouth/themes/axiomos/axiomos.script
EOF

# Generate Text Image for Plymouth
convert -background transparent -fill white -font DejaVu-Sans-Bold -pointsize 48 label:'AxiomOS' /usr/share/plymouth/themes/axiomos/text.png

cat > /usr/share/plymouth/themes/axiomos/axiomos.script <<EOF
# Simple Plymouth Script to display centered logo and text
Window.SetBackgroundTopColor(0.0, 0.0, 0.0);
Window.SetBackgroundBottomColor(0.0, 0.0, 0.0);

logo_image = Image("logo.png");
text_image = Image("text.png");

# Scale logo to 25% of screen width (slightly smaller to make room for text)
scale_factor = (Window.GetWidth() * 0.25) / logo_image.GetWidth();
scaled_logo = logo_image.Scale(logo_image.GetWidth() * scale_factor, logo_image.GetHeight() * scale_factor);

# Place Logo
logo_sprite = Sprite(scaled_logo);
logo_sprite.SetX(Window.GetWidth() / 2 - scaled_logo.GetWidth() / 2);
logo_sprite.SetY(Window.GetHeight() / 2 - scaled_logo.GetHeight() / 2 - 40); # Shift up slightly
logo_sprite.SetZ(10);

# Place Text below Logo
text_sprite = Sprite(text_image);
text_sprite.SetX(Window.GetWidth() / 2 - text_image.GetWidth() / 2);
text_sprite.SetY(logo_sprite.GetY() + scaled_logo.GetHeight() + 20);
text_sprite.SetZ(10);

# Animation Loop (Required for Shutdown/Reboot to keep displaying)
fun refresh_callback ()
  {
    # Just keep the sprites visible
  }
  
Plymouth.SetRefreshFunction (refresh_callback);
EOF

# Install and set as default
plymouth-set-default-theme -R axiomos


# --- Deep Branding: Console & Login ---
echo "AxiomOS \n \l" > /etc/issue
echo "AxiomOS" > /etc/issue.net

# --- GUI Customization: Default User Settings (via /etc/skel) ---
# Create necessary config directories
mkdir -p /etc/skel/.config
mkdir -p /etc/skel/.local/share

# 1. Apply Arc Dark Theme & Papirus Icons globally for KDE
cat > /etc/skel/.config/kdeglobals <<EOF
[General]
ColorScheme=ArcDark
Name=Arc Dark
widgetStyle=Breeze

[Icons]
Theme=Papirus-Dark

[KDE]
LookAndFeelPackage=org.kde.breezedark.desktop
EOF

# 2. Enable "Wobbly Windows" and Magic Lamp (Genie) Effect for interactivity
cat > /etc/skel/.config/kwinrc <<EOF
[Plugins]
wobblywindowsEnabled=true
kwin4_effect_magiclampEnabled=true
blurEnabled=true
contrastEnabled=true

[Effect-wobblywindows]
AdvancedMode=true
Friction=50
Stiffness=10
EOF

# 2.1 Generate and Set Branded Wallpaper
# Create a 1920x1080 black wallpaper with the logo centered
mkdir -p /usr/share/wallpapers/AxiomOS/contents/images
convert -size 1920x1080 xc:black \
    /usr/share/plymouth/themes/axiomos/logo.png -gravity center -composite \
    /usr/share/wallpapers/AxiomOS/contents/images/1920x1080.png

# Create metadata for the wallpaper
cat > /usr/share/wallpapers/AxiomOS/metadata.desktop <<EOF
[Desktop Entry]
Name=AxiomOS
X-KDE-PluginInfo-Name=AxiomOS
X-KDE-PluginInfo-Author=AxiomOS Team
X-KDE-PluginInfo-License=GPL
Type=Service
ServiceTypes=KPackage/GenericQML
EOF

# Configure Plasma to use this wallpaper by default (via appletsrc)
# This is a best-effort attempt to set the default wallpaper for the first desktop
cat > /etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc <<EOF
[Containments][1][Wallpaper][org.kde.image][General]
Image=file:///usr/share/wallpapers/AxiomOS/contents/images/1920x1080.png
FillMode=2
EOF

# 2.2 Set Application Launcher Icon
# We overwrite the 'start-here-kde' icon in the Papirus theme with our logo
# This ensures it shows up in the panel
cp /usr/share/plymouth/themes/axiomos/logo.png /usr/share/icons/Papirus-Dark/symbolic/places/start-here-kde-symbolic.svg
# Also copy to other sizes to be safe (as png)
cp /usr/share/plymouth/themes/axiomos/logo.png /usr/share/icons/Papirus-Dark/64x64/places/start-here-kde.svg

# 2.3 Configure SDDM (Login Screen) Branding
# Create a custom SDDM theme config that points to our wallpaper and logo
mkdir -p /usr/share/sddm/themes/breeze
cat > /usr/share/sddm/themes/breeze/theme.conf.user <<EOF
[General]
background=/usr/share/wallpapers/AxiomOS/contents/images/1920x1080.png
logo=/usr/share/plymouth/themes/axiomos/logo.png
EOF


# 3. Configure Taskbar / Plasma Theme (Optional, stick to Breeze Dark for stability but with Arc colors)
cat > /etc/skel/.config/plasmarc <<EOF
[Theme]
name=breeze-dark
EOF

# 4. Configure GTK Apps to match
mkdir -p /etc/skel/.config/gtk-3.0
cat > /etc/skel/.config/gtk-3.0/settings.ini <<EOF
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
EOF

# 5. Create "Install AxiomOS" Desktop Shortcut
mkdir -p /etc/skel/Desktop
cat > /etc/skel/Desktop/calamares.desktop <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Install AxiomOS
GenericName=Live Installer
Comment=Install the operating system to disk
Exec=pkexec calamares
Icon=calamares
Terminal=false
Categories=System;
EOF
chmod +x /etc/skel/Desktop/calamares.desktop

# Remove "Install Debian" shortcut if it exists (often from debian-installer-launcher)
apt-get purge -y debian-installer-launcher || true
rm -f /usr/share/applications/debian-installer-launcher.desktop
rm -f /etc/skel/Desktop/debian-installer-launcher.desktop

# --- Installer Configuration (Calamares) ---
mkdir -p /etc/calamares/branding/axiomos

# 1. Branding
cat > /etc/calamares/branding/axiomos/branding.desc <<EOF
---
componentName: axiomos
welcomeStyleCalamares: true
welcomeExpandingLogo: true
windowExpanding: normal
windowSize: 800px,520px
windowPlacement: center

strings:
    productName:         AxiomOS
    shortProductName:    AxiomOS
    version:             1.0
    shortVersion:        1.0
    versionedName:       AxiomOS 1.0
    shortVersionedName:  AxiomOS 1.0
    bootloaderEntryName: AxiomOS

images:
    productLogo:         "/usr/share/plymouth/themes/axiomos/logo.png"
    productIcon:         "/usr/share/plymouth/themes/axiomos/logo.png"
    productWelcome:      "/usr/share/plymouth/themes/axiomos/logo.png"

slideshow:               []

style:
   sidebarBackground:    "#2f343f"
   sidebarText:          "#FFFFFF"
   sidebarTextSelect:    "#2980b9"
EOF

# 2. Settings (Module Order)
cat > /etc/calamares/settings.conf <<EOF
---
modules-search: [ local ]

instances:
- id:       before
  module:   shellprocess
  config:   shellprocess-before.conf

sequence:
- show:
  - welcome
  - locale
  - keyboard
  - partition
  - users
  - summary
- exec:
  - partition
  - mount
  - unpackfs
  - machineid
  - fstab
  - locale
  - keyboard
  - users
  - networkcfg
  - hwclock
  - services-systemd
  - grubcfg
  - bootloader
  - umount
- show:
  - finished

branding: axiomos
prompt-install: false
dont-chroot: false
oem-setup: false
disable-cancel: false
disable-cancel-during-exec: false
hide-back-and-next-during-exec: false
quit-at-end: false
EOF

# --- Auto-Update Configuration ---
chmod +x /usr/local/bin/first-boot-update.sh
systemctl enable first-boot-update.service

# --- Install Custom Apps ---
# 1. Axiom Welcome App
cp /resources/apps/axiom-welcome/axiom-welcome.py /usr/local/bin/axiom-welcome
chmod +x /usr/local/bin/axiom-welcome
cp /resources/apps/axiom-welcome/axiom-welcome.desktop /usr/share/applications/

# 2. Axiom Control Center
cp /resources/apps/axiom-control-center/axiom-control-center.py /usr/local/bin/axiom-control-center
chmod +x /usr/local/bin/axiom-control-center
cp /resources/apps/axiom-control-center/axiom-control-center.desktop /usr/share/applications/

# Autostart Welcome App
mkdir -p /etc/skel/.config/autostart
cp /resources/apps/axiom-welcome/axiom-welcome.desktop /etc/skel/.config/autostart/

# --- Performance & Security Optimizations ---
# Install TLP (Power Management), ZRAM (Memory Swap), and UFW (Firewall)
apt-get install -y tlp tlp-rdw zram-tools ufw

# Enable Services
systemctl enable tlp
systemctl enable zramswap.service

# Configure Firewall (Default Deny Incoming)
ufw default deny incoming
ufw default allow outgoing
ufw enable

# --- Install Profile Scripts ---
cp /resources/scripts/axiom-install-dev.sh /usr/local/bin/axiom-install-dev
chmod +x /usr/local/bin/axiom-install-dev

cp /resources/scripts/axiom-install-creator.sh /usr/local/bin/axiom-install-creator
chmod +x /usr/local/bin/axiom-install-creator

# --- Developer Tools (Base) ---
# Install Git, Zsh, and curl if not already present
apt-get install -y git zsh curl

# Install Starship Prompt
curl -sS https://starship.rs/install.sh | sh -s -- -y
# Configure Zsh with Starship for new users
mkdir -p /etc/skel
echo 'eval "$(starship init zsh)"' >> /etc/skel/.zshrc

# 5. Install Utilities
apt-get install -y software-properties-common curl wget git

# 5. Create a default user
useradd -m -s /bin/bash -c "User" user
echo "user:password" | chpasswd
usermod -aG sudo user

# Set User Avatar (Login Screen Logo)
cp /usr/share/plymouth/themes/axiomos/logo.png /home/user/.face.icon
chown user:user /home/user/.face.icon

# Set Default SDDM Face
mkdir -p /usr/share/sddm/faces
cp /usr/share/plymouth/themes/axiomos/logo.png /usr/share/sddm/faces/.default

# Remove installer shortcut from /etc/skel so it doesn't appear on the installed system
rm -f /etc/skel/Desktop/calamares.desktop

# Ensure "Install Debian" is gone from the live user's desktop
rm -f /home/user/Desktop/debian-installer-launcher.desktop

# 6. Set Hostname
# 6. Set Hostname and Branding
echo "AxiomOS" > /etc/hostname
echo "127.0.1.1 AxiomOS" >> /etc/hosts

# Update os-release
cat > /etc/os-release <<EOF
PRETTY_NAME="AxiomOS"
NAME="AxiomOS"
ID=axiomos
ID_LIKE=debian
HOME_URL="https://example.com/"
SUPPORT_URL="https://example.com/support"
BUG_REPORT_URL="https://example.com/bugs"
EOF

# 7. Network Configuration
cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

allow-hotplug eth0
iface eth0 inet dhcp
EOF

# 8. Clean up to reduce ISO size
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*

# 9. Update GRUB and Regenerate Initramfs (Important for Plymouth)
update-grub
update-initramfs -u

echo "Internal configuration complete."
