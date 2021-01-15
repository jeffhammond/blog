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
  * Write the image to it.  This takes about 10 minutes.
  
I used Ubuntu's `Disks` GUI app but one can of course use `dd` instead.

[This](https://synyx.de/blog/turing-pi-the-ultimate-cluster-board-for-raspis/) appears to be another good description
of the setup process, with more automation.  You might find that more useful than mine.

# Getting Started

I was dumb and initially only imaged one compute module.
What I learned from using the first image is that the Pi 3+ can barely run Gnome,
e.g. I saw multiple hangs and even when I went back to the pure terminal, the graphics was sluggish.
This isn't too surprising, but given that I have a pretty good time with Ubuntu 20 and Gnome
on my Raspberry Pi 4, 
I subsequently uninstalled Gnome and will only use these things via SSH from a more powerful system.

After imaging all of the modules, I see all of the node IP addresses in my router and with `nmap`.
I used `pdsh` to make Apt changes symmetrically.

# Running HPC Workloads

## MPI

Open-MPI is much more reliable at launching processes on the Turing Pi.
The following just works.
```
$ mpicc.openmpi -g -Os hello.c -o hello.x && pdsh -R exec -w turing[1-5] ssh -l ubuntu %h scp turing0:/tmp/hello.x /tmp/hello.x && /usr/bin/mpirun.openmpi --host turing0:4,turing1:4,turing2:4,turing3:4,turing4:4,turing5:4 /tmp/hello.x
```

The following does not work.
```
$ mpicc.mpich -g -Os hello.c -o hello.x && pdsh -R exec -w turing[1-5] ssh -l ubuntu %h scp turing0:/tmp/hello.x /tmp/hello.x && /usr/bin/mpirun.mpich --host turing0:4,turing1:4,turing2:4,turing3:4,turing4:4,turing5:4 /tmp/hello.x
```

Eventually, I had to change `~/.ssh/config` to use the key by default and just use the raw IP addresses.
I don't know for sure, but it seems like a DNS issue (https://isitdns.com/).
```
$ mpicc.mpich -g -Os hello.c -o hello.x && pdsh -R exec -w turing[1-5] ssh -l ubuntu %h scp turing0:/tmp/hello.x /tmp/hello.x && /usr/bin/mpirun.mpich -launcher ssh --host 192.168.1.23:4,192.168.1.24:4,192.168.1.25:4,192.168.1.26:4,192.168.1.27:4,192.168.1.28:4 /tmp/hello.x
```

### MPI `hello.c` (in case you need it)
```c
#include <stdio.h>
#include <mpi.h>

int main(int argc, char** argv)
{
    MPI_Init(&argc, &argv);

    int np;
    MPI_Comm_size(MPI_COMM_WORLD, &np);

    int me;
    MPI_Comm_rank(MPI_COMM_WORLD, &me);

    int name_len; //unused
    char name[MPI_MAX_PROCESSOR_NAME];
    MPI_Get_processor_name(name, &name_len);
    printf("Hello from processor %s, rank %d out of %d processors\n", name, me, np);

    MPI_Finalize();

    return 0;
}
```

## NWChem

### Install

NWChem is part of the Debian/Ubuntu package manager:
```
apt install nwchem
```
While the binary is not built optimally, it's good enough to start.
Building NWChem is not trivial either in human time or execution time of the build -- using a pre-built binary saves a lot of time, although this is eventually offset by increased execution time of the application itself.

### Launch

After doing all the necessary SSH things, including passwordless SSH keys and `~/.ssh/knownhosts`, one can use Open-MPI 4.0.3 (from Apt) to run jobs.  Test your MPI installing by running `hostname`.

```
$ /usr/bin/mpirun.openmpi --host turing0:4,turing1:4,turing2:4,turing3:4,turing4:4,turing5:4 /usr/bin/nwchem w9_b3lyp_6-31G_energy.nw 
```

## More NWChem

This is WIP.  I am still debugging the NWChem build...
```
$ /usr/bin/mpirun.mpich -launcher ssh --host 192.168.1.23:4,192.168.1.24:4,192.168.1.25:4,192.168.1.26:4,192.168.1.27:4,192.168.1.28:4 /tmp/nwchem w9_b3lyp_6-31G_energy.nw
```
