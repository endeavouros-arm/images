
#!/bin/bash

_partition_OdroidN2() {
    parted --script -a minimal $DEVICENAME \
    mklabel msdos \
    unit mib \
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

_partition_OdroidXU4() {
    parted --script -a minimal $DEVICENAME \
    mklabel msdos \
    unit mib \
    mkpart primary 2MiB $DEVICESIZE"MiB" \
    quit
}

_choose_filesystem_type() {
    if [[ "$PLATFORM" == "RPi64" ]]; then
        FILESYSTEMTYPE=$(whiptail --title "EndeavourOS ARM Setup - Filesystem type" --menu --notags "\n              Use the arrow keys to choose the filesystem type\n                         or Cancel to abort script\n\n" 15 80 5 \
            "ext4" "ext4" \
            "btrfs" "btrfs" \
        3>&2 2>&1 1>&3)

        if [[ "$FILESYSTEMTYPE" == "" ]]; then   # if user chose to cancel
            exit
        fi
    else
        FILESYSTEMTYPE="ext4"
    fi
}

_install_OdroidN2_image() {
    local user_confirm

    wget http://os.archlinuxarm.org/os/ArchLinuxARM-odroid-n2-latest.tar.gz
    printf "\n\n${CYAN}Untarring the image...might take a few minutes.${NC}\n"
    bsdtar -xpf ArchLinuxARM-odroid-n2-latest.tar.gz -C MP2
    mv MP2/boot/* MP1
    dd if=MP1/u-boot.bin of=$DEVICENAME conv=fsync,notrunc bs=512 seek=1
    # for Odroid N2 ask if storage device is micro SD or eMMC or USB device
    user_confirm=$(whiptail --title " Odroid N2 / N2+" --menu --notags "\n             Choose Storage Device or Press right arrow twice to abort" 17 100 3 \
         "0" "micro SD card" \
         "1" "eMMC card" \
         "2" "USB device" \
    3>&2 2>&1 1>&3)

    case $user_confirm in
       "") printf "\nScript aborted by user\n\n"
           exit ;;
        0) printf "\nN2 micro SD card\n" > /dev/null ;;
        1) sed -i 's/mmcblk1/mmcblk0/g' MP2/etc/fstab ;;
        2) sed -i 's/root=\/dev\/mmcblk${devno}p2/root=\/dev\/sda2/g' MP1/boot.ini
           printf "\# Static information about the filesystems.\n# See fstab(5) for details.\n\n# <file system> <dir> <type> <options> <dump> <pass>\n" > MP2/etc/fstab
           printf "/dev/sda1  /boot   vfat    defaults        0       0\n/dev/sda2  /   ext4   defaults     0    0\n" >> MP2/etc/fstab ;;
    esac
    cp $CONFIG_UPDATE MP2/root
}   # End of function _install_OdroidN2_image

_install_RPi4_image() {
    local uuidno
    local old
    local new
    local url
    local totalurl
    local exit_status

    url=$(curl https://github.com/pudges-place/exper-images/releases | grep "enos-image-.*/enosLinuxARM-rpi-aarch64-latest.tar.zst" | sed s'#^.*pudges-place#pudges-place#'g | sed s'#latest.tar.zst.*#latest.tar.zst#'g | head -n 1)
    totalurl="https://github.com/"$url
    wget $totalurl
    # exit_status=$?
    # if [ "$exit_status" != "0" ]; then
    #     wget https://pudges-place.ddns.net/EndeavourOS/enosLinuxARM-rpi-aarch64-latest.tar.gz
    #     exit_status=$?
    #     if [ "$exit_status" != "0" ]; then
    #         printf "\n\nCannot download the EnOS ARM 64 bit image. Check internet connections\n\n"
    #         exit
    #     fi
    # fi

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

    printf "\n\n${CYAN}Untarring the image...may take a few minutes.${NC}\n"
    bsdtar --use-compress-program=unzstd -xpf enosLinuxARM-rpi-aarch64-latest.tar.zst -C MP2

    printf "\n\n${CYAN}syncing files...may take a few minutes.${NC}\n"
    sync
    mv MP2/boot/* MP1
    # make /etc/fstab work with a UUID instead of a label such as /dev/sda
    printf "\n${CYAN}In /etc/fstab and /boot/cmdline.txt changing Disk labels to UUID numbers.${NC}\n"
    mv MP2/etc/fstab MP2/etc/fstab-bkup
    uuidno=$(lsblk -o UUID $PARTNAME1)
    uuidno=$(echo $uuidno | sed 's/ /=/g')
    printf "# /etc/fstab: static file system information.\n#\n# Use 'blkid' to print the universally unique identifier for a device; this may\n" >> MP2/etc/fstab
    printf "# be used with UUID= as a more robust way to name devices that works even if\n# disks are added and removed. See fstab(5).\n" >> MP2/etc/fstab
    printf "#\n# <file system>             <mount point>  <type>  <options>  <dump>  <pass>\n\n"  >> MP2/etc/fstab
    printf "$uuidno  /boot  vfat  defaults  0  0\n" >> MP2/etc/fstab
    # make /boot/cmdline.txt work with a UUID instead of a lable such as /dev/sda
    if [[ "$FILESYSTEMTYPE" == "btrfs" ]]; then
        genfstab -U MP2 >> MP2/etc/fstab
        sed -i 's/subvolid=\d*,//g' MP2/etc/fstab
    fi
    uuidno=$(lsblk -o UUID $PARTNAME2)
    uuidno=$(echo $uuidno | sed 's/ /=/g')
    old=$(awk '{print $1}' MP1/cmdline.txt)
    if [[ "$FILESYSTEMTYPE" == "btrfs" ]]; then
        boot_options="rootflags=subvol=@ rootfstype=btrfs fsck.repair=no"
        new="root="$uuidno" "$boot_options
    else
        new="root="$uuidno
    fi
    sed -i "s#$old#$new#" MP1/cmdline.txt
    # cp $CONFIG_UPDATE MP2/root
    # cp countrycodes MP2/root
}  # End of function _install_RPi4_image

_install_OdroidXU4_image() {
    wget http://os.archlinuxarm.org/os/ArchLinuxARM-odroid-xu3-latest.tar.gz
    printf "\n\n${CYAN}Untarring the image...might take a few minutes.${NC}\n"
    bsdtar -xpf ArchLinuxARM-odroid-xu3-latest.tar.gz -C MP1
    cd MP1/boot
    sh sd_fusing.sh $DEVICENAME
    cd ../..
    cp $CONFIG_UPDATE MP1/root
}   # End of function _install_OdroidXU4_image


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
         esac
      fi      
   done
   ##### Determine data device size in MiB and partition ###
   printf "\n${CYAN}Partitioning, & formatting storage device...${NC}\n"
   DEVICESIZE=$(fdisk -l | grep "Disk $DEVICENAME" | awk '{print $5}')
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
       OdroidN2)   _partition_OdroidN2 ;;
       OdroidXU4)  _partition_OdroidXU4 ;;
       RPi64)      _partition_RPi4 ;;
   esac
   printf "\npartition name = $DEVICENAME\n\n" >> /root/enosARM.log
   printf "\n${CYAN}Formatting storage device $DEVICENAME...${NC}\n"
   printf "\n${CYAN}If \"/dev/sdx contains an existing file system Labelled XXXX\" or similar appears, Enter: y${NC}\n\n\n"

   if [[ ${DEVICENAME:5:6} = "mmcblk" ]]
   then
      DEVICENAME=$DEVICENAME"p"
   fi
   
   case $PLATFORM in
      OdroidN2 | RPi64) PARTNAME1=$DEVICENAME"1"
                        mkfs.fat $PARTNAME1   2>> /root/enosARM.log
                        PARTNAME2=$DEVICENAME"2"
                        case $FILESYSTEMTYPE in
                            ext4) mkfs.ext4 -F $PARTNAME2   2>> /root/enosARM.log ;;
                           btrfs) mkfs.btrfs -f $PARTNAME2   2>> /root/enosARM.log ;;
                        esac
                        mkdir MP1 MP2
                        mount $PARTNAME1 MP1
                        mount $PARTNAME2 MP2 ;;
      OdroidXU4)        PARTNAME1=$DEVICENAME"1"
                        mkfs.ext4 $PARTNAME1  2>> /root/enosARM.log
                        mkdir MP1
                        mount $PARTNAME1 MP1 ;;
   esac
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
         "0" "Odroid N2 or N2+" \
         "1" "Odroid XU4" \
         "2" "Raspberry Pi 4b 64 bit" \
    3>&2 2>&1 1>&3)

    case $PLATFORM in
        "") printf "\n\nScript aborted by user..${NC}\n\n"
            exit ;;
         0) PLATFORM="OdroidN2" ;;
         1) PLATFORM="OdroidXU4" ;;
         2) PLATFORM="RPi64" ;;
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

    pacman -S --noconfirm --needed libnewt &>/dev/null # for whiplash dialog
    pacman -S --noconfirm --needed arch-install-scripts
    _check_if_root
    _check_all_apps_closed
    _choose_device
    _choose_filesystem_type
    _partition_format_mount  # function to partition, format, and mount a uSD card or eMMC card
    case $PLATFORM in
       OdroidN2)   _install_OdroidN2_image ;;
       OdroidXU4)  _install_OdroidXU4_image ;;
       RPi64)      _install_RPi4_image ;;
    esac

    printf "\n\n${CYAN}Almost done! Just a couple of minutes more for the last step.${NC}\n\n"

    case $PLATFORM in
       OdroidN2 | RPi64) if [[ "$FILESYSTEMTYPE" == "btrfs" ]]; then
                            umount MP2/home MP2/var/log MP2/var/cache
                         fi
                         umount MP1 MP2
                         rm -rf MP1 MP2 ;;
       OdroidXU4)        umount MP1
                         rm -rf MP1 ;;
    esac

#    rm ArchLinuxARM*

    printf "\n\n${CYAN}End of script!${NC}\n"
    printf "\n${CYAN}Be sure to use a file manager to umount the device before removing the USB SD reader${NC}\n"

    printf "\n${CYAN}The default user is ${NC}alarm${CYAN} with the password ${NC}alarm\n"
    printf "${CYAN}The default root password is ${NC}root\n\n\n"

    exit
}

Main "$@"
