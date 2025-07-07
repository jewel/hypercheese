class User < ActiveRecord::Base
  has_many :sources
  has_many :items, through: :sources
  belongs_to :sponsor, class_name: "User", foreign_key: "sponsor_id", optional: true
  has_many :sponsored_users, class_name: "User", foreign_key: "sponsor_id"
  has_many :comments
  has_many :item_tags, foreign_key: "added_by"
  has_many :created_places, class_name: 'Place', foreign_key: 'created_by'
  has_many :item_places

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable,
         :authentication_keys => [:login]

  attr_accessor :login

  def email_required?
    false
  end

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
    role == :user || role == :admin
  end

  def is_admin?
    role == :admin
  end

  def self.find_for_database_authentication warden_conditions
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_hash).where(["username = :value or email = :value", value: login ]).first
    else
      where(conditions.to_hash).first
    end
  end
end
