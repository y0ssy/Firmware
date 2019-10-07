#! /usr/bin/env bash

## Bash script to setup PX4 development environment on Arch Linux.
## Tested on Manjaro 18.0.1.
##
## Installs:
## - Common dependencies and tools for nuttx, jMAVSim
## - NuttX toolchain (omit with arg: --no-nuttx)
## - jMAVSim simulator (omit with arg: --no-sim-tools)
##
## Not Installs:
## - Gazebo simulation
## - FastRTPS and FastCDR

INSTALL_NUTTX="true"
INSTALL_SIM="true"

# Parse arguments
for arg in "$@"
do
	if [[ $arg == "--no-nuttx" ]]; then
		INSTALL_NUTTX="false"
	fi

	if [[ $arg == "--no-sim-tools" ]]; then
		INSTALL_SIM="false"
	fi

done

# script directory
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# check requirements.txt exists (script not run in source tree)
REQUIREMENTS_FILE="requirements.txt"
if [[ ! -f "${DIR}/${REQUIREMENTS_FILE}" ]]; then
	echo "FAILED: ${REQUIREMENTS_FILE} needed in same directory as ubuntu.sh (${DIR})."
	return 1
fi

echo
echo "Installing PX4 general dependencies"

sudo pacman -Sy
sudo pacman -S \
	astyle \
	base-devel \
	ccache \
	clang \
	cmake \
	cppcheck \
	doxygen \
	gdb \
	ninja \
	rsync \
	shellcheck \
	;

# Python dependencies
echo "Installing PX4 Python3 dependencies"
sudo pip install --upgrade pip setuptools wheel
sudo pip install -r ${DIR}/requirements.txt


# NuttX toolchain (arm-none-eabi-gcc)
if [[ $INSTALL_NUTTX == "true" ]]; then
	echo
	echo "Installing NuttX dependencies"

	sudo pacman -S \
		gperf \
		vim \
		;

	# add user to dialout group (serial port access)
	sudo usermod -aG uucp $USER

	# Remove modem manager (interferes with PX4 serial port/USB serial usage).
	sudo pacman -R modemmanager

	# arm-none-eabi-gcc
	NUTTX_GCC_VERSION="7-2017-q4-major"
	GCC_VER_STR=$(arm-none-eabi-gcc --version)
	STATUSRETVAL=$(echo $GCC_VER_STR | grep -c "${NUTTX_GCC_VERSION}")

	if [ $STATUSRETVAL -eq "1" ]; then
		echo "arm-none-eabi-gcc-${NUTTX_GCC_VERSION} found, skipping installation"
	else
		echo "Installing arm-none-eabi-gcc-${NUTTX_GCC_VERSION}";
		wget -O /tmp/gcc-arm-none-eabi-${NUTTX_GCC_VERSION}-linux.tar.bz2 https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/7-2017q4/gcc-arm-none-eabi-${NUTTX_GCC_VERSION}-linux.tar.bz2 && \
			sudo tar -jxf /tmp/gcc-arm-none-eabi-${NUTTX_GCC_VERSION}-linux.tar.bz2 -C /opt/;

		# add arm-none-eabi-gcc to user's PATH
		exportline="export PATH=/opt/gcc-arm-none-eabi-${NUTTX_GCC_VERSION}/bin:\$PATH"

		if grep -Fxq "$exportline" $HOME/.profile;
		then
			echo "${NUTTX_GCC_VERSION} path already set.";
		else
			echo $exportline >> $HOME/.profile;
		fi
	fi
fi

# Simulation tools
if [[ $INSTALL_SIM == "true" ]]; then
	echo
	echo "Installing PX4 simulation dependencies"

	# java (jmavsim or fastrtps)
	sudo pacman -S \
		ant \
		jdk8-openjdk \
		;
fi

if [[ $INSTALL_NUTTX == "true" ]]; then
	echo
	echo "Reboot computer before attempting to build NuttX targets"
fi
