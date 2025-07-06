# Google Pixel Motion Photo Support

This feature allows you to extract and play back the short videos embedded in Google Pixel Motion Photos.

## What are Motion Photos?

Google Pixel phones can capture "Motion Photos" - these are regular JPEG files that also contain a short video clip (1-3 seconds) embedded within them. The video captures motion before and after the photo was taken.

Motion photos are identified by:
- **Newer format**: Files named `PXL_[datetime].MP.jpg`
- **Older format**: Files named `MVIMG_[datetime].jpg`

## Features

- **Automatic Detection**: Motion photos are automatically detected during import
- **Video Extraction**: The embedded videos are extracted and stored separately
- **Gallery Integration**: Photos with motion videos show a play icon overlay
- **Seamless Playback**: Click on motion photos to toggle between photo and video
- **Keyboard Shortcuts**: Press 'M' to toggle motion video in detail view

## How It Works

1. **Import**: When photos are imported, the system checks if they're motion photos
2. **Extraction**: If detected, a background job extracts the embedded video
3. **Storage**: Videos are stored in `/public/data/motion_videos/`
4. **Display**: The gallery shows a play icon on motion photos
5. **Playback**: Users can click or press 'M' to play the motion video

## Setup and Usage

### Run the Database Migration

```bash
bundle exec rails db:migrate
```

### Extract Motion Videos from Existing Photos

To process existing photos in your gallery:

```bash
bundle exec rake motion_photos:extract
```

### List Motion Photos in Your System

```bash
bundle exec rake motion_photos:list
```

### Clean Up Orphaned Motion Videos

```bash
bundle exec rake motion_photos:cleanup
```

## User Interface

### Gallery View
- Motion photos display a small play icon overlay
- Hover over the icon to see it highlight

### Detail View
- Motion photos show a large play button overlay
- Click the photo or press 'M' to toggle between photo and video
- Video plays automatically and loops
- Motion video controls appear in yellow (distinct from regular video controls)

### Keyboard Shortcuts
- **Space**: Play/pause motion video (or navigate if not a motion photo)
- **M**: Toggle motion video for photos that have it
- **Arrow keys**: Navigate to next/previous item (stops any playing motion video)

## Technical Details

### File Detection
The system detects motion photos using:
1. Filename patterns (`PXL_*.MP.jpg`, `MVIMG_*.jpg`)
2. XMP metadata inspection for motion photo markers

### Video Extraction Methods
1. **XMP Metadata**: Preferred method using embedded metadata to find video offset/length
2. **Binary Search**: Fallback method searching for MP4 file headers

### Storage
- Motion videos are stored in `/public/data/motion_videos/`
- Filename format: `{item_id}-{item_code}.mp4`
- Videos are served directly by the web server

### Database
- `items.motion_video_path`: Stores the filename of the extracted video
- API includes `has_motion_video` and `motion_video_url` fields

## Troubleshooting

### Motion Videos Not Extracting
1. Check that the files are actually motion photos (filename or metadata)
2. Ensure the `motion_videos` directory is writable
3. Check Rails logs for extraction errors
4. Try running the extraction rake task manually

### Play Button Not Showing
1. Verify the item has `has_motion_video: true` in the API response
2. Check that the motion video file exists on disk
3. Ensure CSS is properly loaded

### Motion Video Not Playing
1. Check browser console for video loading errors
2. Verify the motion video URL is accessible
3. Ensure the extracted video file is valid (try opening directly)

## Development

### Adding Support for Other Motion Photo Formats
The `MotionPhotoExtractor` class can be extended to support other phone manufacturers:
1. Add new filename patterns
2. Add new metadata detection methods
3. Add new extraction algorithms

### Testing
Create test motion photos by placing them in the `originals/` directory and running import.

## Browser Compatibility

Motion video playback requires:
- HTML5 video support
- MP4 playback capability
- Modern JavaScript (ES6+)

Works on all modern browsers including Chrome, Firefox, Safari, and Edge.