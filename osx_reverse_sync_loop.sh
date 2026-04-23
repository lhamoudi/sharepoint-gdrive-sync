#!/bin/bash

# Script to sync Voice Ops & Engineering folder contents FROM Google Drive TO GitHub
# Workflow:
# 1. Sync files from Google Drive to local repository
# 2. Stage, commit, and push changes to GitHub repository
# 3. Optional: Repeat in continuous loop mode
# 
# Note: This script must be run from the root of a git repository

set -e  # Exit on any error

# Default values
LOOP_MODE=false
INTERVAL_MINUTES=30
SOURCE=""
DEST=""
COMMIT_MESSAGE=""
DRY_RUN=false
EXCLUDES=()

# Function to show help
show_help() {
    echo ""
    echo "NYL FILE SHARE REVERSE SYNC - OSX"
    echo "=================================="
    echo "Syncs files FROM Google Drive TO GitHub repository."
    echo ""
    echo "WORKFLOW:"
    echo "  1. Sync files from Google Drive to local repository"
    echo "  2. Stage, commit, and push changes to GitHub"
    echo "  3. Optional: Repeat in continuous loop mode"
    echo ""
    echo "USAGE:"
    echo "  ./osx_reverse_sync_loop.sh -s '/path/to/gdrive/source' -d '/path/to/local/dest'        # Run once"
    echo "  ./osx_reverse_sync_loop.sh -l -s '/path/to/gdrive/source' -d '/path/to/local/dest'    # Run continuously every 30 minutes"
    echo "  ./osx_reverse_sync_loop.sh -l -i 10 -s '/path/to/gdrive/source' -d '/path/to/local/dest'  # Run every 10 minutes"
    echo "  ./osx_reverse_sync_loop.sh -s '/path/to/gdrive/source' -d '/path/to/local/dest' --dry-run   # Test mode"
    echo "  ./osx_reverse_sync_loop.sh -h                                                         # Show this help"
    echo ""
    echo "OPTIONS:"
    echo "  -l, --loop                     Enable continuous loop mode"
    echo "  -i, --interval MINUTES        Interval between syncs (default: 30 minutes)"
    echo "  -s, --source PATH              [REQUIRED] Google Drive source directory path"
    echo "  -d, --destination PATH         [REQUIRED] Local repository destination directory path"
    echo "  -m, --message MESSAGE          Custom commit message"
    echo "  -e, --exclude PATTERN          Exclude files/folders matching PATTERN (repeatable)"
    echo "  --dry-run                      Test mode - show what would be done without making changes"
    echo "  -h, --help                     Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo '  ./osx_reverse_sync_loop.sh -s "/Users/$USER/Library/CloudStorage/GoogleDrive-user@company.com/Shared drives/Company/Project Files" -d "./Voice Ops & Engineering - Neuraflash Working Folder"'
    echo ""
    echo "Press Ctrl+C to stop the loop when running continuously."
    echo ""
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--loop)
            LOOP_MODE=true
            shift
            ;;
        -i|--interval)
            INTERVAL_MINUTES="$2"
            shift 2
            ;;
        -s|--source)
            SOURCE="$2"
            shift 2
            ;;
        -d|--destination)
            DEST="$2"
            shift 2
            ;;
        -m|--message)
            COMMIT_MESSAGE="$2"
            shift 2
            ;;
        -e|--exclude)
            EXCLUDES+=("$2")
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information."
            exit 1
            ;;
    esac
done

