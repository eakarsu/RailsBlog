class User < ApplicationRecord
  ROLES = %w[author editor moderator admin].freeze
  STATUSES = %w[active suspended].freeze

  has_secure_password
  has_many :posts, foreign_key: :author_id, dependent: :restrict_with_error

  before_validation { self.email = email.to_s.downcase.strip }

  validates :email, presence: true, length: { maximum: 254 }, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }
  validates :display_name, presence: true, length: { maximum: 80 }
  validates :role, inclusion: { in: ROLES }
  validates :status, inclusion: { in: STATUSES }
  validates :password, length: { minimum: 12 }, if: -> { password.present? }

  def active?
    status == "active"
  end

  def editor?
    %w[editor admin].include?(role)
  end

  def moderator?
    %w[moderator admin].include?(role)
  end

  def admin?
    role == "admin"
  end
end
