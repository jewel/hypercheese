# Album Support Implementation

This document outlines the comprehensive album support feature that has been implemented for the photo sharing application.

## Overview

Albums allow users to organize their photos into named collections that can be shared with unique links. The implementation includes full CRUD operations, sharing capabilities, and integration with the existing photo selection system.

## Database Schema

### New Tables

1. **albums**
   - `id` (primary key)
   - `name` (string, required) - Album name
   - `description` (text, optional) - Album description
   - `user_id` (foreign key) - Album owner
   - `created_at`, `updated_at` (timestamps)

2. **album_items**
   - `id` (primary key)
   - `album_id` (foreign key) - References albums table
   - `item_id` (foreign key) - References items table
   - `added_by` (foreign key) - User who added the item to album
   - `created_at`, `updated_at` (timestamps)
   - Unique constraint on (album_id, item_id)

3. **album_shares**
   - `id` (primary key)
   - `album_id` (foreign key) - References albums table
   - `code` (string, unique) - Share code for anonymous access
   - `allows_uploads` (boolean) - Whether anonymous users can upload
   - `created_at`, `updated_at` (timestamps)

### Migration Files

- `db/migrate/20250706152013_create_albums.rb`
- `db/migrate/20250706152014_create_album_items.rb`
- `db/migrate/20250706152015_create_album_shares.rb`

## Backend Implementation

### Models

#### Album (`app/models/album.rb`)
- Belongs to user
- Has many album_items and items through album_items
- Has many album_shares
- Validates name presence
- Includes scopes for ordering and recently updated albums
- Method to get items ordered by date (oldest first)

#### AlbumItem (`app/models/album_item.rb`)
- Join table between albums and items
- Tracks who added each item to which album
- Validates uniqueness of album_id/item_id combination

#### AlbumShare (`app/models/album_share.rb`)
- Manages shareable album links
- Auto-generates unique codes
- Tracks upload permissions for shared albums

### Controllers

#### AlbumsController (`app/controllers/albums_controller.rb`)
- `index` - List all albums
- `show` - Show specific album with items
- `create` - Create new album
- `update` - Update album (owner only)
- `destroy` - Delete album (owner only)
- `add_items` - Add selected items to album
- `remove_item` - Remove item from album
- `share` - Create shareable link for album
- `user_albums` - Get user's albums sorted by recent activity

#### AlbumSharesController (`app/controllers/album_shares_controller.rb`)
- `show` - Display shared album (no authentication required)
- `items` - Get album items via API (no authentication required)
- `download` - Download all album items as zip
- `download_item` - Download specific item from shared album
- `upload` - Handle uploads to shared albums (if enabled)

### Serializers

- `AlbumSerializer` - Serializes album data with user, items, and metadata
- `AlbumItemSerializer` - Serializes album item relationships

### Routes

```ruby
# API routes
resources :albums do
  member do
    post :add_items
    delete 'remove_item/:item_id', action: :remove_item
    post :share
  end
end

get 'users/albums', to: 'albums#user_albums'

# Shared album routes
scope :album_shares do
  get ':share_id' => 'album_shares#show'
  get ':share_id/download' => 'album_shares#download'
  get ':share_id/items' => 'album_shares#items'
  get ':share_id/download_item/:item_id' => 'album_shares#download_item'
  post ':share_id/upload' => 'album_shares#upload'
  get ':share_id/(*path)' => 'album_shares#show'
end

# Frontend routing
get 'albums/(*path)' => 'home#index'
```

## Frontend Implementation

### Store Methods (`react/store.coffee`)

Added album-specific methods to the Store:
- `fetchUserAlbums()` - Load user's albums
- `createAlbum(name, description)` - Create new album
- `addSelectionToAlbum(albumId)` - Add selected items to album
- `shareAlbum(albumId, allowsUploads)` - Generate shareable link

### SelectBar Updates (`react/selectbar.coffee`)

Enhanced the selection toolbar with album functionality:
- "Add to Album" dropdown button with list of user's albums
- Most recently updated albums appear first
- Option to create new album inline
- Modal form for album creation with name and description fields

### Albums Component (`react/albums.coffee`)

New component for displaying all albums:
- Grid layout showing album cards
- Album cover images (first item thumbnail)
- Album metadata (name, description, item count, owner)
- Hover overlay with share button
- Empty state for users with no albums

### Navigation Updates

- Added "Albums" link to main navigation dropdown
- Integrated album routing in main app component

### Styling (`react/sass/`)

- `albums.sass` - Styles for album grid and cards
- `selectbar.sass` - Added styles for album form overlay

## Key Features

### 1. Album Creation and Management
- Users can create albums with names and optional descriptions
- Albums are owned by users and only owners can modify them
- Albums can be updated or deleted by their owners

### 2. Photo Organization
- Easy integration with existing photo selection system
- Select multiple photos and add them to albums via dropdown
- Most recently used albums appear first in the list
- Track who added which photos to which albums

### 3. Sharing System
- Each album can generate multiple unique share links
- Share links work like existing photo shares (no authentication required)
- Shared albums can optionally allow uploads from anonymous users
- Each share generates a new unique link for security

### 4. Photo Ordering
- Photos in albums are always ordered oldest first (by taken date)
- Consistent ordering across all album views

### 5. User Experience
- Seamless integration with existing UI patterns
- Familiar sharing workflow (same as photo sharing)
- Albums are listed to all authenticated users
- Clear visual hierarchy in album listings

## Installation Notes

To complete the implementation:

1. **Resolve Bundle Dependencies**: The bundle install command failed due to permissions. This needs to be resolved to run migrations.

2. **Run Migrations**: 
   ```bash
   bundle exec rake db:migrate
   ```

3. **Asset Compilation**: Ensure SASS files are compiled to include new album styles.

4. **Test the Implementation**: 
   - Create albums via the UI
   - Add photos to albums
   - Test sharing functionality
   - Verify anonymous upload capabilities

## Future Enhancements

Potential future improvements:
- Album permissions (collaborative albums)
- Album categories or tags
- Bulk album operations
- Album templates
- Advanced sharing options (password protection, expiration dates)
- Album statistics and analytics

## Security Considerations

- Album ownership is enforced at the controller level
- Share codes are cryptographically secure (URL-safe base64)
- Anonymous upload permissions are granular per share
- All item visibility rules are respected within albums

The implementation follows the existing application patterns and maintains consistency with the current photo sharing system while adding powerful new organizational capabilities.