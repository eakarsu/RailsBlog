require "test_helper"

class CommentTest < ActiveSupport::TestCase
  test "high-link comments are quarantined as spam" do
    post = create_post(author: create_user, status: "published")
    comment = post.comments.create!(author: "Reader", body: "https://a.test https://b.test https://c.test", ip_digest: "digest")
    assert_equal "spam", comment.status
  end

  test "raw script input is stored as text and rendered escaped" do
    comment = Comment.new(post: create_post(author: create_user, status: "published"), author: "<script>alert(1)</script>", body: "<script>alert(2)</script>", ip_digest: "digest")
    assert comment.valid?
    assert_includes comment.body, "<script>"
  end
end
