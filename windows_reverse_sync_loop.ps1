param(
    [switch]$Loop,
    [int]$IntervalMinutes = 30,
    [string]$SourcePath,
    [string]$DestinationPath,
    [string]$CommitMessage,
    [string]$RepositoryPath = ".",
    [string[]]$ExcludeFolders = @(),
    [switch]$DryRun,
    [switch]$Help
)

if ($Help) {
    Write-Host ""
    Write-Host "NYL FILE SHARE REVERSE SYNC - WINDOWS" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "Syncs files FROM GitHub repository TO SharePoint/OneDrive."
    Write-Host "1. Pull latest changes from GitHub"
    Write-Host "2. Copy files from local repository to OneDrive/SharePoint"
    Write-Host "3. Optional: Run in continuous loop with configurable interval"
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\windows_reverse_sync_loop.ps1 -SourcePath 'C:\Path\To\Local\Repo' -DestinationPath 'C:\Path\To\OneDrive'"
    Write-Host "  .\windows_reverse_sync_loop.ps1 -Loop -SourcePath 'C:\Path\To\Local\Repo' -DestinationPath 'C:\Path\To\OneDrive'"
    Write-Host "  .\windows_reverse_sync_loop.ps1 -Loop -IntervalMinutes 10 -SourcePath 'C:\Path\To\Local\Repo' -DestinationPath 'C:\Path\To\OneDrive'"
    Write-Host "  .\windows_reverse_sync_loop.ps1 -SourcePath 'C:\Path\To\Local\Repo' -DestinationPath 'C:\Path\To\OneDrive' -DryRun"
    Write-Host "  .\windows_reverse_sync_loop.ps1 -Help                     # Show this help"
    Write-Host ""
    Write-Host "PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -Loop            Run continuously in a loop"
    Write-Host "  -IntervalMinutes Interval between sync runs (default: 30 minutes)"
    Write-Host "  -SourcePath      [REQUIRED] Local repository source path"
    Write-Host "  -DestinationPath [REQUIRED] OneDrive/SharePoint destination path"
    Write-Host "  -RepositoryPath  Git repository path (default: current directory)"
    Write-Host "  -ExcludeFolders  Folders to exclude from sync (comma-separated or repeated)"
    Write-Host "  -DryRun          Test mode - show what would be done"
    Write-Host "  -Help            Show this help message"
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host '  .\windows_reverse_sync_loop.ps1 -SourcePath "C:\Dev\nf-nyl-file-share\Voice Ops & Engineering - Neuraflash Working Folder" -DestinationPath "C:\Users\%USERNAME%\OneDrive - NEW YORK LIFE INSURANCE COMPANY\Voice Ops & Engineering - Neuraflash Working Folder"'
    Write-Host ""
    Write-Host "Press Ctrl+C to stop the loop when running continuously." -ForegroundColor Gray
    Write-Host ""
    exit 0
}

function Write-Header {
    param($Title, $Color = "Cyan")
    Write-Host ""
    Write-Host "========================================" -ForegroundColor $Color
    Write-Host " $Title" -ForegroundColor $Color
    Write-Host "========================================" -ForegroundColor $Color
    Write-Host ""
}

function Pull-FromGitHub {
    param(
        [string]$RepoPath,
        [bool]$DryRunMode
    )
    
    Write-Host "Step 1: Pulling latest changes from GitHub..." -ForegroundColor Yellow
    Write-Host ""
    
    # Change to repository directory if specified
    if ($RepoPath -and (Test-Path $RepoPath)) {
        Set-Location $RepoPath
    }

    # Check if we're in a git repository
    if (-not (Test-Path ".git")) {
        Write-Host "ERROR: This script must be run from the root of a git repository" -ForegroundColor Red
        Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
        return $false
    }

    if ($DryRunMode) {
        Write-Host "[DRY RUN] Would run: git pull" -ForegroundColor Magenta
        return $true
    }

    try {
        Write-Host "Running git pull..." -ForegroundColor Gray
        $output = git pull 2>&1
        $exitCode = $LASTEXITCODE
        
        Write-Host $output -ForegroundColor Gray
        
        if ($exitCode -eq 0) {
            Write-Host "Git pull completed successfully" -ForegroundColor Green
            return $true
        } else {
            Write-Host "WARNING: Git pull failed with exit code $exitCode" -ForegroundColor Yellow
            Write-Host "Continuing with sync operation using current files..." -ForegroundColor Yellow
            return $true  # Continue with current files even if pull fails
        }
    } catch {
        Write-Host "WARNING: Git pull failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "Continuing with sync operation using current files..." -ForegroundColor Yellow
        return $true  # Continue with current files even if pull fails
    }
}

