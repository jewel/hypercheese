class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  if Rails.application.config.use_omniauth
    devise :omniauthable, :omniauth_providers => [:facebook]
  end

  def role
    val = read_attribute(:role)
    val = :stranger unless val && !val.empty?
    val.to_sym
  end

  def approved?
    role != :stranger
  end

  def self.find_for_facebook_oauth auth, signed_in_resource=nil
    user = User.where(provider: auth.provider, uid: auth.uid).first
    user ||= User.create(
      name: auth.extra.raw_info.name,
      provider: auth.provider,
      uid: auth.uid,
      email: auth.info.email,
      password: Devise.friendly_token[0,20]
    )
    user
  end
end
