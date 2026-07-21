require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "normalizes content and creates collision-safe slugs" do
    author = create_user
    first = create_post(author: author, title: "  Café\u0000 Notes  ")
    second = create_post(author: author, title: "Café Notes")
    assert_equal "Café Notes", first.title
    assert_equal "cafe-notes", first.slug
    assert_equal "cafe-notes-2", second.slug
  end

  test "requires publication timestamp consistency and HTTPS canonical URLs" do
    post = Post.new(author: create_user, title: "Secure article", body: "Useful body", status: "published",
                    canonical_url: "http://unsafe.example/article")
    assert_not post.valid?
    assert_includes post.errors[:published_at], "is required for published articles"
    assert post.errors[:canonical_url].any?
  end
end
