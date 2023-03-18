
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
    local uuidno
    local old
    local new
    local user_confirm

    tag=$(curl https://api.github.com/repos/endeavouros-arm/images/releases | grep server-odroid-n2 |  sed s'#^.*server-odroid-n2#server-odroid-n2#'g | cut -c 1-25 | head -n 1)
    printf "\n${CYAN}Downloading image enosARM-server-odroid-n2-latest.tar.zst tag = $tag${NC}\n\n"
    wget https://github.com/endeavouros-arm/images/releases/download/$tag/enosARM-server-odroid-n2-latest.tar.zst

    printf "\n\n${CYAN}Untarring the image...takes 4 to 5 minutes.${NC}\n"
    pv "enosARM-server-odroid-n2-latest.tar.zst" | zstd -T0 -cd -  | bsdtar -xf -  -C /mnt
#   bsdtar --use-compress-program=unzstd -xpf enosLinuxARM-server-odroid-n2-latest.tar.zst -C /mnt
    printf "\n\n${CYAN}syncing files...takes 4 to 5 minutes.${NC}\n"
    sync
#    mv /mnt/boot/* MP1
    dd if=/mnt/boot/u-boot.bin of=$DEVICENAME conv=fsync,notrunc bs=512 seek=1

    # make /etc/fstab work with a UUID instead of a label such as /dev/sda
    printf "\n${CYAN}In /etc/fstab and /boot/cmdline.txt changing Disk labels to UUID numbers.${NC}\n"
    mv /mnt/etc/fstab /mnt/etc/fstab-bkup
    uuidno=$(lsblk -o UUID $PARTNAME1)
    uuidno=$(echo $uuidno | sed 's/ /=/g')
    printf "# /etc/fstab: static file system information.\n#\n# Use 'blkid' to print the universally unique identifier for a device; this may\n" >> /mnt/etc/fstab
    printf "# be used with UUID= as a more robust way to name devices that works even if\n# disks are added and removed. See fstab(5).\n" >> /mnt/etc/fstab
    printf "#\n# <file system>             <mount point>  <type>  <options>  <dump>  <pass>\n\n"  >> /mnt/etc/fstab
    printf "$uuidno  /boot  vfat  defaults  0  0\n" >> /mnt/etc/fstab
    # make /boot/boot.ini work with a UUID instead of a lable such as /dev/sda
    uuidno=$(lsblk -o UUID $PARTNAME2)
    uuidno=$(echo $uuidno | sed 's/ /=/g')
    old=$(grep "setenv bootargs \"root=" /mnt/boot.ini)

    sed -i "s#$old#$new#" /mnt/boot.ini
}   # End of function _install_OdroidN2_image


