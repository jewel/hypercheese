# Usage Examples for Google Pixel Slow Motion Video Implementation

## Backend Usage Examples

### 1. Extract Metadata from a Video
```ruby
# In Rails console or application code
item = Item.find(123)  # Replace with actual video item ID
extractor = VideoMetadataExtractor.new(item)

# Extract all metadata
metadata = extractor.extract_metadata
puts metadata[:is_pixel_slow_motion]  # true/false
puts metadata[:basic_info]            # Video duration, dimensions, etc.

# Extract and save speed segments
segments_created = extractor.extract_and_create_speed_segments!
puts "Created #{item.video_speed_segments.count} segments"
```

### 2. Manually Create Speed Segments
```ruby
# Create a slow motion segment manually
item = Item.find(123)
segment = item.video_speed_segments.create!(
  start_time: 5.0,        # Start at 5 seconds
  end_time: 15.0,         # End at 15 seconds
  playback_rate: 0.25,    # 1/4 speed (slow motion)
  source_type: 'manual',
  metadata: { note: 'Manually created slow motion segment' }.to_json
)

# Create multiple segments for a video
segments_data = [
  { start_time: 0.0, end_time: 5.0, playback_rate: 1.0 },    # Normal speed
  { start_time: 5.0, end_time: 15.0, playback_rate: 0.25 },  # Slow motion
  { start_time: 15.0, end_time: 20.0, playback_rate: 1.0 }   # Normal speed
]

segments_data.each do |data|
  item.video_speed_segments.create!(
    start_time: data[:start_time],
    end_time: data[:end_time],
    playback_rate: data[:playback_rate],
    source_type: 'manual'
  )
end
```

### 3. Query Speed Segments
```ruby
item = Item.find(123)

# Check if video has slow motion segments
if item.has_slow_motion?
  puts "Video has slow motion segments"
end

# Get all segments ordered by start time
segments = item.video_speed_segments.ordered
segments.each do |segment|
  puts "#{segment.start_time}s-#{segment.end_time}s: #{segment.playback_rate}x speed"
end

# Find segment for a specific time
current_time = 10.5
segment = item.video_speed_segments.for_time(current_time).first
puts "At #{current_time}s: #{segment&.playback_rate || 1.0}x speed"

# Get JSON for frontend
json_segments = item.speed_segments_json
puts json_segments
```

### 4. Background Processing
```ruby
# Queue extraction job for a video
ExtractVideoSpeedSegmentsJob.perform_later(item.id)

# Process all existing videos
Item.where(variety: 'video').find_each do |item|
  ExtractVideoSpeedSegmentsJob.perform_later(item.id)
end

# Process with priority
ExtractVideoSpeedSegmentsJob.set(priority: 1).perform_later(item.id)
```

## Frontend Usage Examples

### 1. Using the Enhanced Video Component
```coffeescript
# In your React component
<Video
  videoRef={videoRef}
  setPlaying={setPlaying}
  toggleControls={toggleControls}
  showControls={showControls}
  poster={posterUrl}
  itemId={itemId}
  itemCode={itemCode}
  speedSegments={item.speed_segments || []}
/>
```

### 2. Using the Speed Segment Editor
```coffeescript
# In your React component
<SpeedSegmentEditor
  itemId={itemId}
  segments={item.speed_segments || []}
  onSegmentsChange={(newSegments) -> 
    # Handle segment changes
    console.log('Segments updated:', newSegments)
  }
/>
```

### 3. Manual Speed Segment Creation
```coffeescript
# Example of programmatically creating segments
segments = [
  {
    start_time: 0.0,
    end_time: 5.0,
    playback_rate: 1.0,
    source_type: 'manual'
  },
  {
    start_time: 5.0,
    end_time: 15.0,
    playback_rate: 0.25,
    source_type: 'manual'
  },
  {
    start_time: 15.0,
    end_time: 20.0,
    playback_rate: 1.0,
    source_type: 'manual'
  }
]

# These would be passed to the Video component
<Video speedSegments={segments} {...otherProps} />
```

## API Usage Examples

### 1. Get Speed Segments for a Video
```javascript
// GET /api/items/123/video_speed_segments
fetch('/api/items/123/video_speed_segments')
  .then(response => response.json())
  .then(segments => {
    console.log('Speed segments:', segments);
  });
```

### 2. Create a New Speed Segment
```javascript
// POST /api/items/123/video_speed_segments
const segmentData = {
  video_speed_segment: {
    start_time: 5.0,
    end_time: 15.0,
    playback_rate: 0.25,
    metadata: JSON.stringify({ note: 'Slow motion section' })
  }
};

fetch('/api/items/123/video_speed_segments', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
  },
  body: JSON.stringify(segmentData)
})
.then(response => response.json())
.then(segment => {
  console.log('Created segment:', segment);
});
```

