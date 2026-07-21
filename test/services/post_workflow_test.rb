require "test_helper"

class PostWorkflowTest < ActiveSupport::TestCase
  test "author submits and an independent editor publishes with audit events" do
    author = create_user
    editor = create_user(role: "editor")
    post = create_post(author: author)

    Publishing::PostWorkflow.call(post: post, actor: author, action: :submit)
    assert_equal "review", post.reload.status
    Publishing::PostWorkflow.call(post: post, actor: editor, action: :publish)
    assert_equal "published", post.reload.status
    assert post.published_at.present?
    assert_equal [["draft", "review"], ["review", "published"]], post.publication_events.order(:id).pluck(:from_status, :to_status)
  end

  test "editor cannot publish their own article and invalid transitions fail" do
    editor = create_user(role: "editor")
    post = create_post(author: editor, status: "review")
    assert_raises(Publishing::PostWorkflow::Forbidden) do
      Publishing::PostWorkflow.call(post: post, actor: editor, action: :publish)
    end
    assert_raises(Publishing::PostWorkflow::InvalidTransition) do
      Publishing::PostWorkflow.call(post: create_post(author: editor), actor: editor, action: :publish)
    end
  end

  test "editing creates an immutable revision and unpublishes into review" do
    author = create_user
    editor = create_user(role: "editor")
    post = create_post(author: author, status: "published")
    Publishing::PostEditor.call(post: post, actor: editor, attributes: { title: "Revised title" }, reason: "Accuracy")
    assert_equal "review", post.reload.status
    assert_nil post.published_at
    revision = post.revisions.first
    assert_equal "A substantial article", revision.title
    assert_not revision.update(body: "tampered")
  end
end
