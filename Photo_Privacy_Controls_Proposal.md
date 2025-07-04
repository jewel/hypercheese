# Photo Privacy Controls Proposal for Hypercheese

## Executive Summary

This proposal outlines a comprehensive approach to implement granular photo privacy controls in the Hypercheese photo organizer system. The current system has a binary visibility model (public/private) that needs to be enhanced to provide users with fine-grained control over who can view their photos.

## Current State Analysis

### Existing System Architecture
- **User Management**: Multi-user system with roles (stranger, user, admin)
- **Photo Organization**: Items (photos/videos) belong to Sources, Sources belong to Users
- **Current Privacy Model**: Binary visibility using `published` boolean field
- **Sharing System**: Basic public sharing via generated links (Share/ShareItem models)

### Current Privacy Logic
```ruby
# Current visibility check in Item model
def check_visibility_for user
  return if published  # Anyone can see if published
  raise "Must be logged in to see this item" unless user
  sources.each do |source|
    return if source.user_id == user.id  # Owner can see
  end
  raise "Item #{id} is not published"
end
```

### Problems with Current System
1. **Binary Visibility**: Photos are either public to everyone or private to only the owner
2. **No Granular Control**: Cannot share with specific users or groups
3. **Limited Privacy Options**: No concept of friends, followers, or custom groups
4. **Security Concerns**: All published photos are visible to any authenticated user

## Proposed Solution

### 1. Enhanced Privacy Model

#### Privacy Levels
Replace the binary `published` field with a more sophisticated privacy system:

- **Public**: Visible to all authenticated users (current `published: true`)
- **Private**: Visible only to the owner (current `published: false`)
- **Friends**: Visible to approved friends only
- **Custom Groups**: Visible to specific user-defined groups
- **Selected Users**: Visible to individually selected users

#### Database Schema Changes

```sql
-- New privacy levels table
CREATE TABLE privacy_levels (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(50) NOT NULL,
  description TEXT,
  system_level BOOLEAN DEFAULT FALSE
);

-- Enhanced items table
ALTER TABLE items 
ADD COLUMN privacy_level_id INT,
ADD COLUMN custom_visibility_data JSON,
ADD FOREIGN KEY (privacy_level_id) REFERENCES privacy_levels(id);

-- User relationships (friendships)
CREATE TABLE user_relationships (
  id INT PRIMARY KEY AUTO_INCREMENT,
  requester_id INT NOT NULL,
  addressee_id INT NOT NULL,
  status ENUM('pending', 'accepted', 'declined', 'blocked') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (requester_id) REFERENCES users(id),
  FOREIGN KEY (addressee_id) REFERENCES users(id),
  UNIQUE KEY unique_relationship (requester_id, addressee_id)
);

-- Custom user groups
CREATE TABLE user_groups (
  id INT PRIMARY KEY AUTO_INCREMENT,
  owner_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (owner_id) REFERENCES users(id)
);

-- User group memberships
CREATE TABLE user_group_memberships (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_group_id INT NOT NULL,
  user_id INT NOT NULL,
  added_by INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_group_id) REFERENCES user_groups(id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (added_by) REFERENCES users(id),
  UNIQUE KEY unique_membership (user_group_id, user_id)
);

-- Item-specific user permissions
CREATE TABLE item_user_permissions (
  id INT PRIMARY KEY AUTO_INCREMENT,
  item_id INT NOT NULL,
  user_id INT NOT NULL,
  permission_type ENUM('view', 'comment', 'tag') DEFAULT 'view',
  granted_by INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (item_id) REFERENCES items(id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (granted_by) REFERENCES users(id),
  UNIQUE KEY unique_item_user_permission (item_id, user_id, permission_type)
);
```

### 2. New Model Classes

#### PrivacyLevel Model
```ruby
class PrivacyLevel < ApplicationRecord
  has_many :items
  
  validates :name, presence: true, uniqueness: true
  
  scope :user_selectable, -> { where(system_level: false) }
  
  def self.default_levels
    [
      { name: 'Public', description: 'Visible to all users', system_level: true },
      { name: 'Private', description: 'Visible only to you', system_level: true },
      { name: 'Friends', description: 'Visible to your friends', system_level: true },
      { name: 'Custom', description: 'Custom visibility settings', system_level: true }
    ]
  end
end
```

