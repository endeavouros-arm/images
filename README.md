# ARM Images
 
 [![Maintenance](https://img.shields.io/maintenance/yes/2023.svg)]() [![Downloads](https://img.shields.io/github/downloads/endeavouros-arm/images/total)]()
 
Images for the installation of EndeavourOS on supported ARM devices. <br />
Supported devices include Raspberry Pi 4b, Raspberry Pi 5b. Odroid N2, and Pinebook Pro. <br />
There is also an image for a bare bones headless server for the RPi 4b / 5b. <br />
These images contain an EndeavourOS image complete up to including the "Desktop-Base + Common packages". <br />
The only things missing is some personalization and configuration plus a Desktop Environment or Window Manager. <br />
These are provided by a script which launches automatically upon first bootup. <br /> <br />


# Installation Instructions

Review the Release images by clicking on the "Releases" button on the right side if this page. <br /> 
Select the appropriate Tag for your ARM device. <br />
When you find the desired image Tag, click on it. <br />
Using Raspberry Pi 5 as an example, there should be two files listed.  <br />

enosLinuxARM-rpi5-latest.img.xz
enosLinuxARM-rpi5-latest.img.xz.sha512sum

Click on each file to download the twp files. <br />
In a terminal window, go to the directory where the files were downloaded. <br />
Verify the integrity of the downloaded files. <br />
sha512sum -c enosLinuxARM-rpi5-latest.img.xz.sha512sum
This should come back with OK.

Use your favorite flash burner app to install <br /> 
enosLinuxARM-rpi5-latest.img.xz file <br />
to a storage device such as a micro SD, eMMC, or USB SSD device. <br />

Connect the storage device to your ARM device and bootup. <br />
The device will automatically log in and run a script that allows <br />
the entry of your personal details.  Simply answer the questions. <br />

There is also a method for installing a headless LAN server on a RPi 4b. Scroll to the bottom <br />
for the headless server install.




Under Assets, for example rpi, click on <br /> 
```
enosLinuxARM-rpi-latest.img.xz 
AND
enosLinuxARM-rpi-latest.img.xz.sha512sum
```
In a terminal window, cd into the directory the images were downloaded to.
Then run <br />
```
$ sha512sum -c enosLinuxARM-rpi-latest.img.xz.sha512sum
```
should show image check is OK

Now use dd or your favorite image burning app to transfer the img.xz file
to a micro SD or USB SSD. <br />
gnome-disk-utility is recommended.  <br />
When finished transferring the image, ROOT_EOS Partition 2 will show about <br />
6.2 GB followed by a large amount of Free Space. <br />
On first boot, Calamares will run and resize Partition 2 to include the Free Space.

```
# Install headless server image on a RPi 4b.

On an operational Arch Linux (or derivative) computer: <br />
Connect a micro SD card to the computer's USB port or SD slot. <br />
Launch your favorite Terminal and maximize the window or make it at least 130 x 30 <br />
Make a temporary directory and cd into that directory.
```
wget https://github.com/endeavouros-arm/images/raw/main/ARM-install-server-image.sh
```
Make the script executable
```
chmod 754 ARM-install-server-image.sh
```
Then execute the script and answer the prompts. Select RPi 4b 64 bit.
```
sudo ./ARM-install-server-image.sh
```
Unmount the uSD and connect it to a RPi 4b with a Monitor, keyboard, and mouse. <br />
Connect a USB 3 SSD to a USB 3 port on the RPi 4b if you want the script <br />
to partition and format the DATA SSD. Then create mount points and modify <br />
the /etc/fstab file to mount the DATA SSD on every bootup. <br />

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

# Post Image Install

Connect the uSD or USB SSD enclosure to your supported ARM device.
Then boot up the device.
A script should automatically start up and ask for information on your install.
Follow the instructions to complete the EndeavourOS install.
