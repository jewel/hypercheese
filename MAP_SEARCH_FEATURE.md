# Map Search Feature Implementation

## Overview
I've successfully implemented a map search view that shows all photos taken in an area of the map. The feature includes:

- **Interactive Map**: Users can scroll and zoom to explore different geographical areas
- **Photo Thumbnails**: Photos appear as circular thumbnails on the map at their GPS coordinates
- **Hover Effects**: Hovering over a photo thumbnail shows a large preview of the photo
- **Click Navigation**: Clicking on the large photo preview navigates to that photo's page
- **Real-time Updates**: The map updates automatically as users scroll or zoom to show relevant photos

## Files Created/Modified

### Backend Changes

1. **app/controllers/items_controller.rb** - Added `map_search` method
   - Accepts bounding box parameters (north, south, east, west)
   - Returns photos within the specified geographical area
   - Includes visibility filtering for published/unpublished photos
   - Limits results to 500 items for performance

2. **config/routes.rb** - Added routes
   - `get :map_search` route for the API endpoint
   - `get 'map' => 'home#index'` for the map search page

### Frontend Changes

3. **react/map_search.coffee** - New MapSearch component
   - Full-screen interactive map using Leaflet
   - Custom photo thumbnail markers with hover effects
   - Photo overlay system for previews
   - Automatic loading of photos based on map bounds
   - Loading indicators and photo count display

4. **react/app.coffee** - Updated routing
   - Added map route parsing in `parseUrl()`
   - Added map page rendering logic

5. **react/navbar.coffee** - Added navigation
   - Added "Map Search" option to the dropdown menu

6. **app/assets/stylesheets/leaflet.sass** - Enhanced styling
   - Custom styles for photo markers
   - Hover effects and transitions
   - Photo overlay styles
   - Responsive design considerations

## Technical Implementation Details

### API Endpoint
```ruby
# GET /api/items/map_search
def map_search
  north = params[:north].to_f
  south = params[:south].to_f
  east = params[:east].to_f
  west = params[:west].to_f
  
  # Find items within bounding box with GPS coordinates
  items = Item.where(
    'latitude IS NOT NULL AND longitude IS NOT NULL AND 
     latitude >= ? AND latitude <= ? AND 
     longitude >= ? AND longitude <= ?', 
    south, north, west, east
  )
  
  # Apply visibility filtering and limit results
  # ... (visibility logic)
  
  items = items.limit(500)
  
  # Return minimal data structure for performance
  render json: items.map { |item|
    {
      id: item.id,
      code: item.code,
      latitude: item.latitude,
      longitude: item.longitude,
      variety: item.variety,
      taken: item.taken
    }
  }
end
```

### Frontend Component Structure
```coffeescript
component 'MapSearch', ->
  # State management
  [items, setItems] = useState([])
  [selectedItem, setSelectedItem] = useState(null)
  [hoveredItem, setHoveredItem] = useState(null)
  [isLoading, setIsLoading] = useState(false)
  
  # Map initialization with event listeners
  # Photo marker creation with custom thumbnails
  # Hover and click handlers
  # API integration for loading photos
```

## User Experience Features

### Map Interaction
- **Scroll and Zoom**: Users can navigate the map naturally
- **Automatic Updates**: Photos load automatically when the map view changes
- **Performance**: Limited to 500 photos per view to maintain responsiveness
- **Loading Indicators**: Clear feedback when photos are being loaded

### Photo Display
- **Thumbnail Markers**: 40px circular thumbnails with photo previews
- **Hover Preview**: Large photo overlay (up to 800px) on hover
- **Click Navigation**: Tapping the large photo navigates to the photo's detail page
- **Responsive Design**: Works on both desktop and mobile devices

### Visual Design
- **Circular Thumbnails**: Photos appear as circles with white borders and shadows
- **Smooth Transitions**: Hover effects with 0.2s ease transitions
- **Overlay System**: Semi-transparent backdrop for photo previews
- **Map Controls**: Standard Leaflet controls for navigation

## Navigation Integration

The map search is integrated into the main navigation:
- Available through the dropdown menu in the navbar
- Accessible via `/map` URL
- Consistent with the existing application routing

## Database Requirements

The implementation assumes:
- Items have `latitude` and `longitude` columns (already exists)
- GPS coordinates are populated by the existing `GeolocateJob`
- Photo thumbnails are available at `/data/resized/160/` and `/data/resized/800/`

## Performance Considerations

1. **Bounding Box Queries**: Efficient geographical queries using lat/lon indexes
2. **Result Limiting**: Maximum 500 photos per map view
3. **Minimal Data Transfer**: Only essential fields returned from API
4. **Thumbnail Loading**: Progressive loading of photo thumbnails
5. **Map Debouncing**: Updates triggered only on moveend/zoomend events

## Browser Compatibility

- Uses modern JavaScript features (fetch, arrow functions)
- Requires Leaflet for map functionality
- Compatible with modern browsers supporting ES6+
- Responsive design for mobile and desktop

## Future Enhancements

Potential improvements could include:
- Clustering for high-density areas
- Advanced filtering options (date, tags, etc.)
- Geolocation-based initial positioning
- Search functionality within the map
- Full-screen mode for photos
- Batch operations on visible photos

## Testing

To test the implementation:
1. Start the Rails server
2. Navigate to `/map`
3. The map should load with photo thumbnails
4. Hover over thumbnails to see large previews
5. Click large previews to navigate to photo pages
6. Scroll/zoom to load photos in different areas