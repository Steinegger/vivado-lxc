#!/bin/bash

# create ubuntu 18.04 lxc container and install vitis/vivado

# Path to the Vivado xsetup config file for batch installation
VIVADO_INSTALLER_CONFIG=./Xilinx_Vitis_2019_2_install_config.txt
# Path to the Xilinx Webinstaller
VIVADO_INSTALLER_FILE=~/Downloads/Xilinx_Unified_2019.2_1106_2127_Lin64.bin
# Specifies if the supplied installer i
VIVADO_IS_WEB_INSTALLER="1"
# URL of the Vivado Licence server to be exported as XILINXD_LICENSE_FILE
VIVADO_LICENCE_SERVER=""
# path to the base lxc vivado config file
VIVADO_LXC_CONFIG_FILE=./vivado_lxc_profile.txt
# Name of the created Container
LXC_CONTAINER_NAME="vivado"
# LXC base image used for the container
LXC_CONTAINER_IMAGE="ubuntu:18.04"
# Non-root LXC user in container
LXC_USER="ubuntu"
# Home directory of user in the container
LXC_CONTAINER_HOME=/home/ubuntu
# Directory in the container to copy the installer to
LXC_CONTAINER_XILINX=${LXC_CONTAINER_HOME:?}/Xilinx
# Path of a shared workdirectory on the hostmachine
LXC_SHARED_WORKDIRECTORY_HOST=""
# Respective path of the shared workdirectory in the container
LXC_SHARED_WORKDIRECTORY_CONTAINER="/home/ubuntu/host"
# Username and password of the xilinx account to download and installe the software
XILINX_USERNAME=""
XILINX_PASSWORD=""


### Argument processing
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -u)
    XILINX_USERNAME="$2"
    shift; shift # past argument and value
    ;;
    -p)
    XILINX_PASSWORD="$2"
    shift; shift # past argument and value
    ;;
    -c)
    LXC_CONTAINER_NAME="$2"
    shift; shift # past argument and value
    ;;
    --shared-host)
    LXC_SHARED_WORKDIRECTORY_HOST="$2"
    shift; shift # past argument and value
    ;;
    --shared-container)
    LXC_SHARED_WORKDIRECTORY_CONTAINER="$2"
    shift; shift # past argument and value
    ;;
    -l)
    VIVADO_LICENCE_SERVER="$2"
    shift; shift # past argument and value
    ;;
    --lxc-profile-file)
    VIVADO_LXC_CONFIG_FILE="$2"
    shift; shift # past argument and value
    ;;
    --vivado-config)
    VIVADO_INSTALLER_CONFIG="$2"
    shift; shift # past argument and value
    ;;
    --vivado-installer)
    VIVADO_INSTALLER_FILE="$2"
    shift; shift # past argument and value
    ;;
    --standalone)
    VIVADO_IS_WEB_INSTALLER="0"
    shift # past argument and value
    ;;
    --help)
    echo "Script to install Vivado in and LXC container. "
    echo ""
    echo "Options:"
    echo "    -c NAME                     NAME of the container to be created. Default: ${LXC_CONTAINER_NAME:?}"
    echo "    --shared-host      PATH     PATH on host to a shared work directory between container and host. Not mapped if omitted."
    echo "    --shared-container PATH     PATH to shared work directory between container and host. Default: ${LXC_SHARED_WORKDIRECTORY_CONTAINER:?}"
    echo "    -l URL                      Vivado Licence server URL to be exported as environment variable."
    echo "    -u USERNAME                 Xilinx USERNAME for authentication."
    echo "    -p PASSWORD                 Xilinx PASSWORD for authentication."
    echo "    --lxc-profile-file PATH     PATH to lxc profile file with default container configuration."
    echo "    --xsetup-config    PATH     PATH to the Vivado xsetup config file for batch installation."
    echo "    --vivado-installer PATH     PATH to the Xilinx Webinstaller or installer .tar.gz."
    echo "    --standalone                The supplied installer is a standalone installer, does not require authentication."
    echo "    --help                      Display this help message."
    exit 0
    ;;
    *)    # unknown option
    echo "Unknown Argument $2. Exiting."
    exit 1
    ;;
esac
done


if  [ ${VIVADO_IS_WEB_INSTALLER:?} = "1" ]; then
    # ask for Xilinx username if none passed
    if [ -z "${XILINX_USERNAME}" ]
    then
        read -p 'Xilinx Username: ' XILINX_USERNAME
    fi;
    # ask for Xilinx password if none passed
    if [ -z "${XILINX_PASSWORD}" ]
    then
        read -sp 'Xilinx Password: ' XILINX_PASSWORD
        echo ""
    fi;
fi;

# Create container
lxc launch ${LXC_CONTAINER_IMAGE:?} ${LXC_CONTAINER_NAME:?} < ${VIVADO_LXC_CONFIG_FILE:?}
if [[ $? != 0 ]]; then
    echo "Container couldn't be created."
    exit 1
fi

# wait for container to be initialized (use either method)
lxc exec ${LXC_CONTAINER_NAME:?} -- cloud-init status -w
#lxc exec ${LXC_CONTAINER_NAME:?} -- bash -c 'while [ "$(systemctl is-system-running 2>/dev/null)" != "running" ] && [ "$(systemctl is-system-running 2>/dev/null)" != "degraded" ]; do :; done'

