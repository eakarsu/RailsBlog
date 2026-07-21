module Publishing
  class PostEditor
    class Forbidden < StandardError; end

    def self.call(post:, actor:, attributes:, reason: nil)
      raise Forbidden, "article cannot be edited" unless Policy.new(actor, post).edit?

      Post.transaction do
        post.lock!
        if post.persisted? && (post.title_changed? || post.body_changed?)
          raise ActiveRecord::StaleObjectError.new(post, "update")
        end
        if post.persisted? && attributes.slice(:title, :body, "title", "body").present?
          next_number = post.revisions.maximum(:number).to_i + 1
          post.revisions.create!(
            editor: actor,
            number: next_number,
            title: post.title,
            body: post.body,
            reason: reason.to_s.strip.presence,
            content_sha256: Digest::SHA256.hexdigest([post.title, post.body].join("\n"))
          )
        end
        post.assign_attributes(attributes)
        if post.status == "published" && post.changed?
          post.status = "review"
          post.published_at = nil
        end
        post.save!
      end
      post
    end
  end
end
