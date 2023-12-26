#!/bin/bash

_partition_Radxa5b() {
    wget https://github.com/endeavouros-arm/plasma-image/raw/main/configs/rk3588-uboot.img
    dd if=/dev/zero of=$DEVICENAME bs=1M count=18
    dd if=rk3588-uboot.img of=$DEVICENAME
#    dd if=$WORKDIR/configs/rk3588-uboot.img ibs=1 skip=0 count=15728640 of=$DEVICENAME
    parted --script -a minimal $DEVICENAME \
    mklabel gpt \
    mkpart primary 17MB 266MB \
    mkpart primary 266MB $DEVICESIZE"MiB" \
    quit
    rm rk3588-uboot.img
}

_partition_Pinebook() {
    dd if=/dev/zero of=$DEVICENAME bs=1M count=16
    parted --script -a minimal $DEVICENAME \
    mklabel gpt \
    unit mib \
    mkpart primary fat32 16MiB 216MiB \
    mkpart primary 216MiB $DEVICESIZE"MiB" \
    quit
}

_partition_OdroidN2() {
    parted --script -a minimal $DEVICENAME \
    mklabel msdos \
    unit Mib \
    mkpart primary fat32 2MiB 258MiB \
    mkpart primary 258MiB $DEVICESIZE"MiB" \
    quit
}

_partition_RPi4() {
    parted --script -a minimal $DEVICENAME \
    mklabel gpt \
    unit MiB \
    mkpart primary fat32 2MiB 202MiB \
    mkpart primary $FILESYSTEMTYPE 202MiB $DEVICESIZE"MiB" \
    quit
}

_create_btrfs_subvolumes() {
    printf "\n\n${CYAN}Creating btrfs Subvolumes${NC}\n"
    btrfs subvolume create $WORKDIR/MP2/@
    btrfs subvolume create $WORKDIR/MP2/@home
    btrfs subvolume create $WORKDIR/MP2/@log
    btrfs subvolume create $WORKDIR/MP2/@cache
    umount $WORKDIR/MP2
    o_btrfs=defaults,compress=zstd:4,noatime,commit=120
    mount -o $o_btrfs,subvol=@ $PARTNAME2 $WORKDIR/MP2
    mkdir -p $WORKDIR/MP2/{boot,home,var/log,var/cache}
    mount -o $o_btrfs,subvol=@home $PARTNAME2 $WORKDIR/MP2/home
    mount -o $o_btrfs,subvol=@log $PARTNAME2 $WORKDIR/MP2/var/log
    mount -o $o_btrfs,subvol=@cache $PARTNAME2 $WORKDIR/MP2/var/cache
}   # end of function _create_btrfs_subvolumes

_fstab_uuid() {

    local fstabuuid

    printf "\n${CYAN}Changing /etc/fstab to UUID numbers instead of a lable such as /dev/sda.${NC}\n"
    mv $WORKDIR/MP2/etc/fstab $WORKDIR/MP2/etc/fstab-bkup
    fstabuuid=$(lsblk -o UUID $PARTNAME1)
    fstabuuid=$(echo $fstabuuid | sed 's/ /=/g')
    printf "# /etc/fstab: static file system information.\n#\n# Use 'blkid' to print the universally unique identifier for a device; this may\n" > $WORKDIR/MP2/etc/fstab
    printf "# be used with UUID= as a more robust way to name devices that works even if\n# disks are added and removed. See fstab(5).\n" >> $WORKDIR/MP2/etc/fstab
    printf "#\n# <file system>             <mount point>  <type>  <options>  <dump>  <pass>\n\n"  >> $WORKDIR/MP2/etc/fstab
    printf "$fstabuuid  /boot  vfat  defaults  0  0\n\n" >> $WORKDIR/MP2/etc/fstab
    if [[ "$FILESYSTEMTYPE" == "btrfs" ]]; then
        genfstab -U $WORKDIR/MP2 >> $WORKDIR/MP2/etc/fstab
        sed -i '/# \/dev\/sd*/d' $WORKDIR/MP2/etc/fstab
        sed -i 's/subvolid=.*,//g' $WORKDIR/MP2/etc/fstab
        sed -i '/swap/d' $WORKDIR/MP2/etc/fstab   # Remove any swap carried over from the host device
        sed -i '/zram/d' $WORKDIR/MP2/etc/fstab   # Remove any zram carried over from the host device
    fi
}   # end of function _fstab_uuid

