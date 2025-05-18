# Raspberry Pi Zero W Yocto Project

This repository contains a basic WiFi Yocto setup for Raspberrypi zero w

## Project Structure

- **build/**: Contains build configuration and output files
- **meta-custom/**: Custom layer with recipes for WiFi configuration and system customization
- **meta-raspberrypi/**: BSP layer for Raspberry Pi boards
- **oe-core/**: OpenEmbedded Core layer

## Prerequisites

- Docker
- Git
- At least 50GB of free disk space

## Getting Started

### Setup and Build

1. Clone this repository:
```bash
git clone https://github.com/HenVanGogh/yocto_raspi0w.git yocto_raspi0w
cd yocto_raspi0w
```

2. Run the setup script to initialize the required meta layers:
```bash
./setup-yocto-env.sh
```
This script will:
- Clone the meta-raspberrypi and oe-core (Poky) layers with the correct versions
- Apply necessary patches to the meta-raspberrypi layer
- Create the build directory structure

3. Run the build environment in Docker (optional):
```bash
./start-docker-build.sh
```
Or manually:
```bash
YOCTO_WORKDIR=$(pwd) docker run --rm -it -v "${YOCTO_WORKDIR}":/workdir crops/poky:ubuntu-22.04 --workdir=/workdir
```

4. Initialize the build environment:
```bash
source oe-core/oe-init-build-env build
```

5. Start the build:
```bash
bitbake core-image-base
```

## WiFi Configuration

The project includes custom WiFi configuration in the meta-custom layer. 

**Note**: WiFi credentials are not included in this repository for security reasons. You'll need to set up your own WiFi credentials in:
```
meta-custom/recipes-connectivity/wifi-config/files/wpa_supplicant-wlan0.conf
```

A template file is provided at `meta-custom/recipes-connectivity/wifi-config/files/wpa_supplicant-wlan0.conf.example`

## Custom Features

- Optimized for Raspberry Pi Zero W
- WiFi connectivity pre-configured
- SSH server enabled

## License

This project is distributed under the MIT license.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
