#!/bin/bash
# First Boot Auto-Update Script for AxiomOS

# Wait for network connection
echo "Waiting for internet connection..."
until ping -c 1 google.com &> /dev/null; do
    sleep 5
done

echo "Updating system..."
apt-get update
apt-get upgrade -y

echo "Update complete."

# Disable this service so it doesn't run again
systemctl disable first-boot-update.service
