class Tag < ApplicationRecord
  has_many :post_tags, dependent: :restrict_with_error
  has_many :posts, through: :post_tags
  before_validation { self.slug = name.to_s.parameterize }
  validates :name, presence: true, length: { maximum: 40 }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }
end