_install_Radxa5b_image() {

    local uuidno
    local old

    tag=$(curl https://github.com/endeavouros-arm/images/releases | grep rootfs-radxa-5b |  sed s'#^.*rootfs-radxa-5b#rootfs-radxa-5b#'g | cut -c 1-24 | head -n 1)
    printf "\n${CYAN}Downloading image enosLinuxARM-radxa-5b-latest.tar.zst tag = $tag${NC}\n\n"
    wget https://github.com/endeavouros-arm/images/releases/download/$tag/enosLinuxARM-radxa-5b-latest.tar.zst
    if [[ "$FILESYSTEMTYPE" == "btrfs" ]]; then
       _create_btrfs_subvolumes
    fi
    printf "\n${CYAN}Untarring the image...can take up to 5 minutes.${NC}\n"
    pv "enosLinuxARM-radxa-5b-latest.tar.zst" | zstd -T0 -cd -  | bsdtar -xf -  -C $WORKDIR/MP2
    # bsdtar --use-compress-program=unzstd -xpf enosLinuxARM-odroid-n2-latest.tar.zst -C $WORKDIR/MP2
    printf "\n${CYAN}syncing files...can take up to 5 minutes.${NC}\n"
    sync
    mv $WORKDIR/MP2/boot/* $WORKDIR/MP1
    _fstab_uuid
    # change extlinux.conf to UUID instead of partition label.
    uuidno=$(lsblk -o UUID $PARTNAME2)
    uuidno=$(echo $uuidno | sed 's/ /=/g')
    uuidno="root=$uuidno"   # uuidno should now be root=UUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX
    old=$(grep 'root=' $WORKDIR/MP1/extlinux/extlinux.conf | awk '{print $2}')

    if [[ "$FILESYSTEMTYPE" == "btrfs" ]]; then
        uuidno="$uuidno rootfstype=btrfs rootflags=subvol=@ fsck.repair=no/"
    fi
    sed -i "s#$old#$uuidno#" $WORKDIR/MP1/extlinux/extlinux.conf
}   # End of function _install_Radxa5b_image

_install_Pinebook_image() {
    local uuidno
    local old

    tag=$(curl https://github.com/endeavouros-arm/images/releases | grep rootfs-pbp |  sed s'#^.*rootfs-pbp#rootfs-pbp#'g | cut -c 1-19 | head -n 1)
    printf "\n${CYAN}Downloading image enosLinuxARM-pbp-latest.tar.zst tag = $tag${NC}\n\n"
    wget https://github.com/endeavouros-arm/images/releases/download/$tag/enosLinuxARM-pbp-latest.tar.zst
    if [[ "$FILESYSTEMTYPE" == "btrfs" ]]; then
        _create_btrfs_subvolumes
    fi
    printf "\n\n${CYAN}Untarring the image...can take up to 5 minutes.${NC}\n"
    pv "enosLinuxARM-pbp-latest.tar.zst" | zstd -T0 -cd -  | bsdtar -xf -  -C $WORKDIR/MP2
    printf "\n\n${CYAN}syncing files...can take up to 5 minutes.${NC}\n"
    sync
    mv $WORKDIR/MP2/boot/* $WORKDIR/MP1
    dd if=$WORKDIR/MP1/Tow-Boot.noenv.bin of=$DEVICENAME seek=64 conv=notrunc,fsync
    _fstab_uuid
    # make /boot/extlinux/extlinux.conf work with a UUID instead of a lable such as /dev/sda
    uuidno=$(lsblk -o UUID $PARTNAME2)
    uuidno=$(echo $uuidno | sed 's/ /=/g')
    uuidno="root=$uuidno"   # uuidno should now be root=UUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX
    old=$(grep 'root=' $WORKDIR/MP1/extlinux/extlinux.conf | awk '{print $5}')
    if [[ "$FILESYSTEMTYPE" == "btrfs" ]]; then
        uuidno="$uuidno rootflags=subvol=@ rootfstype=btrfs fsck.repair=no"
    fi
    sed -i "s#$old#$uuidno#" $WORKDIR/MP1/extlinux/extlinux.conf
}   # End of function _install_Pinebook_image

_install_OdroidN2_image() {
    local uuidno
    local old

    tag=$(curl https://github.com/endeavouros-arm/images/releases | grep rootfs-odroid-n2 |  sed s'#^.*rootfs-odroid-n2#rootfs-odroid-n2#'g | cut -c 1-25 | head -n 1)
    printf "\n${CYAN}Downloading image enosLinuxARM-odroid-n2-latest.tar.zst tag = $tag${NC}\n\n"
    wget https://github.com/endeavouros-arm/images/releases/download/$tag/enosLinuxARM-odroid-n2-latest.tar.zst
    if [[ "$FILESYSTEMTYPE" == "btrfs" ]]; then
        _create_btrfs_subvolumes
    fi
    printf "\n${CYAN}Untarring the image...can take up to 5 minutes.${NC}\n"
    pv "enosLinuxARM-odroid-n2-latest.tar.zst" | zstd -T0 -cd -  | bsdtar -xf -  -C $WORKDIR/MP2
    # bsdtar --use-compress-program=unzstd -xpf enosLinuxARM-odroid-n2-latest.tar.zst -C $WORKDIR/MP2
    printf "\n${CYAN}syncing files...can take up to 5 minutes.${NC}\n"
    sync
    mv $WORKDIR/MP2/boot/* $WORKDIR/MP1
    dd if=$WORKDIR/MP1/u-boot.bin of=$DEVICENAME conv=fsync,notrunc bs=512 seek=1
    _fstab_uuid
    # make /boot/boot.ini work with a UUID instead of a label such as /dev/sda
    uuidno=$(lsblk -o UUID $PARTNAME2)
    uuidno=$(echo $uuidno | sed 's/ /=/g')
    uuidno="root=$uuidno"   # uuidno should now be root=UUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX
    old=$(grep "root=" $WORKDIR/MP1/boot.ini | awk '{print $3}')

    if [[ "$FILESYSTEMTYPE" == "btrfs" ]]; then
        uuidno="\"$uuidno rootflags=subvol=@ rootfstype=btrfs fsck.repair=no"
    fi
    sed -i "s#$old#$uuidno#" $WORKDIR/MP1/boot.ini
}   # End of function _install_OdroidN2_image

_install_RPi4_image() {
    local uuidno
    local old

    if [[ "$FILESYSTEMTYPE" == "btrfs" ]]; then
        _create_btrfs_subvolumes
    fi

    case $PLATFORM in
       Rpi4)
          tag=$(curl https://github.com/endeavouros-arm/images/releases | grep rootfs-rpi4 |  sed s'#^.*rootfs-rpi4#rootfs-rpi4#'g | cut -c 1-20 | head -n 1)
           printf "\n${CYAN}Downloading image enosLinuxARM-rpi4-latest.tar.zst tag = $tag${NC}\n\n"
           wget https://github.com/endeavouros-arm/images/releases/download/$tag/enosLinuxARM-rpi4-latest.tar.zst
           printf "\n\n${CYAN}Untarring the image...can take up to 5 minutes.${NC}\n"
           pv "enosLinuxARM-rpi4-latest.tar.zst" | zstd -T0 -cd -  | bsdtar -xf -  -C $WORKDIR/MP2
           ;;
       Rpi5)
           tag=$(curl https://github.com/endeavouros-arm/images/releases | grep rootfs-rpi5 |  sed s'#^.*rootfs-rpi5#rootfs-rpi5#'g | cut -c 1-20 | head -n 1)
           printf "\n${CYAN}Downloading image enosLinuxARM-rpi5-latest.tar.zst tag = $tag${NC}\n\n"
           wget https://github.com/endeavouros-arm/images/releases/download/$tag/enosLinuxARM-rpi5-latest.tar.zst
           printf "\n\n${CYAN}Untarring the image...can take up to 5 minutes.${NC}\n"
           pv "enosLinuxARM-rpi5-latest.tar.zst" | zstd -T0 -cd -  | bsdtar -xf -  -C $WORKDIR/MP2
           ;;
    esac
    # bsdtar --use-compress-program=unzstd -xpf enosLinuxARM-rpi-aarch64-latest.tar.zst -C $WORKDIR/MP2
    printf "\n\n${CYAN}syncing files...can take up to 5 minutes.${NC}\n"
    sync
    mv $WORKDIR/MP2/boot/* $WORKDIR/MP1
    _fstab_uuid
    # configure cmdline.txt to use UUIDs instead of partition lables
    uuidno=$(lsblk -o UUID $PARTNAME2)
    uuidno=$(echo $uuidno | sed 's/ /=/g')
    uuidno="root=$uuidno"   # uuidno should now be root=UUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX
    printf "\nBreakPoint uuidno = $uuidno\n\n"
    read z
    old=$(cat $WORKDIR/MP1/cmdline.txt | grep root= | awk '{print $1}')
#    old=$(awk '{print $1}' $WORKDIR/MP1/cmdline.txt)
    case $FILESYSTEMTYPE in
        btrfs) sed -i "s/fsck.repair=yes/fsck.repair=no/" $WORKDIR/MP1/cmdline.txt
               uuidno="$uuidno rootfstype=btrfs rootflags=subvol=@"
               boot_options=" usbhid.mousepoll=8" ;;
         ext4) boot_options=" usbhid.mousepoll=8" ;;
    esac
    sed -i "s#$old#$uuidno#" $WORKDIR/MP1/cmdline.txt
    sed -i "s/$/$boot_options/" $WORKDIR/MP1/cmdline.txt
}  # End of function _install_RPi4_image

_partition_format_mount() {
   local finished
   local base_dialog_content
   local dialog_content
   local exit_status
   local count
   local i
   local u
   local x

   base_dialog_content="\nThe following storage devices were found\n\n$(lsblk -o NAME,MODEL,FSTYPE,SIZE,FSUSED,FSAVAIL,MOUNTPOINT)\n\n \
   Enter target device name without a partition designation (e.g. /dev/sda or /dev/mmcblk0):"
   dialog_content="$base_dialog_content"
   finished=1
   while [ $finished -ne 0 ]
   do
       DEVICENAME=$(whiptail --title "EndeavourOS ARM Setup - micro SD Configuration" --inputbox "$dialog_content" 27 115 3>&2 2>&1 1>&3)
      exit_status=$?
      if [ $exit_status == "1" ]; then           
         printf "\nScript aborted by user\n\n"
         exit
      fi
      if [[ ! -b "$DEVICENAME" ]]; then
         dialog_content="$base_dialog_content\n    Not a listed block device, or not prefaced by /dev/ Try again."
      else   
         case $DEVICENAME in
            /dev/sd*)     if [[ ${#DEVICENAME} -eq 8 ]]; then
                             finished=0
                          else
                             dialog_content="$base_dialog_content\n    Input improperly formatted. Try again."   
                          fi ;;
            /dev/mmcblk*) if [[ ${#DEVICENAME} -eq 12 ]]; then
                             finished=0
                          else
                             dialog_content="$base_dialog_content\n    Input improperly formatted. Try again."   
                          fi ;;
            /dev/nvme*) if [[ ${#DEVICENAME} -eq 12 ]]; then
                             finished=0
                          else
                             dialog_content="$base_dialog_content\n    Input improperly formatted. Try again."   
                          fi ;;
         esac
      fi      
   done
   ##### Determine data device size in MiB and partition ###
   printf "\n${CYAN}Partitioning, & formatting storage device...${NC}\n"
   DEVICESIZE=$(fdisk -l | grep "Disk $DEVICENAME" | head -n 1 | awk '{print $5}')
   ((DEVICESIZE=$DEVICESIZE/1048576))
   ((DEVICESIZE=$DEVICESIZE-1))  # for some reason, necessary for USB thumb drives
   printf "\n${CYAN}Partitioning storage device $DEVICENAME...${NC}\n"
   # umount partitions before partitioning and formatting
   lsblk $DEVICENAME -o MOUNTPOINT | grep /run/media > mounts
   count=$(wc -l mounts | awk '{print $1}')
   if [ $count -gt 0 ]
   then
      for ((i = 1 ; i <= $count ; i++))
      do
         u=$(awk -v "x=$i" 'NR==x' mounts)
         umount $u
      done
   fi
   rm mounts
   case $PLATFORM in
       Pinebook)     _partition_Pinebook ;;
       OdroidN2)     _partition_OdroidN2 ;;
       Rpi4 | Rpi5)  _partition_RPi4 ;;
       Radxa5b)      _partition_Radxa5b ;;
   esac
   printf "\n${CYAN}Formatting storage device $DEVICENAME...${NC}\n"
   printf "\n${CYAN}If \"/dev/sdx contains an existing file system Labelled XXXX\" or similar appears, Enter: y${NC}\n\n"

   if [[ ${DEVICENAME:5:6} = "mmcblk" ]] || [[ ${DEVICENAME:5:4} = "nvme" ]]
   then
      DEVICENAME=$DEVICENAME"p"
   fi
   PARTNAME1=$DEVICENAME"1"
   mkfs.fat -n BOOT_EOS $PARTNAME1
   PARTNAME2=$DEVICENAME"2"
   case $FILESYSTEMTYPE in
       ext4) mkfs.ext4 -F -L ROOT_EOS $PARTNAME2 ;;
       btrfs) mkfs.btrfs -f -L ROOT_EOS $PARTNAME2 ;;
   esac
   mkdir $WORKDIR/MP1 $WORKDIR/MP2
   mount $PARTNAME1 $WORKDIR/MP1
   mount $PARTNAME2 $WORKDIR/MP2

} # end of function _partition_format_mount

_check_if_root() {
    local whiptail_installed

    if [ $(id -u) -ne 0 ]
    then
       whiptail_installed=$(pacman -Qs libnewt)
       if [[ "$whiptail_installed" != "" ]]; then
          whiptail --title "Error - Cannot Continue" --msgbox "Please run this script as root" 8 47
          exit
       else
          printf "${RED}Error - Cannot Continue. Please run this script with as root.${NC}\n"
          exit
       fi
    fi
}

_check_all_apps_closed() {
    whiptail --title "CAUTION" --msgbox "Ensure ALL apps are closed, especially any file manager such as Thunar" 8 74 3>&2 2>&1 1>&3
}

_choose_device() {
    PLATFORM=$(whiptail --title " SBC Model Selection" --menu --notags "\n            Choose which SBC to install or Press right arrow twice to cancel" 17 100 6 \
         "0" "Raspberry Pi 4 model B 64 bit" \
         "1" "Raspberry Pi 5 model B 64 bit" \
         "2" "Odroid N2 or N2+" \
         "3" "Pinebook Pro" \
         "4" "Radxa ROCK 5B" \
    3>&2 2>&1 1>&3)

    case $PLATFORM in
        "") printf "\n\nScript aborted by user..${NC}\n\n"
            exit ;;
         0) PLATFORM="Rpi4" ;;
         1) PLATFORM="Rpi5" ;;
         2) PLATFORM="OdroidN2" ;;
         3) PLATFORM="Pinebook" ;;
         4) PLATFORM="Radxa5b" ;;
    esac
}

_choose_filesystem_type() {
        FILESYSTEMTYPE=$(whiptail --title "EndeavourOS ARM Setup - Filesystem type" --menu --notags "\n              Use the arrow keys to choose the filesystem type\n                         or Cancel to abort script\n\n" 15 80 5 \
           "ext4" "ext4" \
           "btrfs" "btrfs" \
        3>&2 2>&1 1>&3)

        case $FILESYSTEMTYPE in
            "") exit ;;
            ext4) FILESYSTEMTYPE="ext4" ;;
            btrfs) FILESYSTEMTYPE="btrfs" ;;
        esac
}

#################################################
# beginning of script
#################################################

Main() {
    # VARIABLES
    PLATFORM=" "     # e.g. OdroidN2, OdroidXU4, or RPi64
    DEVICENAME=" "   # storage device name e.g. /dev/sda
    DEVICESIZE="1"
    PARTNAME1=" "
    PARTNAME2=" "
    FILESYSTEMTYPE=""
    CONFIG_UPDATE="config-update-V2.7.sh"
    WORKDIR=$(pwd)

    # Declare color variables
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color

    pacman -S --noconfirm --needed libnewt arch-install-scripts pv wget parted &>/dev/null # packages needed for install
    _check_if_root
    _check_all_apps_closed
    _choose_device
    _choose_filesystem_type
    _partition_format_mount  # function to partition, format, and mount a uSD card or eMMC card
    case $PLATFORM in
       OdroidN2)    _install_OdroidN2_image ;;
       Rpi4 | Rpi5) _install_RPi4_image ;;
       Pinebook)    _install_Pinebook_image ;;
       Radxa5b)     _install_Radxa5b_image ;;
    esac

    printf "\n${CYAN}Almost done! Just a couple of minutes more for the last step.${NC}\n"

    if [[ "$FILESYSTEMTYPE" == "btrfs" ]]; then
       umount $WORKDIR/MP2/home $WORKDIR/MP2/var/log $WORKDIR/MP2/var/cache
    fi
    umount $WORKDIR/MP1 $WORKDIR/MP2
    rm -rf $WORKDIR/MP1 $WORKDIR/MP2
    rm enosLinuxARM*
    printf "\n${CYAN}End of script!${NC}\n"
    printf "\n${CYAN}Be sure to use a file manager to umount the device before removing the USB SD reader${NC}\n"

    printf "\n${CYAN}The default user is ${NC}alarm${CYAN} with the password ${NC}alarm\n"
    printf "${CYAN}The default root password is ${NC}root\n\n\n"
    read -n 1 -s -r -p "Press any key to continue"
    printf "\n"
    exit
}

Main "$@"
