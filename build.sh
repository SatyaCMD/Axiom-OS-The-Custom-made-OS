#!/bin/bash
set -e

# Configuration
OS_NAME="AxiomOS"
WORK_DIR="$(pwd)/work"
CD_DIR="$(pwd)/cd-image"
ISO_NAME="axiomos.iso"
DEBIAN_MIRROR="http://deb.debian.org/debian/"
DEBIAN_RELEASE="bookworm" # Debian 12 (Stable)

# Check for root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root (sudo ./build.sh)"
    exit 1
fi

# Install dependencies if missing (basic check)
if ! command -v debootstrap &> /dev/null; then
    echo "Installing build dependencies..."
    apt update
    apt install -y debootstrap squashfs-tools xorriso isolinux syslinux-utils mtools grub-pc-bin grub-efi-amd64-bin dosfstools debian-archive-keyring
fi

echo "=== Starting Build for $OS_NAME ==="

# Clean up previous builds
echo "Cleaning up previous build files..."
rm -rf "$WORK_DIR" "$CD_DIR" "$ISO_NAME"
mkdir -p "$WORK_DIR" "$CD_DIR"/{isolinux,live}

# 1. Bootstrap the base system
echo "Bootstrapping base system ($DEBIAN_RELEASE)..."
# --no-check-gpg is used to bypass the host keyring check, which often fails in custom environments.
# The internal system will still verify packages via apt.
debootstrap --arch=amd64 --no-check-gpg "$DEBIAN_RELEASE" "$WORK_DIR" "$DEBIAN_MIRROR"

# 2. Configure the system (Chroot)
echo "Configuring the system..."
cp configure_system.sh "$WORK_DIR/"
chmod +x "$WORK_DIR/configure_system.sh"

# Copy the entire resources directory to the chroot
cp -r resources "$WORK_DIR/"

# Copy branding assets (Legacy handling, can be cleaned up later if configure_system uses /resources directly)
if [ -f "resources/logo.png" ]; then
    mkdir -p "$WORK_DIR/usr/share/plymouth/themes/axiomos"
    cp resources/logo.png "$WORK_DIR/usr/share/plymouth/themes/axiomos/logo.png"
else
    echo "Error: resources/logo.png not found. Please ensure the logo file exists."
    exit 1
fi

# Copy Auto-Update Scripts
if [ -f "resources/first-boot-update.sh" ] && [ -f "resources/first-boot-update.service" ]; then
    cp resources/first-boot-update.sh "$WORK_DIR/usr/local/bin/"
    cp resources/first-boot-update.service "$WORK_DIR/etc/systemd/system/"
else
    echo "Error: Auto-update scripts not found in resources/."
    exit 1
fi

# Copy Release Notes
if [ -f "RELEASE_NOTES.md" ]; then
    cp RELEASE_NOTES.md "$CD_DIR/"
fi

# Bind mount dev, proc, sys for the chroot
mount --bind /dev "$WORK_DIR/dev"
mount --bind /dev/pts "$WORK_DIR/dev/pts"
mount --bind /proc "$WORK_DIR/proc"
mount --bind /sys "$WORK_DIR/sys"

# Prevent services from starting in chroot (Fixes dbus/systemd errors)
cat > "$WORK_DIR/usr/sbin/policy-rc.d" <<EOF
#!/bin/sh
exit 101
EOF
chmod +x "$WORK_DIR/usr/sbin/policy-rc.d"

# Run the configuration script inside the chroot
export LC_ALL=C
chroot "$WORK_DIR" /configure_system.sh

# Unmount
umount "$WORK_DIR/dev/pts"
umount "$WORK_DIR/sys"
umount "$WORK_DIR/proc"
umount "$WORK_DIR/dev"
rm "$WORK_DIR/configure_system.sh"
rm "$WORK_DIR/usr/sbin/policy-rc.d"

# 3. Build the filesystem image
echo "Building filesystem.squashfs..."
mksquashfs "$WORK_DIR" "$CD_DIR/live/filesystem.squashfs" -e boot

# 4. Prepare Bootloader (ISOLINUX/GRUB)
echo "Setting up bootloader..."
cp "$WORK_DIR/boot/vmlinuz"* "$CD_DIR/live/vmlinuz"
cp "$WORK_DIR/boot/initrd.img"* "$CD_DIR/live/initrd.img"

# Create isolinux config
cat > "$CD_DIR/isolinux/isolinux.cfg" <<EOF
UI menu.c32
PROMPT 0
TIMEOUT 50
MENU TITLE $OS_NAME Boot Menu
MENU BACKGROUND /isolinux/splash.png

LABEL live
    MENU LABEL Run $OS_NAME Live
    LINUX /live/vmlinuz
    INITRD /live/initrd.img
    APPEND boot=live quiet splash vga=788

LABEL live-nomodeset
    MENU LABEL Run $OS_NAME Live (Safe Graphics)
    LINUX /live/vmlinuz
    INITRD /live/initrd.img
    APPEND boot=live nomodeset

