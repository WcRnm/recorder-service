# recorder-service

Simple MP3 audio recorder service. Stop and start with a single keypress.

## Setup

These instructions are for a OrangePi running Ubuntu 18.04

### Update the OS

```bash
sudo apt update
sudo apt upgrade
```

### Check the filesystem on every boot

```bash
$ tune2fs -c 1 /dev/mmcblk1p1
tune2fs 1.44.1 (24-Mar-2018)
Setting maximal mount count to 1
```

### Install Apps

```bash
apt install arecord lame
```

## Copy the service files to the target device

Notes

- Preserve executable permissions on the *.bash files

/etc/systemd/system/*
/opt/recorder/*
/root/onboot.bash

## Enable the onboot script

TBD

## Change the default boot target

Become root. In /lib/systemd/system, change the default.target symlink:

```bash
cd /lib/systemd/system
rm default.target
ln -s multi-user.target default.target
systemctl daemon-reload
```
