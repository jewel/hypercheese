# Google Pixel Slow Motion Video Metadata Research

## Key Findings

### Motion Photo Format
Google Pixel phones use the Motion Photo format which includes:
- XMP metadata in the `http://ns.google.com/photos/1.0/camera/` namespace
- `Camera:MotionPhotoPresentationTimestampUs` - presentation timestamp for the still image frame
- Potential metadata tracks with frame scoring and timing information
- `MotionPhotoFrameScoreDescriptor` with `presentationTimestampUs` for individual frames

### Metadata Extraction Methods
1. **FFprobe** - Can extract XMP metadata and technical video information
2. **ExifTool** - Advanced metadata extraction for XMP and proprietary formats
3. **JavaScript libraries** - For client-side metadata parsing

### Variable Speed Implementation
1. **HTML5 Video API** - `playbackRate` property for speed control
2. **Time-based segments** - Define start/end times with corresponding playback rates
3. **Event-driven playback** - Use `timeupdate` events to adjust speed in real-time

## Solution Architecture

### Backend Processing (Import Time)
- Extract metadata using FFprobe/ExifTool
- Parse XMP data for timing information
- Store speed segments in database
- Generate fallback segments if metadata is incomplete

### Frontend Playback (Runtime)
- JavaScript video controller with speed adjustment
- Segment-based playback rate changes
- Smooth transitions between speed zones
- Fallback to normal playback if metadata unavailable

## Implementation Plan

1. Create video metadata extraction service
2. Build JavaScript video player with variable speed support
3. Create database schema for speed segments
4. Implement import workflow
5. Add user interface controls

## References
- [Motion Photo Format Specification](https://developer.android.com/media/platform/motion-photo-format)
- [FFprobe Documentation](https://ffmpeg.org/ffprobe.html)
- [XMP Metadata Standards](http://www.adobe.com/devnet/xmp.html)