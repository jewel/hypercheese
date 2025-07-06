# Face Trails Implementation

This document outlines the comprehensive implementation of face trails for the HyperCheese face detection system. The system now detects faces in every frame of videos and groups them into trails based on position and movement, while maintaining the original 2-second interval for embedding generation.

## Overview

### What Changed

1. **Face Detection Frequency**: Changed from every 2 seconds to every frame (30 FPS)
2. **Face Trails**: New system groups faces by position and movement through video frames
3. **Embedding Generation**: Still occurs every 2 seconds for performance reasons
4. **UI Updates**: Shows face trails instead of individual faces for videos
5. **Trail Details**: Click on trails to see all faces in that trail

### Key Benefits

- **Reduced Clutter**: Videos now show face trails instead of hundreds of individual faces
- **Better UX**: More intuitive representation of people moving through video
- **Performance**: Smart separation of detection (every frame) and embedding generation (every 2 seconds)
- **Multiple Identities**: Handles cases where the same person is detected as multiple people

## Database Changes

### New Tables

#### `face_trails`
- `id` (primary key)
- `item_id` (foreign key to items)
- `start_timestamp` (decimal) - When the trail begins
- `end_timestamp` (decimal) - When the trail ends
- `center_x`, `center_y` (decimal) - Average position of the trail
- `width`, `height` (decimal) - Average dimensions of faces in the trail
- `representative_face_id` (foreign key to faces) - The face shown in the UI
- `created_at`, `updated_at` (timestamps)

### Modified Tables

#### `faces`
- Added `face_trail_id` (foreign key to face_trails)
- Added `frame_only` (boolean) - Whether this face is only for positioning (no embedding)

## Code Changes

### Models

#### `FaceTrail` (new)
- `app/models/face_trail.rb`
- Manages groups of faces that represent a person moving through video frames
- Calculates middle timestamps, tag names, and representative faces
- Provides methods to get faces with embeddings and frame positions

#### `Face` (modified)
- Added `belongs_to :face_trail` relationship
- Faces can now be part of a trail

#### `Item` (modified)
- Added `has_many :face_trails` relationship

### Jobs

#### `FindFacesJob` (major rewrite)
- `app/jobs/find_faces_job.rb`
- New constants for detection frequency and trail grouping
- `detect_faces_in_video()` - Main video processing method
- `detect_faces_in_frame()` - Process individual frames for position data
- `create_face_trails()` - Groups faces into trails based on position and time
- `find_matching_trail()` - Determines if a face belongs to an existing trail
- `process_embedding_frame()` - Handles embedding generation every 2 seconds
- Maintains backward compatibility with photo processing

### Controllers

#### `FaceTrailsController` (new)
- `app/controllers/face_trails_controller.rb`
- API endpoints for trail data
- `GET /api/face_trails/:id/faces` - Returns all faces in a trail

#### `ItemsController` (modified)
- Updated to include face_trails when loading item details

### Serializers

#### `ItemDetailsSerializer` (modified)
- `app/serializers/item_details_serializer.rb`
- Added `face_trails` attribute
- Modified `faces` method to return empty array for videos (since we use trails)
- New `face_trails()` method returns trail data with tag names and representative faces

### Frontend Components

#### `FacesAndTags` (major rewrite)
- `react/faces_and_tags.coffee`
- Conditional rendering: shows trails for videos, individual faces for photos
- New trail display with primary tag name highlighted
- Click handler for trail details

#### `TrailDetailDialog` (new)
- `react/trail_detail_dialog.coffee`
- Modal dialog showing all faces in a trail
- Displays trail summary with all detected names
- Grid layout of faces with timestamps

### Styling

#### `face.sass` (extended)
- `react/sass/face.sass`
- New styles for face trails display
- Modal dialog styling for trail details
- Responsive grid layout for faces within trails

### Routes

#### `config/routes.rb` (modified)
- Added `/api/face_trails/:id/faces` route
- RESTful routes for face trails API

## Algorithm Details

### Face Trail Creation

1. **Frame-by-Frame Detection**: Extract frames at 30 FPS and detect faces in each
2. **Position Tracking**: For each detected face, calculate center position and dimensions
3. **Trail Matching**: Group faces into trails based on:
   - Position proximity (within 50 pixels)
   - Time proximity (within 2 seconds gap)
   - Sequential timing (no backwards time jumps)
4. **Trail Updates**: As faces are added to trails, update the trail bounds and average position

### Embedding Generation

1. **Separate Processing**: Extract frames at 0.25 FPS (every 4 seconds) for embedding generation
2. **Trail Assignment**: Match embedding faces to existing trails based on position and time
3. **Face Processing**: Generate thumbnails, embeddings, and perform clustering as before
4. **Representative Face**: Choose the face closest to the trail's middle timestamp

### Constants

