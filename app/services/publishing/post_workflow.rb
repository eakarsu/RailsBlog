module Publishing
  class PostWorkflow
    class InvalidTransition < StandardError; end
    class Forbidden < StandardError; end

    TRANSITIONS = {
      "submit" => { from: %w[draft rejected], to: "review" },
      "publish" => { from: %w[review], to: "published" },
      "reject" => { from: %w[review], to: "rejected" },
      "archive" => { from: %w[draft rejected published], to: "archived" }
    }.freeze

    def self.call(post:, actor:, action:, reason: nil)
      new(post, actor, action.to_s, reason).call
    end

    def initialize(post, actor, action, reason)
      @post, @actor, @action, @reason = post, actor, action, reason.to_s.strip.presence
    end

    def call
      transition = TRANSITIONS.fetch(@action) { raise InvalidTransition, "unknown action" }
      Post.transaction do
        @post.lock!
        raise InvalidTransition, "cannot #{@action} from #{@post.status}" unless transition[:from].include?(@post.status)
        authorize!
        validate_reason!
        from = @post.status
        @post.status = transition[:to]
        @post.published_at = @action == "publish" ? Time.current : nil
        @post.save!
        @post.publication_events.create!(actor: @actor, from_status: from, to_status: @post.status, reason: @reason)
      end
      @post
    end

    private

    def authorize!
      allowed = case @action
                when "submit" then Publishing::Policy.new(@actor, @post).edit?
                when "publish", "reject" then @actor&.active? && @actor.editor?
                when "archive" then @actor&.active? && (@actor.editor? || (@post.author_id == @actor.id && @post.status != "published"))
                end
      raise Forbidden, "role cannot perform transition" unless allowed
      if @action == "publish" && @post.author_id == @actor.id && !@actor.admin?
        raise Forbidden, "an editor cannot publish their own article"
      end
    end

    def validate_reason!
      raise InvalidTransition, "a reason is required" if %w[reject archive].include?(@action) && @reason.blank?
    end
  end
end