#### UserRelationship Model
```ruby
class UserRelationship < ApplicationRecord
  belongs_to :requester, class_name: 'User'
  belongs_to :addressee, class_name: 'User'
  
  validates :requester_id, presence: true
  validates :addressee_id, presence: true
  validates :status, inclusion: { in: %w[pending accepted declined blocked] }
  validate :cannot_friend_self
  
  scope :accepted, -> { where(status: 'accepted') }
  scope :pending, -> { where(status: 'pending') }
  
  def self.are_friends?(user1, user2)
    return false if user1 == user2
    exists?(
      requester: user1, addressee: user2, status: 'accepted'
    ) || exists?(
      requester: user2, addressee: user1, status: 'accepted'
    )
  end
  
  private
  
  def cannot_friend_self
    errors.add(:addressee_id, "can't be the same as requester") if requester_id == addressee_id
  end
end
```

#### UserGroup Model
```ruby
class UserGroup < ApplicationRecord
  belongs_to :owner, class_name: 'User'
  has_many :user_group_memberships, dependent: :destroy
  has_many :members, through: :user_group_memberships, source: :user
  
  validates :name, presence: true
  validates :owner_id, presence: true
  
  def add_member(user, added_by)
    user_group_memberships.create(user: user, added_by: added_by)
  end
  
  def remove_member(user)
    user_group_memberships.where(user: user).destroy_all
  end
  
  def includes_user?(user)
    members.include?(user)
  end
end
```

### 3. Enhanced Item Model

#### Updated Visibility Logic
```ruby
class Item < ApplicationRecord
  # ... existing associations ...
  belongs_to :privacy_level, optional: true
  has_many :item_user_permissions, dependent: :destroy
  has_many :permitted_users, through: :item_user_permissions, source: :user
  
  # Enhanced visibility check
  def check_visibility_for(user)
    return true if can_view?(user)
    raise "You don't have permission to view this item"
  end
  
  def can_view?(user)
    return false unless user
    
    # Owner can always see their own items
    return true if owned_by?(user)
    
    # Admin can see everything
    return true if user.is_admin?
    
    # Check privacy level
    case privacy_level&.name
    when 'Public'
      true
    when 'Private'
      false
    when 'Friends'
      friends_can_view?(user)
    when 'Custom'
      custom_visibility_check(user)
    else
      # Fallback to legacy published field
      published == true
    end
  end
  
  private
  
  def owned_by?(user)
    sources.joins(:user).where(users: { id: user.id }).exists?
  end
  
  def friends_can_view?(user)
    owner_ids = sources.pluck(:user_id).compact
    return false if owner_ids.empty?
    
    owner_ids.any? do |owner_id|
      UserRelationship.are_friends?(User.find(owner_id), user)
    end
  end
  
  def custom_visibility_check(user)
    # Check direct user permissions
    return true if item_user_permissions.where(user: user, permission_type: 'view').exists?
    
    # Check group memberships
    return true if visible_via_groups?(user)
    
    false
  end
  
  def visible_via_groups?(user)
    return false unless custom_visibility_data.present?
    
    group_ids = custom_visibility_data['group_ids'] || []
    return false if group_ids.empty?
    
    UserGroup.joins(:user_group_memberships)
             .where(id: group_ids)
             .where(user_group_memberships: { user_id: user.id })
             .exists?
  end
end
```

### 4. User Model Enhancements

