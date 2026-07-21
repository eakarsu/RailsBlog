class MediaController < ApplicationController
  def show
    blob = ActiveStorage::Blob.find_signed!(params[:signed_id])
    not_found and return unless Post::ALLOWED_MEDIA_TYPES.include?(blob.content_type)
    expires_in 1.hour, public: true
    send_data blob.download, filename: blob.filename.to_s, type: blob.content_type, disposition: "inline"
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    not_found
  end
end
