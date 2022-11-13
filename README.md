# gadget\_cdrom
Based on [tjmnmk](https://github.com/tjmnmk/) [gadget_cdrom](https://github.com/tjmnmk/gadget_cdrom)
## Requirements
* [Banana Pi M2 Zero](https://www.banana-pi.org/en/banana-pi-sbcs/1.html)
* [Waveshare 1.3inch OLED HAT](https://www.waveshare.com/wiki/1.3inch_OLED_HAT)
* Tested on [Armbian](https://www.armbian.com/) jammy current (5.15.77)

## Description
* gadget\_cdrom converts your Banana Pi M2 Zero to virtual usb cdrom.
* [Original tjmnmk Youtube video](https://www.youtube.com/watch?v=DntezzK9Eqc)

# Usage
You can switch between HDD mode, virtual cdrom mode, and virtual flash drive mode.

| Mode     |      Description      |  Button |
|----------|:---------------------:|------:|
| `CD Mode`  |  the BPI will pretend to be a cdrom and presenting the `.iso` you selected | `Key3` |
| `USB Mode` |  the BPI will pretend to be a flash drive, presenting the usb `.img` you selected.   |   `Key3` |
| `HDD Mode` | in that mode your Banana Pi M2 Zero is basically USB flash drive connected to your computer. You can store any files and upload `.iso` and `.img` files to use in `CD` and `USB` Modes |    `Key3` |
| `Shutdown` | Halt/Shutdown PBI |  `Joystick Left` |
| `Init`     | State that you'll see during internal storage initialization process after first boot | `-` |


## Keys
* `Key1` - Activate selected image
* `Key2` - Deactivate image
* `Key3` - Change mode
* `Joystick Down` - next image (only in CD/USB modes)
* `Joystick Up` - previous image (only in CD/USB modes)
* `Joystick Left` - shutdown

## Performance
In HDD Mode with `MicroSDXC Kingston CANVAS Select Plus 1st class V10 A1 64GB` as main storage, my file transfer speed is around 7-8MB/s for read and write.

# BPI Images options
## Ready to use [Armbian](https://www.armbian.com/) + gadget_cdrom image
There are customized Armbian images with gadget_cdrom and kernel patch for big isos in the [releases section](https://github.com/rzrbld/gadget_cdrom_bpi_m2_zero/releases), just write it to sd-card (you can use rpi-imager, dd, etc.), turn BPI on and wait a few minutes (5-7) to get everything ready. Latest prebuild images uses [exFAT](https://en.wikipedia.org/wiki/ExFAT) as defaut HDD Mode partition `iso.img`.

## Build your own Armbian image
- chekout current `armbian-build` repo `git clone https://github.com/armbian/build.git` 

- chekout current `gadget_cdrom_bpi_m2_zero` repo `git clone -b banana_pi_m2_zero https://github.com/rzrbld/gadget_cdrom_bpi_m2_zero.git` 

- copy `userpatches` form `gadget_cdrom_bpi_m2_zero` directory to armbian  `build` folder `cp -r /git/gadget_cdrom_bpi_m2_zero/armbian/banapi_m2_zero/userpatches/* /git/build/userpatches/`

- compile image `cd /git/build/ && ./compile.sh BOARD=bananapim2zero BRANCH=current RELEASE=jammy BUILD_MINIMAL=yes BUILD_DESKTOP=no KERNEL_ONLY=no KERNEL_CONFIGURE=no COMPRESS_OUTPUTIMAGE=sha,gpg,gz` in case of error with debian repos - add this parameters `DEBIAN_MIRROR='%my_favorite_mirror%' NO_APT_CACHER=yes` [list of Debian mirrors](https://www.debian.org/mirror/list) i.e. `cd /git/build/ && ./compile.sh BOARD=bananapim2zero BRANCH=current RELEASE=jammy BUILD_MINIMAL=yes BUILD_DESKTOP=no KERNEL_ONLY=no KERNEL_CONFIGURE=no COMPRESS_OUTPUTIMAGE=sha,gpg,gz DEBIAN_MIRROR='ftp.ru.debian.org/debian/' NO_APT_CACHER=yes`


### Userpatches
```bash
 banapi_m2_zero
    └── userpatches
        ├── customize-image.sh #pre install gadget cdrom
        ├── kernel #patch for support isos bigger than ~2.5GB (Optional)
        ├── linux-sunxi-current.config #default linux kernel config (ensure that SPIDEV & Mass Storage is set to <m>/<y>)
        └── README.md #compile parameters
```

# Manual Installation
### Install dependencies
```bash
apt update -y -q && \
apt install -y -q sed \
                  git \
                  vim p7zip-full \
                  armbian-config \
                  python3-smbus \
                  python3-numpy \
                  python3-pil \
                  fonts-dejavu \
                  ntfs-3g \
                  exfat-fuse \
                  exfatprogs \
                  python3-dev \
                  python3-pip \
                  zip \
                  unzip \
                  dosfstools 
```

### Create a file for wiringPi 
```bash
#make a file for wiringPi
mkdir /var/lib/bananapi/ && touch /var/lib/bananapi/board.sh
echo "BOARD=bpi-m2z" >> /var/lib/bananapi/board.sh
echo "BOARD_AUTO=bpi-m2z" >> /var/lib/bananapi/board.sh
```

### Checkout patched WiringPi2, RPi.GPIO repos and gadget_cdrom (Banana-pi edition) 
```bash
mkdir -p /opt/BPI-WiringPi2 && git clone https://github.com/bontango/BPI-WiringPi2.git /opt/BPI-WiringPi2/
mkdir -p /opt/RPi.GPIO && git clone https://github.com/GrazerComputerClub/RPi.GPIO.git /opt/RPi.GPIO
mkdir -p /opt/gadget_cdrom && git clone --branch banana_pi_m2_zero https://github.com/rzrbld/gadget_cdrom_bpi_m2_zero.git /opt/gadget_cdrom
```

### Install Python dependencies
```bash
#install pip deps
pip3 install wheel && pip3 install spidev
```

### Build patched [WiringPi](https://github.com/bontango/BPI-WiringPi2) for BPI
```bash
cd /opt/BPI-WiringPi2/ && ./build
```

### Build [PRi.GPIO](https://github.com/GrazerComputerClub/RPi.GPIO) for BPI
```bash	
cd /opt/RPi.GPIO/ && CFLAGS="-fcommon" python3 setup.py install
```

### Enable spi-spidev
```bash
echo "overlays=spi-spidev" >> /boot/armbianEnv.txt
echo "param_spidev_spi_bus=0" >> /boot/armbianEnv.txt
```

### Remove conflicted modules 
```bash
sed -i '/g_serial/d' /etc/modules
sed -i '/g_ether/d' /etc/modules
```

### Prepare storage
```bash
# sudo ./create_image.sh
Space available: 24G
Size, e.g. 16G? 8G"
Creating 8G image...
Done!
```

### Reboot
```bash
reboot
```

### Check is everything is ok
```bash
gpio readall #shows pinout table 
ls -al /dev/spi* #shows spi device
```

### Add cdrom_gadget to systemd and start
```bash
ln -s /opt/gadget_cdrom/gadget_cdrom.service /etc/systemd/system/gadget_cdrom.service && \
systemctl enable gadget_cdrom.service
systemctl start gadget_cdrom.service
```    


### Optional
**Recompile kernel for support isos bigger than ~2.5GB**
* Apply this [patch](../master/tools/kernel/00-remove_iso_limit.patch)
* Build kernel: [Armbian Linux Build Framework](https://github.com/armbian/build)
