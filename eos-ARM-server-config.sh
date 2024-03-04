#!/bin/bash

ZONE_DIR="/usr/share/zoneinfo/"
declare -a TIMEZONE_LIST

generate_timezone_list() {

	input=$1
	if [[ -d $input ]]; then
		for i in "$input"/*; do
			generate_timezone_list $i
		done
	else
		TIMEZONE=${input/#"$ZONE_DIR/"}
		TIMEZONE_LIST+=($TIMEZONE)
		TIMEZONE_LIST+=("")
	fi
}

_edit_mirrorlist() {
    local user_confirmation
    local changes
    local mirrors
    local mirror1
    local old
    local new
    local file
    local str

    whiptail  --title "EndeavourOS ARM Setup - mirrorlist"  --yesno "     Mirrorlist uses a Geo-IP based mirror selection and load balancing.\n     Do you wish to override this and choose mirrors near you?\n\n" 8 80 3>&2 2>&1 1>&3
    user_confirmation=$?
    changes=0
    while [ "$user_confirmation" == "0" ]
    do
        tail -n +11 /etc/pacman.d/mirrorlist | grep -e ^"###" -e ^"# S" -e^"  S"  > tmp-mirrorlist
        readarray -t mirrors < tmp-mirrorlist

        mirror1=$(whiptail --cancel-button 'Done' --notags --title "EndeavourOS ARM Setup - Mirror Selection" --menu  \ "Please choose a mirror to enable.\n Only choose lines starting with: \"# Server\" or \"  Server\"\n The chosen item will be toggled between commented and uncommented.\n Note: You can navigate to different sections with Page Up/Down keys.\n When finished selecting, press right arrow key twice" 30 80 18 \
           "${mirrors[0]}" "${mirrors[0]}" \
           "${mirrors[1]}" "${mirrors[1]}" \
           "${mirrors[2]}" "${mirrors[2]}" \
           "${mirrors[3]}" "${mirrors[3]}" \
           "${mirrors[4]}" "${mirrors[4]}" \
           "${mirrors[5]}" "${mirrors[5]}" \
           "${mirrors[6]}" "${mirrors[6]}" \
           "${mirrors[7]}" "${mirrors[7]}" \
           "${mirrors[8]}" "${mirrors[8]}" \
           "${mirrors[9]}" "${mirrors[9]}" \
           "${mirrors[10]}" "${mirrors[10]}" \
           "${mirrors[11]}" "${mirrors[11]}" \
           "${mirrors[12]}" "${mirrors[12]}" \
           "${mirrors[13]}" "${mirrors[13]}" \
           "${mirrors[14]}" "${mirrors[14]}" \
           "${mirrors[15]}" "${mirrors[15]}" \
           "${mirrors[16]}" "${mirrors[16]}" \
           "${mirrors[17]}" "${mirrors[17]}" \
           "${mirrors[18]}" "${mirrors[18]}" \
           "${mirrors[19]}" "${mirrors[19]}" \
           "${mirrors[20]}" "${mirrors[20]}" \
           "${mirrors[21]}" "${mirrors[21]}" \
           "${mirrors[22]}" "${mirrors[22]}" \
           "${mirrors[23]}" "${mirrors[23]}" \
           "${mirrors[24]}" "${mirrors[24]}" \
           "${mirrors[25]}" "${mirrors[25]}" \
           "${mirrors[26]}" "${mirrors[26]}" \
           "${mirrors[27]}" "${mirrors[27]}" \
           "${mirrors[28]}" "${mirrors[28]}" \
           "${mirrors[29]}" "${mirrors[29]}" \
           "${mirrors[30]}" "${mirrors[30]}" \
           "${mirrors[31]}" "${mirrors[31]}" \
           "${mirrors[32]}" "${mirrors[32]}" \
           "${mirrors[33]}" "${mirrors[33]}" \
           "${mirrors[34]}" "${mirrors[34]}" \
           "${mirrors[35]}" "${mirrors[35]}" \
        3>&2 2>&1 1>&3)
        user_confirmation=$?
        if [ "$user_confirmation" == "0" ]; then
           str=${mirror1:0:8}
           case $str in
              "# Server") changes=$((changes+1))
                          old=${mirror1::-12}
                          new=${old/["#"]/" "}
                          sed -i "s|$old|$new|g" /etc/pacman.d/mirrorlist ;;
              "  Server") changes=$((changes+1))
                          old=${mirror1::-12}
                          new=${old/[" "]/"#"}
                          sed -i "s|$old|$new|g" /etc/pacman.d/mirrorlist ;;
                       *) whiptail  --title "EndeavourOS ARM Setup - ERROR"  --msgbox "     You have selected an item that cannot be edited. Please try again.\n     Only select lines that start with \"# Server\" or \"  Server\"\n     Other items are invalid.\n\n" 10 80 3>&2 2>&1 1>&3
           esac
        fi
    done

    if [ $changes -gt 0 ]; then
       sed -i 's|Server = http://mirror.archlinuxarm.org|# Server = http://mirror.archlinuxarm.org|' /etc/pacman.d/mirrorlist
    fi
    file="tmp-mirrorlist"
    if [ -f "$file" ]; then
       rm tmp-mirrorlist
    fi
}   # end of function _edit_mirrorlist


_enable_paralleldownloads() {
    local user_confirmation
    local numdwn
    local new

    whiptail  --title "EndeavourOS ARM Setup - Parallel Downloads"  --yesno "             By default, pacman has Parallel Downloads disabled.\n             Do you wish to enable Parallel Downloads?\n\n" 8 80 15 3>&2 2>&1 1>&3

    user_confirmation=$?
    if [ "$user_confirmation" == "0" ]; then
       numdwn=$(whiptail --title "EndeavourOS ARM Setup - Parallel Downloads" --menu --notags "           When enabled, Pacman has 5 Parallel Downloads as a default.\n           How many Parallel Downloads do you wish? \n\n" 20 80 10 \
         "2" " 2 Parallel Downloads" \
         "3" " 3 Parallel Downloads" \
         "4" " 4 Parallel Downloads" \
         "5" " 5 Parallel Downloads" \
         "6" " 6 Parallel Downloads" \
         "7" " 7 Parallel Downloads" \
         "8" " 8 Parallel Downloads" \
         "9" " 9 Parallel Downloads" \
         "10" "10 Parallel Downloads" \
       3>&2 2>&1 1>&3)
    fi

    if [[ $numdwn -gt 1 ]]; then
       old=$(cat /etc/pacman.conf | grep ParallelDownloads)
       new="ParallelDownloads = $numdwn"
       sed -i "s|$old|$new|g" /etc/pacman.conf
    fi
}   # end of function _enable_paralleldownloads



_set_time_zone() {
    printf "\n${CYAN}Setting Time Zone...${NC}"
    ln -sf $TIMEZONEPATH /etc/localtime
}

_enable_ntp() {
    printf "\n${CYAN}Enabling NTP...${NC}"
    timedatectl set-ntp true
    timedatectl timesync-status
    sleep 1
}

_sync_hardware_clock() {
    printf "\n${CYAN}Syncing Hardware Clock${NC}\n\n"
    hwclock -r
    if [ $? == "0" ]
    then
       hwclock --systohc
       printf "\n${CYAN}hardware clock was synced${NC}\n"
    else
       printf "\n${RED}No hardware clock was found${NC}\n"
    fi
}

_set_locale() {
    printf "\n${CYAN}Setting Locale...${NC}\n"
    sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
    locale-gen
    printf "\nLANG=en_US.UTF-8\n\n" > /etc/locale.conf
}

_set_hostname() {
    printf "\n${CYAN}Setting hostname...${NC}"
    printf "\n$HOSTNAME\n\n" > /etc/hostname
}

_config_etc_hosts() {
    printf "\n${CYAN}Configuring /etc/hosts...${NC}"
    printf "\n127.0.0.1\tlocalhost\n" > /etc/hosts
    printf "::1\t\tlocalhost\n" >> /etc/hosts
    printf "127.0.1.1\t$HOSTNAME.localdomain\t$HOSTNAME\n\n" >> /etc/hosts
}

_change_user_alarm() {
    local tmpfile

    printf "\n${CYAN}Delete default username (alarm) and Creating a user...${NC}"
    userdel -rf alarm     #delete the default user from the image
    useradd -m -G users -s /bin/bash -u 1000 "$USERNAME"
    printf "\n${CYAN} Updating user password...\n\n"
    echo "${USERNAME}:${USERPASSWD}" | chpasswd
}   # End of function _change_user_alarm

_clean_up() {
    # rebranding to EndeavourOS
    sed -i 's/Arch/EndeavourOS/' /etc/issue
    sed -i 's/Arch/EndeavourOS/' /etc/arch-release
}

_completed_notification() {
    printf "\n\n${CYAN}Installation is complete!\n\n"
    printf "\nRemember your new user name and password when remotely logging into the server\n"
    printf "\nSSH server was installed and enabled to listen on port $SSHPORT\n"
    printf "\nfirewalld was installed and enabled.  public is the default zone.\n"
    printf "\nThe ssh service is in use allowing the appropriate ssh port though.\n"
    printf "\nsources is set to the IP address of your router, which will only allow"
    printf "\naccess to the server from your local LAN on the specified port\n\n"

    printf "Pressing Ctrl c will exit the script and give a CLI prompt"
    printf "\nto allow the user to use pacman to add additional packages"
    printf "\nor change configs. This will not remove install files from /root\n\n"
    printf "Press any key exits the script, removes all install files, and reboots the computer.${NC}\n\n"
}


_install_ssd() {
    local user_confirmation
    local finished
    local base_dialog_content
    local dialog_content
    local exit_status
    local datadevicename
    local datadevicesize
    local mntname
    local uuidno

    usbssd=$(whiptail --title "EndeavourOS ARM Setup - SSD Configuration" --menu --notags "\n  You can do the following with a connected USB SSD for data storge:\n\n  Partition & format, create mount points, & config /etc/fstab.\n  Only create Mount points for an existing USB SSD\n  Do nothing\n\n" 16 75 3 \
       "0" "Partion & format, create mount points, config /etc/fstab" \
       "1" "Only create mount points" \
       "2" "Do nothing" \
       3>&2 2>&1 1>&3)

   case $usbssd in
       0)  whiptail  --title "EndeavourOS ARM Setup - SSD Configuration"  --yesno "        Discharge any bodily static by touching something grounded.\n Connect a USB 3 external enclosure with a SSD or hard drive installed\n\n \
       CAUTION: ALL data on this drive will be erased\n \
       Do you want to continue?" 12 80
           user_confirmation="$?"

           if [ $user_confirmation == "0" ]
           then
              finished=1
              base_dialog_content="\nThe following storage devices were found\n\n$(lsblk -o NAME,MODEL,FSTYPE,SIZE,FSUSED,FSAVAIL,MOUNTPOINT)\n\n \
              Enter target device name without a partition designation (e.g. /dev/sda or /dev/mmcblk0):"
              dialog_content="$base_dialog_content"
              while [ $finished -ne 0 ]
              do
                 datadevicename=$(whiptail --title "EndeavourOS ARM Setup - micro SD Configuration" --inputbox "$dialog_content" 27 115 3>&2 2>&1 1>&3)
                 exit_status=$?
                 if [ $exit_status == "1" ]; then
                    printf "\nInstall SSD aborted by user\n\n"
                    return
                 fi
                 if [[ ! -b "$datadevicename" ]]; then
                    dialog_content="$base_dialog_content\n    Not a listed block device, or not prefaced by /dev/ Try again."
                 else
                    case $datadevicename in
                       /dev/sd*)  if [[ ${#datadevicename} -eq 8 ]]; then
                                    finished=0
                                  else
                                     dialog_content="$base_dialog_content\n    Input improperly formatted. Try again."
                                 fi ;;
                  /dev/mmcblk*)  if [[ ${#datadevicename} -eq 12 ]]; then
                                    finished=0
                                 else
                                    dialog_content="$base_dialog_content\n    Input improperly formatted. Try again."
                                 fi ;;
                    esac
                 fi
              done

              ##### Determine data device size in MiB and partition ###
              printf "\n${CYAN}Partitioning, & formatting DATA storage device...${NC}\n"
              datadevicesize=$(fdisk -l | grep "Disk $datadevicename" | awk '{print $5}')
              ((datadevicesize=$datadevicesize/1048576))
              ((datadevicesize=$datadevicesize-1))  # for some reason, necessary for USB thumb drives
              printf "\n${CYAN}Partitioning DATA device $datadevicename...${NC}\n"
              parted --script -a minimal $datadevicename \
              mklabel gpt \
              unit mib \
              mkpart primary 1MiB $datadevicesize"MiB" \
              quit
              sleep 3
              if [[ ${datadevicename:5:4} = "nvme" ]]
              then
                 mntname=$datadevicename"p1"
              else
                 mntname=$datadevicename"1"
              fi
              printf "\n${CYAN}Formatting DATA device $mntname...${NC}\n"
              printf "\n${CYAN}If \"/dev/sdx contains a ext4 file system Labelled XXXX\" or similar appears,    Enter: y${NC}\n\n"
              mkfs.ext4 -F -L DATA $mntname
              sleep 3
              printf "\n${CYAN}Creating mount points /server & /serverbkup${NC}\n\n"
              mkdir /server /serverbkup
              chown root:users /server /serverbkup
              chmod 774 /server /serverbkup
              sleep 2
              printf "\n${CYAN}Adding DATA storage device to /etc/fstab...${NC}"
              cp /etc/fstab /etc/fstab-bkup
              uuidno=$(lsblk -o UUID $mntname)
              uuidno=$(echo $uuidno | sed 's/ /=/g')
              printf "\n# $mntname\n$uuidno      /server          ext4            rw,relatime     0 2\n" >> /etc/fstab
              printf "\n${CYAN} New /etc/fstab${NC}\n"
              cat /etc/fstab
              sleep 4
              printf "\n${CYAN}Mounting DATA device $mntname on /server...${NC}"
              mount $mntname /server
              chown root:users /server /serverbkup
              chmod 774 /server /serverbkup
              printf "\033c"; printf "\n"
              printf "${CYAN}Data storage device summary:\n\n"
              printf "\nAn external USB 3 device was partitioned, formatted, and /etc/fstab was configured.\n"
              printf "This device will be on mount point /server and will be mounted at bootup.\n"
              printf "The mount point /serverbkup was also created for use in backing up the DATA device.${NC}\n"
              printf "\n\nPress Enter to continue\n"
              read -n 1 z
           fi ;;

       1)  mkdir /server /serverbkup
           chown root:users /server /serverbkup
           chmod 774 /server /serverbkup
           printf "${CYAN}Data storage device summary:${NC}\n\n"
           printf "Mount point for the USB SSD DATA device will be on /server\n"
           printf "/etc/fstab will need to be configured.\n\n"
           printf "Mount point /serverbkup was also created for use in backing up the DATA device.\n\n"
           printf "\n\nPress Enter to continue\n"
           read -n 1 z ;;
       2) return ;;
   esac
}  # end of function _install_ssd

_precheck_setup() {
    local script_directory
    local whiptail_installed
    
    # check where script is installed
    script_directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
    if [[ "$script_directory" == "/home/alarm/"* ]]; then
       whiptail_installed=$(pacman -Qs libnewt)
       if [[ "$whiptail_installed" != "" ]]; then
          whiptail --title "Error - Cannot Continue" --msgbox "This script is in the alarm user's home folder which will be removed.  \
          \n\nPlease move it to the root user's home directory and rerun the script." 10 80
          exit
       else
          printf "${RED}Error - Cannot Continue. This script is in the alarm user's home folder which will be removed. Please move it to the root user's home directory and rerun the script.${NC}\n"
          exit
       fi
    fi

    # check to see if script was run as root #####
    if [ $(id -u) -ne 0 ]
    then
       whiptail_installed=$(pacman -Qs libnewt)
       if [[ "$whiptail_installed" != "" ]]; then
          whiptail --title "Error - Cannot Continue" --msgbox "Please run this script with sudo or as root" 8 47
          exit
       else
          printf "${RED}Error - Cannot Continue. Please run this script with sudo or as root.${NC}\n"
          exit
       fi
    fi
    # Prevent script from continuing if there's any processes running under the alarm user #
    # as we won't be able to delete the user later on in the script #

    if [[ $(pgrep -u alarm) != "" ]]; then
       whiptail_installed=$(pacman -Qs libnewt)
       if [[ "$whiptail_installed" != "" ]]; then
          whiptail --title "Error - Cannot Continue" --msgbox "alarm user still has processes running. Kill them to continue setup." 8 47
          exit
       else
          printf "${RED}Error - Cannot Continue. alarm user still has processes running. Kill them to continue setup.${NC}\n"
          exit
       fi
    fi

     printf "\n${CYAN}Checking Internet Connection...${NC}\n\n"

    finished=1
    while [ $finished -ne 0 ]
    do
       sleep 5
       device=$(ip route | grep default | awk '{print $5}')
       if [ "$device" == "" ]; then
          printf "\n${CYAN}Network is down${NC}\n"
       else
          state=$(ip link show | grep "$device" | awk '{print $9}')
          if [ "$state" == "UP" ]; then
          finished=0
          printf "\n${CYAN}Network $device is up${NC}\n\n"
          fi
       fi
    done

    ping -c 3 endeavouros.com -W 5
    if [ "$?" != "0" ]
    then
       printf "\n\n${RED}No Internet Connection was detected\nFix your Internet Connection and try again${NC}\n\n"
       exit
    fi

    dmesg -n 1    # prevent low level kernel messages from appearing during the script
}  # end of function _precheck_setup


_user_input() {
    local userinputdone
    local finished
    local description
    local initial_user_password
    local initial_root_password
    local lasttriad
    local xyz

    userinputdone=1
    while [ $userinputdone -ne 0 ]
    do
       generate_timezone_list $ZONE_DIR
       TIMEZONE=$(whiptail --nocancel --title "EndeavourOS ARM Setup - Timezone Selection" --menu \
       "Please choose your timezone.\n\nNote: You can navigate to different sections with Page Up/Down or the A-Z keys." 18 90 8 --cancel-button 'Back' "${TIMEZONE_LIST[@]}" 3>&2 2>&1 1>&3)
       TIMEZONEPATH="${ZONE_DIR}${TIMEZONE}"

       finished=1
       description="Enter your desired hostname"
       while [ $finished -ne 0 ]
       do
  	      HOSTNAME=$(whiptail --nocancel --title "EndeavourOS ARM Setup - Configuration" --inputbox "$description" 8 60 3>&2 2>&1 1>&3)
          if [ "$HOSTNAME" == "" ]
          then
	 	    description="Host name cannot be blank. Enter your desired hostname"
          else
            finished=0
          fi
       done

       finished=1
       description="Enter your full name, i.e. John Doe"
       while [ $finished -ne 0 ]
       do
	      FULLNAME=$(whiptail --nocancel --title "EndeavourOS ARM Setup - User Setup" --inputbox "$description" 8 60 3>&2 2>&1 1>&3)

          if [ "$FULLNAME" == "" ]
          then
             description="Entry is blank. Enter your full name"
          else
             finished=0
          fi
       done

       finished=1
       description="Enter your desired user name"
       while [ $finished -ne 0 ]
       do
	      USERNAME=$(whiptail --nocancel --title "EndeavourOS ARM Setup - User Setup" --inputbox "$description" 8 60 3>&2 2>&1 1>&3)

          if [ "$USERNAME" == "" ]
          then
             description="Entry is blank. Enter your desired username"
          else
             finished=0
          fi
       done

       finished=1
       initial_user_password=""
       description="Enter your desired password for ${USERNAME}:"
       while [ $finished -ne 0 ]
       do
	      USERPASSWD=$(whiptail --nocancel --title "EndeavourOS ARM Setup - User Setup" --passwordbox "$description" 8 60 3>&2 2>&1 1>&3)

          if [ "$USERPASSWD" == "" ]; then
              description="Entry is blank. Enter your desired password"
              initial_user_password=""
          elif [[ "$initial_user_password" == "" ]]; then
              initial_user_password="$USERPASSWD"
              description="Confirm password:"
          elif [[ "$initial_user_password" != "$USERPASSWD" ]]; then
              description="Passwords do not match.\nEnter your desired password for ${USERNAME}:"
              initial_user_password=""
          elif [[ "$initial_user_password" == "$USERPASSWD" ]]; then
              finished=0
         fi
       done

       finished=1
       initial_root_password=""
       description="Enter your desired password for the root user:"
       while [ $finished -ne 0 ]
       do
	       ROOTPASSWD=$(whiptail --nocancel --title "EndeavourOS ARM Setup - Root User Setup" --passwordbox "$description" 8 60 3>&2 2>&1 1>&3)
           if [ "$ROOTPASSWD" == "" ]; then
              description="Entry is blank. Enter your desired password"
              initial_root_password=""
           elif [[ "$initial_root_password" == "" ]]; then
              initial_root_password="$ROOTPASSWD"
              description="Confirm password:"
           elif [[ "$initial_root_password" != "$ROOTPASSWD" ]]; then
              description="Passwords do not match.\nEnter your desired password for the root user:"
              initial_root_password=""
           elif [[ "$initial_root_password" == "$ROOTPASSWD" ]]; then
             finished=0
           fi
       done

       finished=1
       description="\n  For better security, change the SSH port\n  to something besides 22\n\n  Enter the desired SSH port between 8000 and 48000"

       while [ $finished -ne 0 ]
       do
          SSHPORT=$(whiptail --nocancel  --title "EndeavourOS ARM Setup - Server Configuration"  --inputbox "$description" 12 60 3>&2 2>&1 1>&3)

          if [ "$SSHPORT" -eq "$SSHPORT" ] # 2>/dev/null
          then
             if [ $SSHPORT -lt 8000 ] || [ $SSHPORT -gt 48000 ]
             then
                description="Your choice is out of range, try again.\n\nEnter the desired SSH port between 8000 and 48000"
             else
                finished=0
             fi
          else
                 description="Your choice is not a number, try again.\n\nEnter the desired SSH port between 8000 and 48000"
          fi
       done

       ETHERNETDEVICE=$(ip r | awk 'NR==1{print $5}')
       ROUTERIP=$(ip r | awk 'NR==1{print $3}')
       THREETRIADS=$ROUTERIP
       xyz=${THREETRIADS#*.*.*.}
       THREETRIADS=${THREETRIADS%$xyz}
       finished=1
       description="\n  Servers work best with a Static IP address. \n  The first three triads of your router are $THREETRIADS\n  For the best router compatibility, the last triad should be between 120 and 250\n\n  Enter the last triad of the desired static IP address $THREETRIADS"
       while [ $finished -ne 0 ]
       do
          lasttriad=$(whiptail --nocancel --title "EndeavourOS ARM Setup - Server Configuration"  --title "SETTING UP THE STATIC IP ADDRESS FOR THE SERVER" --inputbox "$description" 13 88 3>&2 2>&1 1>&3)
          if [ "$lasttriad" -eq "$lasttriad" ] # 2>/dev/null
          then
             if [ $lasttriad -lt 120 ] || [ $lasttriad -gt 250 ]
             then
                description="For the best router compatibility, the last triad should be between 120 and 250\n\nEnter the last triad of the desired static IP address $THREETRIADS\n\nYour choice is out of range. Please try again\n"
             else
                   finished=0
             fi
          else
	         description="For the best router compatibility, the last triad should be between 120 and 250\n\nEnter the last triad of the desired static IP address $THREETRIADS\n\nYour choice is not a number.  Please try again\n"
             fi
       done

       STATICIP=$THREETRIADS$lasttriad
       STATICIP=$STATICIP"/24"

       whiptail --title "EndeavourOS ARM Setup - Review Settings" --yesno "              To review, you entered the following information:\n\n \
       Time Zone: $TIMEZONE \n \
       Host Name: $HOSTNAME \n \
       Full Name: $FULLNAME \n \
       User Name: $USERNAME \n \
       SSH Port:  $SSHPORT \n \
       Static IP: $STATICIP \n\n \
       Is this information correct?" 16 80
       userinputdone="$?"
    done
}   # end of function _user_input

_find_mirrorlist() {
    local currentmirrorlist

    printf "\n${CYAN}Find current endeavouros-mirrorlist...${NC}\n\n"
    sleep 1
    currentmirrorlist=$(curl https://github.com/endeavouros-team/repo/tree/master/endeavouros/aarch64 | grep "endeavouros-mirrorlist" | sed s'/^.*endeavouros-mirrorlist/endeavouros-mirrorlist/'g | sed s'/pkg.tar.zst.*/pkg.tar.zst/'g | head -1)

    printf "\n${CYAN}Downloading endeavouros-mirrorlist...${NC}"
    wget https://github.com/endeavouros-team/repo/raw/master/endeavouros/aarch64/$currentmirrorlist

    printf "\n${CYAN}Installing endeavouros-mirrorlist...${NC}\n"
    pacman -U --noconfirm $currentmirrorlist
    rm $currentmirrorlist
    sed -i "s|\[core\]|\[endeavouros\]\nSigLevel = PackageRequired\nInclude = /etc/pacman.d/endeavouros-mirrorlist\n\n\[core\]|g" /etc/pacman.conf
}  # end of function _find_mirrorlist


