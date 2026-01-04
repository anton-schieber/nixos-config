# Contributing

This document describes the conventions and workflow for contributing to this repository.

## Branch Naming

Use descriptive branch names with the following prefixes:

- `feature/<feature-name>` - New features or functionality
- `fix/<issue-description>` - Bug fixes
- `docs/<description>` - Documentation updates
- `refactor/<description>` - Code refactoring without behavior changes

Examples:
```
feature/add-mergerfs-support
fix/snapraid-timer-schedule
docs/update-install-guide
refactor/storage-module-structure
```

## Commit Messages

Follow the directory-based commit message format:

```
dir1: dir2: Brief description of the change
```

Where `dir1/dir2/` represents the path to the changed files. If multiple directories are
affected, use the most relevant common parent.

Examples:
```
modules: storage: Add mergerfs configuration module
machines: pergamon: Configure mergerfs for data pool
provisioning: scripts: Add confirmation prompt to data disk provisioning
flake: Add new machine configuration for alexandria
```

### Commit Message Guidelines

- Use imperative mood ("Add feature" not "Added feature")
- Keep the first line under 72 characters
- Add a blank line and detailed description for complex changes
- Reference issue numbers when applicable

Example with description:
```
modules: storage: Add mergerfs configuration module

Adds a new module for configuring mergerfs to pool data disks into
a unified filesystem. Supports custom mount options and bay-based
disk selection consistent with snapRAID configuration.
```

## Pull Request Workflow

1. Create a feature branch from `main`
2. Make your changes following the conventions above
3. Test your changes on a development machine if possible
4. Commit with descriptive messages
5. Push your branch and create a pull request
6. Wait for review and address any feedback

## Testing Changes

Before submitting a pull request:

1. **Syntax check**: Ensure Nix syntax is valid
   ```bash
   nix flake check
   ```
2. **Build check**: Verify the configuration builds
   ```bash
   nix build .#nixosConfigurations.<machine>.config.system.build.toplevel
   ```
3. **Test locally**: If possible, test on a development machine
   ```bash
   sudo scripts/rebuild-system.sh --machine <machine> --development
   ```

## Code Style

- Use 2 spaces for indentation in Nix files
- Include descriptive comments in module headers
- Follow existing patterns for consistency
- Keep machine-specific configuration in `machines/<machine>/`
- Keep shared functionality in `modules/`

## Documentation

- Update relevant documentation when adding features
- Include inline comments for complex logic
- Update README.md if adding new commands or workflows
- Update INSTALL.md if changing installation procedures
- Add or update module header comments

## Questions?

If you have questions about contributing, open an issue for discussion.