```ruby
class User < ApplicationRecord
  # ... existing associations ...
  has_many :sent_friend_requests, class_name: 'UserRelationship', foreign_key: 'requester_id'
  has_many :received_friend_requests, class_name: 'UserRelationship', foreign_key: 'addressee_id'
  has_many :owned_groups, class_name: 'UserGroup', foreign_key: 'owner_id'
  has_many :group_memberships, class_name: 'UserGroupMembership'
  has_many :groups, through: :group_memberships, source: :user_group
  
  def friends
    User.joins(
      "LEFT JOIN user_relationships as ur1 ON ur1.addressee_id = users.id AND ur1.requester_id = #{id} AND ur1.status = 'accepted'
       LEFT JOIN user_relationships as ur2 ON ur2.requester_id = users.id AND ur2.addressee_id = #{id} AND ur2.status = 'accepted'"
    ).where("ur1.id IS NOT NULL OR ur2.id IS NOT NULL")
  end
  
  def friend_with?(other_user)
    UserRelationship.are_friends?(self, other_user)
  end
  
  def send_friend_request(other_user)
    return false if self == other_user
    return false if friend_with?(other_user)
    
    # Check if request already exists
    existing = UserRelationship.where(
      requester: self, addressee: other_user
    ).or(
      UserRelationship.where(requester: other_user, addressee: self)
    ).first
    
    return false if existing
    
    sent_friend_requests.create(addressee: other_user, status: 'pending')
  end
  
  def accept_friend_request(other_user)
    request = received_friend_requests.find_by(requester: other_user, status: 'pending')
    request&.update(status: 'accepted')
  end
  
  def decline_friend_request(other_user)
    request = received_friend_requests.find_by(requester: other_user, status: 'pending')
    request&.update(status: 'declined')
  end
  
  def pending_friend_requests
    received_friend_requests.where(status: 'pending')
  end
end
```

### 5. Controller Updates

#### New FriendshipsController
```ruby
class FriendshipsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_approval!
  
  def index
    @friends = current_user.friends.includes(:sources)
    @pending_requests = current_user.pending_friend_requests.includes(:requester)
    render json: {
      friends: @friends,
      pending_requests: @pending_requests
    }
  end
  
  def create
    user = User.find(params[:user_id])
    request = current_user.send_friend_request(user)
    
    if request&.persisted?
      render json: { message: 'Friend request sent' }
    else
      render json: { error: 'Unable to send friend request' }, status: :unprocessable_entity
    end
  end
  
  def update
    user = User.find(params[:id])
    
    if params[:status] == 'accepted'
      current_user.accept_friend_request(user)
      render json: { message: 'Friend request accepted' }
    elsif params[:status] == 'declined'
      current_user.decline_friend_request(user)
      render json: { message: 'Friend request declined' }
    else
      render json: { error: 'Invalid status' }, status: :unprocessable_entity
    end
  end
  
  def destroy
    user = User.find(params[:id])
    UserRelationship.where(
      requester: [current_user, user],
      addressee: [current_user, user]
    ).destroy_all
    
    render json: { message: 'Friendship ended' }
  end
end
```

#### New UserGroupsController
```ruby
class UserGroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_approval!
  
  def index
    @groups = current_user.owned_groups.includes(:members)
    render json: @groups, each_serializer: UserGroupSerializer
  end
  
  def create
    @group = current_user.owned_groups.build(group_params)
    
    if @group.save
      render json: @group, serializer: UserGroupSerializer
    else
      render json: { errors: @group.errors }, status: :unprocessable_entity
    end
  end
  
  def update
    @group = current_user.owned_groups.find(params[:id])
    
    if @group.update(group_params)
      render json: @group, serializer: UserGroupSerializer
    else
      render json: { errors: @group.errors }, status: :unprocessable_entity
    end
  end
  
  def destroy
    @group = current_user.owned_groups.find(params[:id])
    @group.destroy
    render json: { message: 'Group deleted' }
  end
  
  def add_member
    @group = current_user.owned_groups.find(params[:id])
    user = User.find(params[:user_id])
    
    @group.add_member(user, current_user)
    render json: { message: 'Member added' }
  end
  
  def remove_member
    @group = current_user.owned_groups.find(params[:id])
    user = User.find(params[:user_id])
    
    @group.remove_member(user)
    render json: { message: 'Member removed' }
  end
  
  private
  
  def group_params
    params.require(:user_group).permit(:name, :description)
  end
end
```

