# ARM Images
 
 [![Maintenance](https://img.shields.io/maintenance/yes/2023.svg)]() [![Downloads](https://img.shields.io/github/downloads/endeavouros-arm/images/total)]()
 
Images for the installation of EndeavourOS on supported ARM devices. <br />
Devices include Raspberry Pi 4b, Raspberry Pi 5b. Odroid N2, and Pinebook Pro. <br />
There is also an image for a bare bones headless server for the RPi 4b / 5b. <br />
These images contain a base install of EndeavourOS including some Common packages. <br />
Ready for some personalization and configuration plus a Desktop Environment or Window Manager. <br />
These are provided by a script which launches automatically upon first bootup. <br /> <br />


# Installation Instructions

Review the Release images by clicking on the "Releases" button on the right side of this page. <br /> 
Select the appropriate Tag for your ARM device. <br />
When you find the desired image Tag, click on it. <br />
Using Raspberry Pi 5 as an example, there should be two files listed.  <br />
```
enosLinuxARM-rpi5-latest.img.xz
enosLinuxARM-rpi5-latest.img.xz.sha512sum
```
Click on each file to download the files. <br />
In a terminal window, go to the directory where the 2 files were downloaded. <br />
Verify the integrity of the downloaded files. <br />
```
sha512sum -c enosLinuxARM-rpi5-latest.img.xz.sha512sum
```
This should come back with OK.

Use dd or your favorite flash burner app to install <br /> 
```
enosLinuxARM-rpi5-latest.img.xz
```
to a storage device such as a micro SD, eMMC, or USB SSD device. <br />

Connect the storage device to your ARM device and bootup. <br />
The device will automatically log in and run a script that allows <br />
the entry of your personal details.  Simply answer the questions. <br />

After the script is finished, the device will reboot with a functional
Desktop or Windows manager.  

# Install headless server image on a RPi 4b or RPi 5b.

Follow the instructions above to install the server image
except install to a micro SD card only.

Connect the micro SD to a RPi 4b / 5b with a Monitor, keyboard, and mouse. <br />
Connect a USB 3 SSD to a USB 3 port on the RPi if you want the script to <br />
partition and format the DATA SSD. It will then create mount points and <br />
modify the /etc/fstab file to mount the DATA SSD on every bootup. <br />

Boot up the RPi and you will be prompted for information to configure the server <br />
Upon second boot, you can remove the monitor, keyboard, and mouse and run <br />
the server headless.

Go to 
```
https://discovery.endeavouros.com/category/arm/
```
and use the following HowTo's to set up a Linux LAN file server. <br />
Homeserver 1, Homeserver 2, Homeserver 3, and Homesever 7 <br />
There are additional HowTo's for SAMBA and miniDLNA.

