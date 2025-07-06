# File Reimport Implementation

This document explains the implementation of the file reimport system that handles file changes and duplicate file scenarios.

## Overview

The file reimport system automatically detects when files have changed (based on modification time and size) and handles reimporting them appropriately. It addresses the following scenarios:

1. **Single file change**: When a file with only one path changes, reimport it in place
2. **Duplicate file split**: When a file that has multiple paths changes, split it into a new item if other paths still exist
3. **Duplicate file reimport**: When a file that has multiple paths changes but no other paths exist, reimport it in place

## Key Components

### 1. Database Schema Changes

**Migration: `AddFileTrackingToItemPaths`**
- Adds `mtime` (datetime) and `size` (bigint) columns to `item_paths` table
- Adds composite index on `[source_id, path, mtime]` for efficient lookups

### 2. Model Updates

**ItemPath Model (`app/models/item_path.rb`)**
- `file_changed?`: Checks if file mtime or size has changed
- `get_current_file_stats`: Returns current file mtime and size
- `update_file_stats!`: Updates stored mtime and size values
- `file_exists?`: Checks if the file still exists on disk

### 3. File Reimport Service

**FileReimportService (`lib/file_reimport_service.rb`)**
- `check_and_reimport_all`: Processes all files for changes
- `check_and_reimport_item_path`: Handles a specific file path
- `reimport_existing_item`: Updates existing item when file changes
- `split_to_new_item`: Creates new item when duplicates need to be split

### 4. Import Module Updates

**Import Module (`lib/import.rb`)**
- Updated to track file stats during import
- Added `check_and_reimport_all` and `check_and_reimport_path` methods
- Enhanced duplicate detection with file stat updates

### 5. Job Updates

**GenerateThumbsJob (`app/jobs/generate_thumbs_job.rb`)**
- Added `force_regenerate` parameter to bypass existing thumbnail checks
- Added `needs_regeneration?` method to check if thumbnails are newer than source

**LoadMetadataJob (`app/jobs/load_metadata_job.rb`)**
- Added `force_reload` parameter to re-extract metadata even if it exists
- Enhanced to handle re-extraction scenarios

**Item Model (`app/models/item.rb`)**
- Added `schedule_jobs_with_force_regeneration` method for reimport scenarios

## File Change Detection Logic

```ruby
# Check if file has changed
if item_path.file_changed?
  # Determine action based on duplicate status
  all_paths = item_path.item.item_paths
  
  if all_paths.count == 1
    # Single file - reimport in place
    reimport_existing_item(item_path)
  else
    # Multiple files - check if others exist
    other_paths = all_paths - [item_path]
    existing_others = other_paths.select(&:file_exists?)
    
    if existing_others.any?
      # Other files exist - split to new item
      split_to_new_item(item_path)
    else
      # No other files exist - reimport in place
      reimport_existing_item(item_path)
    end
  end
end
```

## Usage

### Rake Tasks

```bash
# Check all files for changes and reimport
rake files:check_and_reimport

# Check a specific file path
rake files:check_path[/path/to/file.jpg]

# Initialize tracking for existing files
rake files:initialize_tracking

# Show file tracking statistics
rake files:stats
```

### Programmatic Usage

```ruby
# Check all files
Import.check_and_reimport_all

# Check specific path
Import.check_and_reimport_path("/path/to/file.jpg")

# Check specific ItemPath
service = FileReimportService.new
service.check_and_reimport_item_path(item_path)
```

## Job Re-execution

The system ensures that jobs handle re-execution properly:

1. **Thumbnail Generation**: 
   - Checks if thumbnails are newer than source files
   - Supports force regeneration flag
   - Handles photo rotation scenarios

2. **Metadata Loading**:
   - Supports force reload flag
   - Re-extracts EXIF data and video metadata
   - Updates dimensions and timestamps

3. **Other Jobs**:
   - Face detection and visual indexing are re-run
   - Geolocation processing is re-run

## File Scenarios Handled

### Scenario 1: Single File Modified
- **Before**: Item A has 1 path: `/photos/vacation.jpg`
- **Action**: File is modified (rotated, edited, etc.)
- **After**: Item A is reimported with new metadata, thumbnails regenerated

### Scenario 2: Duplicate Files - One Modified, Others Exist
- **Before**: Item A has 2 paths: `/photos/vacation.jpg`, `/backup/vacation.jpg`
- **Action**: `/photos/vacation.jpg` is modified
- **After**: 
  - Item A keeps `/backup/vacation.jpg`
  - New Item B created with `/photos/vacation.jpg`

### Scenario 3: Duplicate Files - One Modified, Others Gone
- **Before**: Item A has 2 paths: `/photos/vacation.jpg`, `/backup/vacation.jpg`
- **Action**: `/photos/vacation.jpg` is modified, `/backup/vacation.jpg` is deleted
- **After**: Item A is reimported with modified `/photos/vacation.jpg`

## Error Handling

- Files that no longer exist are skipped
- Unsupported file types are skipped with warnings
- MD5 collisions are handled by merging paths
- Failed operations are logged with details

## Performance Considerations

- Uses `find_each` for memory-efficient batch processing
- Includes associations to avoid N+1 queries
- Only processes files that have actually changed
- Indexes support efficient lookups

## Migration Path

1. **Run Migration**: `rails db:migrate`
2. **Initialize Tracking**: `rake files:initialize_tracking`
3. **Schedule Regular Checks**: Set up cron job or background task
4. **Monitor Results**: Use `rake files:stats` to monitor coverage

## Integration Points

The system integrates with:
- Existing import workflow
- Background job system
- File upload handlers
- CheeseBlob cloud storage system

## Future Enhancements

Potential improvements:
- File system watchers for real-time detection
- Batch processing optimizations
- Incremental backup integration
- Web interface for monitoring changes