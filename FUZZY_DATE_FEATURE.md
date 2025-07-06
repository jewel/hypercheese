# Fuzzy Date Feature Implementation

## Overview
This feature adds the ability for users to adjust photo dates using "fuzzy" date formats in the photo info panel. Users can specify dates at different granularities (decade, year, month, day) and add postfix numbers for sort order.

## Features Implemented

### 1. Fuzzy Date Formats Supported
- **Decade**: `1980s` 
- **Year**: `1985`
- **Month**: `1985-03`
- **Day**: `1985-03-15`
- **Full datetime**: `1985-03-15 14:30:00`

### 2. Postfix Sort Order
Users can append `#N` to any fuzzy date to specify sort order:
- `1985 #3` → Converts to `1985-01-01 00:00:03`
- `1985-03 #2` → Converts to `1985-03-01 00:00:02`
- `1980s #1` → Converts to `1980-01-01 00:00:01`

This allows users to specify order when they know the sequence photos were taken but not exact dates.

### 3. UI/UX
- **Display**: Shows fuzzy date when set, otherwise shows precise date
- **Editing**: Click edit icon to enter fuzzy date format
- **Help**: Click "Examples" to see supported formats
- **Validation**: Invalid dates are ignored (no error shown)
- **Keyboard shortcuts**: Enter to save, Escape to cancel

## Files Modified

### Backend
- `db/migrate/20250706154346_add_fuzzy_date_to_items.rb` - Added fuzzy_date column
- `app/controllers/items_controller.rb` - Added `update_date` endpoint and parsing logic
- `app/serializers/item_details_serializer.rb` - Added fuzzy_date to serialization
- `config/routes.rb` - Added update_date route

### Frontend
- `react/info.coffee` - Updated to use DateEditor component
- `react/date_editor.coffee` - New component for fuzzy date editing
- `react/store.coffee` - Added updateItemDate method
- `app/assets/javascripts/gallery/info.coffee` - Same updates as react version
- `app/assets/javascripts/gallery/date_editor.coffee` - Same component as react version
- `app/assets/javascripts/gallery/store.coffee` - Same updates as react version

### Styling
- `app/assets/stylesheets/info.sass` - Added date editor styles
- `react/sass/info.sass` - Same styles as main version
- `app/assets/javascripts/gallery/sass/info.sass` - Same styles as main version

## API Endpoint

### POST `/api/items/:id/update_date`
**Parameters:**
- `fuzzy_date` (string): The fuzzy date string entered by user

**Response:**
- Returns updated item with both `taken` (precise date) and `fuzzy_date` (user input) fields

## Data Storage

### Database Schema
- `items.taken` (datetime): Precise date used for sorting and search
- `items.fuzzy_date` (string): User's original fuzzy input for display

### Parsing Logic
The `parse_fuzzy_date` method in ItemsController:
1. Extracts postfix numbers (`#N`)
2. Parses date part based on format
3. Converts to precise DateTime with postfix as seconds
4. Handles parse errors gracefully

## Usage Example

1. User clicks edit icon next to date in photo info panel
2. Types `1985 #3` in the input field
3. Presses Enter or clicks checkmark
4. Date is stored as:
   - `fuzzy_date`: `"1985 #3"`
   - `taken`: `1985-01-01 00:00:03`
5. UI displays `1985 #3` instead of full timestamp

## Benefits

1. **Flexible Dating**: Users can specify dates at appropriate granularity
2. **Batch Ordering**: Postfix numbers allow sorting batches of photos
3. **Intuitive UI**: Shows user-friendly format, not technical timestamps
4. **Search Compatible**: Precise dates still work for search and filtering
5. **Backward Compatible**: Existing photos continue to work normally