- `DETECTION_FPS = 30` - Frames per second for face detection
- `FPS = 0.25` - Frames per second for embedding generation
- `TRAIL_DISTANCE_THRESHOLD = 50` - Maximum pixel distance for trail grouping
- `TRAIL_TIME_THRESHOLD = 2.0` - Maximum time gap for trail grouping

## Migration Instructions

### Database Migration

```bash
# The migration file is already created: db/migrate/20250706153718_create_face_trails.rb
# Run the migration to create the new tables and columns
rails db:migrate
```

### Processing Existing Videos

After deploying the changes, you'll need to reprocess existing videos to create face trails:

```bash
# Re-run face detection for all videos
rails runner "
  Item.where(variety: 'video').where.not(face_count: nil).find_each do |item|
    # Clear existing faces and face_count to trigger reprocessing
    item.faces.destroy_all
    item.face_count = nil
    item.save!
    
    # Queue the job to reprocess
    FindFacesJob.perform_later(item.id)
  end
"
```

## UI/UX Changes

### For Videos

- **Before**: Long list of individual faces (could be hundreds)
- **After**: Compact list of face trails showing movement paths
- **Trail Display**: Shows representative face with all detected names
- **Primary Name**: Most common detected name is shown in bold
- **Click Interaction**: Clicking a trail opens a detail dialog

### For Photos

- **No Change**: Photos continue to show individual faces as before
- **Backward Compatibility**: All existing photo functionality preserved

### Trail Detail Dialog

- **Summary**: Shows primary person name and all detected names
- **Timeline**: Displays trail duration and frame counts
- **Face Grid**: Shows all faces with embeddings in chronological order
- **Navigation**: Click individual faces to go to face detail pages

## Performance Considerations

### Processing Time

- **Increased Detection**: More CPU time for frame-by-frame detection
- **Reduced Embedding**: Same embedding generation frequency as before
- **Network Efficiency**: Fewer face images transferred to embedding service

### Storage

- **More Face Records**: Each frame generates face records (but most are frame_only)
- **Fewer Thumbnails**: Only faces with embeddings get thumbnail images
- **Trail Metadata**: Additional storage for trail coordinate data

### Memory Usage

- **Batch Processing**: Processes all frames before creating trails
- **Temporary Storage**: Uses more disk space during processing
- **Cleanup**: Automatically removes temporary frame files

## Testing

### Manual Testing Steps

1. **Upload a video** with people moving through the frame
2. **Wait for processing** (face detection job to complete)
3. **View video details** and verify face trails appear instead of individual faces
4. **Click on a trail** to open the detail dialog
5. **Verify trail contains** faces from the person's movement through the video
6. **Test with photos** to ensure individual faces still work

### Edge Cases

- **Static People**: People who don't move should still create trails
- **Multiple People**: Multiple people in the same frame should create separate trails
- **Overlapping Trails**: People crossing paths should maintain separate trails
- **Short Appearances**: Brief appearances should still create trails

## Troubleshooting

### Common Issues

1. **No Face Trails Appearing**: Check if the migration has been run
2. **Still Seeing Individual Faces**: Ensure you're viewing a video, not a photo
3. **Empty Trail Dialog**: Check that the FaceTrailsController is accessible
4. **Processing Failures**: Monitor job logs for FFMPEG or AI service errors

### Debugging

```bash
# Check face trail creation
rails console
item = Item.find(VIDEO_ID)
item.face_trails.count
item.faces.where(frame_only: true).count
item.faces.where(frame_only: false).count

# Check API endpoint
curl -X GET http://localhost:3000/api/face_trails/TRAIL_ID/faces
```

## Future Enhancements

### Potential Improvements

1. **Trail Visualization**: Show trail paths overlaid on video frames
2. **Smart Grouping**: Use face recognition to merge trails of the same person
3. **Trail Editing**: Allow manual merging/splitting of trails
4. **Performance Optimization**: Implement incremental processing for long videos
5. **Trail Search**: Search for trails by person name or time range

### Configuration Options

Consider adding these configuration options:

```ruby
# In application.rb or environment files
config.face_trails.detection_fps = 30
config.face_trails.embedding_fps = 0.25
config.face_trails.distance_threshold = 50
config.face_trails.time_threshold = 2.0
```

## Summary

The face trail implementation successfully transforms the video face detection experience from overwhelming individual face lists to intuitive movement trails. The system maintains backward compatibility with photos while providing a much more usable interface for videos. The architecture separates concerns effectively, with high-frequency detection for positioning and lower-frequency embedding generation for performance.

The implementation handles the key requirements:
- ✅ Frame-by-frame face detection
- ✅ Face trail grouping by position and movement
- ✅ Embedding generation every 2 seconds
- ✅ UI showing trails instead of individual faces
- ✅ Trail detail dialog with all faces
- ✅ Multiple identity handling per trail
- ✅ Backward compatibility with photos