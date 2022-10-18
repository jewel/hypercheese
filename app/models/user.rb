class User < ActiveRecord::Base
  has_many :sources
  has_many :items, through: :sources

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :authentication_keys => [:login]

  attr_accessor :login

  validates :username,
    presence: true,
    uniqueness: { case_sensitive: false }

  def role
    val = read_attribute(:role)
    val = :stranger unless val && !val.empty?
    val.to_sym
  end

  def approved?
    role != :stranger
  end

  def can_write?
    role == :user
  end

  def self.find_for_database_authentication warden_conditions
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_hash).where(["username = :value or email = :value", value: login ]).first
    else
      where(conditions.to_hash).first
    end
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
