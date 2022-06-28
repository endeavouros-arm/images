# ARM Images
Images for the installation of EndeavourOS on ARM devices
These images contain an EndeavourOS image complete up to including the "Desktop-Base + Common packages".
The only things missing is some personalization and configuration plus a Desktop Environment or Window Manager.
These are provided by a Calamares installer.  

# Installation Instructions
On an operational Arch Linux (or derivative) computer:
Connect a micro SD card or USB SSD enclosure to the computer's USB port or SD slot.
Launch your favorite Terminal and maximize the window or make it at least 120 x 30
```bash 
# (switch to root - enter root's password)
su      
cd /tmp
```
In your tmp directory, make sure a folder named images does not exist
```bash
git clone https://github.com/endeavouros-arm/images.git
cd images
```
check permissions, should show image-install-calamares.sh as executable.
```bash
./image-install-calamares.sh
```
Follow the instructions.

# Post-Install
After installation,
```bash
cd ..
# (remove the images directory)
rm -rf images  
# (exit root)
exit           
```
Connect the uSD or USB SSD enclosure to a Raspberry Pi 4b/400 device or Odroid N2/N2+ device.
Then boot up the device.
Openbox should automatically start up and present the Calamares installer.
Follow the instructions to complete the EndeavourOS install.