_install_RPi4_image() {
    local uuidno
    local old
    local new
    local url
    local totalurl
    local exit_status

    tag=$(curl https://api.github.com/repos/endeavouros-arm/images/releases | grep server-rpi |  sed s'#^.*server-rpi#server-rpi#'g | cut -c 1-19 | head -n 1)
    printf "\n${CYAN}Downloading image enosARM-server-rpi-latest.tar.zst tag = $tag${NC}\n\n"
    wget https://github.com/endeavouros-arm/images/releases/download/$tag/enosARM-server-rpi-latest.tar.zst
    printf "\n\n${CYAN}Untarring the image...takes 4 to 5 minutes.${NC}\n"
    pv "enosARM-server-rpi-latest.tar.zst" | zstd -T0 -cd -  | bsdtar -xf -  -C /mnt
#   bsdtar --use-compress-program=unzstd -xpf enosARM-server-rpi-latest.tar.zst -C /mnt
    printf "\n\n${CYAN}syncing files...takes 4 to 5 minutes.${NC}\n"
    sync
#    mv /mnt/boot/* MP1
    # make /etc/fstab work with a UUID instead of a label such as /dev/sda
    printf "\n${CYAN}In /etc/fstab and /boot/cmdline.txt changing Disk labels to UUID numbers.${NC}\n"
    mv /mnt/etc/fstab /mnt/etc/fstab-bkup
    uuidno=$(lsblk -o UUID $PARTNAME1)
    uuidno=$(echo $uuidno | sed 's/ /=/g')
    printf "# /etc/fstab: static file system information.\n#\n# Use 'blkid' to print the universally unique identifier for a device; this may\n" >> /mnt/etc/fstab
    printf "# be used with UUID= as a more robust way to name devices that works even if\n# disks are added and removed. See fstab(5).\n" >> /mnt/etc/fstab
    printf "#\n# <file system>             <mount point>  <type>  <options>  <dump>  <pass>\n\n"  >> /mnt/etc/fstab
    printf "$uuidno  /boot  vfat  defaults  0  0\n" >> /mnt/etc/fstab
    uuidno=$(lsblk -o UUID $PARTNAME2)
    uuidno=$(echo $uuidno | sed 's/ /=/g')
    old=$(awk '{print $1}' /mnt/boot/cmdline.txt)
    new="root="$uuidno
    sed -i "s#$old#$new#" /mnt/boot/cmdline.txt
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
         esac
      fi      
   done
   ##### Determine data device size in MiB and partition ###
   printf "\n${CYAN}Partitioning, & formatting storage device...${NC}\n"
   DEVICESIZE=$(fdisk -l | grep "Disk $DEVICENAME" | awk '{print $5}')
   ((DEVICESIZE=$DEVICESIZE/1048576))
   ((DEVICESIZE=$DEVICESIZE-1))  # for some reason, necessary for USB thumb drives
   printf "\n${CYAN}Partitioning storage device $DEVICENAME...${NC}\n"

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
       RPi64)      _partition_RPi4 ;;
   esac
   printf "\npartition name = $DEVICENAME\n\n"
   printf "\n${CYAN}Formatting storage device $DEVICENAME...${NC}\n"
   printf "\n${CYAN}If \"/dev/sdx contains an existing file system Labelled XXXX\" or similar appears, Enter: y${NC}\n\n\n"

   if [[ ${DEVICENAME:5:6} = "mmcblk" ]]
   then
      DEVICENAME=$DEVICENAME"p"
   fi
   
   PARTNAME1=$DEVICENAME"1"
   mkfs.fat $PARTNAME1
   PARTNAME2=$DEVICENAME"2"
   mkfs.ext4 $PARTNAME2
   mount $PARTNAME2 /mnt
   mkdir /mnt/boot
   mount $PARTNAME1 /mnt/boot
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
          printf "${RED}Error - Cannot Continue. Please run this script as root.${NC}\n"
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
    3>&2 2>&1 1>&3)

    case $PLATFORM in
        "") printf "\n\nScript aborted by user..${NC}\n\n"
            exit ;;
         0) PLATFORM="RPi64" ;;
         1) PLATFORM="OdroidN2" ;;
    esac
}

#################################################
# beginning of script
#################################################

Main() {
    # VARIABLES
    PLATFORM=" "     # e.g. OdroidN2, or RPi64
    DEVICENAME=" "   # storage device name e.g. /dev/sda
    DEVICESIZE="1"
    PARTNAME1=" "
    PARTNAME2=" "
    FILESYSTEMTYPE="ext4"
    CONFIG_UPDATE="config-update-V2.7.sh"

    # Declare color variables
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color

    _check_if_root
    _check_all_apps_closed
    _choose_device
    _partition_format_mount  # function to partition, format, and mount a uSD card or eMMC card
    case $PLATFORM in
       OdroidN2)   _install_OdroidN2_image ;;
       RPi64)      _install_RPi4_image ;;
    esac

    printf "\n\n${CYAN}Almost done! Just a couple of minutes more for the last step.${NC}\n\n"

    umount /mnt/boot /mnt

#    rm enosLinuxARM*

    printf "\n\n${CYAN}End of script!${NC}\n"
    printf "\n${CYAN}Be sure to use a file manager to umount the device before removing the USB SD reader${NC}\n"

    printf "\n${CYAN}The default user is ${NC}alarm${CYAN} with the password ${NC}alarm\n"
    printf "${CYAN}The default root password is ${NC}root\n\n\n"

    exit
}

Main "$@"
