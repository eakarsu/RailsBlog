class Comment < ApplicationRecord
  STATUSES = %w[pending approved rejected spam].freeze

  belongs_to :post
  belongs_to :moderated_by, class_name: "User", optional: true
  has_many :moderation_events, dependent: :restrict_with_error

  validates :author, presence: true, length: { maximum: 80 }
  validates :email, length: { maximum: 254 }, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :body, presence: true, length: { in: 2..5_000 }
  validates :status, inclusion: { in: STATUSES }
  validates :ip_digest, presence: true

  before_validation :normalize_input
  before_validation :score_spam, on: :create

  scope :visible, -> { where(status: "approved") }

  private

  def normalize_input
    self.author = author.to_s.unicode_normalize(:nfc).delete("\u0000").strip
    self.email = email.to_s.downcase.strip.presence
    self.body = body.to_s.unicode_normalize(:nfc).delete("\u0000").strip
  end

  def score_spam
    links = body.to_s.scan(%r{https?://}i).length
    repeated = body.to_s.match?(/(.)\1{9,}/) ? 2 : 0
    self.spam_score = links * 2 + repeated
    self.status = "spam" if spam_score >= 6
  end
end
