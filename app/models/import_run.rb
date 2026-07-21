class ImportRun < ApplicationRecord
  belongs_to :actor, class_name: "User"
  validates :status, inclusion: { in: %w[validated completed rejected] }
  validates :payload_sha256, presence: true

  def reported_errors
    JSON.parse(errors_json)
  rescue JSON::ParserError
    ["invalid stored error data"]
  end
end
