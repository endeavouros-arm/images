# exper-images
Experimental images for the Raspberry Pi 4b/400 device, and the Odroid N2/N2+ device.

These images contain an EndeavourOS image complete up to including the "Systembase + Common packages".

The only things missing is some personalization and configuration plus a Desktop Environment or Window Manager.

These are provided by a Calamares installer.  

Installation.

On an operational Arch Linux (or derivative) computer:

Connect a micro SD card or USB SSD enclosure to the computer's USB port or SD slot.

Launch your favorite Terminal and maximize the window or make it at least 120 x 30

In your home directory, make sure a folder named exper-images does not exist

git clone https://github.com/pudges-place/exper-images.git

cd into exper-images

check permissions, should show image-install-calamares.sh as executable.

sudo ./image-install-calamares.sh

Follow the instructions.

After installation,

cd ..

then remove the temporary directory.

Connect the uSD or USB SSD enclosure to a Raspberry Pi 4b/400 device or Odroid N2/N2+ device.

Then boot up the device.

Openbox should automatically start up and present the Calamares installer.

Follow the instructions to complete the EndeavourOS install.


