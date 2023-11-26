#!/bin/bash

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

_install_Pinebook_image() {
    local uuidno
    local old
    local new
    local user_confirm

    tag=$(curl https://github.com/endeavouros-arm/images/releases | grep rootfs-pbp |  sed s'#^.*rootfs-pbp#rootfs-pbp#'g | cut -c 1-19 | head -n 1)
    printf "\n${CYAN}Downloading image enosLinuxARM-pbp-latest.tar.zst tag = $tag${NC}\n\n"
    wget https://github.com/endeavouros-arm/images/releases/download/$tag/enosLinuxARM-pbp-latest.tar.zst

    if [[ "$FILESYSTEMTYPE" == "btrfs" ]]; then
        printf "\n\n${CYAN}Creating btrfs Subvolumes${NC}\n"
        btrfs subvolume create MP2/@
        btrfs subvolume create MP2/@home
        btrfs subvolume create MP2/@log
        btrfs subvolume create MP2/@cache
        umount MP2
        o_btrfs=defaults,compress=zstd:4,noatime,commit=120
        mount -o $o_btrfs,subvol=@ $PARTNAME2 MP2
        mkdir -p MP2/{boot,home,var/log,var/cache}
        mount -o $o_btrfs,subvol=@home $PARTNAME2 MP2/home
        mount -o $o_btrfs,subvol=@log $PARTNAME2 MP2/var/log
        mount -o $o_btrfs,subvol=@cache $PARTNAME2 MP2/var/cache
    fi

    printf "\n\n${CYAN}Untarring the image...takes 4 to 5 minutes.${NC}\n"
    pv "enosLinuxARM-pbp-latest.tar.zst" | zstd -T0 -cd -  | bsdtar -xf -  -C MP2
    # bsdtar --use-compress-program=unzstd -xpf enosLinuxARM-pbp-latest.tar.zst -C MP2
    printf "\n\n${CYAN}syncing files...takes 4 to 5 minutes.${NC}\n"
    sync
    mv MP2/boot/* MP1
    dd if=MP1/Tow-Boot.noenv.bin of=$DEVICENAME seek=64 conv=notrunc,fsync

    # make /etc/fstab work with a UUID instead of a label such as /dev/sda
    printf "\n${CYAN}In /etc/fstab and /boot/cmdline.txt changing Disk labels to UUID numbers.${NC}\n"
    mv MP2/etc/fstab MP2/etc/fstab-bkup
    uuidno=$(lsblk -o UUID $PARTNAME1)
    uuidno=$(echo $uuidno | sed 's/ /=/g')
    printf "# /etc/fstab: static file system information.\n#\n# Use 'blkid' to print the universally unique identifier for a device; this may\n" >> MP2/etc/fstab
    printf "# be used with UUID= as a more robust way to name devices that works even if\n# disks are added and removed. See fstab(5).\n" >> MP2/etc/fstab
    printf "#\n# <file system>             <mount point>  <type>  <options>  <dump>  <pass>\n\n"  >> MP2/etc/fstab
    printf "$uuidno  /boot  vfat  defaults  0  0\n" >> MP2/etc/fstab
    if [[ "$FILESYSTEMTYPE" == "btrfs" ]]; then
        genfstab -U MP2 >> MP2/etc/fstab
        sed -i 's/subvolid=.*,//g' MP2/etc/fstab
        sed -i /swap/d MP2/etc/fstab   # Remove any swap carried over from the host device
        sed -i /zram/d MP2/etc/fstab   # Remove any zram carried over from the host device
    fi
    # make /boot/extlinux/extlinux.conf work with a UUID instead of a lable such as /dev/sda
    uuidno=$(lsblk -o UUID $PARTNAME2)
    uuidno=$(echo $uuidno | sed 's/ /=/g')
    old=$(grep -o 'root=.* ' MP1/extlinux/extlinux.conf)
    case $FILESYSTEMTYPE in
        btrfs) new="root=$uuidno rootflags=subvol=@ rootfstype=btrfs fsck.repair=no rw rootwait" ;;
         ext4) new="root=$uuidno rw rootwait" ;;
    esac
    sed -i "s#$old#$new #" MP1/extlinux/extlinux.conf
}   # End of function _install_Pinebook_image

_install_OdroidN2_image() {
    local uuidno
    local old
    local new
    local user_confirm

    tag=$(curl https://github.com/endeavouros-arm/images/releases | grep rootfs-odroid-n2 |  sed s'#^.*rootfs-odroid-n2#rootfs-odroid-n2#'g | cut -c 1-25 | head -n 1)
    printf "\n${CYAN}Downloading image enosLinuxARM-odroid-n2-latest.tar.zst tag = $tag${NC}\n\n"
    wget https://github.com/endeavouros-arm/images/releases/download/$tag/enosLinuxARM-odroid-n2-latest.tar.zst

    if [[ "$FILESYSTEMTYPE" == "btrfs" ]]; then
        printf "\n\n${CYAN}Creating btrfs Subvolumes${NC}\n"
        btrfs subvolume create MP2/@
        btrfs subvolume create MP2/@home
        btrfs subvolume create MP2/@log
        btrfs subvolume create MP2/@cache
        umount MP2
        o_btrfs=defaults,compress=zstd:4,noatime,commit=120
        mount -o $o_btrfs,subvol=@ $PARTNAME2 MP2
        mkdir -p MP2/{boot,home,var/log,var/cache}
        mount -o $o_btrfs,subvol=@home $PARTNAME2 MP2/home
        mount -o $o_btrfs,subvol=@log $PARTNAME2 MP2/var/log
        mount -o $o_btrfs,subvol=@cache $PARTNAME2 MP2/var/cache
    fi

    printf "\n${CYAN}Untarring the image...takes 4 to 5 minutes.${NC}\n"
    pv "enosLinuxARM-odroid-n2-latest.tar.zst" | zstd -T0 -cd -  | bsdtar -xf -  -C MP2
    # bsdtar --use-compress-program=unzstd -xpf enosLinuxARM-odroid-n2-latest.tar.zst -C MP2
    printf "\n${CYAN}syncing files...takes 4 to 5 minutes.${NC}\n"
    sync
    mv MP2/boot/* MP1
    dd if=MP1/u-boot.bin of=$DEVICENAME conv=fsync,notrunc bs=512 seek=1

    # make /etc/fstab work with a UUID instead of a label such as /dev/sda
    printf "\n${CYAN}In /etc/fstab and /boot/cmdline.txt changing Disk labels to UUID numbers.${NC}\n"
    mv MP2/etc/fstab MP2/etc/fstab-bkup
    uuidno=$(lsblk -o UUID $PARTNAME1)
    uuidno=$(echo $uuidno | sed 's/ /=/g')
    printf "# /etc/fstab: static file system information.\n#\n# Use 'blkid' to print the universally unique identifier for a device; this may\n" >> MP2/etc/fstab
    printf "# be used with UUID= as a more robust way to name devices that works even if\n# disks are added and removed. See fstab(5).\n" >> MP2/etc/fstab
    printf "#\n# <file system>             <mount point>  <type>  <options>  <dump>  <pass>\n\n"  >> MP2/etc/fstab
    printf "$uuidno  /boot  vfat  defaults  0  0\n\n" >> MP2/etc/fstab
    if [[ "$FILESYSTEMTYPE" == "btrfs" ]]; then
        genfstab -U MP2 >> MP2/etc/fstab
        sed -i '/# \/dev\/sd*/d' MP2/etc/fstab
        sed -i 's/subvolid=.*,//g' MP2/etc/fstab
        sed -i '/swap/d' MP2/etc/fstab   # Remove any swap carried over from the host device
        sed -i '/zram/d' MP2/etc/fstab   # Remove any zram carried over from the host device
    fi
    # make /boot/boot.ini work with a UUID instead of a label such as /dev/sda
    uuidno=$(lsblk -o UUID $PARTNAME2)
    uuidno=$(echo $uuidno | sed 's/ /=/g')
    old=$(grep "setenv bootargs \"root=" MP1/boot.ini)

    if [[ "$FILESYSTEMTYPE" == "btrfs" ]]; then
        boot_options="rootflags=subvol=@ rootfstype=btrfs fsck.repair=no"
        new="setenv bootargs \"root=$uuidno $boot_options rootwait rw\""
        sed -i "s#fsck.repair=yes ##" MP1/boot.ini
    else
        new="setenv bootargs \"root=$uuidno rootwait rw\""
    fi
    sed -i "s#$old#$new#" MP1/boot.ini
}   # End of function _install_OdroidN2_image

_install_RPi4_image() {
    local uuidno
    local old
    local new
    local url
    local totalurl
    local exit_status

    tag=$(curl https://github.com/endeavouros-arm/images/releases | grep rootfs-rpi |  sed s'#^.*rootfs-rpi#rootfs-rpi#'g | cut -c 1-19 | head -n 1)
    printf "\n${CYAN}Downloading image enosLinuxARM-rpi-latest.tar.zst tag = $tag${NC}\n\n"
    wget https://github.com/endeavouros-arm/images/releases/download/$tag/enosLinuxARM-rpi-latest.tar.zst

    if [[ "$FILESYSTEMTYPE" == "btrfs" ]]; then
        printf "\n\n${CYAN}Creating btrfs Subvolumes${NC}\n"
        btrfs subvolume create MP2/@
        btrfs subvolume create MP2/@home
        btrfs subvolume create MP2/@log
        btrfs subvolume create MP2/@cache
        umount MP2
        o_btrfs=defaults,compress=zstd:4,noatime,commit=120
        mount -o $o_btrfs,subvol=@ $PARTNAME2 MP2
        mkdir -p MP2/{boot,home,var/log,var/cache}
        mount -o $o_btrfs,subvol=@home $PARTNAME2 MP2/home
        mount -o $o_btrfs,subvol=@log $PARTNAME2 MP2/var/log
        mount -o $o_btrfs,subvol=@cache $PARTNAME2 MP2/var/cache
    fi

    printf "\n\n${CYAN}Untarring the image...takes 4 to 5 minutes.${NC}\n"
    pv "enosLinuxARM-rpi-latest.tar.zst" | zstd -T0 -cd -  | bsdtar -xf -  -C MP2
    # bsdtar --use-compress-program=unzstd -xpf enosLinuxARM-rpi-aarch64-latest.tar.zst -C MP2
    printf "\n\n${CYAN}syncing files...takes 4 to 5 minutes.${NC}\n"
    sync
    mv MP2/boot/* MP1
    # make /etc/fstab work with a UUID instead of a label such as /dev/sda
    printf "\n${CYAN}In /etc/fstab and /boot/cmdline.txt changing Disk labels to UUID numbers.${NC}\n"
    mv MP2/etc/fstab MP2/etc/fstab-bkup
    uuidno=$(lsblk -o UUID $PARTNAME1)
    uuidno=$(echo $uuidno | sed 's/ /=/g')
    printf "# /etc/fstab: static file system information.\n#\n# Use 'blkid' to print the universally unique identifier for a device; this may\n" > MP2/etc/fstab
    printf "# be used with UUID= as a more robust way to name devices that works even if\n# disks are added and removed. See fstab(5).\n" >> MP2/etc/fstab
    printf "#\n# <file system>             <mount point>  <type>  <options>  <dump>  <pass>\n\n"  >> MP2/etc/fstab
    printf "$uuidno  /boot  vfat  defaults  0  0\n\n" >> MP2/etc/fstab
    # make /boot/cmdline.txt work with a UUID instead of a lable such as /dev/sda
    if [[ "$FILESYSTEMTYPE" == "btrfs" ]]; then
        genfstab -U MP2 >> MP2/etc/fstab
        sed -i '/# \/dev\/sd*/d' MP2/etc/fstab
        sed -i 's/subvolid=.*,//g' MP2/etc/fstab
        sed -i '/swap/d' MP2/etc/fstab   # Remove any swap carried over from the host device
        sed -i '/zram/d' MP2/etc/fstab   # Remove any zram carried over from the host device
    fi

    uuidno=$(lsblk -o UUID $PARTNAME2)
    uuidno=$(echo $uuidno | sed 's/ /=/g')
    old=$(awk '{print $1}' MP1/cmdline.txt)
    case $FILESYSTEMTYPE in
        btrfs) new="root=$uuidno rootflags=subvol=@ rootfstype=btrfs fsck.repair=no"
               boot_options=" usbhid.mousepoll=8" ;;
         ext4) new="root=$uuidno"
               boot_options=" usbhid.mousepoll=8" ;;
    esac
    sed -i "s#$old#$new#" MP1/cmdline.txt
    sed -i "s/$/$boot_options/" MP1/cmdline.txt
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
   printf "\ndevicename = $DEVICENAME     devicesize = $DEVICESIZE\n" >> /root/enosARM.log
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
       Pinebook)   _partition_Pinebook ;;
       OdroidN2)   _partition_OdroidN2 ;;
       RPi64)      _partition_RPi4 ;;
   esac
   printf "\npartition name = $DEVICENAME\n\n" >> /root/enosARM.log
   printf "\n${CYAN}Formatting storage device $DEVICENAME...${NC}\n"
   printf "\n${CYAN}If \"/dev/sdx contains an existing file system Labelled XXXX\" or similar appears, Enter: y${NC}\n\n"

   if [[ ${DEVICENAME:5:6} = "mmcblk" ]] || [[ ${DEVICENAME:5:4} = "nvme" ]]
   then
      DEVICENAME=$DEVICENAME"p"
   fi
   PARTNAME1=$DEVICENAME"1"
   mkfs.fat $PARTNAME1   2>> /root/enosARM.log
   PARTNAME2=$DEVICENAME"2"
   case $FILESYSTEMTYPE in
       ext4) mkfs.ext4 -F $PARTNAME2   2>> /root/enosARM.log ;;
       btrfs) mkfs.btrfs -f $PARTNAME2   2>> /root/enosARM.log ;;
   esac
   mkdir MP1 MP2
   mount $PARTNAME1 MP1
   mount $PARTNAME2 MP2

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
    PLATFORM=$(whiptail --title " SBC Model Selection" --menu --notags "\n            Choose which SBC to install or Press right arrow twice to cancel" 17 100 4 \
         "0" "Raspberry Pi 4b 64 bit" \
         "1" "Odroid N2 or N2+" \
         "2" "Pinebook Pro" \
    3>&2 2>&1 1>&3)

    case $PLATFORM in
        "") printf "\n\nScript aborted by user..${NC}\n\n"
            exit ;;
         0) PLATFORM="RPi64" ;;
         1) PLATFORM="OdroidN2" ;;
         2) PLATFORM="Pinebook" ;;
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
       OdroidN2)   _install_OdroidN2_image ;;
       RPi64)      _install_RPi4_image ;;
       Pinebook) _install_Pinebook_image ;;
    esac

    printf "\n${CYAN}Almost done! Just a couple of minutes more for the last step.${NC}\n"

    if [[ "$FILESYSTEMTYPE" == "btrfs" ]]; then
       umount MP2/home MP2/var/log MP2/var/cache
    fi
    umount MP1 MP2
    rm -rf MP1 MP2
    printf "\n${CYAN}Remove or save downloaded image? [r/s]${NC} "
    read -n 1 r
    if [[ $r == "r" || $r == "R" ]]; then
        rm enosLinuxARM*
        printf "\n${CYAN}image removed${NC}\n"
    else
        printf "\n${CYAN}image saved${NC}\n"
    fi

    printf "\n${CYAN}End of script!${NC}\n"
    printf "\n${CYAN}Be sure to use a file manager to umount the device before removing the USB SD reader${NC}\n"

    printf "\n${CYAN}The default user is ${NC}alarm${CYAN} with the password ${NC}alarm\n"
    printf "${CYAN}The default root password is ${NC}root\n\n\n"
    read -n 1 -s -r -p "Press any key to continue"
    exit
}

Main "$@"
