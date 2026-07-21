class Post < ApplicationRecord
  STATUSES = %w[draft review published rejected archived].freeze
  ALLOWED_MEDIA_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  MAX_MEDIA_BYTES = 5.megabytes

  belongs_to :author, class_name: "User"
  has_many :comments, dependent: :destroy
  has_many :revisions, dependent: :restrict_with_error
  has_many :publication_events, dependent: :restrict_with_error
  has_many :post_categories, dependent: :destroy
  has_many :categories, through: :post_categories
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags
  has_one_attached :hero_image

  validates :title, presence: true, length: { in: 2..180 }
  validates :body, presence: true, length: { maximum: 200_000 }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :status, inclusion: { in: STATUSES }
  validates :seo_title, length: { maximum: 70 }, allow_blank: true
  validates :seo_description, length: { maximum: 160 }, allow_blank: true
  validates :canonical_url, length: { maximum: 2_048 }, format: { with: /\Ahttps:\/\/[[:alnum:].-]+(?:\/[^\s]*)?\z/ }, allow_blank: true
  validate :published_timestamp_consistent
  validate :acceptable_hero_image

  before_validation :normalize_content
  before_validation :assign_unique_slug, on: :create

  scope :published, -> { where(status: "published").where("published_at <= ?", Time.current) }
  scope :recent_first, -> { order(published_at: :desc, created_at: :desc) }

  def to_param
    slug
  end

  private

  def normalize_content
    self.title = title.to_s.unicode_normalize(:nfc).delete("\u0000").strip
    self.body = body.to_s.unicode_normalize(:nfc).delete("\u0000").strip
    self.excerpt = excerpt.to_s.unicode_normalize(:nfc).delete("\u0000").strip.presence
    self.seo_title = seo_title.to_s.strip.presence
    self.seo_description = seo_description.to_s.strip.presence
    self.canonical_url = canonical_url.to_s.strip.presence
  end

  def assign_unique_slug
    base = title.to_s.parameterize.presence || "article"
    candidate = base
    suffix = 2
    while self.class.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base}-#{suffix}"
      suffix += 1
    end
    self.slug = candidate
  end

  def published_timestamp_consistent
    errors.add(:published_at, "is required for published articles") if status == "published" && published_at.blank?
    errors.add(:published_at, "must be empty until publication") if status != "published" && published_at.present?
  end

  def acceptable_hero_image
    return unless hero_image.attached?
    errors.add(:hero_image, "must be a JPEG, PNG, WebP, or GIF") unless ALLOWED_MEDIA_TYPES.include?(hero_image.blob.content_type)
    errors.add(:hero_image, "must be 5 MB or smaller") if hero_image.blob.byte_size > MAX_MEDIA_BYTES
  end
end