# Add lxc shared directories
echo "Mapping ${HOME:?}/Downloads to  /home/ubuntu/Downloads"
lxc config device add ${LXC_CONTAINER_NAME:?} downloads disk source=${HOME:?}/Downloads path=/home/ubuntu/Downloads
if [ ! -z "${LXC_SHARED_WORKDIRECTORY_HOST:?}" ]; then
    echo "Mapping ${LXC_SHARED_WORKDIRECTORY_HOST:?} to ${LXC_SHARED_WORKDIRECTORY_CONTAINER:?}"
    lxc config device add ${LXC_CONTAINER_NAME:?} work disk source=${LXC_SHARED_WORKDIRECTORY_HOST:?} path=${LXC_SHARED_WORKDIRECTORY_CONTAINER:?}
fi;

lxc exec ${LXC_CONTAINER_NAME:?} -- su -c "mkdir ${LXC_CONTAINER_HOME:?}/Xilinx" ${LXC_USER:?}
lxc file push ${VIVADO_INSTALLER_FILE:?} ${LXC_CONTAINER_NAME:?}/${LXC_CONTAINER_XILINX:?}/ --uid 1000 --gid 1000 --mode 770
lxc file push ${VIVADO_INSTALLER_CONFIG:?} ${LXC_CONTAINER_NAME:?}/${LXC_CONTAINER_XILINX:?}/  --uid 1000 --gid 1000 --mode 770

# Set licenceserver environment
if [ ! -z "${VIVADO_LICENCE_SERVER:?}" ]; then
    echo "Adding Xilinx licencing server ${VIVADO_LICENCE_SERVER:?} to environment"
    lxc exec ${LXC_CONTAINER_NAME:?} --cwd ${LXC_CONTAINER_HOME:?} -- su -c "echo \"export XILINXD_LICENSE_FILE=${VIVADO_LICENCE_SERVER:?}\" >> .zshrc" ${LXC_USER:?}
fi


if  [ ${VIVADO_IS_WEB_INSTALLER:?} = "1" ]; then
    # Only working for Ubuntu 16.04 and 18.04 in container, due to missing package `empty-expect`
    # for details on why this is necessary see https://forums.xilinx.com/t5/Installation-and-Licensing/Webbased-Command-Line-Installer-Generating-Token-with-Script/td-p/984186 
    #
    # add `-L ./empty.log` to enable logging of output
    #
    # Alternatively you might spawn a shell in the container and run the installer with
    # Xilinx_Unified_2019.2_1106_2127_Lin64.bin -- -b AuthTokenGen
    # Xilinx_Unified_2019.2_1106_2127_Lin64.bin -- --agree 3rdPartyEULA,WebTalkTerms,XilinxEULA --batch Install --config /PATH/TO/VIVADO_LXC_CONFIG_FILE
    # 
    echo "Generating auth token, this might take a moment"
    lxc exec ${LXC_CONTAINER_NAME:?} --cwd ${LXC_CONTAINER_HOME:?} -- su -c "empty -f -i ./in.fifo -o ./out.fifo -p ./empty.pid ${LXC_CONTAINER_XILINX:?}/$(basename ${VIVADO_INSTALLER_FILE:?}) -- -b AuthTokenGen ; \
                                                                            empty -w -t 600 -i out.fifo -o in.fifo \"User ID\" ${XILINX_USERNAME:?} ; \
                                                                            echo \"${XILINX_PASSWORD:?}\" | empty -s -t 600 -i out.fifo -o in.fifo " ${LXC_USER:?}

    lxc exec ${LXC_CONTAINER_NAME:?} --cwd ${LXC_CONTAINER_HOME:?} -- su -c "${LXC_CONTAINER_XILINX:?}/$(basename ${VIVADO_INSTALLER_FILE:?}) -- --agree 3rdPartyEULA,WebTalkTerms,XilinxEULA --batch Install --config ${LXC_CONTAINER_XILINX:?}/$(basename ${VIVADO_INSTALLER_CONFIG:?})" ${LXC_USER:?}
else
    # Unpackign the standalone installer
    lxc exec ${LXC_CONTAINER_NAME:?} --cwd ${LXC_CONTAINER_XILINX:?} -- su -c "tar xzf ${LXC_CONTAINER_XILINX:?}/$(basename ${VIVADO_INSTALLER_FILE:?})"  ${LXC_USER:?}
    lxc exec ${LXC_CONTAINER_NAME:?} --cwd ${LXC_CONTAINER_HOME:?} -- su -c "${LXC_CONTAINER_XILINX:?}/$(basename --suffix=.tar.gz ${VIVADO_INSTALLER_FILE:?})/xsetup --agree 3rdPartyEULA,WebTalkTerms,XilinxEULA --batch Install --config ${LXC_CONTAINER_XILINX:?}/$(basename ${VIVADO_INSTALLER_CONFIG:?})"  ${LXC_USER:?}
fi;

# Cleanup, delete the Xilinx folder with the installer
lxc exec ${LXC_CONTAINER_NAME:?} --cwd ${LXC_CONTAINER_HOME:?} -- su -c "rm -rf ${LXC_CONTAINER_XILINX:?}"
