class Revision < ApplicationRecord
  belongs_to :post
  belongs_to :editor, class_name: "User"

  validates :number, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :post_id }
  validates :title, :body, :content_sha256, presence: true
  validate :content_hash_matches

  before_update { throw(:abort) }
  before_destroy { throw(:abort) }

  private

  def content_hash_matches
    expected = Digest::SHA256.hexdigest([title, body].join("\n"))
    errors.add(:content_sha256, "does not match content") unless ActiveSupport::SecurityUtils.secure_compare(content_sha256.to_s, expected)
  end
end
