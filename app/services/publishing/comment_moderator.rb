module Publishing
  class CommentModerator
    class Forbidden < StandardError; end
    class InvalidDecision < StandardError; end

    def self.call(comment:, moderator:, decision:, reason:)
      raise Forbidden, "moderator role required" unless moderator&.active? && moderator.moderator?
      target = { "approve" => "approved", "reject" => "rejected", "spam" => "spam" }.fetch(decision.to_s) do
        raise InvalidDecision, "unknown moderation decision"
      end
      explanation = reason.to_s.strip
      raise InvalidDecision, "reason is required" if explanation.blank?

      Comment.transaction do
        comment.lock!
        raise InvalidDecision, "comment already decided" unless %w[pending spam].include?(comment.status)
        from = comment.status
        comment.update!(status: target, moderated_by: moderator, moderated_at: Time.current, moderation_reason: explanation)
        comment.moderation_events.create!(moderator: moderator, from_status: from, to_status: target, reason: explanation)
      end
      comment
    end
  end
end
