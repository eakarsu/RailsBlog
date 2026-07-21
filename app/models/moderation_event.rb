class ModerationEvent < ApplicationRecord
  belongs_to :comment
  belongs_to :moderator, class_name: "User"
  validates :from_status, :to_status, :reason, presence: true
  before_update { throw(:abort) }
  before_destroy { throw(:abort) }
end