# Function to perform reverse sync operation (Google Drive -> GitHub)
perform_reverse_sync() {
    local start_time=$(date +%s)
    
    # Validate required parameters first
    if [ -z "$SOURCE" ]; then
        echo "ERROR: Google Drive source directory not specified"
        echo "Please specify a valid source path using -s parameter"
        echo "Example: ./osx_reverse_sync_loop.sh -s '/path/to/google/drive/source' -d '/path/to/local/destination'"
        return 1
    fi
    
    if [ -z "$DEST" ]; then
        echo "ERROR: Local destination directory not specified"
        echo "Please specify a valid destination path using -d parameter"
        echo "Example: ./osx_reverse_sync_loop.sh -s '/path/to/google/drive/source' -d '/path/to/local/destination'"
        return 1
    fi
    
    echo "========================================"
    echo " Reverse Sync: Google Drive → GitHub"
    echo " $(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================================"
    echo ""

    # Check if we're in a git repository
    if [ ! -d ".git" ]; then
        echo "ERROR: This script must be run from the root of a git repository"
        return 1
    fi

    # Step 1: Sync files from Google Drive to local repository
    echo "Step 1: Syncing files from Google Drive to local repository..."
    echo ""
    
    # Check if source directory exists
    if [ ! -d "$SOURCE" ]; then
        echo "ERROR: Google Drive source directory not found: $SOURCE"
        echo "Please verify the source path is correct"
        echo "Example: ./osx_reverse_sync_loop.sh -s '/path/to/google/drive/source' -d '/path/to/local/destination'"
        return 1
    fi

    echo "Source (Google Drive): $SOURCE"
    echo "Destination (Local Repo): $DEST"
    echo ""

    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would sync from: $SOURCE"
        echo "[DRY RUN] Would sync to: $DEST"
        echo "[DRY RUN] Would check git status"
        echo "[DRY RUN] Would stage, commit, and push changes"
        echo ""
        echo "Dry run completed successfully"
        return 0
    fi

    echo "Starting sync operation..."
    echo "Please wait, this may take several minutes depending on file size..."
    echo ""

    # Create destination directory if it doesn't exist
    if [ ! -d "$DEST" ]; then
        echo "Creating destination directory..."
        mkdir -p "$DEST"
    fi

    # Use rsync to sync from Google Drive to local repository
    echo "Running rsync from Google Drive..."
    # Build exclude args: hardcoded system/git files + any user-specified patterns
    RSYNC_EXCLUDES=(--exclude=".*" --exclude=".DS_Store" --exclude="Thumbs.db" --exclude="desktop.ini" --exclude=".git" --exclude=".gitignore")
    for pattern in "${EXCLUDES[@]}"; do
        RSYNC_EXCLUDES+=(--exclude="$pattern")
    done
    if [ ${#EXCLUDES[@]} -gt 0 ]; then
        echo "Excluding patterns: ${EXCLUDES[*]}"
    fi
    if rsync -av --delete --progress --human-readable \
        "${RSYNC_EXCLUDES[@]}" \
        "$SOURCE/" "$DEST/"; then
        
        SYNC_EXIT_CODE=0
    else
        SYNC_EXIT_CODE=$?
        echo "ERROR: Rsync operation failed with exit code $SYNC_EXIT_CODE"
        return $SYNC_EXIT_CODE
    fi

    echo ""
    echo "Step 2: Committing and pushing changes to GitHub..."
    echo ""

    # Pull latest remote changes before committing to reduce push conflicts
    echo "Pulling latest changes from remote..."
    if ! git pull --rebase; then
        echo "WARNING: git pull failed, continuing with push attempt"
    fi
    echo ""

    # Create commit message with timestamp if none provided
    if [ -z "$COMMIT_MESSAGE" ]; then
        COMMIT_MESSAGE="Update files from Google Drive - $(date '+%Y-%m-%d %H:%M:%S')"
    fi

    # Check git status
    echo "Checking repository status..."
    GIT_STATUS=$(git status --porcelain)
    
    if [ -z "$GIT_STATUS" ]; then
        echo "No changes detected in repository."
        echo ""
        echo "========================================"
        echo "Reverse sync completed - no changes to commit"
        echo "========================================"
        echo ""
    else
        echo "Changes detected, staging files..."
        if git add --all; then
            echo "Files staged successfully"
        else
            echo "ERROR: Failed to stage files"
            return 1
        fi

        echo "Committing changes..."
        if git commit -m "$COMMIT_MESSAGE"; then
            echo "Changes committed successfully"
        else
            echo "ERROR: Failed to commit changes"
            return 1
        fi

        echo "Pushing to remote repository..."
        if git push; then
            PUSH_OK=true
        else
            echo "Push rejected - pulling remote changes and retrying..."
            if git pull --rebase && git push; then
                PUSH_OK=true
            else
                PUSH_OK=false
            fi
        fi

        if [ "$PUSH_OK" = true ]; then
            echo ""
            echo "========================================"
            echo "Reverse sync completed successfully!"
            echo ""
            echo "Changes have been pushed to GitHub from:"
            echo "  Google Drive: $SOURCE"
            echo "  Local Repo: $DEST"
            echo "========================================"
            echo ""
        else
            echo "ERROR: Failed to push to remote repository"
            return 1
        fi
    fi

    # Show summary statistics
    echo "Checking synced files..."
    if [ -d "$DEST" ]; then
        FILE_COUNT=$(find "$DEST" -type f | wc -l | tr -d ' ')
        DIR_COUNT=$(find "$DEST" -type d | wc -l | tr -d ' ')
        echo "Total files in repository: $FILE_COUNT"
        echo "Total directories: $DIR_COUNT"
        
        # Show disk usage
        if command -v du >/dev/null 2>&1; then
            TOTAL_SIZE=$(du -sh "$DEST" | cut -f1)
            echo "Total size: $TOTAL_SIZE"
        fi
    else
        echo "No files were synced."
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local duration_formatted=$(printf "%02d:%02d:%02d" $((duration/3600)) $((duration%3600/60)) $((duration%60)))
    
    echo "Reverse sync duration: $duration_formatted"
    echo ""
    
    return 0
}

# Function to handle Ctrl+C gracefully
cleanup() {
    echo ""
    echo ""
    echo "========================================"
    echo " Reverse Sync Loop Stopped by User"
    echo "========================================"
    echo ""
    echo "Final Statistics:"
    echo "  Total runs: $((success_count + failure_count))"
    echo "  Successful: $success_count"
    echo "  Failed: $failure_count"
    
    if [ $start_time_global -gt 0 ]; then
        local end_time=$(date +%s)
        local total_uptime=$((end_time - start_time_global))
        local uptime_formatted=$(printf "%02d:%02d:%02d:%02d" $((total_uptime/86400)) $((total_uptime%86400/3600)) $((total_uptime%3600/60)) $((total_uptime%60)))
        echo "  Total uptime: $uptime_formatted"
    fi
    
    echo ""
    echo "Reverse sync loop terminated."
    exit 0
}

# Set up signal handler for Ctrl+C
trap cleanup SIGINT

# Main execution
if [ "$LOOP_MODE" = true ]; then
    echo "========================================"
    echo " Starting Continuous Reverse Sync Mode"
    echo "========================================"
    echo ""
    echo "Sync interval: $INTERVAL_MINUTES minutes"
    echo "Direction: Google Drive → GitHub"
    echo "Press Ctrl+C to stop the loop"
    echo ""
    
    success_count=0
    failure_count=0
    start_time_global=$(date +%s)
    
    while true; do
        cycle_start=$(date +%s)
        
        # Run reverse sync operation
        if perform_reverse_sync; then
            success_count=$((success_count + 1))
            echo "Reverse sync cycle completed successfully."
        else
            failure_count=$((failure_count + 1))
            echo "Reverse sync cycle failed."
        fi
        
        # Show statistics
        total_runs=$((success_count + failure_count))
        uptime=$(($(date +%s) - start_time_global))
        uptime_formatted=$(printf "%02d:%02d:%02d:%02d" $((uptime/86400)) $((uptime%86400/3600)) $((uptime%3600/60)) $((uptime%60)))
        
        echo ""
        echo "Statistics:"
        echo "  Total runs: $total_runs"
        echo "  Successful: $success_count"
        echo "  Failed: $failure_count"
        echo "  Uptime: $uptime_formatted"
        echo ""
        
        # Calculate next run time
        next_run=$(date -r $((cycle_start + INTERVAL_MINUTES * 60)) '+%Y-%m-%d %H:%M:%S')
        echo "Next reverse sync: $next_run"
        echo "Waiting $INTERVAL_MINUTES minutes..."
        
        # Wait for the specified interval with countdown
        interval_seconds=$((INTERVAL_MINUTES * 60))
        for ((i=interval_seconds; i>0; i--)); do
            remaining_minutes=$((i / 60))
            remaining_seconds=$((i % 60))
            
            # Update countdown every 30 seconds or last 10 seconds
            if [ $((i % 30)) -eq 0 ] || [ $i -le 10 ]; then
                printf "\rWaiting: %02d:%02d remaining..." "$remaining_minutes" "$remaining_seconds"
            fi
            
            sleep 1
        done
        
        printf "\r                                    \r"  # Clear the countdown line
    done
else
    # Single run mode
    if perform_reverse_sync; then
        echo "Single reverse sync operation completed."
        exit 0
    else
        echo "Single reverse sync operation failed."
        exit 1
    fi
fi