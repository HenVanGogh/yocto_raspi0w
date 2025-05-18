#!/bin/bash
# Setup script for Raspberry Pi Zero W Yocto Project
# This script clones the necessary meta layers with the exact versions used in development

set -e

echo "Setting up Raspberry Pi Zero W Yocto Project..."

# Define the base directory (the directory where this script is located)
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${BASE_DIR}"

# Clone meta-raspberrypi if it doesn't exist
if [ ! -d "meta-raspberrypi" ]; then
    echo "Cloning meta-raspberrypi layer..."
    git clone git://git.yoctoproject.org/meta-raspberrypi.git
    cd meta-raspberrypi
    # Checkout the specific commit used in development
    git checkout c489c75260fea5877b079a0045513ce3b2b7483c
    cd ..
    echo "meta-raspberrypi layer setup completed!"
else
    echo "meta-raspberrypi directory already exists, skipping clone..."
fi

# Clone oe-core (Poky) if it doesn't exist
if [ ! -d "oe-core" ]; then
    echo "Cloning oe-core (Poky) layer..."
    git clone git://git.yoctoproject.org/poky.git oe-core
    cd oe-core
    # Checkout the specific branch and commit used in development
    git checkout scarthgap
    git checkout 488cf4238a3c86a65ca54204f9e3b14aa6534c55
    cd ..
    echo "oe-core (Poky) layer setup completed!"
else
    echo "oe-core directory already exists, skipping clone..."
fi

echo "Applying necessary patches to meta layers..."
if [ -f "meta-raspberrypi/conf/machine/include/rpi-base.inc" ]; then
    echo "Patching rpi-base.inc to add essential kernel modules and udev rules..."
    # Backup original file
    cp meta-raspberrypi/conf/machine/include/rpi-base.inc meta-raspberrypi/conf/machine/include/rpi-base.inc.bak
    
    # Apply the patch using sed
    sed -i '/MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS += "${@oe.utils.conditional.*gpio-shutdown.*/a MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS += " kernel-modules udev-rules-rpi"' meta-raspberrypi/conf/machine/include/rpi-base.inc
    
    echo "Patch applied successfully!"
else
    echo "Warning: Could not find rpi-base.inc to patch. You may need to apply the change manually."
fi

echo "Creating build directory structure if needed..."
mkdir -p build/conf

# Check if the local.conf and bblayers.conf files already exist
if [ ! -f "build/conf/local.conf" ] && [ -f "build/conf/local.conf.sample" ]; then
    echo "Creating local.conf from sample..."
    cp build/conf/local.conf.sample build/conf/local.conf
fi

if [ ! -f "build/conf/bblayers.conf" ] && [ -f "build/conf/bblayers.conf.sample" ]; then
    echo "Creating bblayers.conf from sample..."
    cp build/conf/bblayers.conf.sample build/conf/bblayers.conf
fi

echo "==================================================================="
echo "Setup completed! To initialize the Yocto build environment, run:"
echo "source oe-core/oe-init-build-env build"
echo ""
echo "To build the image, run:"
echo "bitbake core-image-base"
echo "==================================================================="