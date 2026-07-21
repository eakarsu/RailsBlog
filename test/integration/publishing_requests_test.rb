require "test_helper"

class PublishingRequestsTest < ActionDispatch::IntegrationTest
  test "public sees published content but cannot read drafts or create articles" do
    author = create_user
    published = create_post(author: author, status: "published", title: "Public reporting")
    draft = create_post(author: author, title: "Confidential draft")
    get post_path(published)
    assert_response :success
    assert_includes response.body, "Public reporting"
    get post_path(draft)
    assert_response :not_found
    post posts_path, params: { post: { title: "Attack", body: "No" } }
    assert_redirected_to login_path
  end

  test "authenticated author creates draft and cannot force published status" do
    author = create_user
    sign_in(author)
    assert_difference("Post.count", 1) do
      post posts_path, params: { post: { title: "New reporting", body: "Verified material", status: "published" } }
    end
    assert_equal "draft", Post.last.status
  end

  test "comment endpoint uses nested slug, hides email, and queues moderation" do
    article = create_post(author: create_user, status: "published")
    assert_difference("Comment.count", 1) do
      post post_comments_path(article), params: { comment: { author: "Reader", email: "reader@example.test", body: "A civil comment" } }, headers: { "REMOTE_ADDR" => "203.0.113.10" }
    end
    assert_equal "pending", Comment.last.status
    get post_path(article)
    assert_not_includes response.body, "reader@example.test"
    assert_not_includes response.body, "A civil comment"
  end

  test "honeypot accepts without persistence and failed login is generic" do
    article = create_post(author: create_user, status: "published")
    assert_no_difference("Comment.count") do
      post post_comments_path(article), params: { comment: { author: "Bot", body: "spam", website: "https://spam.test" } }
    end
    assert_response :accepted
    post session_path, params: { email: "missing@example.test", password: "wrong" }
    assert_response :unprocessable_entity
    assert_includes response.body, "Invalid email or password"
  end

  test "JSON login establishes a verifiable session without exposing credentials" do
    author = create_user
    post "/api/auth/login", params: { email: author.email, password: "correct horse battery staple" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal author.email, body.dig("user", "email")
    assert_not body.to_s.include?("password")

    get "/api/auth/me", as: :json
    assert_response :success
    assert_equal author.id, JSON.parse(response.body).dig("user", "id")
  end

  test "comment posting is rate limited by source address" do
    article = create_post(author: create_user, status: "published")
    5.times do |index|
      post post_comments_path(article), params: { comment: { author: "Reader", body: "Comment number #{index}" } },
           headers: { "REMOTE_ADDR" => "198.51.100.88" }
      assert_response :redirect
    end
    post post_comments_path(article), params: { comment: { author: "Reader", body: "One too many" } },
         headers: { "REMOTE_ADDR" => "198.51.100.88" }
    assert_response :too_many_requests
  end

  test "export has a checksum and never includes credentials or comment PII" do
    create_post(author: create_user, status: "published")
    get export_path
    assert_response :success
    assert_match(/\A[0-9a-f]{64}\z/, response.headers["X-Content-SHA256"])
    assert_not_includes response.body, "password_digest"
    assert_not_includes response.body, "email"
  end

  test "editorial and moderation queues enforce their distinct roles" do
    author = create_user
    sign_in(author)
    get editorial_path
    assert_response :forbidden
    get comments_path
    assert_response :forbidden

    editor = create_user(role: "editor")
    sign_in(editor)
    get editorial_path
    assert_response :success
    get comments_path
    assert_response :forbidden

    moderator = create_user(role: "moderator")
    sign_in(moderator)
    get comments_path
    assert_response :success
  end

  test "authorized author can inspect and restore an immutable revision" do
    author = create_user
    post_record = create_post(author: author)
    Publishing::PostEditor.call(post: post_record, actor: author, attributes: { title: "Current title" }, reason: "Update")
    revision = post_record.revisions.first
    sign_in(author)
    get post_revision_path(post_record, revision)
    assert_response :success
    post restore_post_revision_path(post_record, revision), params: { reason: "Prefer original wording" }
    assert_redirected_to post_path(post_record)
    assert_equal "A substantial article", post_record.reload.title
    assert_equal 2, post_record.revisions.count
  end

  test "signed media delivery serves an allowed attachment and rejects bad signatures" do
    article = create_post(author: create_user, status: "published")
    png = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=")
    article.hero_image.attach(io: StringIO.new(png), filename: "pixel.png", content_type: "image/png")
    get media_path(signed_id: article.hero_image.blob.signed_id, filename: "pixel.png")
    assert_response :success
    assert_equal "image/png", response.media_type
    get media_path(signed_id: "tampered", filename: "pixel.png")
    assert_response :not_found
  end
end
