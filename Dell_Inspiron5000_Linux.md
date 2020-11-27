# Summary

This post describes my experience getting Linux installed on a [Dell Inspiron 5000 laptop](https://www.dell.com/en-us/member/shop/dell-laptops/new-inspiron-14-5000-laptop/spd/inspiron-14-5402-laptop/nn5402ejobh) with the latest (as of 2020) Intel processor, known as Tiger Lake.

**TL;DR** Turn of BitLocker, install Ubuntu 20.10 (not 20.04!), and repartition the drive to dual-boot Linux alongside Windows 10.  Everything works nicely.

# Disclaimer

I was not compensated by anyone to write this, but I work for Intel and thus you should not treat this as an objective, third-party review.  In any case, my focus here will be explaining what I did to install Linux and how things are working so far, not to compare it to any competitive products.  My primary basis for comparison will older Dell laptops and other computers on which I run Linux.

# What's in the box?

The box contains a laptop, the power cable and the trivial paperwork.  That's it.  There was minimal plastic (sleeves around each item) and the cardboard appears to be recycled.

Here are some hardware details if you care:
```sh
$ sudo lshw 
tigerlake                   
    description: Notebook
    product: Inspiron 5402 (0A01)
    vendor: Dell Inc.
    serial: *
    width: 64 bits
    capabilities: smbios-3.2.0 dmi-3.2.0 smp vsyscall32
    configuration: boot=normal chassis=notebook family=Inspiron sku=0A01 
  *-core
       description: Motherboard
       product: 0MF3C8
       vendor: Dell Inc.
       physical id: 0
       version: A00
       serial: *
     *-firmware
          description: BIOS
          vendor: Dell Inc.
          physical id: 0
          version: 1.1.5
          date: 09/22/2020
          size: 1MiB
          capacity: 32MiB
          capabilities: pci pnp upgrade shadowing cdboot bootselect edd int5printscreen int9keyboard int14serial int17printer acpi usb smartbattery biosbootspecification netboot uefi
     *-cpu
          description: CPU
          product: 11th Gen Intel(R) Core(TM) i7-1165G7 @ 2.80GHz
          vendor: Intel Corp.
          physical id: 400
          bus info: cpu@0
          version: 11th Gen Intel(R) Core(TM) i7-1165G7 @ 2.80GHz
          slot: CPU 1
          size: 1274MHz
          capacity: 4700MHz
          width: 64 bits
          clock: 100MHz
          capabilities: lm fpu fpu_exception wp vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp x86-64 constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf tsc_known_freq pni pclmulqdq dtes64 monitor ds_cpl vmx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fault epb cat_l2 invpcid_single cdp_l2 ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow vnmi flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid rdt_a avx512f avx512dq rdseed adx smap avx512ifma clflushopt clwb intel_pt avx512cd sha_ni avx512bw avx512vl xsaveopt xsavec xgetbv1 xsaves split_lock_detect dtherm ida arat pln pts hwp hwp_notify hwp_act_window hwp_epp hwp_pkg_req avx512vbmi umip pku ospke avx512_vbmi2 gfni vaes vpclmulqdq avx512_vnni avx512_bitalg avx512_vpopcntdq rdpid movdiri movdir64b fsrm avx512_vp2intersect md_clear flush_l1d arch_capabilities cpufreq
          configuration: cores=4 enabledcores=4 threads=8
```

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

# Comparison to past experiences

I've been a Dell Linux laptop user for many years, since 2005 or so.  In the past, I would install OpenSUSE because it seemed to have the best driver support and wouldn't even think the fact that Windows was there, although I recall the horrors of ndiswrapper in cases where my wireless chip didn't permit native Linux drives.  Things are different now, mostly in good ways, although BIOS security features and SecureBoot mean that nuking Windows requires slightly more work.  As noted already, I am keeping Windows 10 around in a dual-boot configuration just in case I need it to update the firmware or something like that.

# Installing oneAPI

Because the motivation for getting this machine was to evaluate the developer experience of oneAPI on a Tiger Lake laptop, I installed oneAPI and other Intel GPU software.  Fortunately, both support Apt and the process is trivial.  Since the details are documented elsewhere, I will merely link to those:

* https://dgpu-docs.intel.com/installation-guides/ubuntu/ubuntu-focal.html
* https://software.intel.com/content/www/us/en/develop/articles/installing-intel-oneapi-toolkits-via-apt.html

Aside: the above works just fine in WSL as well, but the GPU isn't exposed because the driver support isn't there yet.

# Performance

## Practical

The other computers on my desk right now are a Macbook Pro circa 2018-2019 and a Hades Canyon NUC.  The Tiger Lake laptop feels noticeably faster than the NUC even though the NUC has a higher power envelope and frequency ceiling.  I'm not sure whether this is real or not, and if it's real, how it correlates with the processor, memory, or SSD capability. 

I can't really compare the Mac laptop because it is burdened with corporate IT bloatware like Microsoft Outlook that I unfortunately have to run all the time.  I've mostly given up on building software natively on MacOS because Apple refuses to let me program the GPU in a sensible manner (their OpenCL is decent for a 1.x implementation, but that's not saying much).

The other thing I like about this laptop is that it cost around $800.  My Macbook Pro cost around $3000 and while it has twice the SSD and more memory (16 vs 12), it's not faster than the cheaper one, and certainly not anywhere near four times faster.  I can get a similarly provisioned Mac laptop with the new M1 procesor in it for *only* twice the cost of my Dell.  While people on Twitter tell me that the M1 is seventy bazillion times better than every other processor ever made, I am very happy with the performance and the battery life on the Dell, particularly for the price.  Also, my name is not Jon Masters and I do not love ARM processors *that* much.

## Raw

`clpeak` is a nice way to measure the peak memory and compute capability of CPU and GPU devices using an equivalent methodology.

I ran these tests with the Linux governor set for performance ([details](https://askubuntu.com/questions/604720/setting-to-high-performance)).

```sh
jrhammon@tigerlake:~/clpeak$ echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
performance
```

```sh
jrhammon@tigerlake:~/clpeak$ ./clpeak | tee clpeak.log

Platform: Intel(R) OpenCL
  Device: 11th Gen Intel(R) Core(TM) i7-1165G7 @ 2.80GHz
    Driver version  : 2020.11.10.0.05_160000 (Linux x64)
    Compute units   : 8
    Clock frequency : 2800 MHz

    Global memory bandwidth (GBPS)
      float   : 32.09
      float2  : 31.57
      float4  : 34.14
      float8  : 28.76
      float16 : 21.88

    Single-precision compute (GFLOPS)
      float   : 218.19
      float2  : 409.03
      float4  : 407.21
      float8  : 400.21
      float16 : 393.09

    No half precision support! Skipped

    Double-precision compute (GFLOPS)
      double   : 211.05
      double2  : 203.61
      double4  : 201.58
      double8  : 198.51
      double16 : 86.28

    Integer compute (GIOPS)
      int   : 75.64
      int2  : 134.78
      int4  : 172.68
      int8  : 88.42
      int16 : 86.30

    Integer compute Fast 24bit (GIOPS)
      int   : 58.13
      int2  : 85.43
      int4  : 90.68
      int8  : 89.62
      int16 : 85.92

    Transfer bandwidth (GBPS)
      enqueueWriteBuffer              : 14.70
      enqueueReadBuffer               : 14.85
      enqueueWriteBuffer non-blocking : 14.68
      enqueueReadBuffer non-blocking  : 14.82
      enqueueMapBuffer(for read)      : 59322.75
        memcpy from mapped ptr        : 14.69
      enqueueUnmap(after write)       : 52377.65
        memcpy to mapped ptr          : 14.51

    Kernel launch latency : 1.97 us

Platform: Intel(R) OpenCL HD Graphics
  Device: Intel(R) Graphics Gen12LP [0x9a49]
    Driver version  : 20.46.18421 (Linux x64)
    Compute units   : 96
    Clock frequency : 1300 MHz

    Global memory bandwidth (GBPS)
      float   : 32.51
      float2  : 24.16
      float4  : 31.49
      float8  : 32.43
      float16 : 40.02

    Single-precision compute (GFLOPS)
      float   : 1413.85
      float2  : 1410.00
      float4  : 860.81
      float8  : 899.68
      float16 : 753.69

    Half-precision compute (GFLOPS)
      half   : 2327.97
      half2  : 2304.86
      half4  : 2329.34
      half8  : 1427.09
      half16 : 1612.55

    No double precision support! Skipped

    Integer compute (GIOPS)
      int   : 329.21
      int2  : 238.15
      int4  : 225.79
      int8  : 308.19
      int16 : 260.67

    Integer compute Fast 24bit (GIOPS)
      int   : 326.83
      int2  : 235.12
      int4  : 252.99
      int8  : 252.23
      int16 : 256.53

    Transfer bandwidth (GBPS)
      enqueueWriteBuffer              : 12.41
      enqueueReadBuffer               : 12.48
      enqueueWriteBuffer non-blocking : 10.37
      enqueueReadBuffer non-blocking  : 10.18
      enqueueMapBuffer(for read)      : 4294959.00
        memcpy from mapped ptr        : 12.43
      enqueueUnmap(after write)       : inf
        memcpy to mapped ptr          : 12.43

    Kernel launch latency : 26.90 us

```

# Hardware details

The wireless hardware that Ubuntu 20.04 doesn't support is:
```
$ sudo lshw -C network
  *-network                 
       description: Wireless interface
       product: Wi-Fi 6 AX201
       vendor: Intel Corporation
       physical id: 14.3
       logical name: wlp0s20f3
       version: 20
       serial: *
       width: 64 bits
       clock: 33MHz
       capabilities: pm msi pciexpress msix bus_master cap_list ethernet physical wireless
       configuration: broadcast=yes driver=iwlwifi driverversion=5.8.0-29-generic firmware=55.d9698065.0 ip=* latency=0 link=yes multicast=yes wireless=IEEE 802.11
```

(c) Copyright Jeff Hammond, 2020.  No reuse permitted except by permission from the author.
