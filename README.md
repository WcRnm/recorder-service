# recorder-service

Simple MP3 audio recorder service. Stop and start with a single keypress.

## Setup

These instructions are for a OrangePi running Raspian (Debian)

### Update the OS

```bash
# sudo apt update
# sudo apt upgrade
```

### Install Apps

```bash
# sudo apt install arecord lame
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
# cd /lib/systemd/system
# rm default.target
# ln -s multi-user.target default.target
# systemctl daemon-reload
```