### 3. Extract Segments from Metadata
```javascript
// POST /api/items/123/video_speed_segments/extract
fetch('/api/items/123/video_speed_segments/extract', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
  }
})
.then(response => response.json())
.then(data => {
  console.log(data.message);
  console.log('Extracted segments:', data.segments);
});
```

### 4. Update an Existing Segment
```javascript
// PUT /api/items/123/video_speed_segments/456
const updateData = {
  video_speed_segment: {
    start_time: 6.0,
    end_time: 14.0,
    playback_rate: 0.5
  }
};

fetch('/api/items/123/video_speed_segments/456', {
  method: 'PUT',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
  },
  body: JSON.stringify(updateData)
})
.then(response => response.json())
.then(segment => {
  console.log('Updated segment:', segment);
});
```

### 5. Delete a Speed Segment
```javascript
// DELETE /api/items/123/video_speed_segments/456
fetch('/api/items/123/video_speed_segments/456', {
  method: 'DELETE',
  headers: {
    'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
  }
})
.then(response => {
  if (response.ok) {
    console.log('Segment deleted');
  }
});
```

## Common Use Cases

### 1. Auto-detect and Apply Slow Motion
```ruby
# When a video is uploaded
item = Item.find(video_id)
if item.pixel_slow_motion?
  ExtractVideoSpeedSegmentsJob.perform_later(item.id)
end
```

### 2. Bulk Processing Existing Videos
```ruby
# Process all Pixel videos
Item.where(variety: 'video').find_each do |item|
  if item.pixel_slow_motion?
    ExtractVideoSpeedSegmentsJob.perform_later(item.id)
  end
end
```

### 3. Custom Speed Patterns
```ruby
# Create custom speed patterns
def create_wave_pattern(item, duration)
  segments = []
  segment_duration = duration / 10
  
  (0...10).each do |i|
    start_time = i * segment_duration
    end_time = (i + 1) * segment_duration
    
    # Create wave pattern: slow-fast-slow-fast...
    rate = i.even? ? 0.5 : 1.5
    
    segments << {
      start_time: start_time,
      end_time: end_time,
      playback_rate: rate,
      source_type: 'manual'
    }
  end
  
  segments.each do |data|
    item.video_speed_segments.create!(data)
  end
end

# Usage
item = Item.find(123)
create_wave_pattern(item, 30.0)  # 30 second video
```

### 4. Validate Video Playback
```coffeescript
# Check if video has speed segments and apply them
checkVideoCapabilities = (videoElement, segments) ->
  if segments && segments.length > 0
    # Test if browser supports playback rate changes
    if videoElement.playbackRate?
      console.log('Browser supports variable playback rates')
      return true
    else
      console.log('Browser does not support variable playback rates')
      return false
  else
    console.log('No speed segments defined')
    return false

# Usage in component
React.useEffect ->
  if videoRef.current && speedSegments.length > 0
    supported = checkVideoCapabilities(videoRef.current, speedSegments)
    unless supported
      console.warn('Variable speed playback not supported')
, [videoRef, speedSegments]
```

## Testing Examples

### 1. Test Metadata Extraction
```ruby
# Test with actual video file
item = Item.find(123)
extractor = VideoMetadataExtractor.new(item)

# Check if file exists
puts "File exists: #{File.exist?(item.full_path)}"

# Test FFprobe
cmd = ['ffprobe', '-v', 'error', '-show_format', '-of', 'json', item.full_path]
stdout, stderr, status = Open3.capture3(*cmd)
puts "FFprobe status: #{status.success?}"
puts "FFprobe output: #{stdout[0..200]}..."

# Test extraction
metadata = extractor.extract_metadata
puts "Metadata keys: #{metadata.keys}"
puts "Basic info: #{metadata[:basic_info]}"
```

### 2. Test Frontend Integration
```javascript
// Test in browser console
const video = document.querySelector('video');
const segments = [
  { start_time: 0, end_time: 5, playback_rate: 1.0 },
  { start_time: 5, end_time: 10, playback_rate: 0.5 },
  { start_time: 10, end_time: 15, playback_rate: 1.0 }
];

// Test playback rate changes
video.addEventListener('timeupdate', () => {
  const currentTime = video.currentTime;
  const segment = segments.find(s => 
    currentTime >= s.start_time && currentTime < s.end_time
  );
  
  if (segment && video.playbackRate !== segment.playback_rate) {
    console.log(`Changing speed to ${segment.playback_rate}x at ${currentTime}s`);
    video.playbackRate = segment.playback_rate;
  }
});
```

This implementation provides a complete system for handling Google Pixel slow motion videos with both automatic detection and manual editing capabilities.