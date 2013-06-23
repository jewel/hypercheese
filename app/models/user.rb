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

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :provider, :uid, :name
end
