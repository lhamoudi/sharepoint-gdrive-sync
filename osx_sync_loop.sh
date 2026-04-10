#!/bin/bash

# Script to sync Voice Ops & Engineering folder contents with loop option
# Workflow:
# 1. Pull latest changes from Git repository
# 2. Sync files from local repository to Google Drive
# 3. Optional: Repeat in continuous loop mode
# 
# Note: This script must be run from the root of a git repository

set -e  # Exit on any error

# Default values
LOOP_MODE=false
INTERVAL_MINUTES=30
SOURCE=""
DEST=""
EXCLUDES=()

# Function to show help
show_help() {
    echo ""
    echo "NYL FILE SHARE SYNC - OSX"
    echo "=========================="
    echo "Pulls latest changes from Git and syncs Voice Ops & Engineering folder to Google Drive."
    echo ""
    echo "WORKFLOW:"
    echo "  1. Pull latest changes from Git repository"
    echo "  2. Sync files from local repository to Google Drive"
    echo "  3. Optional: Repeat in continuous loop mode"
    echo ""
    echo "USAGE:"
    echo "  ./osx_sync_loop.sh -s '/path/to/source' -d '/path/to/dest'                    # Run once"
    echo "  ./osx_sync_loop.sh -l -s '/path/to/source' -d '/path/to/dest'                # Run continuously every 30 minutes"
    echo "  ./osx_sync_loop.sh -l -i 10 -s '/path/to/source' -d '/path/to/dest'          # Run every 10 minutes"
    echo "  ./osx_sync_loop.sh -h                                                         # Show this help"
    echo ""
    echo "OPTIONS:"
    echo "  -l, --loop                     Enable continuous loop mode"
    echo "  -i, --interval MINUTES        Interval between syncs (default: 30 minutes)"
    echo "  -s, --source PATH              [REQUIRED] Source directory path"
    echo "  -d, --destination PATH         [REQUIRED] Destination directory path"
    echo "  -e, --exclude PATTERN          Exclude files/folders matching PATTERN (repeatable)"
    echo "  -h, --help                     Show this help message"
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
        -e|--exclude)
            EXCLUDES+=("$2")
            shift 2
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

# Function to perform sync operation
perform_sync() {
    local start_time=$(date +%s)
    
    # Validate required parameters first
    if [ -z "$SOURCE" ]; then
        echo "ERROR: Source directory not specified"
        echo "Please specify a valid source path using -s parameter"
        echo "Example: ./osx_sync_loop.sh -s '/path/to/source' -d '/path/to/destination'"
        return 1
    fi
    
    if [ -z "$DEST" ]; then
        echo "ERROR: Destination directory not specified"
        echo "Please specify a valid destination path using -d parameter"
        echo "Example: ./osx_sync_loop.sh -s '/path/to/source' -d '/path/to/destination'"
        return 1
    fi
    
    echo "========================================"
    echo " Syncing Voice Ops & Engineering Files"
    echo " $(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================================"
    echo ""

    # Step 1: Pull latest changes from Git
    echo "Step 1: Pulling latest changes from Git repository..."
    echo ""
    
    # Check if we're in a git repository
    if [ ! -d ".git" ]; then
        echo "ERROR: This script must be run from the root of a git repository"
        return 1
    fi
    
    # Pull latest changes
    echo "Running git pull..."
    if git pull; then
        echo "Git pull completed successfully"
    else
        local git_exit_code=$?
        echo "WARNING: Git pull failed with exit code $git_exit_code"
        echo "Continuing with sync operation using current files..."
        echo ""
    fi
    
    echo ""
    echo "Step 2: Syncing files to Google Drive..."
    echo ""
    
    # Check if source directory exists
    if [ ! -d "$SOURCE" ]; then
        echo "ERROR: Source directory not found: $SOURCE"
        echo "Please verify the source path is correct"
        echo "Example: ./osx_sync_loop.sh -s '/path/to/source' -d '/path/to/destination'"
        return 1
    fi

    echo "Source: $SOURCE"
    echo "Destination: $DEST"
    echo ""
    echo "Starting sync operation..."
    echo "Please wait, this may take several minutes depending on file size..."
    echo ""

    # Create destination directory if it doesn't exist
    if [ ! -d "$DEST" ]; then
        echo "Creating destination directory..."
        mkdir -p "$DEST"
    fi

    # Use rsync to mirror the directory
    echo "Running rsync..."
    # Build exclude args: hardcoded system files + any user-specified patterns
    RSYNC_EXCLUDES=(--exclude=".*" --exclude=".DS_Store" --exclude="Thumbs.db" --exclude="desktop.ini")
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
    fi

    echo ""
    echo "========================================"
    if [ $SYNC_EXIT_CODE -eq 0 ]; then
        echo "Sync operation completed successfully!"
        echo ""
        echo "Files have been synced to:"
        echo "$DEST"
        # Write last_synced timestamp artifact to destination
        echo "$(date '+%Y-%m-%d %H:%M:%S')" > "$DEST/last_synced.txt"
    else
        echo "ERROR: Sync operation failed with exit code $SYNC_EXIT_CODE"
        echo "Please check the paths and permissions, then try again."
        return $SYNC_EXIT_CODE
    fi
    echo "========================================"
    echo ""

    # Show summary statistics
    echo "Checking synced files..."
    if [ -d "$DEST" ]; then
        FILE_COUNT=$(find "$DEST" -type f | wc -l | tr -d ' ')
        DIR_COUNT=$(find "$DEST" -type d | wc -l | tr -d ' ')
        echo "Total files synced: $FILE_COUNT"
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
    
    echo "Sync duration: $duration_formatted"
    echo ""
    
    return $SYNC_EXIT_CODE
}

# Function to handle Ctrl+C gracefully
cleanup() {
    echo ""
    echo ""
    echo "========================================"
    echo " Sync Loop Stopped by User"
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
    echo "Sync loop terminated."
    exit 0
}

# Set up signal handler for Ctrl+C
trap cleanup SIGINT

# Main execution
if [ "$LOOP_MODE" = true ]; then
    echo "========================================"
    echo " Starting Continuous Sync Mode"
    echo "========================================"
    echo ""
    echo "Sync interval: $INTERVAL_MINUTES minutes"
    echo "Press Ctrl+C to stop the loop"
    echo ""
    
    success_count=0
    failure_count=0
    start_time_global=$(date +%s)
    
    while true; do
        cycle_start=$(date +%s)
        
        # Run sync operation
        if perform_sync; then
            success_count=$((success_count + 1))
            echo "Sync cycle completed successfully."
        else
            failure_count=$((failure_count + 1))
            echo "Sync cycle failed."
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
        echo "Next sync: $next_run"
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
    if perform_sync; then
        echo "Single sync operation completed."
        exit 0
    else
        echo "Single sync operation failed."
        exit 1
    fi
fi