#!/bin/bash
# AxiomOS Developer Profile Installer

echo "Installing Developer Tools..."

# 1. VS Code
echo "Installing VS Code..."
apt-get install -y wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg
apt-get update
apt-get install -y code

# 2. Docker
echo "Installing Docker..."
apt-get install -y docker.io docker-compose
usermod -aG docker $USER

# 3. Node.js (LTS)
echo "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs

# 4. Python Tools
echo "Installing Python Tools..."
apt-get install -y python3-pip python3-venv

echo "Developer Profile Installation Complete!"
