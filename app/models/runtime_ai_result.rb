class RuntimeAiResult < ApplicationRecord
  belongs_to :user

  validates :prompt, :content, :provider, :model, presence: true
end
