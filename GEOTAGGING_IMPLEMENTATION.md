# Geotagging Feature Implementation

This document describes the implementation of the geotagging feature that allows users to add or edit location data on photos and videos with fuzzy location support.

## Features Implemented

### 1. Interactive Geotagging Map
- **Enhanced LeafletMap Component**: Created `GeotaggingMap` component that supports both display and geotagging modes
- **Click-to-Place**: Users can click on the map to place a location marker
- **Dual Mode Operation**: The map works both for viewing existing locations and for adding/editing locations

### 2. Fuzzy Location Support
- **Precision Circles**: Visual representation of location uncertainty as circles on the map
- **Configurable Precision**: Users can select from predefined precision levels:
  - Exact location (no circle)
  - ±50 meters
  - ±100 meters  
  - ±500 meters
  - ±1 kilometer
  - ±5 kilometers
  - ±10 kilometers
- **Database Storage**: Added `precision` field to `items` table to store fuzzy radius

### 3. Place Name Search
- **Search Input**: Text input for searching place names
- **Database Integration**: Uses existing `locations` table from the geo database
- **Real-time Search**: Debounced search with loading indicator
- **Smart Centering**: Clicking a search result centers and zooms the map to that location

### 4. User Interface
- **Geotagging Button**: Added "Add Location" or "Edit Location" button below the map
- **Controls Panel**: When in geotagging mode, shows:
  - Place name search input
  - Precision selector dropdown
  - Save and Cancel buttons
- **Responsive Design**: Styled with Bootstrap classes for consistency

## Files Created/Modified

### Database
- `db/migrate/20250115000001_add_precision_to_items.rb` - Migration to add precision field

### Frontend Components
- `react/geotagging_map.coffee.erb` - New enhanced map component
- `app/assets/javascripts/gallery/geotagging_map.coffee.erb` - Gallery version
- `react/info.coffee` - Updated to use new component with geotagging controls
- `app/assets/javascripts/gallery/info.coffee` - Gallery version updates

### Backend API
- `config/routes.rb` - Added routes for geotagging and location search
- `app/controllers/items_controller.rb` - Added `geotag` action
- `app/controllers/locations_controller.rb` - New controller for place search

### Styling
- `app/assets/stylesheets/geotagging.scss` - CSS styles for geotagging UI

### State Management
- `react/store.coffee` - Added `updateItem` method
- `app/assets/javascripts/gallery/store.coffee` - Added `updateItem` method

## API Endpoints

### POST /api/items/:id/geotag
Saves geotag data to an item:
```json
{
  "latitude": 40.7128,
  "longitude": -74.0060,
  "precision": 100
}
```

### GET /api/locations/search?q=query
Searches for place names in the geo database:
```json
[
  {
    "id": 1,
    "name": "New York City",
    "geoid": "nyc_001", 
    "bounds": [[40.4774, -74.2591], [40.9176, -73.7004]]
  }
]
```

## Usage Workflow

1. **View Mode**: When viewing a photo/video, the map displays existing location with precision circle if available
2. **Enable Geotagging**: User clicks "Add Location" or "Edit Location" button
3. **Search (Optional)**: User can search for a place name to center the map
4. **Place Marker**: User clicks on the map to place/move the location marker
5. **Set Precision**: User selects desired precision level from dropdown
6. **Save**: User clicks "Save Location" to persist the changes
7. **Auto-Geocoding**: System automatically runs geolocation job to find matching administrative boundaries

## Technical Details

### Map Integration
- Uses Leaflet.js for map functionality
- OpenStreetMap tiles for base layer
- Click handlers for interactive placement
- Circle overlays for precision visualization

### Data Flow
- Frontend sends geotag data to Rails API
- Rails updates item with latitude, longitude, and precision
- Triggers GeolocateJob to find matching locations in geo database
- Frontend updates Store state and re-renders

### Search Implementation
- LIKE query against location names in database
- Parses JSON properties to extract geographical bounds
- Returns up to 10 results ordered by name
- Supports polygon geometry bounds calculation

## Browser Compatibility
- Modern browsers with ES6+ support
- Requires JavaScript enabled
- Uses Fetch API for HTTP requests
- Leaflet.js handles map rendering across browsers

## Error Handling
- Network errors display in console
- Invalid coordinates prevented by input validation  
- Search failures gracefully fall back to empty results
- Map initialization failures show no map instead of errors

This implementation provides a complete geotagging solution with both exact and fuzzy location capabilities, integrated search, and a user-friendly interface.