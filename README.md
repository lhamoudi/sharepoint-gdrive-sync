# SharePoint ↔ GitHub ↔ Google Drive File Sync

Simple automated **bidirectional** file synchronization between SharePoint/OneDrive, a GitHub repository, and Google Drive.

## 📋 Overview

This toolkit provides **four automated sync solutions** for complete bidirectional synchronization:

### Forward Sync (SharePoint → Google Drive)
- **Windows**: Syncs files from SharePoint/OneDrive to GitHub repository
- **macOS**: Syncs files from GitHub repository to Google Drive

### Reverse Sync (Google Drive → SharePoint)
- **macOS**: Syncs files from Google Drive to GitHub repository
- **Windows**: Syncs files from GitHub repository to SharePoint/OneDrive

## 🔄 Bidirectional Workflow

```
SharePoint/OneDrive  ←→  GitHub Repository  ←→  Google Drive
        ↑                      ↑                    ↑
   Windows Forward        Central Hub          macOS Forward
   Windows Reverse                             macOS Reverse
```

## 🚀 Quick Start

### Forward Sync: SharePoint → Google Drive

#### Windows (SharePoint/OneDrive → GitHub)

```powershell
# Example with typical OneDrive path structure
# Run every 10 minutes
.\windows_sync_loop.ps1 -Loop -IntervalMinutes 10 `
  -SourcePath "C:\Users\%USERNAME%\OneDrive - YOUR COMPANY NAME\Your Project Folder" `
  -DestinationPath "C:\Path\To\Your\Local\Repository\Your Project Folder"

# One-time sync
.\windows_sync_loop.ps1 `
  -SourcePath "C:\Users\%USERNAME%\YOUR COMPANY NAME\Your Project Folder" `
  -DestinationPath "C:\Path\To\Your\Local\Repository\Your Project Folder"

# Test mode (see what would happen)
.\windows_sync_loop.ps1 `
  -SourcePath "C:\Users\%USERNAME%\OneDrive\Your Project Folder" `
  -DestinationPath "C:\Path\To\Your\Local\Repository\Your Project Folder" `
  -DryRun
```

#### macOS (GitHub → Google Drive)

```bash
# Example with typical path structure
# Run every 10 minutes
./osx_sync_loop.sh -l -i 10 `
  -s "/Users/$USER/code/github/your-repo/Your Project Folder" `
  -d "/Users/$USER/Library/CloudStorage/GoogleDrive-you@company.com/Shared drives/Your Shared Drive/Your Project/__Document Sync"

# One-time sync
./osx_sync_loop.sh `
  -s "/path/to/your/repository/Your Project Folder" `
  -d "/path/to/google/drive/sync/folder"

# Custom interval (60 minutes)
./osx_sync_loop.sh -l -i 60 `
  -s "/Users/$USER/code/github/your-repo/Your Project Folder" `
  -d "/Users/$USER/Library/CloudStorage/GoogleDrive-you@company.com/Shared drives/Company Name/Project Folder"
```

### Reverse Sync: Google Drive → SharePoint

#### macOS (Google Drive → GitHub)

```bash
# Example with typical path structure
# Run every 10 minutes
./osx_reverse_sync_loop.sh -l -i 10 `
  -s "/Users/$USER/Library/CloudStorage/GoogleDrive-you@company.com/Shared drives/Your Shared Drive/Your Project/__Document Sync" `
  -d "/Users/$USER/code/github/your-repo/Your Project Folder"

# One-time sync
./osx_reverse_sync_loop.sh `
  -s "/path/to/google/drive/sync/folder" `
  -d "/path/to/your/repository/Your Project Folder"

# Test mode (see what would happen)
./osx_reverse_sync_loop.sh `
  -s "/path/to/google/drive/sync/folder" `
  -d "/path/to/your/repository/Your Project Folder" `
  --dry-run
```

#### Windows (GitHub → SharePoint/OneDrive)

```powershell
# Example with typical OneDrive path structure
# Run every 10 minutes
.\windows_reverse_sync_loop.ps1 -Loop -IntervalMinutes 10 `
  -SourcePath "C:\Path\To\Your\Local\Repository\Your Project Folder" `
  -DestinationPath "C:\Users\%USERNAME%\OneDrive - YOUR COMPANY NAME\Your Project Folder"

# One-time sync
.\windows_reverse_sync_loop.ps1 `
  -SourcePath "C:\Path\To\Your\Local\Repository\Your Project Folder" `
  -DestinationPath "C:\Users\%USERNAME%\YOUR COMPANY NAME\Your Project Folder"

# Test mode (see what would happen)
.\windows_reverse_sync_loop.ps1 `
  -SourcePath "C:\Path\To\Your\Local\Repository\Your Project Folder" `
  -DestinationPath "C:\Users\%USERNAME%\OneDrive\Your Project Folder" `
  -DryRun