#### Updated ItemsController
```ruby
class ItemsController < ApplicationController
  # ... existing code ...
  
  def update_privacy
    require_write!
    
    ids = params[:item_ids].map(&:to_i)
    items = Item.where(id: ids)
    
    # Verify ownership
    items.each do |item|
      raise "You don't own this item" unless item.owned_by?(current_user)
    end
    
    privacy_level = PrivacyLevel.find(params[:privacy_level_id])
    
    Item.transaction do
      items.each do |item|
        item.privacy_level = privacy_level
        item.custom_visibility_data = params[:custom_visibility_data] if params[:custom_visibility_data]
        item.save!
        
        # Clear existing permissions if changing privacy level
        item.item_user_permissions.destroy_all if params[:clear_permissions]
      end
    end
    
    render json: { message: 'Privacy settings updated' }
  end
  
  def grant_permission
    require_write!
    
    item = Item.find(params[:item_id])
    user = User.find(params[:user_id])
    
    raise "You don't own this item" unless item.owned_by?(current_user)
    
    permission = item.item_user_permissions.find_or_create_by(
      user: user,
      permission_type: params[:permission_type] || 'view'
    ) do |p|
      p.granted_by = current_user
    end
    
    render json: { message: 'Permission granted' }
  end
  
  def revoke_permission
    require_write!
    
    item = Item.find(params[:item_id])
    user = User.find(params[:user_id])
    
    raise "You don't own this item" unless item.owned_by?(current_user)
    
    item.item_user_permissions.where(
      user: user,
      permission_type: params[:permission_type] || 'view'
    ).destroy_all
    
    render json: { message: 'Permission revoked' }
  end
end
```

### 6. Frontend UI Components

#### Privacy Settings Modal
```javascript
// React component for privacy settings
const PrivacySettingsModal = ({ items, onClose, onSave }) => {
  const [privacyLevel, setPrivacyLevel] = useState('public');
  const [selectedFriends, setSelectedFriends] = useState([]);
  const [selectedGroups, setSelectedGroups] = useState([]);
  const [customUsers, setCustomUsers] = useState([]);
  
  const handleSave = () => {
    const privacyData = {
      privacy_level_id: privacyLevel,
      custom_visibility_data: {
        friend_ids: selectedFriends,
        group_ids: selectedGroups,
        user_ids: customUsers
      }
    };
    
    onSave(privacyData);
  };
  
  return (
    <div className="modal">
      <div className="modal-content">
        <h3>Privacy Settings</h3>
        
        <div className="privacy-options">
          <label>
            <input
              type="radio"
              value="public"
              checked={privacyLevel === 'public'}
              onChange={(e) => setPrivacyLevel(e.target.value)}
            />
            Public - Anyone can see
          </label>
          
          <label>
            <input
              type="radio"
              value="friends"
              checked={privacyLevel === 'friends'}
              onChange={(e) => setPrivacyLevel(e.target.value)}
            />
            Friends Only
          </label>
          
          <label>
            <input
              type="radio"
              value="custom"
              checked={privacyLevel === 'custom'}
              onChange={(e) => setPrivacyLevel(e.target.value)}
            />
            Custom
          </label>
          
          <label>
            <input
              type="radio"
              value="private"
              checked={privacyLevel === 'private'}
              onChange={(e) => setPrivacyLevel(e.target.value)}
            />
            Private - Only me
          </label>
        </div>
        
        {privacyLevel === 'custom' && (
          <div className="custom-privacy">
            <FriendSelector
              selected={selectedFriends}
              onChange={setSelectedFriends}
            />
            <GroupSelector
              selected={selectedGroups}
              onChange={setSelectedGroups}
            />
            <UserSelector
              selected={customUsers}
              onChange={setCustomUsers}
            />
          </div>
        )}
        
        <div className="modal-actions">
          <button onClick={onClose}>Cancel</button>
          <button onClick={handleSave}>Save</button>
        </div>
      </div>
    </div>
  );
};
```

### 7. Migration Strategy

#### Phase 1: Database Schema
```ruby
class AddPrivacyControlsToHypercheese < ActiveRecord::Migration[7.2]
  def up
    # Create privacy levels
    create_table :privacy_levels do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :system_level, default: false
    end
    
    # Seed default privacy levels
    PrivacyLevel.create!([
      { name: 'Public', description: 'Visible to all users', system_level: true },
      { name: 'Private', description: 'Visible only to you', system_level: true },
      { name: 'Friends', description: 'Visible to your friends', system_level: true },
      { name: 'Custom', description: 'Custom visibility settings', system_level: true }
    ])
    
    # Add privacy level to items
    add_column :items, :privacy_level_id, :integer
    add_column :items, :custom_visibility_data, :json
    add_foreign_key :items, :privacy_levels
    
    # Create other tables...
    # (UserRelationships, UserGroups, etc.)
  end
  
  def down
    # Remove all new tables and columns
  end
end
```