_find_keyring() {
    local currentkeyring

    printf "\n${CYAN}Find current endeavouros-keyring...${NC}\n\n"
    sleep 1
    currentkeyring=$(curl https://github.com/endeavouros-team/repo/tree/master/endeavouros/aarch64 | grep endeavouros-keyring | sed s'/^.*endeavouros-keyring/endeavouros-keyring/'g | sed s'/pkg.tar.zst.*/pkg.tar.zst/'g | head -1)

    printf "\n${CYAN}Downloading endeavouros-keyring...${NC}"
    wget https://github.com/endeavouros-team/repo/raw/master/endeavouros/aarch64/$currentkeyring

    printf "\n${CYAN}Installing endeavouros-keyring...${NC}\n"
    pacman -U --noconfirm $currentkeyring
    rm $currentkeyring
}   # End of function _find_keyring

_server_setup() {
    _change_user_alarm    # remove user alarm and create new user of choice

    # create static IP with user supplied static IP
    printf "\n${CYAN}Creating configuration file for static IP address...${NC}"
    wiredconnection=$(nmcli con | grep "Wired" | awk '{print $1, $2, $3}')
    nmcli con mod "$wiredconnection" \
    ipv4.addresses "$STATICIP" \
    ipv4.gateway "$ROUTERIP" \
    ipv4.dns "$ROUTERIP,8.8.8.8" \
    ipv4.method "manual"
    systemctl disable NetworkManager.service
    systemctl enable --now NetworkManager.service

    printf "\n${CYAN}Configure SSH...${NC}"
    sed -i "/Port 22/c Port $SSHPORT" /etc/ssh/sshd_config
    sed -i '/PermitRootLogin/c PermitRootLogin no' /etc/ssh/sshd_config
    sed -i '/PasswordAuthentication/c PasswordAuthentication yes' /etc/ssh/sshd_config
    sed -i '/PermitEmptyPasswords/c PermitEmptyPasswords no' /etc/ssh/sshd_config
    systemctl disable sshd.service
    systemctl enable sshd.service


    printf "\n${CYAN}Enable and Configure firewalld...${NC}\n"
    UFWADDR=$THREETRIADS
    UFWADDR+="0/24"
    systemctl enable --now firewalld
    firewall-cmd --reload
    firewall-cmd --permanent --zone=public --service=ssh --remove-port=22/tcp
    firewall-cmd --permanent --zone=public --service=ssh --add-port=$SSHPORT/tcp
    firewall-cmd --permanent --zone=public --remove-service=dhcpv6-client
    firewall-cmd --permanent --zone=public --add-source=$UFWADDR
    firewall-cmd --permanent --zone=public --remove-forward
    firewall-cmd --reload

    secondary_ip=$(ip addr | grep "secondary dynamic" | awk '{print $2}')
    secondary_device=$(ip addr | grep "secondary dynamic" | awk '{print $NF}')
    if [ $secondary_ip ]; then
       printf "\n${CYAN}A secondary device needs to be removed${NC}\n\n"
       ip addr del $secondary_ip dev $secondary_device
       ip addr
    fi

    sleep 3
    pacman -Syu --noconfirm yay # pahis eos-rankmirrors
}   # end of function _server_setup


#################################################
#          script starts here                   #
#################################################

Main() {
    chvt 2
    TIMEZONE=""
    TIMEZONEPATH=""
    INSTALLTYPE="server"
    USERNAME=""
    HOSTNAME=""
    FULLNAME=""
    DENAME=""
    SSHPORT=""
    THREETRIADS=""
    STATICIP=""
    ROUTERIP=""
    ETHERNETDEVICE=""
    UFWADDR=""

    # Declare color variables
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color

    printf "\n${CYAN}   Initiating...please wait.${NC}\n"
    sleep 5
    _precheck_setup    # check various conditions before continuing the script
    pacman-key --init
    pacman-key --populate archlinuxarm
    _find_mirrorlist
    _find_keyring
    pacman-key --lsign-key EndeavourOS
    pacman-key --lsign-key builder@archlinuxarm.org
    pacman -Syy

    _edit_mirrorlist
    _enable_paralleldownloads
    _user_input
    _set_time_zone
    _enable_ntp
    _sync_hardware_clock
    _set_locale
    _set_hostname
    _config_etc_hosts
    printf "\n${CYAN}Updating root user password...\n\n"
    echo "root:${ROOTPASSWD}" | chpasswd

    _server_setup
    eos-rankmirrors
    _install_ssd
    _completed_notification
    read -n1 x
    systemctl disable resize-fs.service
    rm /etc/systemd/system/resize-fs.service
    rm /root/resize-fs.service
    rm /root/resize-fs.sh
    systemctl disable config-server.service
    rm /etc/systemd/system/config-server.service
    rm /root/eos-ARM-server-config.sh
    systemctl reboot
}  # end of Main

Main "$@"
