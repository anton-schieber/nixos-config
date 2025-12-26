# nixos-config

Connect to wifi with `nmtui`
## partions

Boot SSD, in my case a 500gb nvme at `/dev/nvme0n1`

Wipe existing partions
``` bash
wipefs -a /dev/nvme0n1
sgdisk --zap-all /dev/nvme0n1
```

Enter the partion managemnt for the given drive with `sudo parted /dev/nvme0n1`
``` bash
unit MiB
print # to view current state
mklabel gpt
mkpart ESP fat32 1MiB 1GiB
set 1 esp on
mkpart swap linux-swap 1GiB 9GiB
mkpart root btrfs 9GiB 100%
quit
```

Setup file structure
```bash
sudo mkfs.fat -F 32 -n EFI /dev/nvme0n1p1
sudo mkswap -L swap /dev/nvme0n1p2
sudo mkfs.btrfs -L nixos /dev/nvme0n1p3
```

Mount the files
```bash
# Create subvolumes:
sudo mount /dev/disk/by-label/nixos /mnt
sudo btrfs subvolume create /mnt/@
sudo btrfs subvolume create /mnt/@home
# Other subvolumnes that can be added later
# @nix - Separate /nix/store subvolume
# @log - Separate /var/log
# @appdata - For /mnt/appdata (Docker, Immich, etc.)
sudo btrfs subvolumne list /mnt # should see all the subvolumes
sudo umount /mnt

# Mount with subvolumes (if using ssd, add ssd,compress=zstd,discard=async):
sudo mount -o subvol=@,ssd,compress=zstd,discard=async /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/{boot,home}
sudo mount -o subvol=@home,ssd,compress=zstd,discard=async /dev/disk/by-label/nixos /mnt/home

# Mount boot/swap
sudo mount -o umask=077 /dev/disk/by-label/EFI /mnt/boot
sudo swapon /dev/nvme0n1p2

# Confirm mounted
mount | grep mnt
```

Setup nix os, at this point you can provide your own config; otherwise, run `sudo nixos-generate-config --root /mnt`

### If using ssd do the following
Check `cat /mnt/etc/nixos/hardware-configuration.nix`, ensuring that the options are:
for mtn/home: `options = [ "subvol=@home" "ssd" "compress=zstd" "discard=async" ];`
for mnt: `options = [ "subvol=@" "ssd" "compress=zstd" "discard=async" ];`

Edit `sudo nano /mnt/etc/nixos/configuration.nix` to contin the following:
```nix
{ config, pkgs, ... }:

{
  # ... existing config ...

  # Enable SSH
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };

  # Enable firewall but allow SSH
  networking.firewall.allowedTCPPorts = [ 22 ];

  # Create your user with sudo access
  users.users.yourname = {  # CHANGE 'yourname' to your actual username
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    # Set password after install with: sudo passwd yourname
  };

  # ... rest of existing config ...
}
```

Finally, instal nixos
```bash
sudo nixos-install
sudo nixos-enter --root /mnt -c `passwd yourname`
reboot
```

If set password for root during install, loging under root

reduce power consumption
```
nix-shell -p powertop --run "sudo powertop --auto-tune"
sudo nix --extra-experimental-features "nix-command flakes" run github:notthebee/AutoASPM
```


### Setup github

Create links with new structure
```bash
# Backup original
sudo mv /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup
sudo mv /etc/nixos/hardware-configuration.nix /etc/nixos/hardware-configuration.nix.backup

# Create symlink
sudo ln -s ~/.dotfiles/system/configuration.nix /etc/nixos/configuration.nix
sudo ln -s ~/.dotfiles/system/hardware-configuration.nix /etc/nixos/hardware-configuration.nix
sudo ln -s ~/.dotfiles/users/anton/home.nix ~/.config/nixpkgs/home.nix
```
https://www.youtube.com/watch?v=Dy3KHMuDNS8