# Summary

I got a Turing Pi v1 ([docs](https://docs.turingpi.com/)) for fun.

# Acquisition

The Turing Pi system that you buy is just the board.
You need to buy compute modules and the power supply elsewhere.
I bought six Compute Module 3+ 8GB from [PiShop.us](https://www.pishop.us/product/raspberry-pi-compute-module-3-8gb/)
and the recommended LEDMO power supply from [Amazon](https://www.amazon.com/gp/product/B01461MOGQ/).

The total cost of this setup is just shy of $400, not including any additional storage you might need.
Obviously, it helps to have an HDMI cable, monitor, USB keyboard and mouse, and a USB to MicroUSB cable,
but most people who would buy a Turing Pi have those laying around.

# Setup

I watched the YouTube videos linked on the Turing Pi website to get an idea of what to do.
The documentation isn't perfect but I managed to do it on the first attempt, and I'm not very good at this sort of thing.

I downloaded the Raspberry Pi 3 64-bit image of [Ubuntu](https://ubuntu.com/download/raspberry-pi)
because I use 64-bit Ubuntu 20 almost everywhere else.
The Turing Pi people recommend some other distro.
If you want to follow their documentation exactly, use that instead.

Following the directions on their website, install `usbboot` on some other Linux (or Windows, but who uses that?) system.
You'll use this to boot the compute modules for flashing the OS image onto the eMMC storage.
You will need to do this for every module, which is a bit tedious, but presumably doesn't happen very often.

First, move the jumper next to the MicroUSB port to `flash` instead of `boot`.  Connect the machine where you downloaded the Pi image to the Turing Pi board via USB-to-MicroUSB cable.

For each compute module, do this:

  * Run `sudo ./rpiboot` in a terminal to mount the eMMC storage.
  * Write the image to it.
  
I used Ubuntu's `Disks` GUI app but one can of course use `dd` instead.

# Getting Started

I was dumb and initially only imaged one compute module.
What I learned from using the first image is that the Pi 3+ can barely run Gnome,
e.g. I saw multiple hangs and even when I went back to the pure terminal, the graphics was sluggish.
This isn't too surprising, but given that I have a pretty good time with Ubuntu 20 and Gnome
on my Raspberry Pi 4, 
I subsequently uninstalled Gnome and will only use these things via SSH from a more powerful system.
