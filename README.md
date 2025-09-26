# raspberrypi-BadUSB
This is basically just USB Rubber Ducky made specifically to run via CLI on linux (kali to be specific), it uses whiptail for graphical part, I also modified original duckpi.sh script for standard Windows Czech QWERTZ keyboard layout. It behaves similary to USB Rubber Ducky - device acting as keyboard that types faster, than any human would. This makes it good for automating tasks, pranks, pentesting and much more. Original Ducky scripts should work without a problem, but they must use .txt file extension. This script should be compatible with different devices, like Android phones etc...
# Instructions 
1. Add dtoverlay=dwc2 to config.txt file, this allows pi to work in host mode:
```
echo "dtoverlay=dwc2" | sudo tee -a /boot/config.txt
```
2. Add dwc2 in the driver modules to boot automatically with the OS:
```
echo "dwc2" | sudo tee -a /etc/modules
```
3. Also add libcomposite to allow pi to act as USB composite gadget
```
sudo echo "libcomposite" | sudo tee -a /etc/modules
```
4. Check other configurations, like cmdline.txt, mine looks like this (I dont use g_hid, because I want to preserve otg function for external adapters, etc.):
```
console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait modules-load=dwc2
```
5. Use script to configure libcomposite as keyboard, I used example isticktoit:
```  
#!/bin/bash
cd /sys/kernel/config/usb_gadget/
mkdir -p isticktoit
cd isticktoit
echo 0x1d6b > idVendor # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice # v1.0.0
echo 0x0200 > bcdUSB # USB2
mkdir -p strings/0x409
echo "fedcba9876543210" > strings/0x409/serialnumber
echo "Tobias Girstmair" > strings/0x409/manufacturer
echo "iSticktoit.net USB Device" > strings/0x409/product
mkdir -p configs/c.1/strings/0x409
echo "Config 1: ECM network" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower

# Add functions here
mkdir -p functions/hid.usb0
echo 1 > functions/hid.usb0/protocol
echo 1 > functions/hid.usb0/subclass
echo 8 > functions/hid.usb0/report_length
echo -ne \\x05\\x01\\x09\\x06\\xa1\\x01\\x05\\x07\\x19\\xe0\\x29\\xe7\\x15\\x00\\x25\\x01\\x75\\x01\\x95\\x08\\x81\\x02\\x95\\x01\\x75\\x08\\x81\\x03\\x95\\x05\\x75\\x01\\x05\\x08\\x19\\x01\\x29\\x05\\x91\\x02\\x95\\x01\\x75\\x03\\x91\\x03\\x95\\x06\\x75\\x08\\x15\\x00\\x25\\x65\\x05\\x07\\x19\\x00\\x29\\x65\\x81\\x00\\xc0 > functions/hid.usb0/report_desc
ln -s functions/hid.usb0 configs/c.1/
# End functions

ls /sys/class/udc > UDC
```
6. Finally, to use the script, clone my repository and navigate to it:
```
git clone https://github.com/bababooex/raspberrypi-BadUSB.git
cd ./raspberrypi-BadUSB/Rpi_BadUSB
```
   To use the main script, make it executable with chmod and then simply run it with bash:
```
sudo chmod +x menu.sh
./menu.sh
```
Script requires root access to work with /dev/hidg0, and best of all, dwc2 driver allows you to switch between OTG mode and host mode, that is exactly what I wanted!                    Reminder: Rpi_BadUSB file needs to be put to /home/kali to work correctly, otherwise you need to change path in duckpi.sh scripts to work! 
# Credits 
Authors: Jeff L. Dee-oh-double-gee Theresalu Ossiozac
Credits to Original Authors: DroidDucky by Andrej Budincevic (https://github.com/anbud/DroidDucky) hardpass by girst (https://github.com/girst/hardpass)
# External references
- https://payloadhub.com/blogs/payloads - Rubber Ducky payloads
- https://github.com/ossiozac/Raspberry-Pi-Zero-Rubber-Ducky-Duckberry-Pi - Inspiration to make this
- https://www-users.york.ac.uk/~mjf5/bad_pi/index.html - Also good website to config rpi pi for HID
- https://randomnerdtutorials.com/raspberry-pi-zero-usb-keyboard-hid/ - Isticktoit HID config
- https://github.com/darrylburke/RaspberryPiZero_HID_MultiTool/tree/master - Scripts for HID setup
# TO DO
- Make script better visually
- Maybe add bluetooth support