```

## 📁 Script Details

### Forward Sync Scripts

#### `windows_sync_loop.ps1`
**Purpose**: Copies files from OneDrive/SharePoint to local Git repository and pushes to GitHub

**Key Features**:
- Configurable source and destination paths
- Uses Robocopy for efficient file copying (when available)
- Automatic Git staging, committing, and pushing
- Loop mode with configurable intervals
- Comprehensive error handling and statistics

**Usage**:
```powershell
.\windows_sync_loop.ps1 [options]
```

**Parameters**:
- `-Loop` - Run continuously
- `-IntervalMinutes` - Minutes between sync cycles (default: 30)
- `-SourcePath` - **Required** - OneDrive source path
- `-DestinationPath` - **Required** - Local destination path
- `-CommitMessage` - Custom commit message
- `-ExcludeFolders` - Folders to exclude from sync (array)
- `-DryRun` - Test mode without making changes
- `-Help` - Show detailed help

#### `osx_sync_loop.sh`
**Purpose**: Pulls latest changes from Git and syncs to Google Drive

**Key Features**:
- Git pull before each sync operation
- Rsync-based file synchronization to Google Drive
- Loop mode with configurable intervals
- Real-time statistics and progress tracking
- Intelligent error handling

**Usage**:
```bash
./osx_sync_loop.sh [options]
```

**Parameters**:
- `-l, --loop` - Run continuously
- `-i, --interval MINUTES` - Minutes between sync cycles (default: 30)
- `-s, --source PATH` - **Required** - Source directory path
- `-d, --destination PATH` - **Required** - Destination directory path
- `-e, --exclude PATTERN` - Exclude files/folders matching PATTERN (repeatable)
- `-h, --help` - Show detailed help

### Reverse Sync Scripts

#### `osx_reverse_sync_loop.sh`
**Purpose**: Syncs files from Google Drive to local Git repository and pushes to GitHub

**Key Features**:
- Rsync-based file synchronization from Google Drive
- Automatic Git staging, committing, and pushing
- Loop mode with configurable intervals
- Dry-run mode for testing
- Comprehensive error handling and statistics

**Usage**:
```bash
./osx_reverse_sync_loop.sh [options]
```

**Parameters**:
- `-l, --loop` - Run continuously
- `-i, --interval MINUTES` - Minutes between sync cycles (default: 30)
- `-s, --source PATH` - **Required** - Google Drive source directory path
- `-d, --destination PATH` - **Required** - Local repository destination directory path
- `-m, --message MESSAGE` - Custom commit message
- `-e, --exclude PATTERN` - Exclude files/folders matching PATTERN (repeatable)
- `--dry-run` - Test mode without making changes
- `-h, --help` - Show detailed help

#### `windows_reverse_sync_loop.ps1`
**Purpose**: Pulls latest changes from GitHub and copies files to OneDrive/SharePoint

**Key Features**:
- Git pull before each sync operation
- Uses Robocopy for efficient file copying (when available)
- Loop mode with configurable intervals
- Comprehensive error handling and statistics
- Excludes Git-related files from sync

**Usage**:
```powershell
.\windows_reverse_sync_loop.ps1 [options]
```

**Parameters**:
- `-Loop` - Run continuously
- `-IntervalMinutes` - Minutes between sync cycles (default: 30)
- `-SourcePath` - **Required** - Local repository source path
- `-DestinationPath` - **Required** - OneDrive/SharePoint destination path
- `-RepositoryPath` - Git repository path (default: current directory)
- `-ExcludeFolders` - Folders to exclude from sync (array)
- `-DryRun` - Test mode without making changes
- `-Help` - Show detailed help

## � Bidirectional Sync Setup

### Complete Setup Instructions

1. **Set up GitHub Repository**:
   - Ensure you have a Git repository initialized
   - Configure Git credentials for automated pushing
   - Set up appropriate .gitignore file

2. **Forward Sync (SharePoint → Google Drive)**:
   - Run `windows_sync_loop.ps1` on Windows machine with SharePoint access
   - Run `osx_sync_loop.sh` on macOS machine with Google Drive access
   
3. **Reverse Sync (Google Drive → SharePoint)**:
   - Run `osx_reverse_sync_loop.sh` on macOS machine with Google Drive access
   - Run `windows_reverse_sync_loop.ps1` on Windows machine with SharePoint access

### Best Practices

- **Avoid Conflicts**: Don't run forward and reverse sync simultaneously on the same files
- **Test First**: Use `-DryRun` or `--dry-run` options to test before actual sync
- **Monitor Logs**: Check sync statistics and watch for failed cycles
- **Stagger Intervals**: Use different intervals for forward/reverse sync to prevent conflicts
- **Backup Important Data**: Always maintain backups before setting up bidirectional sync

### Recommended Sync Schedule

```
Forward Sync:  Every 30 minutes during business hours
Reverse Sync:  Every 60 minutes during off hours
```

Or use manual triggers for specific sync operations to maintain control.

### Conflict Resolution

If conflicts occur:
1. Stop all sync operations immediately
2. Manually resolve conflicts in the GitHub repository
3. Ensure all platforms have the correct version
4. Restart sync operations with appropriate intervals

## �🛠️ Setup Requirements

### Windows
- PowerShell 5.1 or later
- Git installed and configured
- Access to OneDrive/SharePoint with project folder
- GitHub repository with push permissions

### macOS
- Bash shell
- Git installed and configured
- Google Drive mounted and accessible
- GitHub repository with pull permissions

## 💡 Common Usage Patterns

```powershell
# Windows: Continuous sync every 10 minutes (recommended)
.\windows_sync_loop.ps1 -Loop -IntervalMinutes 10 `
  -SourcePath "C:\Users\YourUsername\YOUR COMPANY NAME\Your Project Folder" `
  -DestinationPath "Your Project Folder"

