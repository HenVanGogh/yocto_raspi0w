#!/bin/bash
# Safe SD Card Flashing Script for Raspberry Pi Zero W Images
# This script includes multiple safety checks to prevent accidental formatting of main drives

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Safety thresholds
MIN_SD_SIZE_GB=8    # Minimum expected SD card size (8GB)
MAX_SD_SIZE_GB=128  # Maximum expected SD card size (128GB)

echo -e "${BLUE}=== Raspberry Pi Zero W SD Card Flasher ===${NC}"
echo

# Function to show usage
show_usage() {
    echo "Usage: $0 [TARGET_DEVICE]"
    echo
    echo "TARGET_DEVICE (optional):"
    echo "  If not specified, script will auto-detect removable devices"
    echo "  Example: /dev/sda"
    echo
    echo "The script will interactively let you choose which image to flash."
    echo
    echo "Examples:"
    echo "  $0                    # Auto-detect SD card and choose image interactively"
    echo "  $0 /dev/sda           # Flash to specific device with image selection"
    echo
}

# Function to get available images and let user choose
choose_image() {
    local deploy_dir="build/tmp/deploy/images/raspberrypi0-wifi"
    
    echo -e "${BLUE}Available images:${NC}" >&2
    echo >&2
    
    # Find available images (get the symlinks which point to latest)
    local minimal_image=$(readlink -f $deploy_dir/core-image-minimal-raspberrypi0-wifi.rootfs.wic.bz2 2>/dev/null || true)
    local base_image=$(readlink -f $deploy_dir/core-image-base-raspberrypi0-wifi.rootfs.wic.bz2 2>/dev/null || true)
    local fullcmd_image=$(readlink -f $deploy_dir/core-image-full-cmdline-raspberrypi0-wifi.rootfs.wic.bz2 2>/dev/null || true)
    
    local options=()
    local descriptions=()
    local counter=1
    
    if [ -f "$fullcmd_image" ]; then
        options+=("$fullcmd_image")
        descriptions+=("Full cmdline image - With camera support, libcamera, OpenCV")
        echo "${counter}) core-image-full-cmdline" >&2
        echo "   $(basename "$fullcmd_image")" >&2
        echo "   Modified: $(stat -c '%y' "$fullcmd_image" | cut -d'.' -f1)" >&2
        echo "   - Full command-line system with camera support" >&2
        echo "   - Includes libcamera, OpenCV, Python" >&2
        echo >&2
        ((counter++))
    fi
    
    if [ -f "$minimal_image" ]; then
        options+=("$minimal_image")
        descriptions+=("Minimal image - Basic system with essential packages only")
        echo "${counter}) core-image-minimal" >&2
        echo "   $(basename "$minimal_image")" >&2
        echo "   Modified: $(stat -c '%y' "$minimal_image" | cut -d'.' -f1)" >&2
        echo "   - Basic system with essential packages only" >&2
        echo "   - Smaller size, faster boot" >&2
        echo >&2
        ((counter++))
    fi
    
    if [ -f "$base_image" ]; then
        options+=("$base_image")
        descriptions+=("Base image - Includes additional utilities and packages")
        echo "${counter}) core-image-base" >&2
        echo "   $(basename "$base_image")" >&2
        echo "   Modified: $(stat -c '%y' "$base_image" | cut -d'.' -f1)" >&2
        echo "   - Includes additional utilities and packages" >&2
        echo "   - More features, larger size" >&2
        echo >&2
        ((counter++))
    fi
    
    if [ ${#options[@]} -eq 0 ]; then
        echo -e "${RED}Error: No built images found!${NC}" >&2
        echo "Please build an image first with:" >&2
        echo "  bitbake core-image-minimal" >&2
        echo "  bitbake core-image-full-cmdline" >&2
        echo "  or" >&2
        echo "  bitbake core-image-base" >&2
        exit 1
    fi
    
    # Get user choice
    while true; do
        echo -n "Choose image to flash (1-${#options[@]}): " >&2
        read choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#options[@]} ]; then
            local selected_image="${options[$((choice-1))]}"
            local selected_desc="${descriptions[$((choice-1))]}"
            
            echo >&2
            echo -e "${GREEN}Selected: $(basename "$selected_image")${NC}" >&2
            echo "$selected_desc" >&2
            echo >&2
            
            # Only return the image path to stdout
            echo "$selected_image"
            return 0
        else
            echo -e "${RED}Invalid choice. Please enter a number between 1 and ${#options[@]}.${NC}" >&2
        fi
    done
}

# Function to check if device is safe to format
is_safe_device() {
    local device=$1
    
    # Check if device exists
    if [ ! -b "$device" ]; then
        echo -e "${RED}Error: Device $device does not exist${NC}"
        return 1
    fi
    
    # Get device info
    local size_bytes=$(lsblk -b -d -n -o SIZE "$device" 2>/dev/null)
    local size_gb=$((size_bytes / 1024 / 1024 / 1024))
    local is_removable=$(lsblk -d -n -o RM "$device" 2>/dev/null)
    local model=$(lsblk -d -n -o MODEL "$device" 2>/dev/null | xargs)
    
    echo -e "${BLUE}Device Info:${NC}"
    echo "  Device: $device"
    echo "  Size: ${size_gb}GB"
    echo "  Removable: $is_removable"
    echo "  Model: $model"
    echo
    
    # Safety checks
    if [ "$is_removable" != "1" ]; then
        echo -e "${RED}Warning: Device $device is not marked as removable!${NC}"
        echo "This could be your main hard drive. Please verify manually."
        return 1
    fi
    
    if [ "$size_gb" -lt "$MIN_SD_SIZE_GB" ] || [ "$size_gb" -gt "$MAX_SD_SIZE_GB" ]; then
        echo -e "${RED}Warning: Device size (${size_gb}GB) is outside expected SD card range (${MIN_SD_SIZE_GB}-${MAX_SD_SIZE_GB}GB)${NC}"
        return 1
    fi
    
    # Check if device is mounted
    if mount | grep -q "^$device"; then
        echo -e "${YELLOW}Warning: Device $device has mounted partitions${NC}"
        echo "Mounted partitions:"
        mount | grep "^$device" | sed 's/^/  /'
        echo
    fi
    
    return 0
}

# Function to auto-detect SD card
auto_detect_sd() {
    echo -e "${BLUE}Auto-detecting removable storage devices...${NC}" >&2
    echo >&2
    
    # List all removable block devices
    local devices=$(lsblk -d -n -o NAME,RM,SIZE,MODEL | grep "1" | awk '{print "/dev/"$1}')
    
    if [ -z "$devices" ]; then
        echo -e "${RED}No removable devices found!${NC}" >&2
        echo "Please insert your SD card and try again." >&2
        exit 1
    fi
    
    echo "Found removable devices:" >&2
    local suitable_device=""
    
    for dev in $devices; do
        local size=$(lsblk -d -n -o SIZE "$dev")
        local model=$(lsblk -d -n -o MODEL "$dev" | xargs)
        echo "  $dev - $size - $model" >&2
        
        # Check if this looks like an SD card (redirect output to stderr)
        if is_safe_device "$dev" >&2; then
            echo -e "${GREEN}This device looks like a suitable SD card.${NC}" >&2
            suitable_device="$dev"
            break
        fi
    done
    
    if [ -z "$suitable_device" ]; then
        echo -e "${RED}No suitable SD card found automatically.${NC}" >&2
        echo "Please specify the device manually or check your SD card." >&2
        exit 1
    fi
    
    # Only return the device path to stdout
    echo "$suitable_device"
}

# Function to confirm flashing
confirm_flash() {
    local device=$1
    local image_path=$2
    
    echo -e "${YELLOW}=== FINAL CONFIRMATION ===${NC}"
    echo -e "${RED}WARNING: This will COMPLETELY ERASE all data on $device${NC}"
    echo
    echo "Target device: $device"
    echo "Image file: $(basename $image_path)"
    echo
    echo -e "${YELLOW}This action CANNOT be undone!${NC}"
    echo
    read -p "Type 'YES' to confirm flashing: " confirmation
    
    if [ "$confirmation" != "YES" ]; then
        echo "Flashing cancelled."
        exit 0
    fi
}

# Function to flash image
flash_image() {
    local device=$1
    local image_path=$2
    
    echo -e "${BLUE}Starting flash process...${NC}"
    
    # Unmount any mounted partitions
    echo "Unmounting any mounted partitions..."
    for partition in $(mount | grep "^$device" | awk '{print $1}'); do
        echo "  Unmounting $partition"
        sudo umount "$partition" 2>/dev/null || true
    done
    
    # Flash the image
    echo -e "${BLUE}Flashing image to $device...${NC}"
    echo "This may take several minutes..."
    
    if command -v pv >/dev/null 2>&1; then
        # Use pv for progress bar if available
        bzcat "$image_path" | pv | sudo dd of="$device" bs=4M oflag=sync status=none
    else
        # Fallback to regular dd with progress
        bzcat "$image_path" | sudo dd of="$device" bs=4M oflag=sync status=progress
    fi
    
    # Sync to ensure all data is written
    echo "Syncing data to disk..."
    sudo sync
    
    echo -e "${GREEN}Flashing completed successfully!${NC}"
    echo
    echo "You can now safely remove the SD card and insert it into your Raspberry Pi Zero W."
}

# Main script logic
main() {
    # Change to script directory
    cd "$(dirname "$0")"
    
    # Parse arguments
    TARGET_DEVICE=$1
    
    # Check if we're running as root (needed for dd)
    if [ "$EUID" -eq 0 ]; then
        echo -e "${RED}Error: Do not run this script as root!${NC}"
        echo "The script will use sudo when needed for safety."
        exit 1
    fi
    
    # Check if sudo is available
    if ! command -v sudo >/dev/null 2>&1; then
        echo -e "${RED}Error: sudo is required but not found${NC}"
        exit 1
    fi
    
    # Choose image interactively
    IMAGE_PATH=$(choose_image)
    
    # Determine target device
    if [ -z "$TARGET_DEVICE" ]; then
        TARGET_DEVICE=$(auto_detect_sd)
    else
        if ! is_safe_device "$TARGET_DEVICE"; then
            echo -e "${RED}Error: Device $TARGET_DEVICE failed safety checks${NC}"
            exit 1
        fi
    fi
    
    # Show device info for verification
    echo -e "${BLUE}Target device verification:${NC}"
    is_safe_device "$TARGET_DEVICE"
    
    # Final confirmation
    confirm_flash "$TARGET_DEVICE" "$IMAGE_PATH"
    
    # Flash the image
    flash_image "$TARGET_DEVICE" "$IMAGE_PATH"
}

# Show help if requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
    exit 0
fi

# Run main function
main "$@"