function Copy-ToOneDrive {
    param(
        [string]$Source,
        [string]$Destination,
        [string[]]$Excludes = @(),
        [bool]$DryRunMode
    )
    
    Write-Host "Step 2: Copying files to OneDrive/SharePoint..." -ForegroundColor Yellow
    Write-Host ""
    
    # Validate required parameters
    if (-not $Source) {
        Write-Host "ERROR: Source path is required" -ForegroundColor Red
        Write-Host "Please specify a source path using -SourcePath parameter" -ForegroundColor Yellow
        Write-Host "Example: .\windows_reverse_sync_loop.ps1 -SourcePath 'C:\Path\To\Local\Repo' -DestinationPath 'C:\Path\To\OneDrive'" -ForegroundColor Gray
        return $false
    }

    if (-not $Destination) {
        Write-Host "ERROR: Destination path is required" -ForegroundColor Red
        Write-Host "Please specify a destination path using -DestinationPath parameter" -ForegroundColor Yellow
        Write-Host "Example: .\windows_reverse_sync_loop.ps1 -SourcePath 'C:\Path\To\Local\Repo' -DestinationPath 'C:\Path\To\OneDrive'" -ForegroundColor Gray
        return $false
    }

    # Check if source directory exists
    if (-not (Test-Path $Source)) {
        Write-Host "ERROR: Source directory not found: $Source" -ForegroundColor Red
        Write-Host "Please specify a valid source path using -SourcePath parameter" -ForegroundColor Yellow
        Write-Host "Example: .\windows_reverse_sync_loop.ps1 -SourcePath 'C:\Path\To\Local\Repo'" -ForegroundColor Gray
        return $false
    }

    Write-Host "Source (Local Repo): $Source" -ForegroundColor Yellow  
    Write-Host "Destination (OneDrive): $Destination" -ForegroundColor Yellow
    Write-Host ""

    if ($DryRunMode) {
        Write-Host "[DRY RUN] Would copy from: $Source" -ForegroundColor Magenta
        Write-Host "[DRY RUN] Would copy to: $Destination" -ForegroundColor Magenta
        if ($Excludes.Count -gt 0) {
            Write-Host "[DRY RUN] Would exclude folders: $($Excludes -join ', ')" -ForegroundColor Magenta
        }
        return $true
    }

    if ($Excludes.Count -gt 0) {
        Write-Host "Excluding folders: $($Excludes -join ', ')" -ForegroundColor Gray
    }

    # Create destination directory if it doesn't exist
    if (-not (Test-Path $Destination)) {
        Write-Host "Creating destination directory..." -ForegroundColor Gray
        try {
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        } catch {
            Write-Host "ERROR: Failed to create destination directory" -ForegroundColor Red
            return $false
        }
    }

    # Use Robocopy if available, otherwise fall back to PowerShell copy
    $robocopyCommand = Get-Command robocopy -ErrorAction SilentlyContinue
    if ($robocopyCommand) {
        Write-Host "Using Robocopy for file synchronization..." -ForegroundColor Gray
        try {
            # Robocopy parameters:
            # /MIR = Mirror directory tree (copy files AND delete orphaned files)
            # /R:3 = Retry 3 times on failed copies  
            # /W:5 = Wait 5 seconds between retries
            # /NFL = No file list (reduce output)
            # /NDL = No directory list (reduce output) 
            # /NP = No progress (reduce output)
            # /XA:SH = Exclude files with System or Hidden attributes
            # /XF = Exclude files matching pattern (dot files, git files)
            # /XD = Exclude directories (git directory)
            
            $robocopyArgs = @(
                "`"$Source`"",
                "`"$Destination`"", 
                "/MIR",
                "/R:3",
                "/W:5", 
                "/NFL",
                "/NDL",
                "/NP",
                "/XA:SH",
                "/XF", 
                ".*",
                ".gitignore",
                "/XD",
                ".git"
            )
            if ($Excludes.Count -gt 0) {
                $robocopyArgs += $Excludes | ForEach-Object { "`"$_`"" }
            }

            $process = Start-Process -FilePath "robocopy" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow
            $exitCode = $process.ExitCode
            
            # Robocopy exit codes: 0-7 are success, 8+ are errors
            if ($exitCode -le 7) {
                $messages = @{
                    0 = "No files copied"
                    1 = "Files copied successfully"  
                    2 = "Some extra files or directories detected"
                    3 = "Files copied and extra files detected"
                    4 = "Some mismatched files or directories detected"
                    5 = "Files copied and some mismatched files detected"
                    6 = "Extra and mismatched files detected" 
                    7 = "Files copied, extra and mismatched files detected"
                }
                
                Write-Host ""
                Write-Host "========================================" -ForegroundColor Green
                Write-Host "Reverse sync completed - $($messages[$exitCode])" -ForegroundColor Green
                # Write last_synced timestamp artifact to destination
                (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Set-Content -Path (Join-Path $Destination 'last_synced.txt')
                return $true
            } else {
                throw "Robocopy failed with exit code $exitCode"
            }
        } catch {
            Write-Host "ERROR: Robocopy operation failed: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "Using PowerShell for file synchronization..." -ForegroundColor Gray
        try {
            # Use PowerShell to copy files, excluding git-related files
            $excludePatterns = @(".*", ".git*")
            
            Get-ChildItem -Path $Source -Recurse | Where-Object {
                $relativePath = $_.FullName.Substring($Source.Length)
                $shouldExclude = $false
                foreach ($pattern in $excludePatterns) {
                    if ($_.Name -like $pattern -or $relativePath -like "*\.git\*") {
                        $shouldExclude = $true
                        break
                    }
                }
                -not $shouldExclude
            } | Copy-Item -Destination {
                $targetPath = $_.FullName.Replace($Source, $Destination)
                $targetDir = Split-Path $targetPath
                if (-not (Test-Path $targetDir)) {
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                }
                $targetPath
            } -Force
            
            Write-Host "File copy completed successfully." -ForegroundColor Green
            # Write last_synced timestamp artifact to destination
            (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Set-Content -Path (Join-Path $Destination 'last_synced.txt')
            return $true
        } catch {
            Write-Host "ERROR: PowerShell copy operation failed: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
}

function Run-ReverseSyncOperation {
    try {
        $pullSuccess = Pull-FromGitHub -RepoPath $RepositoryPath -DryRunMode $DryRun
        if (-not $pullSuccess) {
            Write-Host "Git pull operation failed." -ForegroundColor Red
            return $false
        }
        
        $copySuccess = Copy-ToOneDrive -Source $SourcePath -Destination $DestinationPath -Excludes $ExcludeFolders -DryRunMode $DryRun
        if (-not $copySuccess) {
            Write-Host "Copy operation failed." -ForegroundColor Red
            return $false
        }
        
        return $true
    }
    catch {
        Write-Host "ERROR: Reverse sync operation failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
Write-Header "NYL File Share Reverse Sync - Windows"

if ($Loop) {
    Write-Header "Starting Continuous Reverse Sync Mode" "Magenta"
    Write-Host "Sync interval: $IntervalMinutes minutes" -ForegroundColor Yellow
    Write-Host "Direction: GitHub → SharePoint/OneDrive" -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop the loop" -ForegroundColor Gray
    Write-Host ""
    
    $successCount = 0
    $failureCount = 0
    $startTime = Get-Date
    
    try {
        while ($true) {
            $cycleStart = Get-Date
            
            # Run reverse sync operation
            $success = Run-ReverseSyncOperation
            
            if ($success) {
                $successCount++
                Write-Host "Reverse sync cycle completed successfully." -ForegroundColor Green
            } else {
                $failureCount++
                Write-Host "Reverse sync cycle failed." -ForegroundColor Red
            }
            
            # Show statistics
            $totalRuns = $successCount + $failureCount
            $uptime = (Get-Date) - $startTime
            Write-Host ""
            Write-Host "Statistics:" -ForegroundColor Cyan
            Write-Host "  Total runs: $totalRuns" -ForegroundColor Gray
            Write-Host "  Successful: $successCount" -ForegroundColor Green
            Write-Host "  Failed: $failureCount" -ForegroundColor $(if ($failureCount -gt 0) { "Red" } else { "Gray" })
            Write-Host "  Uptime: $($uptime.ToString('dd\.hh\:mm\:ss'))" -ForegroundColor Gray
            Write-Host ""
            
            # Calculate next run time
            $nextRun = $cycleStart.AddMinutes($IntervalMinutes)
            Write-Host "Next reverse sync: $($nextRun.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Yellow
            Write-Host "Waiting $IntervalMinutes minutes..." -ForegroundColor Gray
            
            # Wait for the specified interval
            $intervalSeconds = $IntervalMinutes * 60
            for ($i = $intervalSeconds; $i -gt 0; $i--) {
                $remainingMinutes = [math]::Floor($i / 60)
                $remainingSeconds = $i % 60
                
                # Update countdown every 30 seconds or last 10 seconds
                if (($i % 30 -eq 0) -or ($i -le 10)) {
                    Write-Host "`rWaiting: ${remainingMinutes}:$('{0:D2}' -f $remainingSeconds) remaining..." -NoNewline -ForegroundColor DarkGray
                }
                
                Start-Sleep -Seconds 1
            }
            Write-Host "`r                                                    `r" -NoNewline  # Clear the countdown line
        }
    }
    catch [System.Management.Automation.PipelineStoppedException] {
        Write-Host ""
        Write-Host ""
        Write-Header "Reverse Sync Loop Stopped by User" "Yellow"
        Write-Host "Final Statistics:" -ForegroundColor Cyan
        Write-Host "  Total runs: $($successCount + $failureCount)" -ForegroundColor Gray
        Write-Host "  Successful: $successCount" -ForegroundColor Green
        Write-Host "  Failed: $failureCount" -ForegroundColor $(if ($failureCount -gt 0) { "Red" } else { "Gray" })
        Write-Host "  Total uptime: $((Get-Date) - $startTime | ForEach-Object { $_.ToString('dd\.hh\:mm\:ss') })" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Reverse sync loop terminated." -ForegroundColor Yellow
    }
} else {
    # Single run mode
    $success = Run-ReverseSyncOperation
    
    if ($success) {
        Write-Host "Single reverse sync operation completed." -ForegroundColor Green
    } else {
        Write-Host "Single reverse sync operation failed." -ForegroundColor Red
        exit 1
    }
}