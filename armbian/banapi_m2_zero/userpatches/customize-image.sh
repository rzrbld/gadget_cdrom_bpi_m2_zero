#!/bin/bash

# arguments: $RELEASE $LINUXFAMILY $BOARD $BUILD_DESKTOP
#
# This is the image customization script

# NOTE: It is copied to /tmp directory inside the image
# and executed there inside chroot environment
# so don't reference any files that are not already installed

# NOTE: If you want to transfer files between chroot and host
# userpatches/overlay directory on host is bind-mounted to /tmp/overlay in chroot
# The sd card's root path is accessible via $SDCARD variable.

RELEASE=$1
LINUXFAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4

Main() {
	case $RELEASE in
		jammy)
			# your code here
			InstallCDROMGadget
			;;
		buster)
			# your code here
			;;
		bullseye)
			# your code here
			;;
		bionic)
			# your code here
			;;
		focal)
			# your code here
			;;
	esac
} # Main

packageIsInstaled(){
        REQUIRED_PKG=$1
        echo "Check package $1 is installed"
        PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
        echo Checking for $REQUIRED_PKG: $PKG_OK
        if [ "" = "$PKG_OK" ]; then
                #echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
                # sudo apt-get --yes install $REQUIRED_PKG
                return 1
        else
                return 0
        fi
}


InstallCDROMGadget(){
	rm /root/.not_logged_in_yet
	export LANG=C LC_ALL="en_US.UTF-8"
	# install requred packcges
	apt update -y -q && apt install -y -q sed git vim p7zip-full armbian-config python3-smbus python3-numpy python3-pil fonts-dejavu ntfs-3g python3-dev python3-pip zip unzip dosfstools

	#make a file for wiringPi
	mkdir /var/lib/bananapi/ && touch /var/lib/bananapi/board.sh
	echo "BOARD=bpi-m2z" >> /var/lib/bananapi/board.sh
	echo "BOARD_AUTO=bpi-m2z" >> /var/lib/bananapi/board.sh

	#checkout repos
	if packageIsInstaled git; then
			mkdir -p /opt/BPI-WiringPi2 && git clone https://github.com/bontango/BPI-WiringPi2.git /opt/BPI-WiringPi2/
			mkdir -p /opt/RPi.GPIO && git clone https://github.com/GrazerComputerClub/RPi.GPIO.git /opt/RPi.GPIO
			mkdir -p /opt/gadget_cdrom && git clone https://github.com/tjmnmk/gadget_cdrom.git /opt/gadget_cdrom
	else
			echo "Doh!"
	fi

	#install pip deps
	pip3 install wheel && pip3 install spidev

	#build wiringPi for bananapi
	cd /opt/BPI-WiringPi2/ && ./build

	#build PRi.GPIO for bananapi
	cd /opt/RPi.GPIO/ && CFLAGS="-fcommon" python3 setup.py install

    #enable spi-spidev
    echo "overlays=spi-spidev" >> /boot/armbianEnv.txt
    echo "param_spidev_spi_bus=0" >> /boot/armbianEnv.txt

    #rm conflicted modules (usb apper but whitout storage)
    sed -i '/g_serial/d' /etc/modules
    sed -i '/g_ether/d' /etc/modules

    # add cdrom_gadget to systemd
    sudo ln -s /opt/gadget_cdrom/gadget_cdrom.service /etc/systemd/system/gadget_cdrom.service && \
    sudo systemctl enable gadget_cdrom.service

}

Main "$@"