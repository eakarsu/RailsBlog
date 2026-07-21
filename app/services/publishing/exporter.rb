module Publishing
  class Exporter
    SCHEMA_VERSION = 1

    def self.call(actor: nil)
      relation = actor&.editor? ? Post.all : Post.published
      payload = {
        schema_version: SCHEMA_VERSION,
        exported_at: Time.current.iso8601,
        articles: relation.order(:id).map do |post|
          {
            title: post.title,
            body: post.body,
            excerpt: post.excerpt,
            slug: post.slug,
            status: post.status,
            published_at: post.published_at&.iso8601,
            categories: post.categories.order(:name).pluck(:name),
            tags: post.tags.order(:name).pluck(:name)
          }
        end
      }
      canonical = JSON.generate(payload)
      { payload: payload, sha256: Digest::SHA256.hexdigest(canonical) }
    end
  end
end
