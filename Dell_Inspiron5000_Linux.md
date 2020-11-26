# Summary

This post describes my experience getting Linux installed on a Dell Inspiron 5000 laptop with the latest (as of 2020) Intel processor, known as Tiger Lake.

**TL;DR** Turn of BitLocker, install Ubuntu 20.10 (not 20.04!), and repartition the drive to dual-boot Linux alongside Windows 10.  Everything works nicely.

# Disclaimer

I was not compensated by anyone to write this, but I work for Intel and thus you should not treat this as an objective, third-party review.  In any case, my focus here will be explaining what I did to install Linux and how things are working so far, not to compare it to any competitive products.  My primary basis for comparison will older Dell laptops and other computers on which I run Linux.

# What's in the box?

I'll include the details specs later...

The box contains a laptop, the power cable and the trivial paperwork.  That's it.  There was minimal plastic (sleeves around each item) and the cardboard appears to be recycled.

# Booting for the first time

When you power on the system, it enters into the Windows installer.  I do not like Windows and the installer insisted that I provide personal information to proceed.  You can find more about this elsewhere, so I won't elaborate.

# Installing WSL

Before I went all-in with Linux, I decided to see how WSL works.  It's pretty nice, although switching from regular Windows to the Insider Preview updates meant that I had to install the Preview version of Windows Terminal, which seems like an unnecessary user inconvenience.

The biggest issue with WSL (both 1 and 2) is that I cannot get GPU compute support.  This is an area of active interest for many, including Microsoft, all the major GPU vendors, and countless users.  I expect it will be fixed some time in 2021, but this is just an uninformed guess.

The other thing I disliked about about Windows and WSL is how many times I had to reboot the computer.  On Linux, the only time I reboot is when I update the OS kernel itself.  Nothing else requires a reboot.  On Windows, you have to reboot to change just about anything.  I'm sure somebody thinks there is a good reason for this, but it's annoying and one of many reasons why I cannot take Windows seriously.

# Installing Linux

My first few attempts to boot to a USB drive and run Linux live were unsuccessful and I made my computer very angry.  The repeated reboots, including a few forced reboots, triggered system checks and something that looked like a rescue process.  Fortunately, I did not render my machine unusable in the process.

Eventually, I figured out how to boot from an USB drive.  I didn't capture the details properly but you should plug the USB into the driver, go into the BIOS settings, and place the USB boot drive about the others.

The first time I tried to run Linux, I was using the Ubuntu 20.04 ISO on a USB.  This image does not know about WiFi6, which means that I couldn't do anything with it, because the laptop doesn't have an Ethernet jack and I do not have a USB-to-Ethernet dongle.

It appears that ArchLinux has the latest kernel in an ISO but I'm less familiar with Arch so I tried Ubuntu 20.10 instead.  Fortunately, Ubuntu 20.10 has the updates requires to recognize the wireless chip (and all the other hardware I'm aware of).

When I booted into Ubuntu 20.10 in live mode, I could see that all the hardware was recognized, including the wireless and the MicroSD port.  The touchpad and screen worked perfectly.  At this point, I decided to make the Linux install persistent.

Because I wasn't completely sure that Linux can do all the BIOS/firmware updates directly, I decided to dual-boot.  I don't expect to need more than ~250 GB for each OS image, so this won't be an issue even if I never use Windows 10 again.

Ubuntu is really smart and understands the Windows 10 filesystem, and can reorganize the drive to add a Linux (ext4) partition.  However, it can only do this if you turn off BitLocker.  I suppose I can turn on BitLocker again now that Linux is installed, but as this laptop is unlikely to leave my office for a long time, I'm not that worried about physical security.

After booting into Windows to disable Bitlocker (takes about 5 minutes or less), I proceeded with the Ubuntu installer, which was extremely fast (less than 5 minutes).  I opted for the minimal configuration, but added the third-party proprietary drivers in case any of the hardware needs that.

# Running Linux

After the necessary reboot, I saw the Ubuntu boot menu, which defaults to Ubuntu, but also gives me the option to go into the Windows boot flow.  I didn't bother to test the Windows boot again because I don't really care if it works, but if something doesn't work, I'll add a note about that here.

Because I am a luddite, I installed all the things I wanted with Apt in Terminal.  The apps I install everywhere include the Chrome browser, the latest versions of GCC and LLVM, and associated development tools like Git, Vim, Valgrind and CMake (yes, I hate CMake but it's a necessary evil).

# Installing oneAPI

Because the motivation for getting this machine was to evaluate the developer experience of oneAPI on a Tiger Lake laptop, I installed oneAPI and other Intel GPU software.  Fortunately, both support Apt and the process is trivial.  Since the details are documented elsewhere, I will merely link to those:

* https://dgpu-docs.intel.com/installation-guides/ubuntu/ubuntu-focal.html
* https://software.intel.com/content/www/us/en/develop/articles/installing-intel-oneapi-toolkits-via-apt.html

Aside: the above works just fine in WSL as well, but the GPU isn't exposed because the driver support isn't there yet.

# Performance

I'll add stuff here later.


(c) Copyright Jeff Hammond, 2020.  No reuse permitted except by permission from the author.
