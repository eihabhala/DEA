# DEA Repository Management Tools

This directory contains tools for managing the DEA repository.

## Tools Overview

### 1. dea-manager.sh
Main wrapper script that provides a unified interface for all management functions.

**Usage:**
```bash
./dea-manager.sh [command]
```

**Commands:**
- `update` - Update the repository with latest changes
- `check` - Check the repository for issues
- `both` - Update and then check the repository
- `status` - Show repository status
- `help` - Display help message

### 2. dea-updater.sh
Script that updates the DEA repository with the latest changes from the remote.

**Features:**
- Fetches the latest changes from the remote repository
- Pulls changes if the local repository is behind
- Provides detailed logging of operations

### 3. dea-checker.sh
Script that checks the DEA repository for common issues and problems.

**Features:**
- Checks for missing README.md and LICENSE files
- Detects placeholder text like "yourusername" in documentation
- Finds TODO comments in code
- Identifies large files (>10MB)
- Validates setup scripts
- Verifies previously applied fixes are still in place
- Checks for management scripts
- Detailed error reporting

## Installation

The scripts are already in the DEA repository and are ready to use.

## Usage Examples

### Update the repository:
```bash
./dea-manager.sh update
```

### Check the repository for issues:
```bash
./dea-manager.sh check
```

### Update and check the repository:
```bash
./dea-manager.sh both
```

### Show repository status:
```bash
./dea-manager.sh status
```

## Common Issues Checked

The checker script looks for these common issues:

1. **Placeholder text** - "yourusername" in README or setup files
2. **Missing documentation** - Missing README.md or LICENSE files
3. **Large files** - Files larger than 10MB that might not be appropriate for Git
4. **TODO comments** - Unfinished code that needs attention
5. **Broken links** - Invalid URLs in documentation
6. **Configuration issues** - Problems with setup scripts
7. **Missing fixes** - Previously applied fixes that may have been lost

## Log Files

- `repository-check.log` - General logs from the checker script
- `repository-errors.log` - Only errors and warnings from the checker script
- `update.log` - Logs from the updater script

## Automation

You can automate these checks by adding a cron job:

```bash
# Run daily checks at 2 AM
0 2 * * * cd /home/eboalking/DEA && ./dea-manager.sh check

# Run weekly updates on Sunday at 3 AM
0 3 * * 0 cd /home/eboalking/DEA && ./dea-manager.sh update
```

## Contributing

Feel free to improve these scripts by submitting pull requests or issues.