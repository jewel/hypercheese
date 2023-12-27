Trestle.resource(:users, model: User, scope: Auth) do
  menu do
    group :configuration, priority: :last do
      item :users, icon: "fas fa-users"
    end
  end

  table do
    column :name, link: true
    column :username, link: true do |user|
      user.username || user.email || user.uid
    end
    column :role
    column :sponsor
    column :comments do |user|
      user.comments.count
    end
    column :taggings do |user|
      user.item_tags.count
    end
    column :current_sign_in_at
    actions do |a|
      a.delete unless a.instance == current_user
    end
  end

  form do |user|
    text_field :name
    text_field :username
    text_field :email
    roles = %i{none stranger readonly user admin}
    select :role, roles
    select :sponsor_id, User.where(role: :admin), include_blank: true

    row do
      col(sm: 6) { password_field :password }
      col(sm: 6) { password_field :password_confirmation }
    end
  end

  build_instance do |attrs,params|
    obj = self.model.new(attrs)
    obj.role = :user
    obj.sponsor = current_user
    obj
  end

  # Ignore the password parameters if they are blank
  update_instance do |instance, attrs|
    if attrs[:password].blank?
      attrs.delete(:password)
      attrs.delete(:password_confirmation) if attrs[:password_confirmation].blank?
    end

    if attrs[:email].blank?
      attrs[:email] = nil
    end

    instance.assign_attributes(attrs)
  end

  # Log the current user back in if their password was changed
  after_action on: :update do
    if instance == current_user && instance.encrypted_password_previously_changed?
      login!(instance)
    end
  end if Devise.sign_in_after_reset_password
end
