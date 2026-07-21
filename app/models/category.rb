class Category < ApplicationRecord
  has_many :post_categories, dependent: :restrict_with_error
  has_many :posts, through: :post_categories
  before_validation { self.slug = name.to_s.parameterize }
  validates :name, presence: true, length: { maximum: 80 }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }
end
