# vivado-lxc

Vivado/Vitis Design Suite installed into an lxc/lxd container for local developement on otherwise unsupported platforms. Currently configured for Vivado 2019.2 in an ubuntu 16.04 container.

## Prequisite
Requires a working LXD installation and needs be executed as a user capable of running `lxc` commands. 
Note: if you're running `lxd init` during setup, pay attention to the storage backend and use `dir` if you don't explicitely use btrfs, zfs,...)


## Instructions
Clone this repository.
Then download the [Vivado Design Suite Web installer and the separate hardware server](https://www.xilinx.com/support/download.html).
Finally run the provided `install_lxc_vivado.sh` script with 
```
% ./install_lxc_vivado.sh -c <CONTAINER_NAME> --shared-host <SHARED_HOST_DIRECTORY> --shared-container <SHARED_HOST_DIRECTORY> -l <URL_LICENCING_SERVER>
```

The script will ask for your Xilinx username and password to be passed to the webinstaller.


If you can't use the webinstaller and have downloaded the Vitis standalone .tar.gz file, you can install it by passing the `--standalone` flag and provide the path to the .tar.gz file using the `--vivado-installer` flag.
```
% ./install_lxc_vivado.sh --standalone --vivado-installer <PATH_TO_VIVADO_TAR_GZ> -c <CONTAINER_NAME> --shared-host <SHARED_HOST_DIRECTORY> --shared-container <SHARED_HOST_DIRECTORY> -l <URL_LICENCING_SERVER>
```

To get shell access to the container run:
```
% lxc exec <CONTAINER_NAME> -- sudo --user ubuntu --login
```

To start vivado run:
```
% source /opt/Xilinx/Vivado/20xx.y/settings64.sh
% vivado & 
```

To connect to a board run the [hardware server provided by Xilinx](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2019-2.html) as a separate download and connect to your host's IP address.


## Options
Further options are available

```
Options:
    -c NAME                     NAME of the container to be created. Default: vivado
    --shared-host      PATH     PATH on host to a shared work directory between container and host. Not mapped if omitted.
    --shared-container PATH     PATH to shared work directory between container and host. Default: /home/ubuntu/host
    -l URL                      Vivado Licence server URL to be exported as environment variable.
    -u USERNAME                 Xilinx USERNAME for authentication.
    -p PASSWORD                 Xilinx PASSWORD for authentication.
    --lxc-profile-file PATH     PATH to lxc profile file with default container configuration.
    --xsetup-config    PATH     PATH to the Vivado xsetup config file for batch installation.
    --vivado-installer PATH     PATH to the Xilinx Webinstaller or installer .tar.gz.
    --standalone                The supplied installer is a standalone installer, does not require authentication.
    --help                      Display this help message.
```

## Updating
To update this script to newer versions of Vivado/Vitis, or want to use for different editions of Vivado/Vitis it might be necessary to regenerate the *install_config.txt file. To do so either unpack the .tar.gz and run
``` 
% xsetup -b ConfigGen
``` 

or for the webinstaller run

```
% <WEBINSTALLER> -- -b ConfigGen
``` 

In any cases adjust the config file to only install devices and modules you require.

## Troubleshooting

### ERROR: Before being able to download and install you must generate an authentication token using the xsetup -b AuthTokenGen command.
If the script errors with this message while using the webinstaller, you were using the wrong username/password combination.