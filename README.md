# NixConfig

A NixOS flake-based configuration for managing identical NAS machines with declarative
disk provisioning, automated storage management, and data protection.

## Overview

This repository manages NixOS-based NAS systems using a flake-based configuration. It
provides:

- **Declarative disk provisioning** using disko for both boot SSDs and data disks
- **SnapRAID integration** for parity-based data protection across multiple disks
- **Modular architecture** with shared modules and per-machine customization
- **Automated maintenance** via systemd timers for sync and scrub operations
- **Multiple machine support** from a single repository

The configuration philosophy emphasizes:
- Explicit provisioning steps that are never automated
- Declarative runtime configuration that is version controlled
- Clear separation between installation-time and runtime concerns
- Reproducible builds across identical hardware

## Repository Structure

```
.
├── flake.nix              # Flake entry point and machine definitions
├── flake.lock             # Locked flake inputs
├── README.md              # This file
│
├── doc/                   # Documentation
│   ├── CONTRIBUTING.md    # Contribution guidelines
│   └── INSTALL.md         # Installation guide
│
├── machines/              # Per-machine configurations
│   ├── <machine>/         # Example machine directory
│   │   ├── configuration.nix    # Main machine config
│   │   ├── home-manager.nix     # Home Manager integration
│   │   ├── programs.nix         # Installed programs
│   │   ├── services.nix         # System services
│   │   ├── storage.nix          # Storage and SnapRAID config
│   │   ├── system.nix           # System settings
│   │   ├── users.nix            # User accounts
│   │   └── generated/
│   │       └── hardware.nix     # Generated hardware config
│   └── template/          # Template for new machines
│
├── modules/               # Shared NixOS and Home Manager modules
│   ├── nixos/
│   │   ├── compatibility/       # Non-NixOS binary compatibility
│   │   ├── programs/            # CLI programs and utilities
│   │   ├── services/            # System services
│   │   ├── storage/             # Storage management and data protection
│   │   │   └── filesystem/      # Per-disk mount options
│   │   └── system/              # Bootloader, networking, etc.
│   └── home-manager/
│
├── provisioning/          # Disk provisioning tooling
│   ├── README.md          # Provisioning documentation
│   ├── disko/
│   │   ├── boot.nix       # Boot SSD layout
│   │   └── data.nix       # Data disk layout
│   └── scripts/           # Wrappers for disko files
│
├── scripts/               # Runtime management scripts
│   ├── rebuild-system.sh  # Apply configuration changes
│   └── update-system.sh   # Update flake inputs
│
└── users/                 # Per-user configurations
    ├── <user>/            # Example user
    │   ├── home.nix       # Home Manager config
    │   └── user.nix       # NixOS user config
    └── template/          # Template for new users
```

## Quick Start

### Installation

See [doc/INSTALL.md](doc/INSTALL.md) for complete installation instructions.

### Adding a New Machine

1. Copy the template machine directory:
   ```bash
   cp -r machines/template machines/<newmachine>
   ```
2. Add the machine to `flake.nix`:
   ```nix
   <newmachine> = nixpkgs.lib.nixosSystem {
     system = "x86_64-linux";
     specialArgs = { inherit inputs; };
     modules = [ ./machines/<newmachine>/configuration.nix ];
   };
   ```
3. Follow the installation process in [doc/INSTALL.md](doc/INSTALL.md)
4. Customise the machine configuration files in `machines/<newmachine>/`.  Note, it is
   important to do this after step 3 to ensure only the minimum-required packages are
   included for first boot

### Daily Operations

**Rebuild system after configuration changes:**
```bash
sudo scripts/rebuild-system.sh --machine <machinename>
```

**Update flake inputs (nixpkgs, home-manager, etc.):**
```bash
scripts/update-system.sh
```

## Storage Architecture

### Disk Layout

- **Boot SSD**: NVMe with btrfs subvolumes for root, nix, and logs
- **Data Disks**: Individual ext4 disks mounted at `/srv/disks/data{N}`

### SnapRAID Configuration

SnapRAID provides snapshot-based parity protection across multiple data disks:

- **Automated sync**: Daily at 1:00 AM
- **Automated scrub**: Weekly on Fridays at 2:00 AM (8% of array)
- **Content files**: Stored on root filesystem and all data disks
- **Configuration**: Managed declaratively in `machines/<machine>/storage.nix`

Example storage configuration:
```nix
{
  imports = [
    ../../modules/nixos/storage/snapraid.nix
    ../../modules/nixos/storage/filesystem/data1.nix
    ../../modules/nixos/storage/filesystem/data2.nix
    ../../modules/nixos/storage/filesystem/data3.nix
  ];

  nixos.storage.snapraid.parityBays = [ 1 ];
  nixos.storage.snapraid.dataBays = [ 2 3 ];
}
```

## Key Features

### Declarative Disk Provisioning

All disk layouts are defined in `provisioning/disko/` and applied via wrapper scripts:
- Boot SSD provisioning creates btrfs subvolumes for system components
- Data disk provisioning creates labeled ext4 filesystems
- All provisioning is explicit and manual (never automatic)

### Modular Configuration

Shared functionality lives in `modules/nixos/` and can be imported by any machine:
- Storage modules handle filesystem configuration and SnapRAID
- System modules manage bootloader, networking, and core services
- Service modules configure SSH, compatibility layers, etc.

### Bay-Based Disk Management

Disks are identified by physical bay number rather than device paths:
- Bay numbers are manually assigned based on physical enclosure position
- Configuration references bays (e.g., `data3`, `data4`)
- Eliminates ambiguity when disks are added or replaced

## System Management

### Flake Inputs

This configuration uses:
- **nixpkgs**: NixOS 25.11 release channel
- **home-manager**: Release 25.11

Update inputs periodically:
```bash
scripts/update-system.sh
sudo scripts/rebuild-system.sh --machine <machine>
```

### Development Mode

Use local changes during development:
```bash
# Copy config to ~/.config/nix
cp -r . ~/.config/nix

# Rebuild using local flake
sudo scripts/rebuild-system.sh --machine <machine> --development
```

### Configuration Changes

1. Edit files in `machines/<machine>/` or `modules/`
2. Commit changes to version control
3. Apply: `sudo scripts/rebuild-system.sh --machine <machine>`
4. Verify system state

## Documentation

- **[doc/INSTALL.md](doc/INSTALL.md)**: Complete installation guide
- **[doc/CONTRIBUTING.md](doc/CONTRIBUTING.md)**: Contribution guidelines
- **[provisioning/README.md](provisioning/README.md)**: Disk provisioning documentation
- Module comments: Each module includes inline documentation

## Design Principles

1. **Explicit over implicit**: No hidden automation; all actions are intentional
2. **Version controlled**: All configuration is in Git
3. **Reproducible**: Same config produces same result
4. **Modular**: Shared code is reusable across machines
5. **Documented**: Inline comments explain intent and usage
6. **Safe**: Provisioning requires confirmation; runtime is declarative

## License

This is personal infrastructure configuration. Use at your own risk.

## Contributing

See [doc/CONTRIBUTING.md](doc/CONTRIBUTING.md) for contribution guidelines.
