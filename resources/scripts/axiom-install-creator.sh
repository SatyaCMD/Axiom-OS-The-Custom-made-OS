#!/bin/bash
# AxiomOS Creator Profile Installer

echo "Installing Creator Tools..."

# Graphics & Design
apt-get install -y gimp inkscape krita

# 3D Modeling
apt-get install -y blender

# Video Editing
apt-get install -y kdenlive obs-studio

# Audio
apt-get install -y audacity

echo "Creator Profile Installation Complete!"