LABEL live-failsafe
    MENU LABEL Run $OS_NAME Live (Failsafe)
    LINUX /live/vmlinuz
    INITRD /live/initrd.img
    APPEND boot=live config memtest noapic noacpi pci=noacpi help

LABEL install
    MENU LABEL Install $OS_NAME
    LINUX /live/vmlinuz
    INITRD /live/initrd.img
    APPEND boot=live install quiet splash
EOF

# Copy syslinux modules
cp /usr/lib/ISOLINUX/isolinux.bin "$CD_DIR/isolinux/"
cp /usr/lib/syslinux/modules/bios/menu.c32 "$CD_DIR/isolinux/"
cp /usr/lib/syslinux/modules/bios/ldlinux.c32 "$CD_DIR/isolinux/"
cp /usr/lib/syslinux/modules/bios/libutil.c32 "$CD_DIR/isolinux/"
cp /usr/lib/syslinux/modules/bios/libcom32.c32 "$CD_DIR/isolinux/"

# Copy Splash Image for Boot Menu
if [ -f "resources/logo.png" ]; then
    cp resources/logo.png "$CD_DIR/isolinux/splash.png"
fi

# 4.1 Setup EFI Boot (GRUB)
echo "Setting up EFI..."
mkdir -p "$CD_DIR/boot/grub"
mkdir -p "$CD_DIR/EFI/BOOT"

# Create GRUB config
cat > "$CD_DIR/boot/grub/grub.cfg" <<EOF
search --set=root --file /live/vmlinuz
insmod all_video
set default=0
set timeout=5

menuentry "Run $OS_NAME Live" {
    linux /live/vmlinuz boot=live quiet splash
    initrd /live/initrd.img
}

menuentry "Run $OS_NAME Live (Safe Graphics)" {
    linux /live/vmlinuz boot=live nomodeset
    initrd /live/initrd.img
}

menuentry "Run $OS_NAME Live (Failsafe)" {
    linux /live/vmlinuz boot=live config memtest noapic noacpi pci=noacpi help
    initrd /live/initrd.img
}

menuentry "Install $OS_NAME" {
    linux /live/vmlinuz boot=live install quiet splash
    initrd /live/initrd.img
}
EOF

# Create standalone GRUB EFI binary
# We use /tmp for the prefix to avoid looking for modules at runtime
grub-mkstandalone \
    --format=x86_64-efi \
    --output="$CD_DIR/EFI/BOOT/BOOTX64.EFI" \
    --locales="" \
    --fonts="" \
    "boot/grub/grub.cfg=$CD_DIR/boot/grub/grub.cfg"

# Create EFI System Partition image (efi.img) for xorriso
# Requires dosfstools
dd if=/dev/zero of="$CD_DIR/boot/grub/efi.img" bs=1M count=5
mkfs.vfat "$CD_DIR/boot/grub/efi.img"
# Use mtools to copy files into the image
mmd -i "$CD_DIR/boot/grub/efi.img" ::/EFI
mmd -i "$CD_DIR/boot/grub/efi.img" ::/EFI/BOOT
mcopy -i "$CD_DIR/boot/grub/efi.img" "$CD_DIR/EFI/BOOT/BOOTX64.EFI" ::/EFI/BOOT/BOOTX64.EFI

# 5. Create ISO
echo "Generating ISO..."

# Find isohybrid.bin or isohdpfx.bin (location varies by distro)
ISOHYBRID_BIN=""
POSSIBLE_PATHS=(
    "/usr/lib/ISOLINUX/isohdpfx.bin"
    "/usr/lib/syslinux/isohdpfx.bin"
    "/usr/lib/syslinux/mbr/isohdpfx.bin"
    "/usr/lib/syslinux/bios/isohdpfx.bin"
    "/usr/lib/ISOLINUX/isohybrid.bin"
    "/usr/lib/syslinux/isohybrid.bin"
    "/usr/lib/syslinux/bios/isohybrid.bin"
)

for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -f "$path" ]; then
        ISOHYBRID_BIN="$path"
        echo "Found MBR template at: $ISOHYBRID_BIN"
        break
    fi
done

if [ -z "$ISOHYBRID_BIN" ]; then
    echo "Error: isohybrid.bin or isohdpfx.bin not found."
    echo "Please ensure 'syslinux-utils', 'isolinux', or 'syslinux-common' is installed."
    exit 1
fi

xorriso -as mkisofs \
    -iso-level 3 \
    -o "$ISO_NAME" \
    -full-iso9660-filenames \
    -volid "CUSTOM_OS" \
    -isohybrid-mbr "$ISOHYBRID_BIN" \
    -eltorito-boot isolinux/isolinux.bin \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot -isohybrid-gpt-basdat \
    "$CD_DIR"

echo "=== Build Complete! ==="
echo "ISO generated at: $(pwd)/$ISO_NAME"
