# Custom Windows-Like Linux OS

This project contains the scripts to build a custom, bootable Linux operating system ISO. It is designed to be user-friendly with a Windows-like interface (using KDE Plasma) while providing the full power and stability of a Debian Linux base.

## Prerequisites

**CRITICAL:** You cannot run these scripts directly in Windows PowerShell or Command Prompt. You must use a Linux environment.

1.  **WSL2 (Windows Subsystem for Linux)**:
    *   Install Ubuntu from the Microsoft Store.
    *   Open the Ubuntu terminal.
    *   Navigate to this folder (e.g., `cd /mnt/c/Users/SATYA/OneDrive/Desktop/Custom\ Made\ Operating\ Sytsem`).
2.  **OR A Linux Virtual Machine**:
    *   Run Ubuntu or Debian in VirtualBox.
    *   Copy these files to the VM.

## Required Packages

Before running the build script, install the necessary dependencies in your Linux terminal:

```bash
sudo apt update
sudo apt install -y debootstrap squashfs-tools xorriso isolinux syslinux-utils mtools grub-pc-bin grub-efi-amd64-bin
```

## How to Build

1.  Open your Linux terminal (WSL or VM).
2.  Make the script executable:
    ```bash
    chmod +x build.sh
    ```
3.  Run the build script with root privileges:
    ```bash
    sudo ./build.sh
    ```
4.  Wait for the process to complete. It will download packages and build the ISO. This may take 30-60 minutes depending on your internet speed.
5.  The output file `custom-os.iso` will be created in this directory.

## How to Run

1.  Open **VirtualBox** on Windows.
2.  Create a New Machine (Type: Linux, Version: Debian 64-bit).
3.  In "Storage", attach the `custom-os.iso` file to the Optical Drive.
4.  Start the VM.

## Login Credentials

*   **Username**: `user`
*   **Password**: `password`
*   **Root Password**: (Not set, use `sudo`)

## Troubleshooting

### Stuck at `grub>` Prompt?

**DIAGNOSIS:**
You are 100% booting from the **Virtual Hard Disk**, which has a broken installation.
*   `ls` only shows `(hd0)` (Hard Disk). It does **not** show `(cd0)` (CD Drive).
*   The system on `(hd0)` is missing its kernel in `/boot`, so it will **never boot**.

**THE FIX: Force Boot from ISO**
Since changing the boot order didn't work, we will **remove the Hard Disk** temporarily to force the VM to use the ISO.

1.  **Power off** the VM.
2.  Go to **Settings** -> **Storage**.
3.  Look under "Controller: SATA" (or IDE).
4.  **Right-click** on the **Hard Disk** (the square icon, usually `AxiomOS.vdi`) and select **"Remove Attachment"**.
    *   *Don't worry, this doesn't delete the file, just unplug it.*
5.  Ensure the **Optical Drive** (circle icon) still has `axiomos.iso` selected.
6.  **Start the VM**.

**Result:**
*   The VM *must* boot from the ISO now because there is no Hard Disk!
*   You should see the **AxiomOS Boot Menu**.
*   Once you reach the desktop, you can power off, add the Hard Disk back, and run the installer.
