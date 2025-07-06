# Places Implementation Summary

This document outlines the implementation of custom places functionality for the photo management system.

## Overview

The places feature allows users to create custom geographic regions with GPS coordinates and radius. Photos are automatically associated with places when they fall within the defined area, and the "in:" search parameter now includes places alongside the existing location database.

## Database Changes

### New Tables

1. **places** table:
   - `id` (primary key)
   - `name` (string, not null) - Name of the place
   - `latitude` (decimal, precision: 10, scale: 6, not null) - GPS latitude
   - `longitude` (decimal, precision: 10, scale: 6, not null) - GPS longitude  
   - `radius` (decimal, precision: 8, scale: 2, not null) - Radius in meters
   - `created_by` (bigint, not null) - User ID who created the place
   - `created_at` and `updated_at` (timestamps)
   - Indexes on name, lat/lon coordinates, and created_by

2. **item_places** table:
   - `id` (primary key)
   - `item_id` (bigint, not null) - References items table
   - `place_id` (bigint, not null) - References places table
   - `user_id` (bigint, nullable) - User who manually added the association (null if system-added)
   - `created_at` (datetime, not null)
   - Unique index on item_id + place_id combination
   - Foreign key constraints

## Model Changes

### New Models

1. **Place** (`app/models/place.rb`):
   - Validates coordinates within valid GPS ranges
   - Validates radius is positive
   - Haversine formula for distance calculations
   - Methods to check if coordinates fall within place radius
   - Automatically associates existing items when created
   - Updates item associations when coordinates/radius change
   - Respects manually-added associations (doesn't remove user-added items)

2. **ItemPlace** (`app/models/item_place.rb`):
   - Junction table model
   - Methods to check if association was system vs user added
   - Validates uniqueness of item+place combinations

### Updated Models

1. **Item** (`app/models/item.rb`):
   - Added `has_many :item_places` and `has_many :places, through: :item_places`
   - New `assign_places!` method to associate with matching places

2. **User** (`app/models/user.rb`):
   - Added `has_many :created_places` and `has_many :item_places`

## Backend Logic Changes

### GeolocateJob Updates
- Modified `app/jobs/geolocate_job.rb` to call `item.assign_places!` after setting GPS coordinates
- Ensures photos are automatically assigned to places when location data is extracted

### Search Updates
- Modified `lib/search.rb` to include places in "in:" parameter searches
- Query now searches both locations and places tables for matches

### API Controller
- New `app/controllers/places_controller.rb` with full CRUD operations
- Handles automatic item association on create/update
- Proper error handling and validation

### Serializers
- New `app/serializers/place_serializer.rb` for API responses
- Updated `app/serializers/item_details_serializer.rb` to include places

## Frontend Changes

### New Components
- `react/places.coffee` - Main places management interface
- `PlaceForm` component for creating/editing places
- Bootstrap-styled cards showing place details

### Navigation Updates
- Added "Places" link to navbar dropdown menu
- Added routing support for `/places` URLs

### App Routing
- Updated `react/app.coffee` to handle places page routing
- Added places page rendering with error boundaries

## Key Features

### Automatic Association
- Photos with GPS coordinates are automatically associated with matching places
- Associations are created when:
  - A photo is imported and has GPS coordinates
  - A place is created (checks existing photos)
  - A place's coordinates/radius are updated

### Manual Override Protection
- User-manually added place associations are preserved
- When place boundaries change, only system-added associations are removed
- Users can manually associate photos with places regardless of GPS coordinates

### Search Integration
- "in:" parameter now searches both traditional locations and custom places
- Example: `in:home` will find photos in locations named "home" AND places named "home"

### UI Features
- List all places with creator info and item counts
- Create new places with name, coordinates, and radius
- Edit existing places (triggers automatic re-association)
- Delete places (removes all associations)
- Responsive card layout
- Form validation

## Security Considerations
- Places show all users but track who created them
- CSRF protection on all API endpoints
- User authentication required for all operations
- Foreign key constraints ensure data integrity

## Future Enhancements
The implementation provides a solid foundation for:
- Place-based photo browsing interface
- Map visualization of places and photos
- Import/export of place definitions
- Place sharing between users
- Hierarchical place organization

## Migration Files
- `db/migrate/20250125000001_create_places.rb`
- `db/migrate/20250125000002_create_item_places.rb`

Run `rails db:migrate` to apply the database changes.