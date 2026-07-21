module Publishing
  class Importer
    class InvalidPayload < StandardError; end
    MAX_ARTICLES = 500

    def self.call(json:, actor:, dry_run: true)
      raise InvalidPayload, "editor role required" unless actor&.active? && actor.editor?
      raw = json.to_s
      raise InvalidPayload, "payload is too large" if raw.bytesize > 5.megabytes
      data = JSON.parse(raw)
      raise InvalidPayload, "unsupported schema version" unless data["schema_version"] == 1
      articles = data["articles"]
      raise InvalidPayload, "articles must be an array" unless articles.is_a?(Array)
      raise InvalidPayload, "too many articles" if articles.length > MAX_ARTICLES

      errors = validate_articles(articles, actor)
      run = ImportRun.create!(actor: actor, status: errors.empty? ? "validated" : "rejected", dry_run: dry_run,
                              record_count: articles.length, payload_sha256: Digest::SHA256.hexdigest(raw), errors_json: errors.to_json)
      return run if dry_run || errors.any?

      Post.transaction do
        articles.each { |record| import_article(record, actor) }
        run.update!(status: "completed")
      end
      run
    rescue JSON::ParserError
      raise InvalidPayload, "payload is not valid JSON"
    end

    def self.validate_articles(articles, actor)
      articles.each_with_index.flat_map do |record, index|
        unless record.is_a?(Hash)
          next ["articles[#{index}] must be an object"]
        end
        post = Post.new(title: record["title"], body: record["body"], excerpt: record["excerpt"], author: actor, status: "draft")
        record_errors = []
        record_errors << "articles[#{index}]: #{post.errors.full_messages.join(', ')}" unless post.valid?
        record_errors.concat(validate_terms(record["categories"], index, "categories", 20, 80))
        record_errors.concat(validate_terms(record["tags"], index, "tags", 30, 40))
        record_errors
      end
    end
    private_class_method :validate_articles

    def self.validate_terms(value, index, field, max_items, max_length)
      return [] if value.nil?
      return ["articles[#{index}].#{field} must be an array"] unless value.is_a?(Array)
      errors = []
      errors << "articles[#{index}].#{field} has too many values" if value.length > max_items
      value.each_with_index do |term, term_index|
        valid = term.is_a?(String) && term.strip.present? && term.length <= max_length && term.parameterize.present?
        errors << "articles[#{index}].#{field}[#{term_index}] is invalid" unless valid
      end
      errors
    end
    private_class_method :validate_terms

    def self.import_article(record, actor)
      post = Post.create!(title: record["title"], body: record["body"], excerpt: record["excerpt"], author: actor, status: "draft")
      post.categories = Array(record["categories"]).first(20).map { |name| Category.find_or_create_by!(name: name.to_s.first(80)) }
      post.tags = Array(record["tags"]).first(30).map { |name| Tag.find_or_create_by!(name: name.to_s.first(40)) }
    end
    private_class_method :import_article
  end
end
