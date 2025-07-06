# Google Pixel Slow Motion Video Implementation Summary

## Overview
This implementation adds support for reading slow motion metadata markers from Google Pixel videos at import time and applying the same speed adjustments during JavaScript video playback.

## Implementation Status

### ✅ COMPLETED COMPONENTS

#### 1. Database Schema
- **File**: `db/migrate/20250102000000_create_video_speed_segments.rb`
- **Table**: `video_speed_segments`
- **Fields**:
  - `item_id` (foreign key to items)
  - `start_time`, `end_time` (decimal timestamps)
  - `playback_rate` (decimal speed multiplier)
  - `source_type` (extracted/manual/fallback)
  - `metadata` (JSON for additional data)
  - Proper indexes for performance

#### 2. Backend Models
- **File**: `app/models/video_speed_segment.rb`
  - Validations for time ranges and playback rates
  - Scopes for ordering and time-based queries
  - Helper methods for JSON serialization
- **File**: `app/models/item.rb` (updated)
  - `has_many :video_speed_segments` relationship
  - `has_slow_motion?`, `speed_segments_json`, `pixel_slow_motion?` methods
  - Integration with video processing pipeline

#### 3. Metadata Extraction Service
- **File**: `app/services/video_metadata_extractor.rb`
  - Uses FFprobe to extract video metadata and XMP data
  - Detects Pixel slow motion videos by camera make/model
  - Extracts speed segments from metadata with fallback patterns
  - Creates database records for segments

#### 4. Background Processing
- **File**: `app/jobs/extract_video_speed_segments_job.rb`
  - Async metadata extraction job
  - Integrated into video processing pipeline (`item.rb:schedule_jobs`)
  - Error handling and logging

#### 5. API Controller
- **File**: `app/controllers/video_speed_segments_controller.rb`
  - Full CRUD operations for speed segments
  - `/items/:id/video_speed_segments/extract` endpoint for metadata extraction
  - Proper authentication and authorization

#### 6. Frontend Components
- **File**: `react/video.coffee` (enhanced)
  - Accepts `speedSegments` prop
  - Real-time playback rate adjustment using `onTimeUpdate`
  - Smooth transitions between speed segments
- **File**: `react/speed_segment_editor.coffee`
  - Manual creation/editing of speed segments
  - Metadata extraction trigger
  - User-friendly time formatting and controls

#### 7. Serialization
- **File**: `app/serializers/item_details_serializer.rb` (updated)
  - Includes `speed_segments` in JSON responses
  - Proper integration with existing serialization

#### 8. Frontend Integration
- **File**: `react/details.coffee` (updated)
  - Passes `speedSegments={item.speed_segments || []}` to Video component
  - Proper integration with existing video player

### ❌ MISSING COMPONENTS

#### 1. Database Migration Execution
- **Status**: Migration created but not executed
- **Action Required**: Run `rails db:migrate` to create the table
- **Command**: `bundle exec rails db:migrate`

#### 2. Routes Configuration
- **Status**: ✅ COMPLETED - Routes added to `config/routes.rb`
- **Includes**: Nested routes for video speed segments under items resource

#### 3. Dependencies
- **FFprobe**: Required for metadata extraction
- **Installation**: `sudo apt-get install ffmpeg` (includes ffprobe)

## Setup Instructions

### 1. Install Dependencies
```bash
# Install FFmpeg (includes ffprobe)
sudo apt-get update
sudo apt-get install ffmpeg

# Verify installation
ffprobe -version
```

### 2. Run Database Migration
```bash
# Create the video_speed_segments table
bundle exec rails db:migrate

# Verify table creation
bundle exec rails db:schema:dump
```

### 3. Test the Implementation

#### Backend Testing
```bash
# Test metadata extraction
bundle exec rails console
> item = Item.where(variety: 'video').first
> extractor = VideoMetadataExtractor.new(item)
> extractor.extract_metadata
> extractor.extract_and_create_speed_segments!
```

#### Frontend Testing
1. Upload a Google Pixel slow motion video
2. View the video in the details page
3. Check that speed segments are applied during playback
4. Test the speed segment editor interface

### 4. Trigger Metadata Extraction for Existing Videos
```bash
# For all existing videos
bundle exec rails console
> Item.where(variety: 'video').find_each do |item|
>   ExtractVideoSpeedSegmentsJob.perform_later(item.id)
> end
```

## Key Features

### Automatic Detection
- Detects Google Pixel phones by camera make/model
- Extracts XMP metadata from Motion Photo format
- Creates fallback segments for detected Pixel videos

### Manual Editing
- Full CRUD interface for speed segments
- Real-time preview of changes
- Validation of segment overlaps and ranges

### Playback Integration
- Seamless speed adjustment during video playback
- Smooth transitions between segments
- Fallback to normal playback if no segments exist

### API Endpoints
- `GET /api/items/:id/video_speed_segments` - List segments
- `POST /api/items/:id/video_speed_segments` - Create segment
- `PUT /api/items/:id/video_speed_segments/:segment_id` - Update segment
- `DELETE /api/items/:id/video_speed_segments/:segment_id` - Delete segment
- `POST /api/items/:id/video_speed_segments/extract` - Extract from metadata

## Troubleshooting

### Common Issues

1. **FFprobe not found**
   - Install FFmpeg: `sudo apt-get install ffmpeg`
   - Check PATH includes ffprobe

2. **Migration errors**
   - Ensure database is running
   - Check migration file syntax
   - Verify Rails environment

3. **Speed segments not applying**
   - Check browser console for JavaScript errors
   - Verify API endpoints are returning data
   - Check video file format compatibility

4. **Metadata extraction fails**
   - Verify video file exists and is readable
   - Check FFprobe can read the file
   - Review extraction service logs

### Testing Commands
```bash
# Test FFprobe on a video file
ffprobe -v error -show_format -show_streams -of json /path/to/video.mp4

# Test metadata extraction
ffprobe -v error -show_entries format_tags -of json /path/to/video.mp4

# Check for XMP metadata
ffprobe -v error -select_streams m -show_entries stream_tags -of json /path/to/video.mp4
```

## Next Steps

1. **Deploy to Production**
   - Run migrations on production database
   - Monitor background job performance
   - Set up error monitoring for extraction failures

2. **Enhancements**
   - Add support for other phone manufacturers
   - Implement batch processing for large video libraries
   - Add user preferences for playback behavior

3. **Performance Optimization**
   - Cache extracted metadata
   - Optimize database queries
   - Implement lazy loading for large segment lists

## Technical Notes

### Metadata Format
The implementation expects Google Pixel Motion Photo format with XMP metadata in the `http://ns.google.com/photos/1.0/camera/` namespace. Key fields include:
- `Camera:MotionPhoto`
- `Camera:MotionPhotoPresentationTimestampUs`
- `make` and `model` for device detection

### Fallback Strategy
When specific metadata isn't available, the system:
1. Detects Pixel phones by make/model
2. Creates estimated segments (30% normal, 40% slow, 30% normal)
3. Allows manual refinement through the editor

### Browser Compatibility
- Uses HTML5 Video API `playbackRate` property
- Requires modern browsers with full video API support
- Gracefully degrades to normal playback on older browsers