#### Phase 2: Data Migration
```ruby
class MigrateExistingPrivacySettings < ActiveRecord::Migration[7.2]
  def up
    public_level = PrivacyLevel.find_by(name: 'Public')
    private_level = PrivacyLevel.find_by(name: 'Private')
    
    Item.where(published: true).update_all(privacy_level_id: public_level.id)
    Item.where(published: false).update_all(privacy_level_id: private_level.id)
  end
end
```

### 8. Security Considerations

#### Access Control
- **Principle of Least Privilege**: Users only see what they explicitly have access to
- **Owner Override**: Photo owners always have full control
- **Admin Oversight**: Admins can access all photos for moderation
- **Audit Trail**: Track permission changes and access attempts

#### Data Protection
- **Encryption**: Store sensitive custom visibility data encrypted
- **API Security**: Ensure all endpoints validate permissions
- **Input Validation**: Sanitize all user inputs
- **Rate Limiting**: Prevent abuse of friendship and sharing features

### 9. Performance Considerations

#### Database Optimization
- **Indexes**: Add indexes on frequently queried fields
- **Caching**: Cache permission checks for frequently accessed items
- **Batch Operations**: Optimize bulk privacy updates
- **Query Optimization**: Use efficient joins for complex visibility checks

#### Scalability
- **Lazy Loading**: Load permissions only when needed
- **Background Jobs**: Process large privacy updates asynchronously
- **CDN Integration**: Ensure CDN respects privacy settings
- **Memory Management**: Optimize memory usage for large friend lists

### 10. Testing Strategy

#### Unit Tests
- Model validations and associations
- Privacy logic edge cases
- Permission calculation accuracy
- Data consistency checks

#### Integration Tests
- End-to-end privacy workflows
- Controller authorization
- API endpoint security
- Frontend-backend integration

#### Performance Tests
- Load testing with large datasets
- Concurrent user scenarios
- Database query performance
- Memory usage optimization

### 11. Rollout Plan

#### Phase 1: Backend Implementation (4 weeks)
1. Database migrations and model updates
2. Enhanced privacy logic implementation
3. API endpoint updates
4. Basic testing and validation

#### Phase 2: Frontend Integration (3 weeks)
1. Privacy settings UI components
2. Friend management interface
3. Group management features
4. User experience testing

#### Phase 3: Migration and Deployment (2 weeks)
1. Data migration from existing system
2. Production deployment
3. User training and documentation
4. Monitoring and bug fixes

#### Phase 4: Advanced Features (3 weeks)
1. Bulk privacy operations
2. Advanced group features
3. Privacy analytics
4. Mobile app integration

### 12. Success Metrics

#### User Adoption
- Percentage of users who set custom privacy settings
- Number of friend connections established
- Usage of custom groups feature
- Reduction in privacy-related support tickets

#### System Performance
- Query response times for privacy checks
- Database load and optimization
- User interface responsiveness
- Error rates and system stability

#### Security Effectiveness
- Zero unauthorized access incidents
- Successful privacy audits
- User satisfaction with privacy controls
- Compliance with data protection regulations

## Conclusion

This comprehensive privacy system will transform Hypercheese from a simple binary visibility model to a sophisticated, user-friendly privacy platform. Users will have complete control over who can see their photos, while the system maintains performance and security standards.

The proposed solution addresses the core problem of "everyone seeing everyone else's photos" by implementing:

1. **Granular Privacy Controls**: Multiple privacy levels from public to highly restricted
2. **Friend Management**: Social networking features for photo sharing
3. **Custom Groups**: Flexible organization of photo visibility
4. **Individual Permissions**: Fine-grained control over specific users
5. **Backward Compatibility**: Smooth migration from existing system

The implementation plan ensures minimal disruption to current users while providing powerful new privacy features that will make Hypercheese a more secure and user-friendly photo sharing platform.