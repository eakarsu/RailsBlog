class PublicationEvent < ApplicationRecord
  belongs_to :post
  belongs_to :actor, class_name: "User"
  validates :from_status, :to_status, presence: true
  before_update { throw(:abort) }
  before_destroy { throw(:abort) }
end
