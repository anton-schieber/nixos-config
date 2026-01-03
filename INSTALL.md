# INSTALL

This document describes the end-to-end installation procedure for a NAS machine using this
repository. It covers initial provisioning, installation, and first boot.  It
intentionally avoids runtime configuration details, which are handled elsewhere.

This repository assumes:
- NixOS is installed using flakes
- Disk provisioning is performed explicitly and manually
- All runtime configuration is declarative and version controlled
- Multiple NAS machines share the same repository but have separate machine directories

Installation is split into four conceptual phases. Each phase consists of one or more
concrete steps documented below.

1. Installer environment
    - Boot the NixOS installer
    - (Optional) Enable SSH access
    - Download the nix-config Git repository
2. Disk provisioning
    - Provision the boot SSD
3. Installation
    - Generate hardware configuration
    - Install NixOS using the flake
4. Verification
    - Reboot into the installed system
    - Verify mounts and basic system state

Provisioning is destructive. Installation is repeatable. Runtime operation is handled
separately.

## 1. Boot the NixOS installer

From the local machine:
1. Download [NixOS](https://nixos.org/download/#nix-install-linux)
2. Create a bootable USB with the downloaded ISO using [Etcher](https://etcher.balena.io/)
   or [USBImager](https://bztsrc.gitlab.io/usbimager/).  It is recommended to use the
   minimal ISO image as it is a smaller bundle.
3. Insert newly flashed USB into the target machine and boot.

Once booted, you will be logged in as the `nixos` user in a live environment. This
environment runs entirely from RAM.

## 2. (Optional) Enable SSH access

From the installer environment:
1. Set a temporary password:
```bash
passwd
```
2. Start the SSH daemon:
```bash
sudo systemctl start sshd
```
3. Find the IP address:
```bash
ip addr
```

This access exists only for the duration of the installer session.

**NOTE**: if `ip addr` fails to return a usable IP address, then Ethernet or Wi-Fi (or
both!) need to be explicitly enabled using `nmtui`.

## 3. Clone the repository

From the local machine:
1. Generate a [GitHub Personal Access Token (PAT)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic)

From the installer environment:
1. Clone the repository
```bash
git clone https://github.com/anton-schieber/nix-config.git
```
2. During the cloning of the repository, enter the required username and password
   credentials.
    - Username: GitHub username
    - Password: Personal Access Token (not the GitHub password)
3. (Optional) Cache credentials for the installer session.  Otherwise, these will need to
   be specified on each following Git action. Note, this cache is memory-only and will be
   cleared on reboot.
```bash
git config --global credential.helper cache
```

## 4. Provision the boot SSD

From the installer environment, execute the
[boot SSD provisioning](provisioning/README.md#boot-ssd-provisioning) steps.

## 5. Generate hardware configuration

From the installer environment:
1. Generate the hardware configuration:
```bash
sudo nixos-generate-config --root /mnt
```
2. Copy the generated hardware configuration into the corresponding machine directory,
   where `MACHINE` is the name of the corresponding machine.  This can be done either on
   the local machine or within the installer environment.  Note, in either case, the
   copied file will need to be committed into Git, using the typical branch, pull request,
   and merge process which is not outlined here.
    - Local machine:
    ```bash
    scp nixos@IPADDRESS:/mnt/etc/nixos/hardware-configuration.nix \
    machines/MACHINE/generated/hardware.nix
    ```
    - Installer environment:
    ```bash
    cp /mnt/etc/nixos/hardware-configuration.nix \
        /home/nixos/nix-config/machines/MACHINE/generated/hardware.nix
    ```

**NOTE**: the generated `/mnt/etc/nixos/configuration.nix` is not used.

## 6. Install NixOS

From the installer environment, run the NixOS installer using the flake output for the
target machine.  This installs:
- NixOS
- Bootloader
- Machine-specific configuration
```bash
sudo nixos-install --flake .#<machinename>
```

## 7. Reboot into the installed system

From the installer environment:
1. Reboot the machine after the installation is complete:
```bash
reboot
```
2. Remove the installer ISO.
3. Wait for boot to complete into the installed NixOS environment.

## 8. First boot verification

From the installed system:
1. Log in
2. Verify mounts:
```bash
findmnt
```
3. Verify the system matches the expected machine:
```bash
hostname
```
4. Verify services and networking as required

## 9. Provision data disks

**After** successful installation and first boot, provision data disks from the running
system. Execute the
[data disk provisioning](provisioning/README.md#data-disk-provisioning) steps for each
data disk you want to add.

This must be done after installation to avoid mount conflicts during the installation
process.

## Notes and principles

- Provisioning tools are one-time, destructive, and manual by design
- Runtime mounts, snapRAID, and mergerfs are configured declaratively
- hardware.nix is machine-specific and generated once per machine
- Reinstallation should never require reprovisioning data disks
