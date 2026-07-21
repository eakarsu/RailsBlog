require "test_helper"

class CommentModeratorTest < ActiveSupport::TestCase
  test "moderator approval is recorded immutably" do
    post = create_post(author: create_user, status: "published")
    comment = post.comments.create!(author: "Reader", body: "Helpful response", ip_digest: "digest")
    moderator = create_user(role: "moderator")
    Publishing::CommentModerator.call(comment: comment, moderator: moderator, decision: :approve, reason: "Constructive")
    assert_equal "approved", comment.reload.status
    assert_equal "pending", comment.moderation_events.first.from_status
    assert_not comment.moderation_events.first.destroy
  end

  test "author cannot moderate" do
    comment = create_post(author: create_user, status: "published").comments.create!(author: "R", body: "Readable", ip_digest: "d")
    assert_raises(Publishing::CommentModerator::Forbidden) do
      Publishing::CommentModerator.call(comment: comment, moderator: create_user, decision: :approve, reason: "No")
    end
  end
end
