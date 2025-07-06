# EXIF Data Storage and Search Functionality

## Overview

This implementation adds comprehensive EXIF data storage and search capabilities to the photo management system. EXIF data is now read at import time, stored in the database, and made searchable.

## Features

### 1. EXIF Data Storage
- EXIF data is extracted during photo import (via `LoadMetadataJob`)
- Data is stored as JSON in the `items.exif_data` column
- Values larger than 1KB are automatically filtered out to prevent database bloat
- Supports both EXIFR library and exiftool fallback

### 2. Database Schema Changes
- Added `exif_data` TEXT column to `items` table
- Added JSON validation constraint to ensure data integrity
- Uses UTF8MB4 collation for proper Unicode support

### 3. API Endpoints

#### Search by EXIF Data
```
POST /api/items/search_by_exif
```

**Parameters:**
- `exif_conditions` (Hash): Multiple field search conditions
- `field` (String): Single field name for simple search
- `value` (String): Value to search for
- `limit` (Integer): Maximum results to return (default: 100)
- `offset` (Integer): Offset for pagination (default: 0)

**Example Requests:**
```javascript
// Search for photos taken with a specific camera
POST /api/items/search_by_exif
{
  "exif_conditions": {
    "camera_model_name": "Canon EOS R5",
    "make": "Canon"
  }
}

// Search for photos with specific ISO
POST /api/items/search_by_exif
{
  "field": "iso",
  "value": "1600"
}
```

#### Get Available EXIF Fields
```
GET /api/items/:id/exif_fields
```

Returns a list of available EXIF fields for a specific item.

**Example Response:**
```json
{
  "fields": [
    "camera_model_name",
    "make",
    "iso",
    "f_number",
    "exposure_time",
    "focal_length",
    "date_time_original",
    "gps_latitude",
    "gps_longitude"
  ]
}
```

### 4. Model Methods

#### Item Model
- `Item.search_by_exif(field, value)`: Search by single EXIF field
- `Item.search_by_exif_fields(conditions)`: Search by multiple EXIF fields
- `item.exif`: Returns parsed EXIF data from database (with file fallback)
- `item.exif_field(field)`: Get specific EXIF field value
- `item.parsed_exif_data`: Returns OpenStruct with EXIF data

### 5. Performance Optimizations
- EXIF data is read only once during import
- Database queries use JSON_EXTRACT for efficient searching
- Large EXIF values (>1KB) are filtered out to prevent performance issues
- Backward compatibility maintained with existing code

### 6. Search Examples

#### Common EXIF Fields for Searching
- `camera_model_name` or `model`: Camera model
- `make`: Camera manufacturer
- `iso`: ISO sensitivity
- `f_number`: Aperture value
- `exposure_time`: Shutter speed
- `focal_length`: Lens focal length
- `date_time_original`: When photo was taken
- `gps_latitude`/`gps_longitude`: GPS coordinates
- `orientation`: Image orientation
- `white_balance`: White balance setting
- `flash`: Flash settings

#### Frontend Integration
```javascript
// Search for photos taken with Canon cameras
fetch('/api/items/search_by_exif', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    exif_conditions: {
      make: 'Canon'
    }
  })
})
.then(response => response.json())
.then(data => {
  console.log('Found photos:', data.items);
  console.log('Total count:', data.meta.total);
});
```

## Migration

Run the migration to add the EXIF data column:
```bash
rails db:migrate
```

## Re-processing Existing Photos

To populate EXIF data for existing photos, you can re-run the metadata loading job:
```ruby
Item.find_each do |item|
  LoadMetadataJob.perform_later(item.id)
end
```

## Troubleshooting

### Missing EXIF Data
- Check if the photo file exists at `item.full_path`
- Verify the file is a valid JPEG with EXIF data
- Check Rails logs for EXIF import errors

### Search Not Working
- Ensure the EXIF field names match exactly (case-sensitive)
- Use `GET /api/items/:id/exif_fields` to see available fields
- Check that the database migration was applied successfully

### Performance Issues
- Add database indexes on commonly searched EXIF fields if needed
- Consider using full-text search for complex queries
- Monitor query performance and optimize as needed