# Windows: One-time sync with custom commit message
.\windows_sync_loop.ps1 `
  -SourcePath "C:\Users\YourUsername\YOUR COMPANY NAME\Your Project Folder" `
  -DestinationPath "Your Project Folder" `
  -CommitMessage "Manual update"

# Windows: Test what would be synced
.\windows_sync_loop.ps1 `
  -SourcePath "C:\Users\YourUsername\YOUR COMPANY NAME\Your Project Folder" `
  -DestinationPath "Your Project Folder" `
  -DryRun
```

```bash
# macOS: Continuous sync every 10 minutes (recommended)
./osx_sync_loop.sh -l -i 10 \
  -s 'Your Project Folder' \
  -d '/Users/yourusername/Library/CloudStorage/GoogleDrive-you@company.com/Shared drives/Your Shared Drive/Your Project/__Document Sync'

# macOS: One-time sync
./osx_sync_loop.sh \
  -s 'Your Project Folder' \
  -d '/Users/yourusername/Library/CloudStorage/GoogleDrive-you@company.com/Shared drives/Your Shared Drive/Your Project/__Document Sync'

# macOS: Sync while excluding specific folders
./osx_sync_loop.sh -l -i 10 \
  -s 'Your Project Folder' \
  -d '/Users/yourusername/Library/CloudStorage/GoogleDrive-you@company.com/Shared drives/Your Shared Drive/Your Project/__Document Sync' \
  -e 'Archive' -e 'UAT Screenshots'

# macOS: Reverse sync (Google Drive → GitHub) excluding a folder
./osx_reverse_sync_loop.sh -l -i 10 \
  -s '/Users/yourusername/Library/CloudStorage/GoogleDrive-you@company.com/Shared drives/Your Shared Drive/Your Project/__Document Sync' \
  -d 'Your Project Folder' \
  -e 'Meeting recordings'
```

## 🔧 Troubleshooting

### Windows Issues

**"Execution Policy" Error**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**"OneDrive Path Not Found"**:
- Ensure you provide valid `-SourcePath` and `-DestinationPath` parameters
- Verify the OneDrive folder exists and is synced
- Use full absolute paths for best results

**Git Push Failures**:
- Verify Git credentials are configured
- Check repository permissions
- Ensure you're in the correct Git repository

### macOS Issues

**"Permission Denied"**:
```bash
chmod +x osx_sync_loop.sh
```

**"Source/Destination Not Found"**:
- Ensure you provide valid `-s` (source) and `-d` (destination) parameters
- Check that Google Drive is mounted and accessible
- Use absolute paths for best results
- Verify file permissions on both source and destination folders

**Git Pull Failures**:
- Verify Git credentials are configured
- Check repository permissions
- Ensure you're in a Git repository directory

## 📊 Monitoring

Both scripts provide real-time statistics when running in loop mode:
- Total sync cycles completed
- Success/failure counts
- Uptime tracking
- Next sync countdown

Press `Ctrl+C` to stop loop mode and see final statistics.

## 🔒 Security Features

- No hardcoded paths or credentials
- Uses existing Git and system authentication
- Configurable paths provided at runtime
- Dry-run mode for testing without changes